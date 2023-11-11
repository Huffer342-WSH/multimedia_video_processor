//****************************************Copyright (c)***********************************//
//ԭ�Ӹ����߽�ѧƽ̨��www.yuanzige.com
//����֧�֣�www.openedv.com
//�Ա����̣�http://openedv.taobao.com 
//��ע΢�Ź���ƽ̨΢�źţ�"����ԭ��"����ѻ�ȡZYNQ & FPGA & STM32 & LINUX���ϡ�
//��Ȩ���У�����ؾ���
//Copyright(C) ����ԭ�� 2018-2028
//All rights reserved                                  
//----------------------------------------------------------------------------------------
// File name:           icmp_rx
// Last modified Date:  2022/9/22 9:20:14
// Last Version:        V1.0
// Descriptions:        ��̫�����ݽ���ģ��
//----------------------------------------------------------------------------------------
// Created by:          ����ԭ��
// Created date:        2022/9/22 9:20:14
// Version:             V1.0
// Descriptions:        The original version
//
//----------------------------------------------------------------------------------------
//****************************************************************************************//

module icmp_rx (
    input clk,    //ʱ���ź�
    input resetn, //��λ�źţ��͵�ƽ��Ч

    input             gmii_rxd_valid,  //GMII����������Ч�ź�
    input      [ 7:0] gmii_rxd_data,   //GMII��������
    output reg        rec_pkt_done,    //��̫���������ݽ�������ź�
    output reg        rec_en,          //��̫�����յ�����ʹ���ź�
    output reg [ 7:0] rec_data,        //��̫�����յ�����
    output reg [15:0] rec_byte_num,    //��̫�����յ���Ч���� ��λ:byte 

    output reg [15:0] icmp_id,        //ICMP��ʶ��
    output reg [15:0] icmp_seq,       //ICMP���к�
    output reg [31:0] reply_checksum  //��������У��

);

  //parameter define
  //������MAC��ַ 00-11-22-33-44-55
  parameter BOARD_MAC = 48'h00_11_22_33_44_55;
  //������IP��ַ 192.168.1.10 
  parameter BOARD_IP = {8'd192, 8'd168, 8'd1, 8'd10};

  //״̬��״̬����
  localparam st_idle = 7'b000_0001;  //��ʼ״̬���ȴ�����ǰ����
  localparam st_preamble = 7'b000_0010;  //����ǰ����״̬ 
  localparam st_eth_head = 7'b000_0100;  //������̫��֡ͷ
  localparam st_ip_head = 7'b000_1000;  //����IP�ײ�
  localparam st_icmp_head = 7'b001_0000;  //����ICMP�ײ�
  localparam st_rx_data = 7'b010_0000;  //������Ч����
  localparam st_rx_end = 7'b100_0000;  //���ս���

  //��̫�����Ͷ���
  localparam ETH_TYPE = 16'h0800;  //��̫��Э������ IPЭ��
  localparam ICMP_TYPE = 8'd1;  //ICMPЭ������

  //ICMP��������:��������
  localparam ECHO_REQUEST = 8'h08;

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
  reg [15:0] total_length;  //IP���� 
  reg [ 1:0] rec_en_cnt;  //8bitת32bit������
  reg [ 7:0] icmp_type;  //ICMP��������:���ڱ�ʶ�������͵Ĳ���Ļ��߲�ѯ���͵ı��汨��
  reg [ 7:0] icmp_code;  //ICMP���Ĵ���:����ICMP����ĵ����ͣ���һ�����������ԭ�򣬴���ֵ��ͬ��Ӧ�Ĵ���Ҳ��ͬ
  //���磺����Ϊ11�Ҵ���Ϊ0����ʾ���ݴ�������г�ʱ�ˣ���ʱ�ľ���ԭ����TTLֵΪ0�����ݱ���������
  reg [15:0] icmp_checksum;  //����У���:���ݷ��͵�Ŀ�ĵغ���Ҫ��ICMP���ݱ�����һ��У�飬���ڼ�����ݱ����Ƿ��д���
  reg [15:0] icmp_data_length;  //data length register
  reg [15:0] icmp_rx_cnt;  //�������ݼ���
  reg [ 7:0] icmp_rx_data_d0;
  reg [31:0] reply_checksum_add;
  //****************************************************
  //**                    main code
  //*****************************************************

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
        if (skip_en) next_state = st_icmp_head;
        else if (error_en) next_state = st_rx_end;
        else next_state = st_ip_head;
      end
      st_icmp_head: begin  //����ICMP�ײ�
        if (skip_en) next_state = st_rx_data;
        else if (error_en) next_state = st_rx_end;
        else next_state = st_icmp_head;
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

      total_length <= 16'd0;

      icmp_type <= 8'd0;
      icmp_code <= 8'd0;
      icmp_checksum <= 16'd0;
      icmp_id <= 16'd0;
      icmp_seq <= 16'd0;

      icmp_rx_data_d0 <= 8'd0;
      reply_checksum <= 32'd0;  //�ۼ�
      reply_checksum_add <= 32'd0;
      icmp_rx_cnt <= 16'd0;
      icmp_data_length <= 16'd0;

      rec_en_cnt <= 2'd0;
      rec_en <= 1'b0;
      rec_data <= 32'd0;
      rec_pkt_done <= 1'b0;
      rec_byte_num <= 16'd0;
    end else begin
      skip_en <= 1'b0;
      error_en <= 1'b0;
      rec_pkt_done <= 1'b0;
      case (next_state)
        st_idle: begin
          if ((gmii_rxd_valid == 1'b1) && (gmii_rxd_data == 8'h55)) skip_en <= 1'b1;
          else;
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
            end else;
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
              if (((des_mac == BOARD_MAC) || (des_mac == 48'hff_ff_ff_ff_ff_ff)) && eth_type[15:8] == ETH_TYPE[15:8] && gmii_rxd_data == ETH_TYPE[7:0]) skip_en <= 1'b1;
              else error_en <= 1'b1;
            end else;
          end else;
        end
        st_ip_head: begin
          if (gmii_rxd_valid) begin  //cnt ip��20��byte����
            cnt <= cnt + 5'd1;
            if (cnt == 5'd0) ip_head_byte_num <= {gmii_rxd_data[3:0], 2'd0};
            else if (cnt == 5'd2) total_length[15:8] <= gmii_rxd_data;
            else if (cnt == 5'd3) total_length[7:0] <= gmii_rxd_data;
            else if (cnt == 5'd4)
              //��Ч�����ֽڳ��ȣ���IP�ײ�20���ֽڣ�icmp�ײ�8���ֽڣ����Լ�ȥ28��
              icmp_data_length <= total_length - 16'd28;
            else if (cnt == 5'd9) begin
              if (gmii_rxd_data != ICMP_TYPE) begin
                //�����ǰ���յ����ݲ���ICMPЭ�飬ֹͣ��������                        
                error_en <= 1'b1;
                cnt <= 5'd0;
              end
            end else if ((cnt >= 5'd16) && (cnt <= 5'd18)) des_ip <= {des_ip[23:0], gmii_rxd_data};  //Ŀ��IP��ַ
            else if (cnt == 5'd19) begin
              des_ip <= {des_ip[23:0], gmii_rxd_data};
              //�ж�IP��ַ�Ƿ�Ϊ������IP��ַ
              if ((des_ip[23:0] == BOARD_IP[31:8]) && (gmii_rxd_data == BOARD_IP[7:0])) begin
                if (cnt == ip_head_byte_num - 1'b1) begin
                  skip_en <= 1'b1;
                  cnt <= 5'd0;
                end
              end else begin
                //IP����ֹͣ�������� 
                error_en <= 1'b1;
                cnt <= 5'd0;
              end
            end else if (cnt == ip_head_byte_num - 1'b1) begin
              skip_en <= 1'b1;  //IP�ײ��������
              cnt     <= 5'd0;
            end else;
          end else;
        end
        st_icmp_head: begin
          if (gmii_rxd_valid) begin  //cnt ICMP��8��byte����
            cnt <= cnt + 5'd1;
            if (cnt == 5'd0) icmp_type <= gmii_rxd_data;
            else if (cnt == 5'd1) icmp_code <= gmii_rxd_data;
            else if (cnt == 5'd2) icmp_checksum[15:8] <= gmii_rxd_data;
            else if (cnt == 5'd3) icmp_checksum[7:0] <= gmii_rxd_data;
            else if (cnt == 5'd4) icmp_id[15:8] <= gmii_rxd_data;
            else if (cnt == 5'd5) icmp_id[7:0] <= gmii_rxd_data;
            else if (cnt == 5'd6) icmp_seq[15:8] <= gmii_rxd_data;
            else if (cnt == 5'd7) begin
              icmp_seq[7:0] <= gmii_rxd_data;
              //�ж�ICMP���������Ƿ��ǻ�������
              if (icmp_type == ECHO_REQUEST) begin
                skip_en <= 1'b1;
                cnt <= 5'd0;
              end else begin
                //ICMP�������ʹ���ֹͣ��������
                error_en <= 1'b1;
                cnt <= 5'd0;
              end
            end else;
          end else;
        end
        st_rx_data: begin
          //��������           
          if (gmii_rxd_valid) begin
            rec_en_cnt <= rec_en_cnt + 2'd1;
            icmp_rx_cnt <= icmp_rx_cnt + 16'd1;
            rec_data <= gmii_rxd_data;
            rec_en <= 1'b1;

            //�жϽ��յ����ݵ���ż����
            if (icmp_rx_cnt == icmp_data_length - 1) begin
              icmp_rx_data_d0 <= 8'h00;
              if (icmp_data_length[0])  //�жϽ��յ������Ƿ�Ϊ��������
                reply_checksum_add <= {8'd0, gmii_rxd_data} + reply_checksum_add;
              else reply_checksum_add <= {icmp_rx_data_d0, gmii_rxd_data} + reply_checksum_add;
            end else if (icmp_rx_cnt < icmp_data_length) begin
              icmp_rx_data_d0 <= gmii_rxd_data;
              icmp_rx_cnt <= icmp_rx_cnt + 16'd1;
              if (icmp_rx_cnt[0] == 1'b1) reply_checksum_add <= {icmp_rx_data_d0, gmii_rxd_data} + reply_checksum_add;
              else reply_checksum_add <= reply_checksum_add;
            end else;

            if (icmp_rx_cnt == icmp_data_length - 16'd1) begin
              skip_en      <= 1'b1;  //��Ч���ݽ������
              icmp_rx_cnt  <= 16'd0;
              rec_en_cnt   <= 2'd0;
              rec_pkt_done <= 1'b1;
              rec_byte_num <= icmp_data_length;
            end else;
          end else;
        end
        st_rx_end: begin  //�������ݽ������
          rec_en <= 1'b0;
          if (gmii_rxd_valid == 1'b0 && skip_en == 1'b0) begin
            reply_checksum <= reply_checksum_add;
            skip_en <= 1'b1;
            reply_checksum_add <= 32'd0;
          end else;
        end
        default: ;
      endcase
    end
  end

endmodule
