`timescale 1ns / 1ps

module udp_osd #(
    parameter integer SCREEN_WIDTH = 1920,  // 图像宽度
    parameter integer SCREEN_HEIGHT = 1080,  // 图像高度
    parameter integer PIXEL_DATA_WIDTH = 16,
    parameter integer R_DATA_WIDTH = 5,
    parameter integer G_DATA_WIDTH = 6,
    parameter integer B_DATA_WIDTH = 5

) (

    input clk,
    input resetn,

    //PL以太网RGMII接口   
    input        eth_rxc,     //RGMII接收数据时钟
    input        eth_rx_ctl,  //RGMII输入数据有效信号
    input  [3:0] eth_rxd,     //RGMII输入数据
    output       eth_txc,     //RGMII发送数据时钟    
    output       eth_tx_ctl,  //RGMII输出数据有效信号
    output [3:0] eth_txd,     //RGMII输出数据   

    output          gmii_clk,              //GMII接收时钟
    output          udp_rx_pkt_start,
    output          udp_rx_pkt_done,       //以太网单包数据接收完成信号
    output          udp_rx_pkt_en,         //以太网接收的数据使能信号
    output [ 7 : 0] udp_rx_pkt_data,       //以太网接收的数据
    output [15 : 0] udp_rx_pkt_dest_port,  //以太网接收目的地端口
    output [15 : 0] udp_rx_pkt_byte_num,   //以太网接收的有效字节数 单位:byte 

    input [10:0] cfg_start_posX,
    input [10:0] cfg_start_posY,
    input [10:0] cfg_end_posX,
    input [10:0] cfg_end_posY,
    input [10:0] cfg_char_width,
    input [10:0] cfg_char_height,


    input                        vs_in,
    input                        hs_in,
    input                        de_in,
    input [PIXEL_DATA_WIDTH-1:0] rgb_in,
    input [                10:0] pos_x,
    input [                10:0] pos_y,

    //hdmi_out 
    output reg                        vs_out,
    output reg                        hs_out,
    output reg                        de_out,
    output reg [PIXEL_DATA_WIDTH-1:0] rgb_out

);

  localparam STRLENDATA_SAVED_ADDR = 1023;
  localparam CHAR_BUFFER_ADDR_WIDTH = 11;
  localparam CHAR_PIC_WIDTH = 9;
  localparam CHAR_PIC_HEIGHT = 18;
  localparam CHAR_WIDTH = 20;
  localparam CHAR_HEIGHT = 30;






  wire                              rgb_ready;
  wire [                      10:0] y_cnt;
  wire [                      23:0] pixel_data;
  wire                              pixel_valid;

  wire [CHAR_BUFFER_ADDR_WIDTH-1:0] ram_rd_addr;
  wire [                       7:0] ram_dout;
  wire                              m_pixel_data;
  wire                              m_pixel_valid;
  wire                              m_pixel_ready;
  wire [                      10:0] m_pixel_posX;
  wire [                      10:0] m_pixel_posY;




  wire                              ram_wen;
  wire [                    10 : 0] ram_addr;
  wire [                     7 : 0] ram_din;


  //---------------------------------------------------------------
  // UDP
  //---------------------------------------------------------------
  //parameter define
  //开发板MAC地址 00-11-22-33-44-55
  parameter BOARD_MAC = 48'h00_11_22_33_44_55;
  //开发板IP地址 192.168.1.10
  parameter BOARD_IP = {8'd192, 8'd168, 8'd10, 8'd10};
  //目的MAC地址 ff_ff_ff_ff_ff_ff
  parameter DES_MAC = 48'hff_ff_ff_ff_ff_ff;
  //目的IP地址 192.168.1.102     
  parameter DES_IP = {8'd192, 8'd168, 8'd10, 8'd102};
  //输入数据IO延时,此处为0,即不延时(如果为n,表示延时n*78ps) 
  parameter IDELAY_VALUE = 0;

  wire [ 7:0] udp_rx_data_tdata;
  wire        udp_rx_data_tlast;
  wire        udp_rx_data_tvalid;
  wire        udp_rx_data_tready;
  wire [15:0] udp_rx_data_tsize;
  wire [ 5:0] udp_rx_cached_pkt_num;

  wire [ 5:0] udp_rx_s_cached_pkt_num;
  wire [ 7:0] udp_tx_m_data;
  wire        udp_tx_m_valid;
  wire        udp_tx_m_start;
  wire [15:0] udp_tx_m_tsize;
  wire        udp_tx_m_last;

  eth_udp #(
      .BOARD_MAC(BOARD_MAC),
      .BOARD_IP(BOARD_IP),
      .DES_MAC(DES_MAC),
      .DES_IP(DES_IP),
      .IDELAY_VALUE(IDELAY_VALUE)
  ) eth_udp_inst (
      .clk       (clk),
      .resetn    (resetn),
      .eth_rxc   (eth_rxc),
      .eth_rx_ctl(eth_rx_ctl),
      .eth_rxd   (eth_rxd),
      .eth_txc   (eth_txc),
      .eth_tx_ctl(eth_tx_ctl),
      .eth_txd   (eth_txd),

      .gmii_clk(gmii_clk),
      .udp_rx_pkt_start(udp_rx_pkt_start),
      .udp_rx_pkt_done(udp_rx_pkt_done),
      .udp_rx_pkt_en(udp_rx_pkt_en),
      .udp_rx_pkt_data(udp_rx_pkt_data),
      .udp_rx_pkt_dest_port(udp_rx_pkt_dest_port),
      .udp_rx_pkt_byte_num(udp_rx_pkt_byte_num),

      .udp_rx_m_data_tdata    (udp_rx_data_tdata),
      .udp_rx_m_data_tlast    (udp_rx_data_tlast),
      .udp_rx_m_data_tvalid   (udp_rx_data_tvalid),
      .udp_rx_m_data_tready   (udp_rx_data_tready),
      .udp_rx_m_data_tsize    (udp_rx_data_tsize),
      .udp_rx_m_cached_pkt_num(udp_rx_cached_pkt_num),

      .udp_tx_s_data (udp_tx_m_data),
      .udp_tx_s_valid(udp_tx_m_valid),
      .udp_tx_s_start(udp_tx_m_start),
      .udp_tx_s_tsize(udp_tx_m_tsize),
      .udp_tx_s_last (udp_tx_m_last)
  );


  //---------------------------------------------------------------
  // UDP数据到RAM
  //---------------------------------------------------------------
  char_buf_writer #(
      .STRLENDATA_SAVED_ADDR (STRLENDATA_SAVED_ADDR),
      .CHAR_BUFFER_ADDR_WIDTH(CHAR_BUFFER_ADDR_WIDTH)
  ) char_buf_writer_inst (
      .clk                 (clk),
      .resetn              (resetn),
      .udp_rx_s_data_tdata (udp_rx_data_tdata),
      .udp_rx_s_data_tlast (udp_rx_data_tlast),
      .udp_rx_s_data_tvalid(udp_rx_data_tvalid),
      .udp_rx_s_data_tready(udp_rx_data_tready),
      .udp_rx_s_data_tsize (udp_rx_data_tsize),

      .ram_addr(ram_addr),
      .ram_din (ram_din),
      .ram_wen (ram_wen)
  );


  // async_ram2048x8_2clk char_ram (
  //     .clka(clk),  // input wire clka
  //     .wea(ram_wen),  // input wire [0 : 0] wea
  //     .addra(ram_addr),  // input wire [10 : 0] addra
  //     .dina(ram_din),  // input wire [7 : 0] dina

  //     .clkb (clk),          // input wire clkb
  //     .addrb(ram_rd_addr),  // input wire [10 : 0] addrb
  //     .doutb(ram_dout)      // output wire [7 : 0] doutb
  // );


  async_ram2048x8_2clk char_ram (
      .wr_data(ram_din),  // input [7:0]
      .wr_addr(ram_addr),  // input [10:0]
      .wr_en(ram_wen),  // input
      .wr_clk(clk),  // input
      .wr_rst(~resetn),  // input

      .rd_addr(ram_rd_addr),  // input [10:0]
      .rd_data(ram_dout),  // output [7:0]
      .rd_clk(clk),  // input
      .rd_rst(~resetn)  // input
  );



  char_osd #(
      .STRLENDATA_SAVED_ADDR(STRLENDATA_SAVED_ADDR),
      .CHAR_BUFFER_ADDR_WIDTH(CHAR_BUFFER_ADDR_WIDTH),
      .CHAR_PIC_WIDTH(CHAR_PIC_WIDTH),
      .CHAR_PIC_HEIGHT(CHAR_PIC_HEIGHT),
      .SCREEN_WIDTH(SCREEN_WIDTH),
      .SCREEN_HEIGHT(SCREEN_HEIGHT)
  ) char_osd_inst (
      .clk   (clk),
      .resetn(resetn),

      .cfg_start_posX (cfg_start_posX),    // input [10:0] cfg_start_posX
      .cfg_start_posY (cfg_start_posY),    // input [10:0] cfg_start_posY
      .cfg_end_posX   (cfg_end_posX),  // input [10:0] cfg_end_posX
      .cfg_end_posY   (cfg_end_posY),  // input [10:0] cfg_end_posY
      .cfg_char_width (cfg_char_width),    // input [10:0] cfg_char_width
      .cfg_char_height(cfg_char_height),    // input [10:0] cfg_char_height


      .ram_rd_addr(ram_rd_addr),
      .ram_dout   (ram_dout),

      .m_pixel_data (m_pixel_data),
      .m_pixel_valid(m_pixel_valid),
      .m_pixel_ready(m_pixel_ready),
      .m_pixel_posX (m_pixel_posX),
      .m_pixel_posY (m_pixel_posY)
  );


  assign m_pixel_ready = (de_in && m_pixel_posX <= pos_x && m_pixel_posY == pos_y) ? 1 : 0;


  always @(posedge clk) begin
    if (~resetn) begin
      rgb_out <= 0;
    end else if (de_in == 0) begin
      rgb_out <= 24'h0000ff;
    end  // else if (pos_y == 0 || pos_y == 1079 || pos_x == 0 || pos_x == 1919) begin
         //   rgb_out <= 24'hff0000;
         // end 
    else if (m_pixel_valid && m_pixel_posX == pos_x && m_pixel_posY == pos_y) begin
      rgb_out <= m_pixel_data ? rgb_in : 24'hff0000;
    end else begin
      rgb_out <= rgb_in;
    end
  end

  always @(posedge clk) begin
    if (~resetn) begin
      vs_out <= 0;
      hs_out <= 0;
      de_out <= 0;
    end else begin
      vs_out <= vs_in;
      hs_out <= hs_in;
      de_out <= de_in;
    end
  end



endmodule
