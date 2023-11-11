`timescale 1ns / 100ps
// `define RES_1080P
`define RES_720P
module multimedia_video_processor #(
    parameter ADDR_WIDTH   = 30,
    parameter WR_NUM_WIDTH = 16,
    parameter RD_NUM_WIDTH = 16,
    parameter IMAGE_W      = 1280,
    parameter IMAGE_H      = 720,
    parameter IMAGE_SIZE   = 11
) (
    input clk,
    input rstn,

    output mem_rst_n,
    output mem_ck,
    output mem_ck_n,
    output mem_cke,

    output mem_cs_n,

    output          mem_ras_n,
    output          mem_cas_n,
    output          mem_we_n,
    output          mem_odt,
    output [15-1:0] mem_a,
    output [ 3-1:0] mem_ba,
    inout  [ 4-1:0] mem_dqs,
    inout  [ 4-1:0] mem_dqs_n,
    inout  [32-1:0] mem_dq,
    output [ 4-1:0] mem_dm,

    //coms1    
    inout        cmos1_scl,    //cmos1 i2c 
    inout        cmos1_sda,    //cmos1 i2c 
    input        cmos1_vsync,  //cmos1 vsync
    input        cmos1_href,   //cmos1 hsync refrence,data valid
    input        cmos1_pclk,   //cmos1 pxiel clock
    input  [7:0] cmos1_data,   //cmos1 data
    output       cmos1_reset,  //cmos1 reset
    //coms2
    inout        cmos2_scl,    //cmos2 i2c 
    inout        cmos2_sda,    //cmos2 i2c 
    input        cmos2_vsync,  //cmos2 vsync
    input        cmos2_href,   //cmos2 hsync refrence,data valid
    input        cmos2_pclk,   //cmos2 pxiel clock
    input  [7:0] cmos2_data,   //cmos2 data
    output       cmos2_reset,  //cmos2 reset
    //MS7200       
    output       iic_scl,
    inout        iic_sda,
    input        hdmi_in_clk,  //pixclk                           
    input        vs_in,
    input        hs_in,
    input        de_in,
    input  [7:0] r_in,
    input  [7:0] g_in,
    input  [7:0] b_in,

    output reg [8:1] led,
    //MS72xx       
    output           rstn_out,
    output           iic_tx_scl,
    inout            iic_tx_sda,

    //HDMI_OUT
    output       pix_clk,  //pixclk                           
    output       vs_out,
    output       hs_out,
    output       de_out,
    output [7:0] r_out,
    output [7:0] g_out,    // D8
    output [7:0] b_out,    // d0

    //以太网RGMII接口  
    output       eth_rstn,
    input        eth_rxc,     //RGMII接收数据时钟
    input        eth_rx_ctl,  //RGMII输入数据有效信号
    input  [3:0] eth_rxd,     //RGMII输入数据
    output       eth_txc,     //RGMII发送数据时钟    
    output       eth_tx_ctl,  //RGMII输出数据有效信号
    output [3:0] eth_txd,     //RGMII输出数据

    input [8:2] key

);
`ifdef RES_1080P
  //MODE_1080p
  parameter V_TOTAL = 12'd1125;
  parameter V_FP = 12'd4;
  parameter V_BP = 12'd36;
  parameter V_SYNC = 12'd5;
  parameter V_ACT = 12'd1080;
  parameter H_TOTAL = 12'd2200;
  parameter H_FP = 12'd88;
  parameter H_BP = 12'd148;
  parameter H_SYNC = 12'd44;
  parameter H_ACT = 12'd1920;
  parameter HV_OFFSET = 12'd0;

