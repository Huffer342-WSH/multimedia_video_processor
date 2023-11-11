module udp #(
    //parameter define
    //������MAC��ַ 00-11-22-33-44-55
    parameter BOARD_MAC = 48'h00_11_22_33_44_55,
    //������IP��ַ 192.168.1.123     
    parameter BOARD_IP  = {8'd192,8'd168,8'd1,8'd123},
    //������IP �˿� 1234
    parameter BOARD_PORT = 16'd1234,
    //Ŀ��MAC��ַ ff_ff_ff_ff_ff_ff
    parameter  DES_MAC   = 48'hff_ff_ff_ff_ff_ff,
    //Ŀ��IP��ַ 192.168.1.102     
    parameter  DES_IP    = {8'd192,8'd168,8'd1,8'd102},
    //Ŀ��IP��ַ �˿� 1234
    parameter DES_PORT = 16'd1234
) (
    input           resetn,          //��λ�źţ��͵�ƽ��Ч
    //GMII�ӿ�
    input           gmii_rx_clk,     //GMII��������ʱ��
    input           gmii_rxd_valid,  //GMII����������Ч�ź�
    input  [   7:0] gmii_rxd_data,   //GMII��������
    input           gmii_tx_clk,     //GMII��������ʱ��    
    output          gmii_txd_valid,  //GMII���������Ч�ź�
    output [   7:0] gmii_txd_data,   //GMII������� 
    //�û��ӿ�
    output          rec_pkt_start,
    output          rec_pkt_done,    //��̫���������ݽ�������ź�
    output          rec_en,          //��̫�����յ�����ʹ���ź�
    output [ 7 : 0] rec_data,        //��̫�����յ�����
    output [15 : 0] rec_dest_port,   //��̫������Ŀ�ĵض˿�
    output [15 : 0] rec_byte_num,    //��̫�����յ���Ч�ֽ��� ��λ:byte     
    input           tx_start_en,     //��̫����ʼ�����ź�
    input  [ 7 : 0] tx_data,         //��̫������������  
    input  [15 : 0] tx_byte_num,     //��̫�����͵���Ч�ֽ��� ��λ:byte  
    input  [47 : 0] des_mac,         //���͵�Ŀ��MAC��ַ
    input  [31 : 0] des_ip,          //���͵�Ŀ��IP��ַ    
    output          tx_done,         //��̫����������ź�
    output          tx_req           //�����������ź�    
);

  //wire define
  wire        crc_en;  //CRC��ʼУ��ʹ��
  wire        crc_clr;  //CRC���ݸ�λ�ź� 
  wire [ 7:0] crc_d8;  //�����У��8λ����

  wire [31:0] crc_data;  //CRCУ������
  wire [31:0] crc_next;  //CRC�´�У���������

  //*****************************************************
  //**                    main code
  //*****************************************************

  assign crc_d8 = gmii_txd_data;

  //��̫������ģ��    
  udp_rx #(
      .BOARD_MAC(BOARD_MAC),  //��������
      .BOARD_IP (BOARD_IP)
  ) u_udp_rx (
      .clk           (gmii_rx_clk),
      .resetn        (resetn),
      .gmii_rxd_valid(gmii_rxd_valid),
      .gmii_rxd_data (gmii_rxd_data),
      .rec_pkt_start (rec_pkt_start),
      .rec_pkt_done  (rec_pkt_done),
      .rec_en        (rec_en),
      .rec_data      (rec_data),
      .rec_dest_port (rec_dest_port),
      .rec_byte_num  (rec_byte_num)
  );

  //��̫������ģ��
  udp_tx #(
      .BOARD_MAC(BOARD_MAC),  //��������
      .BOARD_IP (BOARD_IP),
      .BOARD_PORT (BOARD_PORT),
      .DES_MAC  (DES_MAC),
      .DES_IP   (DES_IP),
      .DES_PORT (DES_PORT)
  ) u_udp_tx (
      .clk           (gmii_tx_clk),
      .resetn        (resetn),
      .tx_start_en   (tx_start_en),
      .tx_data       (tx_data),
      .tx_byte_num   (tx_byte_num),
      .des_mac       (des_mac),
      .des_ip        (des_ip),
      .crc_data      (crc_data),
      .crc_next      (crc_next[31:24]),
      .tx_done       (tx_done),
      .tx_req        (tx_req),
      .gmii_txd_valid(gmii_txd_valid),
      .gmii_txd_data (gmii_txd_data),
      .crc_en        (crc_en),
      .crc_clr       (crc_clr)
  );

  //��̫������CRCУ��ģ��
  crc32_d8 u_crc32_d8 (
      .clk     (gmii_tx_clk),
      .resetn  (resetn),
      .data    (crc_d8),
      .crc_en  (crc_en),
      .crc_clr (crc_clr),
      .crc_data(crc_data),
      .crc_next(crc_next)
  );

endmodule
