module eth_udp #(  //parameter define
    //������MAC��ַ 00-11-22-33-44-55
    parameter BOARD_MAC = 48'h00_11_22_33_44_55,
    //������IP��ַ 192.168.1.10
    parameter BOARD_IP = {8'd192, 8'd168, 8'd10, 8'd10},
    //������IP �˿� 1234
    parameter BOARD_PORT = 16'd1234,
    //Ŀ��MAC��ַ ff_ff_ff_ff_ff_ff
    parameter DES_MAC = 48'hff_ff_ff_ff_ff_ff,
    //Ŀ��IP��ַ 192.168.1.102     
    parameter DES_IP = {8'd192, 8'd168, 8'd10, 8'd102},
    //Ŀ��IP��ַ �˿� 1234
    parameter DES_PORT = 16'd1234,
    //��������IO��ʱ,�˴�Ϊ0,������ʱ(���Ϊn,��ʾ��ʱn*78ps) 
    parameter IDELAY_VALUE = 0
) (
    input        clk,         //! ϵͳʱ��
    input        resetn,      //! ϵͳ��λ�źţ��͵�ƽ��Ч 
    //PL��̫��RGMII�ӿ�   
    input        eth_rxc,     //! RGMII��������ʱ��
    input        eth_rx_ctl,  //! RGMII����������Ч�ź�
    input  [3:0] eth_rxd,     //! RGMII��������
    output       eth_txc,     //! RGMII��������ʱ��    
    output       eth_tx_ctl,  //! RGMII���������Ч�ź�
    output [3:0] eth_txd,     //! RGMII�������   


    //ԭʼ�������� ����GMII����ʱ��ʱ����
    output          gmii_clk,              //! GMII����ʱ��
    output          udp_rx_pkt_start,      //! ��̫���������ݽ��տ�ʼ�ź�
    output          udp_rx_pkt_done,       //! ��̫���������ݽ�������ź�
    output          udp_rx_pkt_en,         //! ��̫�����յ�����ʹ���ź�
    output [ 7 : 0] udp_rx_pkt_data,       //! ��̫�����յ�����
    output [15 : 0] udp_rx_pkt_dest_port,  //! ��̫������Ŀ�ĵض˿�
    output [15 : 0] udp_rx_pkt_byte_num,   //! ��̫�����յ���Ч�ֽ��� ��λ:byte 


    output [ 7:0] udp_rx_m_data_tdata,     //! ���������� ����
    output        udp_rx_m_data_tlast,     //! ���������� ��������
    output        udp_rx_m_data_tvalid,    //! ���������� ��Ч�ź�
    input         udp_rx_m_data_tready,    //! ���������� ׼���ź�
    output [15:0] udp_rx_m_data_tsize,     //! ���������� ������
    output [ 5:0] udp_rx_m_cached_pkt_num, //! ���������� �ѻ������ݰ�����


    input [ 7:0] udp_tx_s_data,   //! ���������� ����
    input        udp_tx_s_valid,  //! ���������� ��Ч�ź�
    input        udp_tx_s_start,  //! ���������� ��ʼ����
    input [15:0] udp_tx_s_tsize,  //! ���������� ������
    input        udp_tx_s_last    //! ���������� ��������
);


  //wire define

  //   wire        gmii_clk;//GMII����ʱ��
  wire        gmii_rxd_valid;  //GMII����������Ч�ź�
  wire [ 7:0] gmii_rxd_data;  //GMII��������
  wire        gmii_txd_valid;  //GMII��������ʹ���ź�
  wire [ 7:0] gmii_txd_data;  //GMII��������     

  wire        arp_gmii_tx_en;  //ARP GMII���������Ч�ź� 
  wire [ 7:0] arp_gmii_txd;  //ARP GMII�������
  wire        arp_rx_done;  //ARP��������ź�
  wire        arp_rx_type;  //ARP�������� 0:����  1:Ӧ��
  wire [47:0] src_mac;  //���յ�Ŀ��MAC��ַ
  wire [31:0] src_ip;  //���յ�Ŀ��IP��ַ    
  wire        arp_tx_en;  //ARP����ʹ���ź�
  wire        arp_tx_type;  //ARP�������� 0:����  1:Ӧ��
  wire [47:0] des_mac;  //���͵�Ŀ��MAC��ַ
  wire [31:0] des_ip;  //���͵�Ŀ��IP��ַ   
  wire        arp_tx_done;  //ARP��������ź�

  wire        icmp_gmii_tx_en;  //ICMP GMII���������Ч�ź� 
  wire [ 7:0] icmp_gmii_txd;  //ICMP GMII�������
  wire        icmp_rec_pkt_done;  //ICMP�������ݽ�������ź�
  wire        icmp_rec_en;  //ICMP���յ�����ʹ���ź�
  wire [ 7:0] icmp_rec_data;  //ICMP���յ�����
  wire [15:0] icmp_rec_byte_num;  //ICMP���յ���Ч�ֽ��� ��λ:byte 
  wire [15:0] icmp_tx_byte_num;  //ICMP���͵���Ч�ֽ��� ��λ:byte 
  wire        icmp_tx_done;  //ICMP��������ź�
  wire        icmp_tx_req;  //ICMP�����������ź�
  wire [ 7:0] icmp_tx_data;  //ICMP����������
  wire        icmp_tx_start_en;  //ICMP���Ϳ�ʼʹ���ź�

  wire        udp_gmii_tx_en;  //UDP GMII���������Ч�ź� 
  wire [ 7:0] udp_gmii_txd;  //UDP GMII�������

  wire [15:0] tx_byte_num;  //UDP���͵���Ч�ֽ��� ��λ:byte 
  wire        udp_tx_done;  //UDP��������ź�
  wire        udp_tx_req;  //UDP�����������ź�
  wire [ 7:0] udp_tx_data;  //UDP����������
  wire        tx_start_en;  //UDP���Ϳ�ʼʹ���ź�

  wire [ 7:0] rec_data;
  wire        rec_en;
  wire        tx_req;
  wire [ 7:0] tx_data;
  //*****************************************************
  //**                    main code
  //*****************************************************

  assign icmp_tx_start_en = icmp_rec_pkt_done;
  assign icmp_tx_byte_num = icmp_rec_byte_num;

  //   assign tx_start_en = rec_pkt_done;
  //   assign tx_byte_num = rec_byte_num;
  assign des_mac = src_mac;
  assign des_ip = src_ip;



  //GMII�ӿ�תRGMII�ӿ�
  gmii_to_rgmii #(
      .IDELAY_VALUE(IDELAY_VALUE)
  ) u_gmii_to_rgmii (
      .gmii_clk      (gmii_clk),
      .gmii_rxd_valid(gmii_rxd_valid),
      .gmii_rxd_data (gmii_rxd_data),
      .gmii_txd_valid(gmii_txd_valid),
      .gmii_txd_data (gmii_txd_data),

      .rgmii_rxc   (eth_rxc),
      .rgmii_rx_ctl(eth_rx_ctl),
      .rgmii_rxd   (eth_rxd),
      .rgmii_txc   (eth_txc),
      .rgmii_tx_ctl(eth_tx_ctl),
      .rgmii_txd   (eth_txd)
  );

  //ARPͨ��
  arp #(
      .BOARD_MAC(BOARD_MAC),  //��������
      .BOARD_IP (BOARD_IP),
      .DES_MAC  (DES_MAC),
      .DES_IP   (DES_IP)
  ) u_arp (
      .resetn(resetn),

      .gmii_rx_clk   (gmii_clk),
      .gmii_rxd_valid(gmii_rxd_valid),
      .gmii_rxd_data (gmii_rxd_data),
      .gmii_tx_clk   (gmii_clk),
      .gmii_txd_valid(arp_gmii_tx_en),
      .gmii_txd_data (arp_gmii_txd),

      .arp_rx_done(arp_rx_done),
      .arp_rx_type(arp_rx_type),
      .src_mac    (src_mac),
      .src_ip     (src_ip),
      .arp_tx_en  (arp_tx_en),
      .arp_tx_type(arp_tx_type),
      .des_mac    (des_mac),
      .des_ip     (des_ip),
      .tx_done    (arp_tx_done)
  );

  //ICMPͨ��
  icmp #(
      .BOARD_MAC(BOARD_MAC),  //��������
      .BOARD_IP (BOARD_IP),
      .DES_MAC  (DES_MAC),
      .DES_IP   (DES_IP)
  ) u_icmp (
      .resetn(resetn),

      .gmii_rx_clk   (gmii_clk),
      .gmii_rxd_valid(gmii_rxd_valid),
      .gmii_rxd_data (gmii_rxd_data),
      .gmii_tx_clk   (gmii_clk),
      .gmii_txd_valid(icmp_gmii_tx_en),
      .gmii_txd_data (icmp_gmii_txd),

      .rec_pkt_done(icmp_rec_pkt_done),
      .rec_en      (icmp_rec_en),
      .rec_data    (icmp_rec_data),
      .rec_byte_num(icmp_rec_byte_num),
      .tx_start_en (icmp_tx_start_en),
      .tx_data     (icmp_tx_data),
      .tx_byte_num (icmp_tx_byte_num),
      .des_mac     (des_mac),
      .des_ip      (des_ip),
      .tx_done     (icmp_tx_done),
      .tx_req      (icmp_tx_req)
  );

  //UDPͨ��
  udp #(
      .BOARD_MAC(BOARD_MAC),  //��������
      .BOARD_IP (BOARD_IP),
      .BOARD_PORT (BOARD_PORT),
      .DES_MAC  (DES_MAC),
      .DES_IP   (DES_IP),
      .DES_PORT (DES_PORT)
  ) u_udp (
      .resetn(resetn),

      .gmii_rx_clk   (gmii_clk),
      .gmii_rxd_valid(gmii_rxd_valid),
      .gmii_rxd_data (gmii_rxd_data),
      .gmii_tx_clk   (gmii_clk),
      .gmii_txd_valid(udp_gmii_tx_en),
      .gmii_txd_data (udp_gmii_txd),

      .des_mac(des_mac),
      .des_ip (des_ip),

      .rec_pkt_start(udp_rx_pkt_start),
      .rec_pkt_done (udp_rx_pkt_done),
      .rec_en       (udp_rx_pkt_en),
      .rec_data     (udp_rx_pkt_data),
      .rec_dest_port(udp_rx_pkt_dest_port),
      .rec_byte_num (udp_rx_pkt_byte_num),

      .tx_start_en(tx_start_en),
      .tx_data    (udp_tx_data),
      .tx_byte_num(tx_byte_num),
      .tx_done    (udp_tx_done),
      .tx_req     (udp_tx_req)
  );

  //�첽FIFO
  //   async_fifo_2048x8 icmp_async_fifo_2048x8b (
  //       .rst   (~resetn),   // input wire rst
  //       .wr_clk(gmii_clk),  // input wire wr_clk
  //       .rd_clk(gmii_clk),  // input wire rd_clk
  //       .din   (rec_data),  // input wire [7 : 0] din
  //       .wr_en (rec_en),    // input wire wr_en
  //       .rd_en (tx_req),    // input wire rd_en
  //       .dout  (tx_data),   // output wire [7 : 0] dout
  //       .full  (),          // output wire full
  //       .empty ()           // output wire empty
  //   );

  //icmp�첽FIFO
  async_fifo_2048x8 icmp_async_fifo_2048x8b (
      .wr_clk      (gmii_clk),  // input
      .wr_rst      (~resetn),   // input
      .wr_en       (rec_en),    // input
      .wr_data     (rec_data),  // input [7:0]
      .wr_full     (),          // output
      .almost_full (),          // output
      .rd_clk      (gmii_clk),  // input
      .rd_rst      (~resetn),   // input
      .rd_en       (tx_req),    // input
      .rd_data     (tx_data),   // output [7:0]
      .rd_empty    (),          // output
      .almost_empty()           // output
  );


  //�� ֻ��1234�˿ڵ����ݽ���receive buffer
  reg default_tx_buffer_wr_en;
  reg default_tx_buffer_start;
  reg default_tx_buffer_done;

  always @(*) begin
    if (udp_rx_pkt_dest_port == 16'd1234 && udp_rx_pkt_en) begin
      default_tx_buffer_wr_en = 1;
    end else begin
      default_tx_buffer_wr_en = 0;
    end
  end
  always @(*) begin
    if (udp_rx_pkt_dest_port == 16'd1234 && udp_rx_pkt_start) begin
      default_tx_buffer_start = 1;
    end else begin
      default_tx_buffer_start = 0;
    end
  end
  always @(*) begin
    if (udp_rx_pkt_dest_port == 16'd1234 && udp_rx_pkt_done) begin
      default_tx_buffer_done = 1;
    end else begin
      default_tx_buffer_done = 0;
    end
  end

  udp_receive_buffer udp_receive_buffer_inst (
      .resetn(resetn),

      .udp_rx_clk_i(gmii_clk),

      .udp_rx_data_i (udp_rx_pkt_data),
      .udp_rx_valid_i(default_tx_buffer_wr_en),
      .udp_rx_num_i  (udp_rx_pkt_byte_num),
      .udp_rx_start_i(default_tx_buffer_start),
      .udp_rx_done_i (default_tx_buffer_done),

      .recv_clk_i        (clk),
      .recv_m_data_tdata (udp_rx_m_data_tdata),
      .recv_m_data_tlast (udp_rx_m_data_tlast),
      .recv_m_data_tvalid(udp_rx_m_data_tvalid),
      .recv_m_data_tready(udp_rx_m_data_tready),
      .recv_m_data_tsize (udp_rx_m_data_tsize),
      .cached_pkt_num    (udp_rx_m_cached_pkt_num)
  );



  // udp���� buffer
  udp_transmit_buffer u_udp_transmit_buffer (
      .resetn(resetn),

      .transmit_clk_i  (clk),
      .transmit_data_i (udp_tx_s_data),
      .transmit_valid_i(udp_tx_s_valid),
      .transmit_start_i(udp_tx_s_start),
      .transmit_num_i  (udp_tx_s_tsize),
      .transmit_end_i  (udp_tx_s_last),

      .udp_tx_m_clk_i     (gmii_clk),
      .udp_tx_m_req_i     (udp_tx_req),
      .udp_tx_m_start_en_o(tx_start_en),
      .udp_tx_m_data_o    (udp_tx_data),
      .udp_tx_m_byte_num_o(tx_byte_num)
  );



  //��̫������ģ��
  eth_ctrl u_eth_ctrl (
      .clk   (gmii_clk),
      .resetn(resetn),

      .arp_rx_done   (arp_rx_done),
      .arp_rx_type   (arp_rx_type),
      .arp_tx_en     (arp_tx_en),
      .arp_tx_type   (arp_tx_type),
      .arp_tx_done   (arp_tx_done),
      .arp_gmii_tx_en(arp_gmii_tx_en),
      .arp_gmii_txd  (arp_gmii_txd),

      .icmp_tx_start_en(icmp_tx_start_en),
      .icmp_tx_done    (icmp_tx_done),
      .icmp_gmii_tx_en (icmp_gmii_tx_en),
      .icmp_gmii_txd   (icmp_gmii_txd),

      .icmp_rec_en  (icmp_rec_en),
      .icmp_rec_data(icmp_rec_data),
      .icmp_tx_req  (icmp_tx_req),
      .icmp_tx_data (icmp_tx_data),

      .udp_tx_start_en(tx_start_en),
      .udp_tx_done    (udp_tx_done),
      .udp_gmii_tx_en (udp_gmii_tx_en),
      .udp_gmii_txd   (udp_gmii_txd),

      //   .udp_rec_data(udp_rec_data),
      //   .udp_rec_en  (udp_rec_en),
      //   .udp_tx_req  (udp_tx_req),
      //   .udp_tx_data (udp_tx_data),

      .rec_data(rec_data),
      .rec_en  (rec_en),
      .tx_req  (tx_req),
      .tx_data (tx_data),

      .gmii_txd_valid(gmii_txd_valid),
      .gmii_txd_data (gmii_txd_data)
  );

endmodule