`else
  // //MODE_720p 
  parameter V_TOTAL = 12'd750;
  parameter V_FP = 12'd5;
  parameter V_BP = 12'd20;
  parameter V_SYNC = 12'd5;
  parameter V_ACT = 12'd720;
  parameter H_TOTAL = 12'd1650;
  parameter H_FP = 12'd110;
  parameter H_BP = 12'd220;
  parameter H_SYNC = 12'd40;
  parameter H_ACT = 12'd1280;
  parameter HV_OFFSET = 12'd0;
`endif

  wire clk_10m, clk_50m, clk_25m, clk_100m, zoom_clk, clk_200m, clk_1080p60Hz, clk_720p60Hz;

  wire                           ddr_clk;
  wire                           wr0_clk;
  wire                           wr0_rst;
  reg                            wr0_vs;
  wire                           wr0_ddr_done;
  wire                           wr0_addr_valid;
  wire        [  ADDR_WIDTH-1:0] wr0_ddr_addr;
  wire        [WR_NUM_WIDTH-1:0] wr0_ddr_num;

  wire                           wr1_clk;
  wire                           wr1_rst;
  wire                           wr1_vs;
  wire                           wr1_ddr_done;
  wire                           wr1_addr_valid;
  wire        [  ADDR_WIDTH-1:0] wr1_ddr_addr;
  wire        [WR_NUM_WIDTH-1:0] wr1_ddr_num;

  wire                           wr2_clk;
  wire                           wr2_rst;
  wire                           wr2_vs;
  wire                           wr2_ddr_done;
  wire                           wr2_addr_valid;
  wire        [  ADDR_WIDTH-1:0] wr2_ddr_addr;
  wire        [WR_NUM_WIDTH-1:0] wr2_ddr_num;
  wire                           zoom_vs_out;

  wire                           wr3_clk;
  wire                           wr3_rst;
  wire                           wr3_ddr_done;
  wire                           wr3_addr_valid;
  wire        [  ADDR_WIDTH-1:0] wr3_ddr_addr;
  wire        [WR_NUM_WIDTH-1:0] wr3_ddr_num;

  wire                           rd0_clk;
  wire                           rd0_rst;
  wire                           rd0_vs;
  wire                           imag_addr_valid;
  wire        [  IMAGE_SIZE-1:0] imag_addr;
  wire                           rd0_ddr_done;
  wire                           rd0_ddr_valid;
  wire        [  ADDR_WIDTH-1:0] rd0_ddr_addr;
  wire        [WR_NUM_WIDTH-1:0] rd0_ddr_num;

  wire                           sift_done;

  wire                           rd1_clk;
  wire                           rd1_rst;
  wire                           rd1_ddr_done;
  wire                           rd1_ddr_valid;
  wire        [  ADDR_WIDTH-1:0] rd1_ddr_addr;
  wire        [WR_NUM_WIDTH-1:0] rd1_ddr_num;
  wire signed [             7:0] shift_h;
  wire                           zoom_image_addr_valid;
  wire        [  IMAGE_SIZE-1:0] zoom_image_addr;

  wire                           rd2_clk;
  wire                           rd2_rst;
  wire                           rd2_vs;
  wire                           rd2_ddr_done;
  wire                           rd2_ddr_valid;
  wire        [  ADDR_WIDTH-1:0] rd2_ddr_addr;
  wire        [WR_NUM_WIDTH-1:0] rd2_ddr_num;
  wire        [             1:0] hdmi_mode;

  wire                           rd3_clk;
  wire                           rd3_rst;
  wire                           rotate_image_addr_valid;
  wire        [            31:0] rotate_image_addr;
  wire                           rd3_ddr_addr_valid;
  wire        [  ADDR_WIDTH-1:0] rd3_ddr_addr;
  wire                           rotate_vs_out;


  wire                           wr0_data_in_valid;
  wire        [            15:0] wr0_data_in;
  wire                           wr1_data_in_valid;
  wire        [            15:0] wr1_data_in;
  wire                           wr2_data_in_valid;
  wire        [            15:0] wr2_data_in;
  wire                           wr3_data_in_valid;
  wire        [            15:0] wr3_data_in;

  wire                           rd0_data_valid;
  wire        [            15:0] rd0_data;
  wire                           rd1_data_valid;
  wire        [            15:0] rd1_data;
  wire                           rd2_data_valid;
  wire        [            15:0] rd2_data;
  wire                           rd3_data_valid;
  wire        [            15:0] rd3_data;
  wire                           rd0_empty;
  wire                           rd1_empty;
  wire                           rd2_empty;
  wire                           rd3_empty;

  wire                           hdmi_out_rd_en;
  wire        [            15:0] hdmi_image_data;
  wire                           hdmi_hs_out0;
  wire                           hdmi_vs_out0;
  wire                           hdmi_de_out0;
  reg                            hdmi_hs_out1;
  reg                            hdmi_vs_out1;
  reg                            hdmi_de_out1;
  reg         [             7:0] hdmi_r_out;
  reg         [             7:0] hdmi_g_out;
  reg         [             7:0] hdmi_b_out;

  //  UDP原始数据时钟输出
  wire                           gmii_clk;
  wire                           udp_rx_pkt_start;
  wire                           udp_rx_pkt_done;
  wire                           udp_rx_pkt_en;
  wire        [           7 : 0] udp_rx_pkt_data;
  wire        [          15 : 0] udp_rx_pkt_dest_port;
  wire        [          15 : 0] udp_rx_pkt_byte_num;


  // 参数管理
  wire        [           199:0] mem;
  wire        [            24:0] mem_flags;
  wire        [             3:0] index_param;
  wire        [             2:0] param_filiter1_mode;
  wire        [             2:0] param_filiter2_mode;
  wire        [             9:0] param_zoom;
  wire        [             7:0] param_rotate;
  wire        [             9:0] param_rotate_A;
  wire        [            10:0] param_osd_startX;
  wire        [            10:0] param_osd_startY;
  wire        [            10:0] param_osd_char_width;
  wire        [            10:0] param_osd_char_height;
  wire signed [            11:0] param_offsetX;
  wire signed [            11:0] param_offsetY;
  wire signed [             8:0] param_modify_H;
  wire signed [             8:0] param_modify_S;
  wire signed [             8:0] param_modify_V;




  wire locked, pll_hdmi_locked;
  wire rst_25m, rst_50m, rst_100m, zoom_rst;
  wire pix_rst, ddr_rst, axi_rst, hdmi_in_rst;
  wire init_calib_complete;


  sys_pll u_sys_pll (
      .clkin1  (clk),       // input
      .pll_lock(locked),    // output
      .clkout0 (clk_50m),   // output
      .clkout1 (clk_200m),  // output
      .clkout2 (clk_100m),  // output
      .clkout3 (clk_25m),   // output
      .clkout4 (clk_10m)    // output
  );

  HDMI_PLL U_HDMI_PLL (
      .clkin1  (clk_50m),          // input
      .pll_lock(pll_hdmi_locked),  // output
      .clkout0 (clk_1080p60Hz),    // output
      .clkout1 (clk_720p60Hz)      // output
  );

  assign ddr_clk  = clk_200m;
  assign zoom_clk = clk_200m;
