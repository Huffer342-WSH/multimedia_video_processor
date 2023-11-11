//*****************************************************************************

// (c) Copyright 2009 - 2013 Xilinx, Inc. All rights reserved.

`timescale 1ps / 1ps

module axi_ddr_top #(
    parameter WIDTH        = 16,
    parameter FIFO_MAX_NUM = 8,
    parameter ADDR_WIDTH   = 30,
    parameter WR_NUM_WIDTH = 16,
    parameter RD_NUM_WIDTH = 16
) (
    input wr0_ddr_sart_addr_valid,
    input wr1_ddr_sart_addr_valid,
    input wr2_ddr_sart_addr_valid,
    input wr3_ddr_sart_addr_valid,
    input [ADDR_WIDTH-1:0] wr0_ddr_sart_addr,
    input [ADDR_WIDTH-1:0] wr1_ddr_sart_addr,
    input [ADDR_WIDTH-1:0] wr2_ddr_sart_addr,
    input [ADDR_WIDTH-1:0] wr3_ddr_sart_addr,
    input [WR_NUM_WIDTH-1:0] wr0_ddr_num,
    input [WR_NUM_WIDTH-1:0] wr1_ddr_num,
    input [WR_NUM_WIDTH-1:0] wr2_ddr_num,
    input [WR_NUM_WIDTH-1:0] wr3_ddr_num,

    output wr0_ddr_done,
    output wr1_ddr_done,
    output wr2_ddr_done,
    output wr3_ddr_done,

    input wr0_clk,
    input wr0_data_in_valid,
    input [WIDTH-1:0] wr0_data_in,
    output wr0_fifo_full,

    input wr1_clk,
    input wr1_data_in_valid,
    input [WIDTH-1:0] wr1_data_in,
    output wr1_fifo_full,

    input wr2_clk,
    input wr2_data_in_valid,
    input [WIDTH-1:0] wr2_data_in,
    output wr2_fifo_full,

    input wr3_clk,
    input wr3_data_in_valid,
    input [WIDTH-1:0] wr3_data_in,
    output wr3_fifo_full,

    input rd0_addr_start_valid,
    input rd1_addr_start_valid,
    input rd2_addr_start_valid,
    input [ADDR_WIDTH-1:0] rd0_ddr_sart_addr,
    input [ADDR_WIDTH-1:0] rd1_ddr_sart_addr,
    input [ADDR_WIDTH-1:0] rd2_ddr_sart_addr,
    input [RD_NUM_WIDTH-1:0] rd0_ddr_num,
    input [RD_NUM_WIDTH-1:0] rd1_ddr_num,
    input [RD_NUM_WIDTH-1:0] rd2_ddr_num,
    output rd0_ddr_done,
    output rd1_ddr_done,
    output rd2_ddr_done,


    input rd0_clk,
    input rd0_en,
    output rd0_data_valid,
    output rd0_empty,
    output [WIDTH-1:0] rd0_data,

    input rd1_clk,
    input rd1_en,
    output rd1_data_valid,
    output rd1_empty,
    output [WIDTH-1:0] rd1_data,

    input rd2_clk,
    input rd2_en,
    output rd2_data_valid,
    output rd2_empty,
    output [WIDTH-1:0] rd2_data,

    input rd3_clk,
    input rd3_ddr_addr_valid,
    input [ADDR_WIDTH-1:0] rd3_ddr_addr,
    output rd3_data_valid,
    output [WIDTH-1:0] rd3_data,
    output rd3_araddr_fifo_full,


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

    input  ddr_clk,
    input  ddr_rstn,
    input  axi_rst,
    output init_calib_complete

);

  // Wire declarations

  wire                  clk;
  wire                  rst;
  // AXI WR_ADDR
  wire [         4-1:0] s_axi_awid = 'd0;
  wire [           1:0] s_axi_awburst = 'd1;  //INC
  wire [           0:0] s_axi_awlock = 'd0;
  wire [           3:0] s_axi_awcache = 4'b0010;
  wire [           2:0] s_axi_awprot = 'd0;
  wire                  s_axi_awready;
  wire [           2:0] s_axi_awsize = 'd7;

  //AXI_WR_DATA

  wire                  s_axi_wready;
  wire                  s_axi_wlast;
  // Slave Interface Write Response Ports
  wire                  s_axi_bready = 'd1;
  wire [         4-1:0] s_axi_bid;
  wire [           1:0] s_axi_bresp;
  wire                  s_axi_bvalid;

  // Slave Interface Read Address Ports
  wire [           1:0] s_axi_arburst = 'd1;
  wire [           0:0] s_axi_arlock = 'd0;
  wire [           3:0] s_axi_arcache = 4'b0010;
  wire [           2:0] s_axi_arprot = 'd0;
  wire                  s_axi_arready;

  // Slave Interface Read Data Ports

  wire                  s_axi_rready = 'd1;
  wire [         4-1:0] s_axi_rid;
  wire [       256-1:0] s_axi_rdata;
  wire [           1:0] s_axi_rresp;
  wire                  s_axi_rlast;
  wire                  s_axi_rvalid;


  wire [ADDR_WIDTH-1:0] s_axi_awaddr;
  wire [           7:0] s_axi_awlen = 'd7;
  wire                  s_axi_awvalid;
  wire                  s_axi_awuser_ap = 'd0;

  wire [       256-1:0] s_axi_wdata;
  wire [   (256/8)-1:0] s_axi_wstrb = 32'hffff_ffff;
  wire                  s_axi_wvalid;

  reg  [         4-1:0] s_axi_arid;
  reg  [ADDR_WIDTH-1:0] s_axi_araddr;
  reg  [           7:0] s_axi_arlen;
  wire [           2:0] s_axi_arsize = 'd7;
  wire                  s_axi_arvalid;

  wire                  s_axi_aruser_ap = 'd0;

  reg                   rst0;
  reg                   rst1;
  assign rst = rst0;
  always @(posedge clk) begin
    if (axi_rst) begin
      rst0 <= 'd1;
      rst1 <= 'd1;
    end else begin
      rst0 <= 'd0;
      rst1 <= rst0;
    end
  end


  assign init_calib_complete = ddr_init_done;
  axi_ddr I_ipsxb_ddr_top (
      .ref_clk      (ddr_clk),
      .resetn       (ddr_rstn),
      .ddr_init_done(ddr_init_done),
      .ddrphy_clkin (clk),
      .pll_lock     (),

      .axi_awaddr   (s_axi_awaddr[2+:ADDR_WIDTH-2]),
      .axi_awuser_ap('d0),
      .axi_awuser_id('d0),
      .axi_awlen    (s_axi_awlen),
      .axi_awready  (s_axi_awready),
      .axi_awvalid  (s_axi_awvalid),

      .axi_wdata      (s_axi_wdata),
      .axi_wstrb      (s_axi_wstrb),
      .axi_wready     (s_axi_wready),
      .axi_wusero_id  (),
      .axi_wusero_last(),

      .axi_araddr   (s_axi_araddr[2+:ADDR_WIDTH-2]),
      .axi_aruser_ap('d0),
      .axi_aruser_id(s_axi_arid),
      .axi_arlen    (s_axi_arlen),
      .axi_arready  (s_axi_arready),
      .axi_arvalid  (s_axi_arvalid),

      .axi_rdata (s_axi_rdata),
      .axi_rid   (s_axi_rid),
      .axi_rlast (s_axi_rlast),
      .axi_rvalid(s_axi_rvalid),

      .apb_clk             ('d0),
      .apb_rst_n           ('d0),
      .apb_sel             ('d0),
      .apb_enable          ('d0),
      .apb_addr            ('d0),
      .apb_write           ('d0),
      .apb_ready           (),
      .apb_wdata           ('d0),
      .apb_rdata           (),
      .apb_int             (),
      .debug_data          (),
      .debug_slice_state   (),
      .debug_calib_ctrl    (),
      .ck_dly_set_bin      (),
      .force_ck_dly_en     ('d0),
      .force_ck_dly_set_bin(8'h14),
      .dll_step            (),
      .dll_lock            (),
      .init_read_clk_ctrl  ('d0),
      .init_slip_step      ('d0),
      .force_read_clk_ctrl ('d0),

      .ddrphy_gate_update_en  ('d0),
      .update_com_val_err_flag(),
      .rd_fake_stop           ('d0),

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
      .mem_dm   (mem_dm)
  );


  wire                  axi_fifo_full;
  wire                  axi_addr_valid;
  wire [ADDR_WIDTH-1:0] axi_addr;
  wire                  axi_data_valid;
  wire [          63:0] axi_data_out;
  axi_wr_connect #(
      .WIDTH       (WIDTH),
      .FIFO_MAX_NUM(FIFO_MAX_NUM),
      .ADDR_WIDTH  (ADDR_WIDTH),
      .WR_NUM_WIDTH(WR_NUM_WIDTH)
  ) u_axi_wr_connect (
      .clk(clk),
      .rst(rst),

      .wr0_ddr_sart_addr_valid(wr0_ddr_sart_addr_valid),
      .wr1_ddr_sart_addr_valid(wr1_ddr_sart_addr_valid),
      .wr2_ddr_sart_addr_valid(wr2_ddr_sart_addr_valid),
      .wr3_ddr_sart_addr_valid(wr3_ddr_sart_addr_valid),
      .wr0_ddr_sart_addr      (wr0_ddr_sart_addr[ADDR_WIDTH-1:8]),
      .wr1_ddr_sart_addr      (wr1_ddr_sart_addr[ADDR_WIDTH-1:8]),
      .wr2_ddr_sart_addr      (wr2_ddr_sart_addr[ADDR_WIDTH-1:8]),
      .wr3_ddr_sart_addr      (wr3_ddr_sart_addr[ADDR_WIDTH-1:8]),
      .wr0_ddr_num            (wr0_ddr_num),
      .wr1_ddr_num            (wr1_ddr_num),
      .wr2_ddr_num            (wr2_ddr_num),
      .wr3_ddr_num            (wr3_ddr_num),

      .wr0_ddr_done(wr0_ddr_done),
      .wr1_ddr_done(wr1_ddr_done),
      .wr2_ddr_done(wr2_ddr_done),
      .wr3_ddr_done(wr3_ddr_done),

      .wr0_clk       (wr0_clk),
      .data_in0_valid(wr0_data_in_valid),
      .data_in0      (wr0_data_in),
      .fifo0_full    (wr0_fifo_full),

      .wr1_clk       (wr1_clk),
      .data_in1_valid(wr1_data_in_valid),
      .data_in1      (wr1_data_in),
      .fifo1_full    (wr1_fifo_full),

      .wr2_clk       (wr2_clk),
      .data_in2_valid(wr2_data_in_valid),
      .data_in2      (wr2_data_in),
      .fifo2_full    (wr2_fifo_full),

      .wr3_clk       (wr3_clk),
      .data_in3_valid(wr3_data_in_valid),
      .data_in3      (wr3_data_in),
      .fifo3_full    (wr3_fifo_full),

      .axi_fifo_full (axi_fifo_full),
      .axi_addr_valid(axi_addr_valid),
      .axi_addr      (axi_addr),
      .axi_data_valid(axi_data_valid),
      .axi_data_out  (axi_data_out)

  );



  localparam WR_IDLE = 4'b0001;
  localparam WR_EN = 4'b0010;
  localparam WR_ADDR = 4'b0100;
  localparam WR_DATA = 4'b1000;
  reg [3:0] wr_sta;
  reg rd_importance;
  reg axi_fifo_full0;
  reg record_data_valid, record_addr_valid;
  wire [11:0] wr_ddr_count;
  wire [ 9:0] rd_ddr_count;
  wire wr_ddr_en, wdata_empty, araddr_empty, wr_arddr_en;
  wire rd_wdata_en, rd_arddr_en;
  wire [255:0] wr_ddr_fifo_wdata;

  //generate 
  //genvar i;
  //for(i=0;i<16;i=i+1)
  //begin 
  //always @(*)
  //begin 
  //    s_axi_wdata[16*i+:16] = wr_ddr_fifo_wdata[16*(15-i)+:16];
  //end 
  //end 
  //endgenerate

  assign s_axi_wdata   = wr_ddr_fifo_wdata;
  assign axi_fifo_full = axi_fifo_full0;
  //wr_ddr_fifo u_wr_ddr_fifo (
  //  .clk(clk),                      // input wire clk
  //  .srst(rst),                    // input wire srst
  //  .din(axi_data_out),                      // input wire [31 : 0] din
  //  .wr_en(axi_data_valid),                  // input wire wr_en
  //  .rd_en(rd_wdata_en),                  // input wire rd_en
  //  .dout(wr_ddr_fifo_wdata),                    // output wire [255 : 0] dout
  //  .full(),                    // output wire full
  //  .empty(wdata_empty),                  // output wire empty
  //  .valid(),                  // output wire valid
  //  .rd_data_count(rd_ddr_count),  // output wire [9 : 0] rd_data_count
  //  .wr_data_count(wr_ddr_count)  // output wire [12 : 0] wr_data_count
  //);
  wr_ddr_fifo u_wr_ddr_fifo (
      .clk           (clk),                // input
      .rst           (rst),                // input
      .wr_en         (axi_data_valid),     // input
      .wr_data       (axi_data_out),       // input [31:0]
      .wr_full       (),                   // output
      .wr_water_level(wr_ddr_count),       // output [12:0]
      .almost_full   (),                   // output
      .rd_en         (rd_wdata_en),        // input
      .rd_data       (wr_ddr_fifo_wdata),  // output [255:0]
      .rd_empty      (wdata_empty),        // output
      .rd_water_level(rd_ddr_count),       // output [9:0]
      .almost_empty  ()                    // output
  );


  wire [31:0] awaddr_ddr_fifo_dout;
  assign s_axi_awaddr = awaddr_ddr_fifo_dout[ADDR_WIDTH-1:0];
  //awaddr_ddr_fifo u_awaddr_ddr_fifo (
  //  .clk(clk),      // input wire clk
  //  .srst(rst),    // input wire srst
  //  .din({{(32-ADDR_WIDTH){1'b0}},axi_addr}),      // input wire [31 : 0] din
  //  .wr_en(axi_addr_valid),  // input wire wr_en
  //  .rd_en(rd_arddr_en),  // input wire rd_en
  //  .dout(awaddr_ddr_fifo_dout),    // output wire [31 : 0] dout
  //  .full(),    // output wire full
  //  .empty(araddr_empty),  // output wire empty
  //  .valid()  // output wire valid
  //);
  awaddr_ddr_fifo u_awaddr_ddr_fifo (
      .clk           (clk),                                     // input
      .rst           (rst),                                     // input
      .wr_en         (axi_addr_valid),                          // input
      .wr_data       ({{(32 - ADDR_WIDTH) {1'b0}}, axi_addr}),  // input [31:0]
      .wr_full       (),                                        // output
      .wr_water_level(),                                        // output [9:0]
      .almost_full   (),                                        // output
      .rd_en         (rd_arddr_en),                             // input
      .rd_data       (awaddr_ddr_fifo_dout),                    // output [31:0]
      .rd_empty      (araddr_empty),                            // output
      .rd_water_level(),                                        // output [9:0]
      .almost_empty  ()                                         // output
  );
  reg rd_wr_fifo_full;
  reg rd_wr_fifo_empty, rd_wr_fast_empty;
  reg rd_ddr_idle;
  reg [2:0] cnt_wr_num;
  always @(posedge clk) begin
    axi_fifo_full0   <= (wr_ddr_count >= (2048 - 512)) ? 1'b1 : 1'b0;
    rd_wr_fifo_full  <= (wr_ddr_count >= (2048 - 512)) ? 1'b1 : 1'b0;
    rd_wr_fifo_empty <= (wr_ddr_count < (4 * 8 * 1 + 8)) ? 1'b1 : 1'b0;
    rd_wr_fast_empty <= (wr_ddr_count < (4 * 8 * 1 - 4 * record_data_valid)) ? 1'b1 : 1'b0;
  end
  assign s_axi_wvalid = ((wr_sta == WR_DATA) && s_axi_wready) ? 1'b1 : 1'b0;
  assign rd_wdata_en = ((~wdata_empty) && (((wr_sta == WR_EN) && (~record_data_valid)) ||
                                           (wr_sta == WR_DATA) && s_axi_wready)) ? 1'b1 : 1'b0;
  assign rd_arddr_en = ((~araddr_empty) && (((wr_sta == WR_EN) && (~record_addr_valid)) ||
                                            (wr_sta == WR_ADDR) && s_axi_awready)) ? 1'b1 : 1'b0;
  assign s_axi_awvalid = (wr_sta == WR_ADDR) ? 1'b1 : 1'b0;
  always @(posedge clk) begin
    if (rst) begin
      wr_sta <= WR_IDLE;
    end else begin
      case (wr_sta)
        WR_IDLE: begin
          if (rd_wr_fifo_full | ((~rd_wr_fast_empty) & (~rd_ddr_idle))) wr_sta <= WR_EN;
          else wr_sta <= WR_IDLE;
        end
        WR_EN: begin
          wr_sta <= WR_ADDR;
        end
        WR_ADDR: begin
          if (s_axi_awready) wr_sta <= WR_DATA;
          else wr_sta <= WR_ADDR;
        end
        WR_DATA: begin
          if ((cnt_wr_num == 'd7) && (s_axi_wready)) begin
            if (rd_importance | (rd_wr_fifo_empty) | (~record_addr_valid)) wr_sta <= WR_IDLE;
            else wr_sta <= WR_ADDR;
          end else wr_sta <= WR_DATA;
        end
        default: wr_sta <= WR_IDLE;
      endcase
    end
  end

  always @(posedge clk) begin
    if (rst) begin
      record_data_valid <= 'd0;
      record_addr_valid <= 'd0;
    end else begin
      case (wr_sta)
        WR_IDLE: begin
          record_data_valid <= record_data_valid;
          record_addr_valid <= record_addr_valid;
        end
        WR_EN: begin
          record_data_valid <= 'd1;
          record_addr_valid <= 'd1;
        end
        WR_ADDR: begin
          record_data_valid <= record_data_valid;
          if (araddr_empty & s_axi_awready) record_addr_valid <= 'd0;
          else record_addr_valid <= record_addr_valid;
        end
        WR_DATA: begin
          record_addr_valid <= record_addr_valid;
          if (wdata_empty) record_data_valid <= 'd0;
          else record_data_valid <= record_data_valid;
        end
        default: ;
      endcase
    end
  end
  assign s_axi_wlast = (((wr_sta == WR_DATA || wr_sta == WR_ADDR) && s_axi_wready) &&
                        cnt_wr_num == 7) ? 1'b1 : 1'b0;
  always @(posedge clk) begin
    //if((wr_sta == WR_DATA||wr_sta == WR_ADDR))
    if ((wr_sta == WR_DATA)) begin
      if (s_axi_wready) cnt_wr_num <= cnt_wr_num + 1'b1;
      else cnt_wr_num <= cnt_wr_num;
    end else cnt_wr_num <= 'd0;
  end


  wire rd0_fifo_empty;
  wire rd0_fifo_full;
  wire rd1_fifo_full;
  wire rd2_fifo_full;
  wire ddr_fifo_full;

  localparam AXI_RD_LEN = 8;
  axi_rd_connect #(
      .WIDTH     (WIDTH),
      .DDR_DWIDTH(256),
      .AXI_RD_LEN(AXI_RD_LEN)
  ) u_axi_rd_connect (
      .clk(clk),
      .rst(rst),

      .rd0_clk       (rd0_clk),
      .rd0_en        (rd0_en),
      .rd0_data_valid(rd0_data_valid),
      .rd0_empty     (rd0_empty),
      .rd0_data      (rd0_data),

      .rd1_clk       (rd1_clk),
      .rd1_en        (rd1_en),
      .rd1_data_valid(rd1_data_valid),
      .rd1_empty     (rd1_empty),
      .rd1_data      (rd1_data),

      .rd2_clk       (rd2_clk),
      .rd2_en        (rd2_en),
      .rd2_data_valid(rd2_data_valid),
      .rd2_empty     (rd2_empty),
      .rd2_data      (rd2_data),

      .axi_rid        (s_axi_rid),
      .axi_rdata_valid(s_axi_rvalid),
      .axi_rdata      (s_axi_rdata),

      .rd0_fifo_empty(rd0_fifo_empty),
      .rd0_fifo_full (rd0_fifo_full),
      .rd1_fifo_full (rd1_fifo_full),
      .rd2_fifo_full (rd2_fifo_full),
      .ddr_fifo_full (ddr_fifo_full)

  );

  localparam S0 = 9'b0_0000_0001;
  localparam S1 = 9'b0_0000_0010;
  localparam S2 = 9'b0_0000_0100;
  localparam S3 = 9'b0_0000_1000;
  localparam S4 = 9'b0_0001_0000;
  localparam S5 = 9'b0_0010_0000;
  localparam S6 = 9'b0_0100_0000;
  localparam S7 = 9'b0_1000_0000;
  //localparam  S8 = 9'b1_0000_0000;



  reg [8:0] rd_sta;
  reg rx_rd0_addr_valid, rx_rd1_addr_valid, rx_rd2_addr_valid;
  reg rd0_ddr_done0, rd1_ddr_done0, rd2_ddr_done0;
  reg rd0_addr_start_valid0, rd0_addr_start_valid1, rd0_addr_start_valid2;
  reg rd1_addr_start_valid0, rd1_addr_start_valid1, rd1_addr_start_valid2;
  reg rd2_addr_start_valid0, rd2_addr_start_valid1, rd2_addr_start_valid2;
  reg rd0_time_permit, rd1_time_permit, rd2_time_permit;
  reg [ADDR_WIDTH-1:0] rd0_ddr_sart_addr0, rd0_ddr_sart_addr1, rd0_ddr_sart_addr2;
  reg [ADDR_WIDTH-1:0] rd1_ddr_sart_addr0, rd1_ddr_sart_addr1, rd1_ddr_sart_addr2;
  reg [ADDR_WIDTH-1:0] rd2_ddr_sart_addr0, rd2_ddr_sart_addr1, rd2_ddr_sart_addr2;
  reg [RD_NUM_WIDTH-1:0] rd0_ddr_num0, rd0_ddr_num1, rd0_ddr_num2;
  reg [RD_NUM_WIDTH-1:0] rd1_ddr_num0, rd1_ddr_num1, rd1_ddr_num2;
  reg [RD_NUM_WIDTH-1:0] rd2_ddr_num0, rd2_ddr_num1, rd2_ddr_num2;
  reg [RD_NUM_WIDTH-1:0] rd0_cnt_num, rd1_cnt_num, rd2_cnt_num;
  reg wr_sta_idle;
  reg rd_all_full;
  reg record_araddr_valid;

  wire [31:0] rd3_axi_addr_dout;
  wire rd0_permit, rd1_permit, rd2_permit;
  wire rd3_araddr_fifo_empty;
  wire rd3_data_full;

  assign rd0_permit = (rd0_time_permit & rx_rd0_addr_valid & (~rd0_fifo_full) & wr_sta_idle) &
      (~ddr_fifo_full);
  assign rd1_permit = (rd1_time_permit & rx_rd1_addr_valid & (~rd1_fifo_full) & wr_sta_idle) &
      (~ddr_fifo_full);
  assign rd2_permit = (rd2_time_permit & rx_rd2_addr_valid & (~rd2_fifo_full) & wr_sta_idle) &
      (~ddr_fifo_full);
  always @(posedge clk) begin
    if (rst) begin
      rd_sta <= S0;
    end else begin
      case (rd_sta)
        S0: begin
          if (rd0_permit) rd_sta <= S1;
          else rd_sta <= S2;
        end
        S1: begin
          if (s_axi_arready) rd_sta <= S2;
          else rd_sta <= S1;
        end
        S2: begin
          if (rd1_permit) rd_sta <= S3;
          else rd_sta <= S4;
        end
        S3: begin
          if (s_axi_arready) rd_sta <= S4;
          else rd_sta <= S3;
        end
        S4: begin
          if (rd2_permit) rd_sta <= S5;
          else rd_sta <= S6;
        end
        S5: begin
          if (s_axi_arready) rd_sta <= S6;
          else rd_sta <= S5;
        end
        S6: begin
          if (wr_sta_idle & (record_araddr_valid) & (rd_all_full) & (~rd3_data_full)) rd_sta <= S7;
          else rd_sta <= S0;
        end
        S7: begin
          if (rd_all_full) rd_sta <= S0;
          else if (s_axi_arready) rd_sta <= S6;
          else rd_sta <= S7;
        end
        default: rd_sta <= S0;
      endcase
    end
  end
  assign s_axi_arvalid = (((rd_sta == S1) || (rd_sta == S3) || (rd_sta == S5) || (rd_sta == S7))) ?
      1'b1 : 1'b0;

  always @(posedge clk) begin
    if (rst) begin
    end else begin
      case (rd_sta)
        S0: begin
          s_axi_arid   <= 'd1;
          s_axi_arlen  <= AXI_RD_LEN - 1;
          s_axi_araddr <= rd0_ddr_sart_addr2 + (rd0_cnt_num) * 256 * 1;
        end
        //	S1:begin 
        //	    if(s_axi_arready)
        //		begin 
        //		    s_axi_araddr <= rd0_ddr_sart_addr2 + rd0_cnt_num*256;
        //		end 
        //		else begin 
        //		    s_axi_araddr <= s_axi_araddr ;
        //		end 
        //	end 
        S2: begin
          s_axi_araddr <= rd1_ddr_sart_addr2 + (rd1_cnt_num) * 256 * 1;
          s_axi_arid   <= 'd2;
          s_axi_arlen  <= AXI_RD_LEN - 1;
        end
        //	S3:begin 
        //	    if(s_axi_arready)
        //		begin 
        //		    s_axi_araddr <= rd1_ddr_sart_addr2 + rd1_cnt_num*256;
        //		end 
        //		else begin 
        //		    s_axi_araddr <= s_axi_araddr ;
        //		end 
        //	end 
        S4: begin
          s_axi_araddr <= rd2_ddr_sart_addr2 + (rd2_cnt_num) * 256 * 1;
          s_axi_arid   <= 'd4;
          s_axi_arlen  <= AXI_RD_LEN - 1;
        end
        //	S5:begin 
        //	    if(s_axi_arready)
        //		begin 
        //		    s_axi_araddr <= rd2_ddr_sart_addr2 + rd2_cnt_num*256;
        //		end 
        //		else begin 
        //		    s_axi_araddr <= s_axi_araddr ;
        //		end 
        //	end 
        S6: begin
          s_axi_arid   <= 'd8;
          s_axi_arlen  <= 'd0;
          s_axi_araddr <= {rd3_axi_addr_dout[ADDR_WIDTH-1:5], 5'd0};
        end
        S7: begin
          s_axi_arid   <= 'd8;
          s_axi_arlen  <= 'd0;
          s_axi_araddr <= s_axi_araddr;
        end
        default: begin
          s_axi_araddr <= s_axi_araddr;
        end
      endcase
    end
  end
  reg rd0_addr_start_fall;
  reg rd1_addr_start_fall;
  reg rd2_addr_start_fall;
  always @(posedge clk) begin
    case (rd_sta)
      S1: begin
        if (s_axi_arready) begin
          rd0_cnt_num <= rd0_cnt_num + 1'b1;
        end else begin
          rd0_cnt_num <= rd0_cnt_num;
        end
      end
      default: begin
        if ((rd0_cnt_num >= rd0_ddr_num2) || (rd0_addr_start_fall)) rd0_cnt_num <= 'd0;
        else rd0_cnt_num <= rd0_cnt_num;
      end
    endcase
  end

  always @(posedge clk) begin
    case (rd_sta)
      S3: begin
        if (s_axi_arready) begin
          rd1_cnt_num <= rd1_cnt_num + 1'b1;
        end else begin
          rd1_cnt_num <= rd1_cnt_num;
        end
      end
      default: begin
        if ((rd1_cnt_num >= rd1_ddr_num2) || (rd1_addr_start_fall)) rd1_cnt_num <= 'd0;
        else rd1_cnt_num <= rd1_cnt_num;
      end
    endcase
  end
  always @(posedge clk) begin
    case (rd_sta)
      S5: begin
        if (s_axi_arready) begin
          rd2_cnt_num <= rd2_cnt_num + 1'b1;
        end else begin
          rd2_cnt_num <= rd2_cnt_num;
        end
      end
      default: begin
        if ((rd2_cnt_num >= rd2_ddr_num2) || (rd2_addr_start_fall)) rd2_cnt_num <= 'd0;
        else rd2_cnt_num <= rd2_cnt_num;
      end
    endcase
  end
  always @(posedge clk) begin
    rd_all_full   <= ~((rd0_permit) | (rd1_permit) | (rd2_permit));
    rd_importance <= (rd0_time_permit & rx_rd0_addr_valid & (rd0_fifo_empty));
    if (rst) record_araddr_valid <= 'd0;
    else begin
      if ((rd_sta == S6) && (~rd3_araddr_fifo_empty)) record_araddr_valid <= 1'b1;
      else if ((rd_sta == S7) && (s_axi_arready)) record_araddr_valid <= 1'b0;
      else record_araddr_valid <= record_araddr_valid;
    end
  end

  always @(posedge clk) begin
    rd0_ddr_sart_addr0    <= rd0_ddr_sart_addr;
    rd1_ddr_sart_addr0    <= rd1_ddr_sart_addr;
    rd2_ddr_sart_addr0    <= rd2_ddr_sart_addr;
    rd0_ddr_sart_addr1    <= rd0_ddr_sart_addr0;
    rd1_ddr_sart_addr1    <= rd1_ddr_sart_addr0;
    rd2_ddr_sart_addr1    <= rd2_ddr_sart_addr0;
    rd0_ddr_num0          <= rd0_ddr_num;
    rd1_ddr_num0          <= rd1_ddr_num;
    rd2_ddr_num0          <= rd2_ddr_num;
    rd0_ddr_num1          <= rd0_ddr_num0;
    rd1_ddr_num1          <= rd1_ddr_num0;
    rd2_ddr_num1          <= rd2_ddr_num0;
    rd0_addr_start_valid0 <= rd0_addr_start_valid;
    rd1_addr_start_valid0 <= rd1_addr_start_valid;
    rd2_addr_start_valid0 <= rd2_addr_start_valid;
    rd0_addr_start_valid1 <= rd0_addr_start_valid0;
    rd1_addr_start_valid1 <= rd1_addr_start_valid0;
    rd2_addr_start_valid1 <= rd2_addr_start_valid0;
    rd0_addr_start_fall   <= (~rd0_addr_start_valid0) & (rd0_addr_start_valid1);
    rd1_addr_start_fall   <= (~rd1_addr_start_valid0) & (rd1_addr_start_valid1);
    rd2_addr_start_fall   <= (~rd2_addr_start_valid0) & (rd2_addr_start_valid1);
    //rd0_addr_start_fall   <= (rd0_addr_start_valid0)&(~rd0_addr_start_valid1);
    //rd1_addr_start_fall   <= (rd1_addr_start_valid0)&(~rd1_addr_start_valid1);
    //rd2_addr_start_fall   <= (rd2_addr_start_valid0)&(~rd2_addr_start_valid1);
  end
  always @(posedge clk) begin
    if (rd0_addr_start_fall) begin
      rd0_ddr_sart_addr2 <= rd0_ddr_sart_addr1;
      rd0_ddr_num2       <= rd0_ddr_num1;
    end else begin
      rd0_ddr_sart_addr2 <= rd0_ddr_sart_addr2;
      rd0_ddr_num2       <= rd0_ddr_num1;
    end
    if (rd1_addr_start_fall) begin
      rd1_ddr_sart_addr2 <= rd1_ddr_sart_addr1;
      rd1_ddr_num2       <= rd1_ddr_num1;
    end else begin
      rd1_ddr_sart_addr2 <= rd1_ddr_sart_addr2;
      rd1_ddr_num2       <= rd1_ddr_num1;
    end
    if (rd2_addr_start_fall) begin
      rd2_ddr_sart_addr2 <= rd2_ddr_sart_addr1;
      rd2_ddr_num2       <= rd2_ddr_num1;
    end else begin
      rd2_ddr_sart_addr2 <= rd2_ddr_sart_addr2;
      rd2_ddr_num2       <= rd2_ddr_num1;
    end
  end
  reg [2:0] rd0_done_cnt = 0, rd1_done_cnt = 0, rd2_done_cnt = 0;
  reg rd0_ddr_done1, rd1_ddr_done1, rd2_ddr_done1;
  assign rd0_ddr_done = rd0_ddr_done1;
  assign rd1_ddr_done = rd1_ddr_done1;
  assign rd2_ddr_done = rd2_ddr_done1;
  always @(posedge clk) begin
    rd0_ddr_done0 <= ((rd0_cnt_num >= rd0_ddr_num2) && (rx_rd0_addr_valid)) ? 1'b1 : 1'b0;
    rd1_ddr_done0 <= ((rd1_cnt_num >= rd1_ddr_num2) && (rx_rd1_addr_valid)) ? 1'b1 : 1'b0;
    rd2_ddr_done0 <= ((rd2_cnt_num >= rd2_ddr_num2) && (rx_rd2_addr_valid)) ? 1'b1 : 1'b0;
    //rd1_ddr_done0 <= (rd1_cnt_num>=rd1_ddr_num2)?1'b1:1'b0;
    //rd2_ddr_done0 <= (rd2_cnt_num>=rd2_ddr_num2)?1'b1:1'b0;
    if (rst) rd0_done_cnt <= 'd0;
    else begin
      if (rd0_ddr_done0) rd0_done_cnt <= 'd7;
      else if (rd0_done_cnt > 0) rd0_done_cnt <= rd0_done_cnt - 1'b1;
    end
    if (rst) rd1_done_cnt <= 'd0;
    else begin
      if (rd1_ddr_done0) rd1_done_cnt <= 'd7;
      else if (rd1_done_cnt > 0) rd1_done_cnt <= rd1_done_cnt - 1'b1;
    end
    if (rst) rd2_done_cnt <= 'd0;
    else begin
      if (rd2_ddr_done0) rd2_done_cnt <= 'd7;
      else if (rd2_done_cnt > 0) rd2_done_cnt <= rd2_done_cnt - 1'b1;
    end
    rd0_ddr_done1 <= (rd0_done_cnt > 0) ? 1'b1 : 1'b0;
    rd1_ddr_done1 <= (rd1_done_cnt > 0) ? 1'b1 : 1'b0;
    rd2_ddr_done1 <= (rd2_done_cnt > 0) ? 1'b1 : 1'b0;
  end
  always @(posedge clk) begin
    if (rst) begin
      rx_rd0_addr_valid <= 'd0;
    end else begin
      if (rd0_addr_start_fall) rx_rd0_addr_valid <= 1'b1;
      else if (rd0_ddr_done0) rx_rd0_addr_valid <= 'd0;
      else rx_rd0_addr_valid <= rx_rd0_addr_valid;
    end
    if (rst) begin
      rx_rd1_addr_valid <= 'd0;
    end else begin
      if (rd1_addr_start_fall) rx_rd1_addr_valid <= 1'b1;
      else if (rd1_ddr_done0) rx_rd1_addr_valid <= 'd0;
      else rx_rd1_addr_valid <= rx_rd1_addr_valid;
    end
    if (rst) begin
      rx_rd2_addr_valid <= 'd0;
    end else begin
      if (rd2_addr_start_fall) rx_rd2_addr_valid <= 1'b1;
      else if (rd2_ddr_done0) rx_rd2_addr_valid <= 'd0;
      else rx_rd2_addr_valid <= rx_rd2_addr_valid;
    end
  end
  reg rd_sta0_reg0, rd_sta0_reg1;
  reg rd_sta2_reg0, rd_sta2_reg1;
  reg rd_sta4_reg0, rd_sta4_reg1;

  always @(posedge clk) begin
    rd_sta0_reg0 <= rd_sta[1];
    rd_sta2_reg0 <= rd_sta[3];
    rd_sta4_reg0 <= rd_sta[5];
    rd_sta0_reg1 <= rd_sta0_reg0;
    rd_sta2_reg1 <= rd_sta2_reg0;
    rd_sta4_reg1 <= rd_sta4_reg0;
  end
  reg [8:0] cnt0_times, cnt1_times, cnt2_times;
  always @(posedge clk) begin
    if (rst) cnt0_times <= 'd0;
    else if ((~rd_sta0_reg0) & rd_sta0_reg1) cnt0_times <= AXI_RD_LEN * 8 - 1;
    else if (cnt0_times > 0) cnt0_times <= cnt0_times - 1'b1;
    if (rst) cnt1_times <= 'd0;
    else if ((~rd_sta2_reg0) & rd_sta2_reg1) cnt1_times <= AXI_RD_LEN * 8 - 1;
    else if (cnt1_times > 0) cnt1_times <= cnt1_times - 1'b1;
    if (rst) cnt2_times <= 'd0;
    else if ((~rd_sta4_reg0) & rd_sta4_reg1) cnt2_times <= AXI_RD_LEN * 8 - 1;
    else if (cnt2_times > 0) cnt2_times <= cnt2_times - 1'b1;
    rd0_time_permit <= (cnt0_times == 0) ? 1'b1 : 1'b0;
    rd1_time_permit <= (cnt1_times == 0) ? 1'b1 : 1'b0;
    rd2_time_permit <= (cnt2_times == 0) ? 1'b1 : 1'b0;
    wr_sta_idle     <= (wr_sta == WR_IDLE) ? 1'b1 : 1'b0;
  end

  wire [31:0] araddr_fifo_dout;
  wire rd3_en, rd3_araddr_fifo_full2;
  assign
      rd3_en = ((~rd3_araddr_fifo_empty) && rd_sta == S6 && (~record_araddr_valid)) ? 1'b1 : 1'b0;
  assign rd3_axi_addr_dout = araddr_fifo_dout[ADDR_WIDTH-1:0];
  //araddr_fifo u_araddr_fifo (
  //  .wr_clk(rd3_clk),  // input wire wr_clk
  //  .wr_rst(rst),  // input wire wr_rst
  //  .rd_clk(clk),  // input wire rd_clk
  //  .rd_rst(rst),  // input wire rd_rst
  //  .din({{(32-ADDR_WIDTH){1'b0}},rd3_ddr_addr}),        // input wire [31 : 0] din
  //  .wr_en(rd3_ddr_addr_valid),    // input wire wr_en
  //  .rd_en(rd3_en),    // input wire rd_en
  //  .dout(araddr_fifo_dout),      // output wire [31 : 0] dout
  //  .full(rd3_araddr_fifo_full2),      // output wire full
  //  .almost_full(),
  //  .empty(rd3_araddr_fifo_empty)    // output wire empty 
  //);
  araddr_fifo u_araddr_fifo (
      .wr_clk        (rd3_clk),                                     // input
      .wr_rst        (rst),                                         // input
      .wr_en         (rd3_ddr_addr_valid),                          // input
      .wr_data       ({{(32 - ADDR_WIDTH) {1'b0}}, rd3_ddr_addr}),  // input [31:0]
      .wr_full       (rd3_araddr_fifo_full2),                       // output
      .wr_water_level(),                                            // output [11:0]
      .almost_full   (),                                            // output
      .rd_clk        (clk),                                         // input
      .rd_rst        (rst),                                         // input
      .rd_en         (rd3_en),                                      // input
      .rd_data       (araddr_fifo_dout),                            // output [31:0]
      .rd_empty      (rd3_araddr_fifo_empty),                       // output
      .almost_empty  ()                                             // output
  );

  wire wr3_en, rd3_data_en, rd3_data_empty;
  reg rd3_data_en0, rd3_data_en1, rd3_data_en2;
  reg [15:0] rd3_ddr_data;
  assign wr3_en = (s_axi_rid[3] & s_axi_rvalid) ? 1'b1 : 1'b0;
  assign rd3_data_en = ~rd3_data_empty;
  //rdata3_fifo u_rdata3_fifo (
  //  .wr_clk(clk),  // input wire wr_clk
  //  .wr_rst(rst),  // input wire wr_rst
  //  .rd_clk(rd3_clk),  // input wire rd_clk
  //  .rd_rst(rst),  // input wire rd_rst
  //  .din(rd3_ddr_data),        // input wire [15 : 0] din
  //  .wr_en(rd3_data_en2),    // input wire wr_en
  //  .rd_en(~rd3_data_empty),    // input wire rd_en
  //  .dout(rd3_data),      // output wire [15 : 0] dout
  //  .full(),      // output wire full
  //  .almost_full(rd3_data_full),      // output wire almost_full
  //  .empty(rd3_data_empty),    // output wire empty
  //  .valid(rd3_data_valid)
  //);
  rdata3_fifo u_rdata3_fifo (
      .wr_clk      (clk),              // input
      .wr_rst      (rst),              // input
      .wr_en       (rd3_data_en2),     // input
      .wr_data     (rd3_ddr_data),     // input [15:0]
      .wr_full     (),                 // output
      .almost_full (rd3_data_full),    // output
      .rd_clk      (rd3_clk),          // input
      .rd_rst      (rst),              // input
      .rd_en       (~rd3_data_empty),  // input
      .rd_data     (rd3_data),         // output [15:0]
      .rd_empty    (rd3_data_empty),   // output
      .almost_empty()                  // output
  );
  reg rd3_data_valid0;
  assign rd3_data_valid = rd3_data_valid0;
  always @(posedge rd3_clk) begin
    rd3_data_valid0 <= ~rd3_data_empty;
  end
  wire [  3:0] switch_data;
  reg  [  3:0] switch_data0;
  reg  [255:0] s_axi_rdata0;
  reg  [255:0] s_axi_rdata1;
  //low_araddr_fifo u_low_araddr_fifo (
  //  .wr_clk(rd3_clk),            // input wire wr_clk
  //  .wr_rst(rst),            // input wire wr_rst
  //  .rd_clk(clk),            // input wire rd_clk
  //  .rd_rst(rst),            // input wire rd_rst
  //  .din(rd3_ddr_addr[4:1]),                  // input wire [4 : 0] din
  //  .wr_en(rd3_ddr_addr_valid),              // input wire wr_en
  //  .rd_en(wr3_en),              // input wire rd_en
  //  .dout(switch_data),                // output wire [4 : 0] dout
  //  .full(),                // output wire full
  //  .almost_full(rd3_araddr_fifo_full),  // output wire almost_full
  //  .empty(),              // output wire empty
  //  .valid()              // output wire valid
  //);
  low_araddr_fifo u_low_araddr_fifo (
      .wr_clk        (rd3_clk),               // input
      .wr_rst        (rst),                   // input
      .wr_en         (rd3_ddr_addr_valid),    // input
      .wr_data       (rd3_ddr_addr[4:1]),     // input [3:0]
      .wr_full       (),                      // output
      .wr_water_level(),                      // output [11:0]
      .almost_full   (rd3_araddr_fifo_full),  // output
      .rd_clk        (clk),                   // input
      .rd_rst        (rst),                   // input
      .rd_en         (wr3_en),                // input
      .rd_data       (switch_data),           // output [3:0]
      .rd_empty      (),                      // output
      .almost_empty  ()                       // output
  );
  always @(posedge clk) begin
    rd3_data_en0 <= wr3_en;
    rd3_data_en1 <= rd3_data_en0;
    rd3_data_en2 <= rd3_data_en1;
    switch_data0 <= switch_data;
  end
  always @(posedge clk) begin
    s_axi_rdata0 <= s_axi_rdata;
    s_axi_rdata1 <= s_axi_rdata0;
    case (switch_data0)
      'd0: begin
        rd3_ddr_data <= s_axi_rdata1[0*16+:16];
      end
      'd1: begin
        rd3_ddr_data <= s_axi_rdata1[1*16+:16];
      end
      'd2: begin
        rd3_ddr_data <= s_axi_rdata1[2*16+:16];
      end
      'd3: begin
        rd3_ddr_data <= s_axi_rdata1[3*16+:16];
      end
      'd4: begin
        rd3_ddr_data <= s_axi_rdata1[4*16+:16];
      end
      'd5: begin
        rd3_ddr_data <= s_axi_rdata1[5*16+:16];
      end
      'd6: begin
        rd3_ddr_data <= s_axi_rdata1[6*16+:16];
      end
      'd7: begin
        rd3_ddr_data <= s_axi_rdata1[7*16+:16];
      end
      'd8: begin
        rd3_ddr_data <= s_axi_rdata1[8*16+:16];
      end
      'd9: begin
        rd3_ddr_data <= s_axi_rdata1[9*16+:16];
      end
      'd10: begin
        rd3_ddr_data <= s_axi_rdata1[10*16+:16];
      end
      'd11: begin
        rd3_ddr_data <= s_axi_rdata1[11*16+:16];
      end
      'd12: begin
        rd3_ddr_data <= s_axi_rdata1[12*16+:16];
      end
      'd13: begin
        rd3_ddr_data <= s_axi_rdata1[13*16+:16];
      end
      'd14: begin
        rd3_ddr_data <= s_axi_rdata1[14*16+:16];
      end
      'd15: begin
        rd3_ddr_data <= s_axi_rdata1[15*16+:16];
      end
      default: ;
    endcase
  end
  reg [4:0] delay_cnt;
  always @(posedge clk) begin
    if (rst) begin
      rd_ddr_idle <= 'd0;
    end else begin
      if (wr_sta == WR_IDLE) begin
        if (rd_sta == S0 || rd_sta == S2 || rd_sta == S4 || rd_sta == S6)
          delay_cnt <= delay_cnt + 1'b1;
        else delay_cnt <= 'd0;
      end else delay_cnt <= 'd0;
      if ((wr_sta == WR_IDLE) && (delay_cnt[4])) rd_ddr_idle <= 'd1;
      else rd_ddr_idle <= 'd0;
    end
  end

endmodule
