module udp_rx #(
    //parameter define
    //������MAC��ַ 00-11-22-33-44-55
    parameter BOARD_MAC = 48'h00_11_22_33_44_55,
    //������IP��ַ 192.168.1.10 
    parameter BOARD_IP  = {8'd192, 8'd168, 8'd1, 8'd10}
) (
    input clk,    //ʱ���ź�
    input resetn, //��λ�źţ��͵�ƽ��Ч

    input       gmii_rxd_valid,  //GMII����������Ч�ź�
    input [7:0] gmii_rxd_data,   //GMII��������

    output reg          rec_pkt_start,
    output reg          rec_pkt_done,   //��̫���������ݽ�������ź�
    output reg          rec_en,         //��̫�����յ�����ʹ���ź�
    output reg [ 7 : 0] rec_data,
    output     [15 : 0] rec_dest_port,
    output reg [15 : 0] rec_byte_num    //��̫�����յ���Ч���� ��λ:byte    
);


  localparam st_idle = 7'b000_0001;  //��ʼ״̬���ȴ�����ǰ����
  localparam st_preamble = 7'b000_0010;  //����ǰ����״̬ 
  localparam st_eth_head = 7'b000_0100;  //������̫��֡ͷ
  localparam st_ip_head = 7'b000_1000;  //����IP�ײ�
  localparam st_udp_head = 7'b001_0000;  //����UDP�ײ�
  localparam st_rx_data = 7'b010_0000;  //������Ч����
  localparam st_rx_end = 7'b100_0000;  //���ս���

  localparam ETH_TYPE = 16'h0800;  //��̫��Э������ IPЭ��
  localparam UDP_TYPE = 8'd17;  //UDPЭ������

  //reg define
  reg [ 6:0] cur_state;
  reg [ 6:0] next_state;

  reg        skip_en;  //����״̬��תʹ���ź�
  reg        error_en;  //��������ʹ���ź�
  reg [ 4:0] cnt;  //�������ݼ�����
  reg [47:0] des_mac;  //Ŀ��MAC��ַ
  reg [15:0] eth_type;  //��̫������
  reg [31:0] des_ip;  //Ŀ��IP��ַ
  reg [ 5:0] ip_head_byte_num;  //IP�ײ�����
  reg [15:0] udp_dest_port;  //UDP Ŀ�ĵ� �˿ں�
  reg [15:0] udp_byte_num;  //UDP����
  reg [15:0] data_byte_num;  //���ݳ���
  reg [15:0] data_cnt;  //��Ч���ݼ���    

  //*****************************************************
  //**                    main code
  //*****************************************************

  assign rec_dest_port = udp_dest_port;
  //(����ʽ״̬��)ͬ��ʱ������״̬ת��
  always @(posedge clk or negedge resetn) begin
    if (!resetn) cur_state <= st_idle;
    else cur_state <= next_state;
  end

  //����߼��ж�״̬ת������
  always @(*) begin
    next_state = st_idle;
    case (cur_state)
      st_idle: begin  //�ȴ�����ǰ����
        if (skip_en) next_state = st_preamble;
        else next_state = st_idle;
      end
      st_preamble: begin  //����ǰ����
        if (skip_en) next_state = st_eth_head;
        else if (error_en) next_state = st_rx_end;
        else next_state = st_preamble;
      end
      st_eth_head: begin  //������̫��֡ͷ
        if (skip_en) next_state = st_ip_head;
        else if (error_en) next_state = st_rx_end;
        else next_state = st_eth_head;
      end
      st_ip_head: begin  //����IP�ײ�
        if (skip_en) next_state = st_udp_head;
        else if (error_en) next_state = st_rx_end;
        else next_state = st_ip_head;
      end
      st_udp_head: begin  //����UDP�ײ�
        if (skip_en) next_state = st_rx_data;
        else next_state = st_udp_head;
      end
      st_rx_data: begin  //������Ч����
        if (skip_en) next_state = st_rx_end;
        else next_state = st_rx_data;
      end
      st_rx_end: begin  //���ս���
        if (skip_en) next_state = st_idle;
        else next_state = st_rx_end;
      end
      default: next_state = st_idle;
    endcase
  end

  //ʱ���·����״̬���,������̫������
  always @(posedge clk or negedge resetn) begin
    if (!resetn) begin
      skip_en <= 1'b0;
      error_en <= 1'b0;
      cnt <= 5'd0;
      des_mac <= 48'd0;
      eth_type <= 16'd0;
      des_ip <= 32'd0;
      ip_head_byte_num <= 6'd0;
      udp_byte_num <= 16'd0;
      data_byte_num <= 16'd0;
      data_cnt <= 16'd0;
      rec_en <= 1'b0;
      rec_data <= 32'd0;
      rec_pkt_start <= 1'b0;
      rec_pkt_done <= 1'b0;
      rec_byte_num <= 16'd0;
      udp_dest_port <= 16'd0;
    end else begin
      skip_en <= 1'b0;
      error_en <= 1'b0;
      rec_pkt_start <= 1'b0;
      rec_pkt_done <= 1'b0;
      case (next_state)
        st_idle: begin
          if ((gmii_rxd_valid == 1'b1) && (gmii_rxd_data == 8'h55)) skip_en <= 1'b1;
        end
        st_preamble: begin
          if (gmii_rxd_valid) begin  //����ǰ����
            cnt <= cnt + 5'd1;
            if ((cnt < 5'd6) && (gmii_rxd_data != 8'h55))  //7��8'h55  
              error_en <= 1'b1;
            else if (cnt == 5'd6) begin
              cnt <= 5'd0;
              if (gmii_rxd_data == 8'hd5)  //1��8'hd5
                skip_en <= 1'b1;
              else error_en <= 1'b1;
            end
          end
        end
        st_eth_head: begin
          if (gmii_rxd_valid) begin
            cnt <= cnt + 5'b1;
            if (cnt < 5'd6) des_mac <= {des_mac[39:0], gmii_rxd_data};  //Ŀ��MAC��ַ
            else if (cnt == 5'd12) eth_type[15:8] <= gmii_rxd_data;  //��̫��Э������
            else if (cnt == 5'd13) begin
              eth_type[7:0] <= gmii_rxd_data;
              cnt <= 5'd0;
              //�ж�MAC��ַ�Ƿ�Ϊ������MAC��ַ���߹�����ַ
              if (((des_mac == BOARD_MAC) || (des_mac == 48'hff_ff_ff_ff_ff_ff)) &&
                  eth_type[15:8] == ETH_TYPE[15:8] && gmii_rxd_data == ETH_TYPE[7:0])
                skip_en <= 1'b1;
              else error_en <= 1'b1;
            end
          end
        end
        st_ip_head: begin
          if (gmii_rxd_valid) begin
            cnt <= cnt + 5'd1;
            if (cnt == 5'd0) ip_head_byte_num <= {gmii_rxd_data[3:0], 2'd0};
            else if (cnt == 5'd9) begin
              if (gmii_rxd_data != UDP_TYPE) begin
                //�����ǰ���յ����ݲ���UDPЭ�飬ֹͣ��������                        
                error_en <= 1'b1;
                cnt <= 5'd0;
              end
            end else if ((cnt >= 5'd16) && (cnt <= 5'd18))
              des_ip <= {des_ip[23:0], gmii_rxd_data};  //Ŀ��IP��ַ
            else if (cnt == 5'd19) begin
              des_ip <= {des_ip[23:0], gmii_rxd_data};
              //�ж�IP��ַ�Ƿ�Ϊ������IP��ַ
              if ((des_ip[23:0] == BOARD_IP[31:8]) && (gmii_rxd_data == BOARD_IP[7:0])) begin
                skip_en <= 1'b1;
                cnt <= 5'd0;
              end else begin
                //IP����ֹͣ��������                        
                error_en <= 1'b1;
                cnt <= 5'd0;
              end
            end
          end
        end
        st_udp_head: begin
          if (gmii_rxd_valid) begin
            cnt <= cnt + 5'd1;
            if (cnt == 5'd2) begin
              //����UDPĿ�Ķ˿ڸ�8λ 
              udp_dest_port[15:8] <= gmii_rxd_data;
            end else if (cnt == 5'd3) begin
              //����UDPĿ�Ķ˿ڵ�8λ 
              udp_dest_port[7:0] <= gmii_rxd_data;
            end else if (cnt == 5'd4) begin
              //����UDP�ֽڳ��� 
              udp_byte_num[15:8] <= gmii_rxd_data;
            end else if (cnt == 5'd5) begin
              //����UDP�ֽڳ��� 
              udp_byte_num[7:0] <= gmii_rxd_data;
            end else if (cnt == 5'd6) begin
              //��Ч�����ֽڳ��ȣ���UDP�ײ�8���ֽڣ����Լ�ȥ8��
              data_byte_num <= udp_byte_num - 16'd8;
              rec_byte_num  <= udp_byte_num - 16'd8;
              rec_pkt_start <= 1;
            end else if (cnt == 5'd7) begin
              //UDPͷ��8�ֽڽ������
              rec_pkt_start <= 1;
              data_byte_num <= data_byte_num;
              rec_byte_num <= rec_byte_num;
              skip_en <= 1'b1;
              cnt <= 5'd0;
            end
          end
        end
        st_rx_data: begin
          //��������       
          rec_pkt_start <= 0;
          rec_byte_num  <= rec_byte_num;
          if (gmii_rxd_valid) begin
            data_cnt <= data_cnt + 16'd1;
            rec_data <= gmii_rxd_data;
            rec_en   <= 1'b1;
            if (data_cnt == data_byte_num - 16'd1) begin
              skip_en      <= 1'b1;  //��Ч���ݽ������
              data_cnt     <= 16'd0;
              rec_pkt_done <= 1'b1;
              rec_byte_num <= data_byte_num;
            end
          end
        end
        st_rx_end: begin  //�������ݽ������   
          rec_en <= 1'b0;
          if (gmii_rxd_valid == 1'b0 && skip_en == 1'b0) skip_en <= 1'b1;
        end
        default: ;
      endcase
    end
  end

endmodule