`ifdef RES_1080P
  assign pix_clk = clk_1080p60Hz;
`else
  assign pix_clk = clk_720p60Hz;
`endif


  wire init_over_tx, init_over_rx;
  reg rstn_5s;


  reg rstn_out0;
  reg rstn_out1;
  reg [15:0] rstn_1ms;
  always @(posedge clk_10m or negedge locked) begin
    if (!locked) begin
      rstn_1ms  <= 16'd0;
      rstn_out0 <= 0;
      rstn_out1 <= 0;
    end else begin
      rstn_out1 <= rstn_out0;
      if (rstn_1ms == 16'h2710) begin
        rstn_1ms  <= rstn_1ms;
        rstn_out0 <= 1;
      end else begin
        rstn_1ms  <= rstn_1ms + 1'b1;
        rstn_out0 <= 0;
      end
    end
  end


  assign rstn_out = rstn_out1;

  reg sync_vg_100m;
  reg [31:0] clk_cnt;

  always @(posedge pix_clk or negedge pll_hdmi_locked) begin
    if (~pll_hdmi_locked) begin
      clk_cnt <= 'd0;
      sync_vg_100m <= 1;
      rstn_5s <= 0;
    end else begin
      if (clk_cnt >= 594_000_000) begin
        clk_cnt <= clk_cnt;
        sync_vg_100m <= 0;
        rstn_5s <= 1;
      end else begin
        clk_cnt <= clk_cnt + 1'b1;
        sync_vg_100m <= 1;
        rstn_5s <= 0;
      end
    end
  end


  sync_rst u_clk25m_rst (
      .clk (clk_25m),
      .rstn(rstn & init_calib_complete),
      .rst (rst_25m)
  );
  sync_rst u_clk50m_rst (
      .clk (clk_50m),
      .rstn(rstn & init_calib_complete & rstn_5s),
      .rst (rst_50m)
  );
  sync_rst u_clk100m_rst (
      .clk (clk_100m),
      .rstn(rstn & init_calib_complete),
      .rst (rst_100m)
  );
  sync_rst u_hdmi_rst (
      .clk (pix_clk),
      .rstn(rstn & init_calib_complete & init_over_tx),
      .rst (pix_rst)
  );
  sync_rst u_zoom_rst (
      .clk (zoom_clk),
      .rstn(rstn & init_calib_complete & init_over_tx),
      .rst (zoom_rst)
  );
  sync_rst u_ddr_rst (
      .clk (ddr_clk),
      .rstn(rstn),
      .rst (ddr_rst)
  );
  sync_rst u_axi_rst (
      .clk (ddr_clk),
      .rstn(rstn & init_calib_complete & rstn_5s),
      .rst (axi_rst)
  );
  sync_rst u_hdm_in_rst (
      .clk (hdmi_in_clk),
      .rstn(rstn & init_calib_complete & init_over_rx & rstn_5s),
      .rst (hdmi_in_rst)
  );




  //assign wr0_clk = clk_50m; cmos2_pclk
  assign wr0_clk = clk_50m;
  assign wr0_rst = rst_50m;

  assign wr1_clk = hdmi_in_clk;
  assign wr1_rst = hdmi_in_rst;

  assign wr2_clk = clk_50m;
  assign wr2_rst = rst_50m;

  assign wr3_clk = clk_50m;
  assign wr3_rst = rst_50m;

  assign rd0_clk = clk_50m;
  assign rd0_rst = rst_50m;

  assign rd2_clk = pix_clk;
  assign rd2_rst = pix_rst;


  assign rd1_clk = zoom_clk;
  assign rd1_rst = zoom_rst;

  assign rd3_clk = wr3_clk;
  assign rd3_rst = wr3_rst;



  //---------------------------------------------------------------
  // HDMI输入输出芯片ms72xx配置
  //---------------------------------------------------------------
  ms72xx_ctl ms72xx_ctl (
      .clk         (clk_10m),       //input       clk,
      .rst_n       (rstn_out),      //input       rstn,
      .init_over_tx(init_over_tx),  //output      init_over,                                
      .init_over_rx(init_over_rx),  //output      init_over,
      .iic_tx_scl  (iic_tx_scl),    //output      iic_scl,
      .iic_tx_sda  (iic_tx_sda),    //inout       iic_sda
      .iic_scl     (iic_scl),       //output      iic_scl,
      .iic_sda     (iic_sda)        //inout       iic_sda
  );


  //---------------------------------------------------------------
  // HDMI输入
  //---------------------------------------------------------------
  hdmi_in_top u_hdmi_in_top (
      .clk(wr1_clk),
      .rst(wr1_rst),

      .r_in (r_in),
      .g_in (g_in),
      .b_in (b_in),
      .vs_in(vs_in),
      .hs_in(hs_in),
      .de_in(de_in),

      .hdmi_data      (wr1_data_in),
      .hdmi_data_valid(wr1_data_in_valid),
      .hdmi_vs_out    (wr1_vs)

  );


  //---------------------------------------------------------------
  // 参数管理
  //---------------------------------------------------------------
  udp_wr_mem #(
      .REG_NUM(25),
      .PORT(1000)
  ) udp_wr_mem_inst (
      .clk(gmii_clk),
      .resetn(~sync_vg_100m),

      .udp_rx_data(udp_rx_pkt_data),
      .udp_rx_valid(udp_rx_pkt_en),
      .udp_rx_dest_port(udp_rx_pkt_dest_port),
      .udp_rx_num(udp_rx_pkt_byte_num),
      .udp_rx_start(udp_rx_pkt_start),
      .mem(mem),
      .flags(mem_flags)
  );

  param_manager #(
      .CLK_FREQ(125000000)
  ) param_manager_inst (
      .clk(gmii_clk),
      .resetn(~pix_rst),
      .akey_left(key[2]),
      .akey_right(key[3]),
      .akey_up(key[4]),
      .akey_down(key[5]),
      .akey_restore(key[6]),
      .mem(mem),
      .mem_flags(mem_flags),

      .index(index_param),
      .filiter1_mode(param_filiter1_mode),
      .filiter2_mode(param_filiter2_mode),
      .zoom(param_zoom),
      .rotate(param_rotate),
      .rotate_A(param_rotate_A),
      .osd_startX(param_osd_startX),
      .osd_startY(param_osd_startY),
      .osd_char_width(param_osd_char_width),
      .osd_char_height(param_osd_char_height),
      .offsetX(param_offsetX),
      .offsetY(param_offsetY),
      .modify_H(param_modify_H),
      .modify_S(param_modify_S),
      .modify_V(param_modify_V)
  );


  //---------------------------------------------------------------
  // 摄像头输入
  //--------------------------------------------------------------
  wire camera_vs;
  wire [15:0] camera_data;
  wire camera_valid;

  ov5640 #(
      .IMAGE_SIZE(IMAGE_SIZE),
      .IMAGE_W   (IMAGE_W),
      .IMAGE_H   (IMAGE_H)
  ) u_ov5640 (
      .clk_50M(clk_50m),
      .clk_25M(clk_25m),
      .rst    (rst_50m),  // sync 50M

      .cmos1_scl  (cmos1_scl),
      .cmos1_sda  (cmos1_sda),
      .cmos1_vsync(cmos1_vsync),
      .cmos1_href (cmos1_href),
      .cmos1_pclk (cmos1_pclk),
      .cmos1_data (cmos1_data),
      .cmos1_reset(cmos1_reset),

      .cmos2_scl  (cmos2_scl),
      .cmos2_sda  (cmos2_sda),
      .cmos2_vsync(cmos2_vsync),
      .cmos2_href (cmos2_href),
      .cmos2_pclk (cmos2_pclk),
      .cmos2_data (cmos2_data),
      .cmos2_reset(cmos2_reset),

      .wr_clk        (wr0_clk),
      .wr_rst        (wr0_rst),
      .shift_w       (0),
      .shift_h       (0),
      .data_vs       (camera_vs),
      .data_out_valid(camera_valid),
      .data_out      (camera_data)
  );


  //---------------------------------------------------------------
  // 滤波
  //---------------------------------------------------------------
  //! 对vs信号延迟。因为摄像头数据进入滤波器会延迟1行数据的时间
  reg camera_vs_ff0, camera_vs_ff1;
  reg [12:0] vs_pos_delay_cnt, vs_down_delay_cnt;

  always @(posedge clk_50m) begin
    if (rst_50m) begin
      camera_vs_ff0 <= 0;
      camera_vs_ff1 <= 0;
    end else begin
      camera_vs_ff0 <= camera_vs;
      camera_vs_ff1 <= camera_vs_ff0;
    end
  end
  //！ 捕获上升沿
  always @(posedge clk_50m) begin
    if (rst_50m) begin
      vs_pos_delay_cnt <= 0;
    end else if (camera_vs_ff0 && ~camera_vs_ff1) begin
      vs_pos_delay_cnt <= 2558;
    end else if (vs_pos_delay_cnt > 0) begin
      vs_pos_delay_cnt <= vs_pos_delay_cnt - 1;
    end else begin
      vs_pos_delay_cnt <= 0;
    end
  end
  //！ 捕获下降沿
  always @(posedge clk_50m) begin
    if (rst_50m) begin
      vs_down_delay_cnt <= 0;
    end else if (~camera_vs_ff0 && camera_vs_ff1) begin
      vs_down_delay_cnt <= 2558;
    end else if (vs_down_delay_cnt > 0) begin
      vs_down_delay_cnt <= vs_down_delay_cnt - 1;
    end else begin
      vs_down_delay_cnt <= 0;
    end
  end
  always @(posedge clk_50m) begin
    if (rst_50m) begin
      wr0_vs <= 0;
    end else if (vs_pos_delay_cnt == 1) begin
      wr0_vs <= 1;
    end else if (vs_down_delay_cnt == 1) begin
      wr0_vs <= 0;
    end else begin
      wr0_vs <= wr0_vs;
    end
  end

  wire temp_v;
  wire [15:0] temp_d;
  image_filiter #(
      .IMAGE_WIDTH(1280),
      .IMAGE_HEIGHT(360),
      .PIXEL_DATA_WIDTH(16),
      .R_DATA_WIDTH(5),
      .G_DATA_WIDTH(6),
      .B_DATA_WIDTH(5),
      .TH(4)
  ) image_filiter_inst (
      .clk(clk_50m),
      .resetn(~rst_50m),
      .rst_busy(),
      .mode(param_filiter1_mode),
      .s_pixel_data(camera_data),
      .s_pixel_valid(camera_valid),
      .m_filtered_data(temp_d),
      .m_filtered_valid(temp_v)
  );
  image_filiter #(
      .IMAGE_WIDTH(1280),
      .IMAGE_HEIGHT(360),
      .PIXEL_DATA_WIDTH(16),
      .R_DATA_WIDTH(5),
      .G_DATA_WIDTH(6),
      .B_DATA_WIDTH(5),
      .TH(4)
  ) image_filiter_inst2 (
      .clk(clk_50m),
      .resetn(~rst_50m),
      .rst_busy(),
      .mode(param_filiter2_mode),
      .s_pixel_data(temp_d),
      .s_pixel_valid(temp_v),
      .m_filtered_data(wr0_data_in),
      .m_filtered_valid(wr0_data_in_valid)
  );

  //---------------------------------------------------------------
  // 旋转
  //---------------------------------------------------------------
  rotate_image #(
      .IMAGE_SIZE(IMAGE_SIZE),
      .MIN_NUM   (IMAGE_W),
      .IMAGE_W   (IMAGE_W),
      .IMAGE_H   (IMAGE_H)
  ) u_rotate_image (
      .clk(wr3_clk),
      .rst(wr3_rst),

      .rotate_angle    (param_rotate),
      .rotate_amplitude(param_rotate_A),
      .offsetX         (param_offsetX),
      .offsetY         (param_offsetY),

      .rotate_en        (rotate_vs_out),
      .ddr_data_in_valid(rd3_data_valid),
      .ddr_data_in      (rd3_data),

      .rd_ddr_addr_valid(rotate_image_addr_valid),
      .rd_ddr_addr      (rotate_image_addr),
      .data_out_valid   (wr3_data_in_valid),
      .data_out         (wr3_data_in)
  );



  //---------------------------------------------------------------
  // 缩放
  //---------------------------------------------------------------
  reg zoom_fifo_full, zoom_vs_out1, zoom_vs_out0;
  wire zoom_data_out_valid;
  wire [15:0] zoom_data_out;
  wire [12:0] wr_water_level;
  wire [15:0] hdmi_out_rd_data;

  //--- 参数跨时钟域 ---//
  reg [9:0] zoom_ff0, zoom_ff1, zoom_ff2;
  always @(posedge zoom_clk) begin
    if (zoom_rst) begin
      zoom_ff0 <= 128;
      zoom_ff1 <= 128;
      zoom_ff2 <= 128;
    end else begin
      zoom_ff0 <= param_zoom;
      zoom_ff1 <= zoom_ff0;
      zoom_ff2 <= zoom_ff1;
    end
  end
  zoom_image_v1 #(
      .IMAGE_SIZE(IMAGE_SIZE),
      .FRA_WIDTH (7),
      .IMAGE_W   (IMAGE_W),
      .IMAGE_H   (IMAGE_H)
  ) u_zoom_image (
      .clk          (zoom_clk),
      .rst          (zoom_rst),
      .zoom_en      (zoom_vs_out1),
      //. zoom_en             (0),
      .hdmi_out_en  (1'b1),
      .data_half_en (1'b0),
      .fifo_full    (zoom_fifo_full),
      .zoom_num     (zoom_ff2),
      .data_in_valid(rd1_data_valid),
      .data_in      (rd1_data),

      .data_out_valid (zoom_data_out_valid),
      .data_out       (zoom_data_out),
      .imag_addr_valid(zoom_image_addr_valid),
      .imag_addr      (zoom_image_addr)
  );
  zoom_hdmi_fifo u_zoom_hdmi_fifo (
      .wr_clk        (zoom_clk),             // input
      .wr_rst        (zoom_rst),             // input
      .wr_en         (zoom_data_out_valid),  // input
      .wr_data       (zoom_data_out),        // input [15:0]
      .wr_full       (),                     // output
      .wr_water_level(wr_water_level),       // output [11:0]
      .almost_full   (),                     // output
      .rd_clk        (pix_clk),              // input
      .rd_rst        (pix_rst),              // input
      .rd_en         (hdmi_out_rd_en),       // input
      .rd_data       (hdmi_out_rd_data),     // output [15:0]
      .rd_empty      (),                     // output
      .almost_empty  ()                      // output
  );

  always @(posedge zoom_clk) begin
    zoom_fifo_full <= (wr_water_level < 4000 - IMAGE_W) ? 1'b1 : 1'b0;
    zoom_vs_out0   <= hdmi_vs_out0;
    zoom_vs_out1   <= zoom_vs_out0;
  end

  //---------------------------------------------------------------
  // HDMI输出时序生成与图像读取
  //---------------------------------------------------------------
  wire [11:0] pos_x;
  wire [11:0] pos_y;

  sync_vg #(
      .V_TOTAL(V_TOTAL),
      .V_FP(V_FP),
      .V_BP(V_BP),
      .V_SYNC(V_SYNC),
      .V_ACT(V_ACT),
      .H_TOTAL(H_TOTAL),
      .H_FP(H_FP),
      .H_BP(H_BP),
      .H_SYNC(H_SYNC),
      .H_ACT(H_ACT)
  ) u_sync_vg (
      .clk      (pix_clk),
      .rst      (sync_vg_100m),
      .vs_out   (hdmi_vs_out0),
      .hs_out   (hdmi_hs_out0),
      .de_re    (hdmi_de_out0),
      .ddr_rd_en(hdmi_out_rd_en),

      .rd_mode        (2),
      .ddr_image_data (hdmi_out_rd_data),
      .hdmi_image_data(hdmi_image_data),
      .pos_x          (pos_x),
      .pos_y          (pos_y)
  );


  always @(posedge pix_clk) begin
    hdmi_hs_out1 <= hdmi_hs_out0;
    hdmi_vs_out1 <= hdmi_vs_out0;
    hdmi_de_out1 <= hdmi_de_out0;
    hdmi_b_out   <= {hdmi_image_data[4:0], hdmi_image_data[4:2]};
    hdmi_g_out   <= {hdmi_image_data[10:5], hdmi_image_data[10:9]};
    hdmi_r_out   <= {hdmi_image_data[15:11], hdmi_image_data[15:13]};
  end

  //---------------------------------------------------------------
  // 以太网UDP通信接口与OSD
  //---------------------------------------------------------------
  assign eth_rstn = rstn_out;
  wire [23:0] rgb_osd;
  wire vs_osd, hs_osd, de_osd;
  udp_osd #(
      .SCREEN_WIDTH(H_ACT),
      .SCREEN_HEIGHT(V_ACT),
      .PIXEL_DATA_WIDTH(24),
      .R_DATA_WIDTH(8),
      .G_DATA_WIDTH(8),
      .B_DATA_WIDTH(8)
  ) udp_osd_inst (
      .clk(pix_clk),
      .resetn(~sync_vg_100m),

      .eth_rxc(eth_rxc),
      .eth_rx_ctl(eth_rx_ctl),
      .eth_rxd(eth_rxd),
      .eth_txc(eth_txc),
      .eth_tx_ctl(eth_tx_ctl),
      .eth_txd(eth_txd),

      .gmii_clk(gmii_clk),
      .udp_rx_pkt_start(udp_rx_pkt_start),
      .udp_rx_pkt_done(udp_rx_pkt_done),
      .udp_rx_pkt_en(udp_rx_pkt_en),
      .udp_rx_pkt_data(udp_rx_pkt_data),
      .udp_rx_pkt_dest_port(udp_rx_pkt_dest_port),
      .udp_rx_pkt_byte_num(udp_rx_pkt_byte_num),


      .cfg_start_posX (param_osd_startX),    // input [10:0] cfg_start_posX
      .cfg_start_posY (param_osd_startY),    // input [10:0] cfg_start_posY
      .cfg_end_posX   (H_ACT),  // input [10:0] cfg_end_posX
      .cfg_end_posY   (V_ACT),  // input [10:0] cfg_end_posY
      .cfg_char_width (param_osd_char_width),    // input [10:0] cfg_char_width
      .cfg_char_height(param_osd_char_height),    // input [10:0] cfg_char_height

      .vs_in (hdmi_vs_out1),
      .hs_in (hdmi_hs_out1),
      .de_in (hdmi_de_out1),
      .rgb_in({hdmi_r_out, hdmi_g_out, hdmi_b_out}),
      .pos_x (pos_x[10:0]),
      .pos_y (pos_y[10:0]),

      //接到“色度 饱和度 亮度调整”模块
      .vs_out (vs_osd),
      .hs_out (hs_osd),
      .de_out (de_osd),
      .rgb_out(rgb_osd)
  );

  //---------------------------------------------------------------
  // 色度 饱和度 亮度调整
  //---------------------------------------------------------------
  adjust_color_wrapper adjust_color_wrapper_inst (
      .clk     (pix_clk),
      .resetn  (~sync_vg_100m),
      .vs_in   (vs_osd),
      .hs_in   (hs_osd),
      .de_in   (de_osd),
      .rgb_in  (rgb_osd),
      .modify_h(param_modify_H),
      .modify_s(param_modify_S),
      .modify_v(param_modify_V),

      //FPGA HDMI输出端口
      .vs_out(vs_out),
      .hs_out(hs_out),
      .de_out(de_out),
      .r_out (r_out),
      .g_out (g_out),
      .b_out (b_out)
  );

  //---------------------------------------------------------------
  // DDR读写
  //---------------------------------------------------------------

  ddr_addr_ctr #(
      .ADDR_WIDTH  (ADDR_WIDTH),
      .WR_NUM_WIDTH(WR_NUM_WIDTH),
      .RD_NUM_WIDTH(RD_NUM_WIDTH),
      .IMAGE_W     (IMAGE_W),
      .IMAGE_H     (IMAGE_H),
      .IMAGE_SIZE  (IMAGE_SIZE)
  ) u_ddr_addr_ctr (
      .clk(clk_50m),
      .rst(rst_50m),

      .wr0_clk       (wr0_clk),
      .wr0_rst       (wr0_rst),
      .wr0_vs        (wr0_vs),
      .wr0_ddr_done  (wr0_ddr_done),
      .wr0_addr_valid(wr0_addr_valid),
      .wr0_ddr_addr  (wr0_ddr_addr),
      .wr0_ddr_num   (wr0_ddr_num),

      .wr1_clk       (wr1_clk),
      .wr1_rst       (wr1_rst),
      .wr1_vs        (wr1_vs),
      .wr1_ddr_done  (wr1_ddr_done),
      .wr1_addr_valid(wr1_addr_valid),
      .wr1_ddr_addr  (wr1_ddr_addr),
      .wr1_ddr_num   (wr1_ddr_num),

      .wr2_clk       (wr2_clk),
      .wr2_rst       (wr2_rst),
      .wr2_ddr_done  (wr2_ddr_done),
      .wr2_addr_valid(wr2_addr_valid),
      .wr2_ddr_addr  (wr2_ddr_addr),
      .wr2_ddr_num   (wr2_ddr_num),
      .zoom_vs_out   (zoom_vs_out),

      .wr3_clk       (wr3_clk),
      .wr3_rst       (wr3_rst),
      .wr3_ddr_done  (wr3_ddr_done),
      .wr3_addr_valid(wr3_addr_valid),
      .wr3_ddr_addr  (wr3_ddr_addr),
      .wr3_ddr_num   (wr3_ddr_num),

      .rd0_clk      (rd0_clk),
      .rd0_rst      (rd0_rst),
      .rd0_ddr_done (rd0_ddr_done),
      .rd0_ddr_valid(rd0_ddr_valid),
      .rd0_ddr_addr (rd0_ddr_addr),
      .rd0_ddr_num  (rd0_ddr_num),

      .sift_done(sift_done),

      .rd1_clk              (zoom_clk),
      .rd1_rst              (zoom_rst),
      .rd1_ddr_done         (rd1_ddr_done),
      .rd1_ddr_valid        (rd1_ddr_valid),
      .rd1_ddr_addr         (rd1_ddr_addr),
      .rd1_ddr_num          (rd1_ddr_num),
      .shift_h              (0),
      .zoom_image_addr_valid(zoom_image_addr_valid),
      .zoom_image_addr      (zoom_image_addr),
      .rd1_mode             (2),
      .rd1_vs               (zoom_vs_out1),

      .rd2_clk      (rd2_clk),
      .rd2_rst      (rd2_rst),
      .rd2_vs       (0),
      .rd2_ddr_done (rd2_ddr_done),
      .rd2_ddr_valid(rd2_ddr_valid),
      .rd2_ddr_addr (rd2_ddr_addr),
      .rd2_ddr_num  (rd2_ddr_num),
      .hdmi_out_mode(2),

      .rd3_clk                (rd3_clk),
      .rd3_rst                (rd3_rst),
      .rotate_image_addr_valid(rotate_image_addr_valid),
      .rotate_image_addr      (rotate_image_addr),
      .rd3_ddr_addr_valid     (rd3_ddr_addr_valid),
      .rd3_ddr_addr           (rd3_ddr_addr),
      .rotate_vs_out          (rotate_vs_out),

      .vs_30hz            (),
      .vs_15hz            (),
      .vs_7hz             (),
      .init_calib_complete(init_calib_complete)
  );



  axi_ddr_top u_axi_ddr_top (
      .wr0_ddr_sart_addr_valid(wr0_addr_valid),
      .wr1_ddr_sart_addr_valid(wr1_addr_valid),
      .wr2_ddr_sart_addr_valid(wr2_addr_valid),
      .wr3_ddr_sart_addr_valid(wr3_addr_valid),
      .wr0_ddr_sart_addr      (wr0_ddr_addr),
      .wr1_ddr_sart_addr      (wr1_ddr_addr),
      .wr2_ddr_sart_addr      (wr2_ddr_addr),
      .wr3_ddr_sart_addr      (wr3_ddr_addr),
      .wr0_ddr_num            (wr0_ddr_num),
      .wr1_ddr_num            (wr1_ddr_num),
      .wr2_ddr_num            (wr2_ddr_num),
      .wr3_ddr_num            (wr3_ddr_num),

      .wr0_ddr_done(wr0_ddr_done),
      .wr1_ddr_done(wr1_ddr_done),
      .wr2_ddr_done(wr2_ddr_done),
      .wr3_ddr_done(wr3_ddr_done),

      .wr0_clk          (wr0_clk),
      .wr0_data_in_valid(wr0_data_in_valid),
      .wr0_data_in      (wr0_data_in),
      .wr0_fifo_full    (),

      .wr1_clk          (wr1_clk),
      .wr1_data_in_valid(wr1_data_in_valid),
      .wr1_data_in      (wr1_data_in),
      .wr1_fifo_full    (),

      .wr2_clk          (wr2_clk),
      .wr2_data_in_valid(wr2_data_in_valid),
      .wr2_data_in      (wr2_data_in),
      .wr2_fifo_full    (),

      .wr3_clk          (wr3_clk),
      .wr3_data_in_valid(wr3_data_in_valid),
      .wr3_data_in      (wr3_data_in),
      .wr3_fifo_full    (),

      .rd0_addr_start_valid(rd0_ddr_valid),
      .rd1_addr_start_valid(rd1_ddr_valid),
      .rd2_addr_start_valid(rd2_ddr_valid),
      .rd0_ddr_sart_addr   (rd0_ddr_addr),
      .rd1_ddr_sart_addr   (rd1_ddr_addr),
      .rd2_ddr_sart_addr   (rd2_ddr_addr),
      .rd0_ddr_num         (rd0_ddr_num),
      .rd1_ddr_num         (rd1_ddr_num),
      .rd2_ddr_num         (rd2_ddr_num),
      .rd0_ddr_done        (rd0_ddr_done),
      .rd1_ddr_done        (rd1_ddr_done),
      .rd2_ddr_done        (rd2_ddr_done),

      .rd0_clk       (rd0_clk),
      .rd0_en        (~rd0_empty),
      .rd0_data_valid(rd0_data_valid),
      .rd0_empty     (rd0_empty),
      .rd0_data      (rd0_data),

      .rd1_clk       (zoom_clk),
      .rd1_en        (~rd1_empty),
      .rd1_data_valid(rd1_data_valid),
      .rd1_empty     (rd1_empty),
      .rd1_data      (rd1_data),

      .rd2_clk       (rd2_clk),
      .rd2_en        ((~rd2_empty) & hdmi_out_en),
      .rd2_data_valid(rd2_data_valid),
      .rd2_empty     (rd2_empty),
      .rd2_data      (rd2_data),

      .rd3_clk             (rd3_clk),
      .rd3_ddr_addr_valid  (rd3_ddr_addr_valid),
      .rd3_ddr_addr        (rd3_ddr_addr),
      .rd3_data_valid      (rd3_data_valid),
      .rd3_data            (rd3_data),
      .rd3_araddr_fifo_full(),

      .mem_rst_n(mem_rst_n),
      .mem_ck   (mem_ck),
      .mem_ck_n (mem_ck_n),
      .mem_cke  (mem_cke),

      .mem_cs_n(mem_cs_n),

      .mem_ras_n(mem_ras_n),
      .mem_cas_n(mem_cas_n),
      .mem_we_n (mem_we_n),
      .mem_odt  (mem_odt),
      .mem_a    (mem_a),
      .mem_ba   (mem_ba),
      .mem_dqs  (mem_dqs),
      .mem_dqs_n(mem_dqs_n),
      .mem_dq   (mem_dq),
      .mem_dm   (mem_dm),

      .init_calib_complete(init_calib_complete),
      .ddr_clk            (ddr_clk),
      .axi_rst            (axi_rst),
      .ddr_rstn           (~ddr_rst)
  );



  always @(*) begin
    led[4:1] = index_param;
  end
endmodule
