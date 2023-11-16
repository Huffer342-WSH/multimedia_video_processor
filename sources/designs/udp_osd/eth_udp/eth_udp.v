module eth_udp #(  //parameter define
    //开发板MAC地址 00-11-22-33-44-55
    parameter BOARD_MAC = 48'h00_11_22_33_44_55,
    //开发板IP地址 192.168.1.10
    parameter BOARD_IP = {8'd192, 8'd168, 8'd10, 8'd10},
    //开发板IP 端口 1234
    parameter BOARD_PORT = 16'd1234,
    //目的MAC地址 ff_ff_ff_ff_ff_ff
    parameter DES_MAC = 48'hff_ff_ff_ff_ff_ff,
    //目的IP地址 192.168.1.102     
    parameter DES_IP = {8'd192, 8'd168, 8'd10, 8'd102},
    //目的IP地址 端口 1234
    parameter DES_PORT = 16'd1234,
    //输入数据IO延时,此处为0,即不延时(如果为n,表示延时n*78ps) 
    parameter IDELAY_VALUE = 0
) (
    input        clk,         //! 系统时钟
    input        resetn,      //! 系统复位信号，低电平有效 
    //PL以太网RGMII接口   
    input        eth_rxc,     //! RGMII接收数据时钟
    input        eth_rx_ctl,  //! RGMII输入数据有效信号
    input  [3:0] eth_rxd,     //! RGMII输入数据
    output       eth_txc,     //! RGMII发送数据时钟    
    output       eth_tx_ctl,  //! RGMII输出数据有效信号
    output [3:0] eth_txd,     //! RGMII输出数据   


    //原始接受数据 处于GMII接收时钟时钟域
    output          gmii_clk,              //! GMII接收时钟
    output          udp_rx_pkt_start,      //! 以太网单包数据接收开始信号
    output          udp_rx_pkt_done,       //! 以太网单包数据接收完成信号
    output          udp_rx_pkt_en,         //! 以太网接收的数据使能信号
    output [ 7 : 0] udp_rx_pkt_data,       //! 以太网接收的数据
    output [15 : 0] udp_rx_pkt_dest_port,  //! 以太网接收目的地端口
    output [15 : 0] udp_rx_pkt_byte_num,   //! 以太网接收的有效字节数 单位:byte 


    output [ 7:0] udp_rx_m_data_tdata,     //! 待接受数据 数据
    output        udp_rx_m_data_tlast,     //! 待接受数据 结束传输
    output        udp_rx_m_data_tvalid,    //! 待接受数据 有效信号
    input         udp_rx_m_data_tready,    //! 待接受数据 准备信号
    output [15:0] udp_rx_m_data_tsize,     //! 待接受数据 数据量
    output [ 5:0] udp_rx_m_cached_pkt_num, //! 待接受数据 已缓存数据包数量


    input [ 7:0] udp_tx_s_data,   //! 待发送数据 数据
    input        udp_tx_s_valid,  //! 待发送数据 有效信号
    input        udp_tx_s_start,  //! 待发送数据 开始传输
    input [15:0] udp_tx_s_tsize,  //! 待发送数据 数据量
    input        udp_tx_s_last    //! 待发送数据 结束传输
);


  //wire define

  //   wire        gmii_clk;//GMII接收时钟
  wire        gmii_rxd_valid;  //GMII接收数据有效信号
  wire [ 7:0] gmii_rxd_data;  //GMII接收数据
  wire        gmii_txd_valid;  //GMII发送数据使能信号
  wire [ 7:0] gmii_txd_data;  //GMII发送数据     

  wire        arp_gmii_tx_en;  //ARP GMII输出数据有效信号 
  wire [ 7:0] arp_gmii_txd;  //ARP GMII输出数据
  wire        arp_rx_done;  //ARP接收完成信号
  wire        arp_rx_type;  //ARP接收类型 0:请求  1:应答
  wire [47:0] src_mac;  //接收到目的MAC地址
  wire [31:0] src_ip;  //接收到目的IP地址    
  wire        arp_tx_en;  //ARP发送使能信号
  wire        arp_tx_type;  //ARP发送类型 0:请求  1:应答
  wire [47:0] des_mac;  //发送的目标MAC地址
  wire [31:0] des_ip;  //发送的目标IP地址   
  wire        arp_tx_done;  //ARP发送完成信号

  wire        icmp_gmii_tx_en;  //ICMP GMII输出数据有效信号 
  wire [ 7:0] icmp_gmii_txd;  //ICMP GMII输出数据
  wire        icmp_rec_pkt_done;  //ICMP单包数据接收完成信号
  wire        icmp_rec_en;  //ICMP接收的数据使能信号
  wire [ 7:0] icmp_rec_data;  //ICMP接收的数据
  wire [15:0] icmp_rec_byte_num;  //ICMP接收的有效字节数 单位:byte 
  wire [15:0] icmp_tx_byte_num;  //ICMP发送的有效字节数 单位:byte 
  wire        icmp_tx_done;  //ICMP发送完成信号
  wire        icmp_tx_req;  //ICMP读数据请求信号
  wire [ 7:0] icmp_tx_data;  //ICMP待发送数据
  wire        icmp_tx_start_en;  //ICMP发送开始使能信号

  wire        udp_gmii_tx_en;  //UDP GMII输出数据有效信号 
  wire [ 7:0] udp_gmii_txd;  //UDP GMII输出数据

  wire [15:0] tx_byte_num;  //UDP发送的有效字节数 单位:byte 
  wire        udp_tx_done;  //UDP发送完成信号
  wire        udp_tx_req;  //UDP读数据请求信号
  wire [ 7:0] udp_tx_data;  //UDP待发送数据
  wire        tx_start_en;  //UDP发送开始使能信号

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



  //GMII接口转RGMII接口
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

  //ARP通信
  arp #(
      .BOARD_MAC(BOARD_MAC),  //参数例化
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

  //ICMP通信
  icmp #(
      .BOARD_MAC(BOARD_MAC),  //参数例化
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

  //UDP通信
  udp #(
      .BOARD_MAC(BOARD_MAC),  //参数例化
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

  //异步FIFO
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

  //icmp异步FIFO
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


  //！ 只有1234端口的数据进入receive buffer
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



  // udp发送 buffer
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



  //以太网控制模块
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
