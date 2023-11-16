module ddr_addr_ctr #(
    parameter ADDR_WIDTH   = 30,
    parameter WR_NUM_WIDTH = 16,
    parameter RD_NUM_WIDTH = 16,
    parameter IMAGE_W      = 1280,
    parameter IMAGE_H      = 720,
    parameter IMAGE_SIZE   = 11
) (
    input clk,
    input rst,

    input wr0_clk,
    input wr0_rst,
    input wr0_vs,
    input wr0_ddr_done,
    output wr0_addr_valid,
    output [ADDR_WIDTH-1:0] wr0_ddr_addr,
    output [WR_NUM_WIDTH-1:0] wr0_ddr_num,

    input wr1_clk,
    input wr1_rst,
    input wr1_vs,
    input wr1_ddr_done,
    output wr1_addr_valid,
    output [ADDR_WIDTH-1:0] wr1_ddr_addr,
    output [WR_NUM_WIDTH-1:0] wr1_ddr_num,

    input wr2_clk,
    input wr2_rst,
    //input  wr2_vs,
    input wr2_ddr_done,
    output wr2_addr_valid,
    output [ADDR_WIDTH-1:0] wr2_ddr_addr,
    output [WR_NUM_WIDTH-1:0] wr2_ddr_num,
    output zoom_vs_out,

    input wr3_clk,
    input wr3_rst,
    input wr3_ddr_done,
    output wr3_addr_valid,
    output [ADDR_WIDTH-1:0] wr3_ddr_addr,
    output [WR_NUM_WIDTH-1:0] wr3_ddr_num,

    input rd0_clk,
    input rd0_rst,
    input rd0_ddr_done,
    output rd0_ddr_valid,
    output [ADDR_WIDTH-1:0] rd0_ddr_addr,
    output [WR_NUM_WIDTH-1:0] rd0_ddr_num,

    input sift_done,

    input rd1_clk,
    input rd1_rst,
    input rd1_ddr_done,
    output rd1_ddr_valid,
    output [ADDR_WIDTH-1:0] rd1_ddr_addr,
    output [WR_NUM_WIDTH-1:0] rd1_ddr_num,
    input signed [7:0] shift_h,
    input zoom_image_addr_valid,
    input [IMAGE_SIZE-1:0] zoom_image_addr,
    input [1:0] rd1_mode,
    input rd1_vs,

    input rd2_clk,
    input rd2_rst,
    input rd2_vs,
    input rd2_ddr_done,
    output rd2_ddr_valid,
    output [ADDR_WIDTH-1:0] rd2_ddr_addr,
    output [WR_NUM_WIDTH-1:0] rd2_ddr_num,
    input [1:0] hdmi_out_mode,

    input rd3_clk,
    input rd3_rst,
    input rotate_image_addr_valid,
    input [31:0] rotate_image_addr,
    output rd3_ddr_addr_valid,
    output [ADDR_WIDTH-1:0] rd3_ddr_addr,
    output rotate_vs_out,

    output reg vs_30hz,
    output reg vs_15hz,
    output reg vs_7hz,
    input init_calib_complete
);
  localparam CLK_FRE_NUM = 100_000_000;
  localparam CLK_CNT_NUM = CLK_FRE_NUM / 120;



  reg [31:0] clk_cnt;


  always @(posedge clk) begin
    if (rst | (~init_calib_complete)) clk_cnt <= 'd0;
    else begin
      if (clk_cnt == CLK_CNT_NUM - 1) clk_cnt <= 'd0;
      else clk_cnt <= clk_cnt + 1'b1;
    end
  end
  always @(posedge clk) begin
    if (clk_cnt == CLK_CNT_NUM - 1) vs_30hz <= 'd1;
    else vs_30hz <= 'd0;
  end

  reg vs_15hz0;
  always @(posedge clk) begin
    vs_15hz0 <= vs_15hz;
    if (rst) vs_15hz <= 'd0;
    else if (vs_30hz) vs_15hz <= ~vs_15hz;
  end

  always @(posedge clk) begin
    if (rst) vs_7hz <= 'd0;
    else if (vs_15hz & (~vs_15hz0)) vs_7hz <= ~vs_7hz;
  end
  reg rd1_vs0;
  always @(posedge rd1_clk) begin
    //rd1_vs0 <= (rd_mode==2)?rd1_vs:vs_7hz;
    rd1_vs0 <= rd1_vs;
  end


  wire [4:0] wr0_image_fram_cnt, wr1_image_fram_cnt;
  wire [2:0] wr2_image_fram_cnt, wr3_image_fram_cnt;
  wire rd_idle_sta;
  // OV5640 

  localparam WR_NUM = IMAGE_H * IMAGE_W * 16 / (256 * 8);
  localparam IMAGE_BLOCK = IMAGE_H * IMAGE_W / 2;
  localparam BLOCK_SIZE = (IMAGE_H == 1080) ? 32'h0010_0000 : 32'h0008_0000;
  wr0_addr_ctr #(
      .START_ADDR  (32'h0000_0000),
      .BLOCK_SIZE  (BLOCK_SIZE),
      .IMAGE_BLOCK (IMAGE_BLOCK),
      .WR_NUM      (WR_NUM / 2),
      .ADDR_WIDTH  (30),
      .WR_NUM_WIDTH(WR_NUM_WIDTH),
      .IMAGE_SIZE  (IMAGE_SIZE)
  ) u_wr0_addr_ctr (
      .clk(wr0_clk),
      .rst(wr0_rst),

      .wr_vs         (wr0_vs),
      .wr_ddr_done   (wr0_ddr_done),
      .wr_addr_valid (wr0_addr_valid),
      .wr_ddr_addr   (wr0_ddr_addr),
      .wr_ddr_num    (wr0_ddr_num),
      .image_fram_cnt(wr0_image_fram_cnt)  //output 

  );


  // 
  wr1_addr_ctr #(
      .START_ADDR  (BLOCK_SIZE / 2),
      .BLOCK_SIZE  (BLOCK_SIZE),
      .IMAGE_BLOCK (IMAGE_BLOCK),
      .WR_NUM      (WR_NUM / 4),
      .ADDR_WIDTH  (30),
      .WR_NUM_WIDTH(WR_NUM_WIDTH),
      .IMAGE_SIZE  (IMAGE_SIZE)
  ) u_wr1_addr_ctr (
      .clk(wr1_clk),
      .rst(wr1_rst),

      .image_fram_cnt    (wr0_image_fram_cnt),  // input 
      .wr_vs             (wr1_vs),
      .wr_ddr_done       (wr1_ddr_done),
      .wr_addr_valid     (wr1_addr_valid),
      .wr_ddr_addr       (wr1_ddr_addr),
      .wr_ddr_num        (wr1_ddr_num),
      .wr1_image_fram_cnt(wr1_image_fram_cnt)

  );

  //ZOOM 
  wr2_addr_ctr #(
      .START_ADDR  (BLOCK_SIZE * 32),
      .BLOCK_SIZE  (BLOCK_SIZE),
      .IMAGE_BLOCK (IMAGE_BLOCK),
      .WR_NUM      (WR_NUM / 4 * 3),
      .ADDR_WIDTH  (30),
      .WR_NUM_WIDTH(WR_NUM_WIDTH),
      .IMAGE_SIZE  (IMAGE_SIZE)
  ) u_wr2_addr_ctr (
      .clk(wr2_clk),
      .rst(wr2_rst),

      //. wr_vs         (vs_30hz        ),
      .wr_vs         (0),
      .wr_ddr_done   (wr2_ddr_done),
      .wr_addr_valid (wr2_addr_valid),
      .wr_ddr_addr   (wr2_ddr_addr),
      .wr_ddr_num    (wr2_ddr_num),
      .image_fram_cnt(wr2_image_fram_cnt),
      .wr_vs_out     (zoom_vs_out)

  );

  //ROTATE
  wr3_addr_ctr #(
      .START_ADDR  (BLOCK_SIZE * 48),
      .BLOCK_SIZE  (BLOCK_SIZE),
      .WR_NUM      (WR_NUM),
      .ADDR_WIDTH  (30),
      .WR_NUM_WIDTH(WR_NUM_WIDTH),
      .IMAGE_SIZE  (IMAGE_SIZE)
  ) u_wr3_addr_ctr (
      .clk(wr3_clk),
      .rst(wr3_rst),

      .wr_vs         (vs_15hz),
      //. wr_vs           (0        ),
      .wr_ddr_done   (wr3_ddr_done),
      .wr_addr_valid (wr3_addr_valid),
      .wr_ddr_addr   (wr3_ddr_addr),
      .wr_ddr_num    (wr3_ddr_num),
      .image_fram_cnt(wr3_image_fram_cnt),
      .wr_vs_out     (rotate_vs_out)
  );

  //SIFT 
  rd0_addr_ctr #(
      .START_ADDR  (32'h00f8_0000),
      .BLOCK_SIZE  (32'h0000_0100),
      .IMAGE_BLOCK (32'h0000_0200),
      .WR_NUM      (32'd512),
      .ADDR_WIDTH  (30),
      .RD_NUM_WIDTH(RD_NUM_WIDTH),
      .IMAGE_SIZE  (IMAGE_SIZE)
  ) u_rd0_addr_ctr (
      .clk         (rd0_clk),
      .rst         (rd0_rst),
      .wr_image_cnt(wr0_image_fram_cnt),
      .sift_done   (sift_done),
      .rd_ddr_done (rd0_ddr_done),
      .rd_ddr_valid(rd0_ddr_valid),
      .rd_ddr_addr (rd0_ddr_addr),
      .rd_ddr_num  (rd0_ddr_num)
  );

  // ZOOM 
  rd1_addr_ctr #(
      .START_ADDR  (32'h0000_0000),
      .BLOCK_SIZE  (BLOCK_SIZE),
      .IMAGE_BLOCK (IMAGE_BLOCK),
      .WR_NUM      (IMAGE_W * 16 / (256 * 8 * 2)),
      .ADDR_WIDTH  (30),
      .RD_NUM_WIDTH(RD_NUM_WIDTH),
      .IMAGE_W     (IMAGE_W),
      .IMAGE_H     (IMAGE_H),
      .IMAGE_SIZE  (IMAGE_SIZE)
  ) u_rd1_addr_ctr (
      .clk             (rd1_clk),
      .rst             (rd1_rst),
      .rd_vs           (rd1_vs0),                // notic  imag_addr_valid and rd_vs delay 
      .shift_h         (shift_h),
      .wr0_image_cnt   (wr0_image_fram_cnt),
      .wr3_image_cnt   (wr3_image_fram_cnt),
      .image_addr_valid(zoom_image_addr_valid),
      .image_addr      (zoom_image_addr),
      .rd_ddr_done     (rd1_ddr_done),
      .rd_ddr_valid    (rd1_ddr_valid),
      .rd_ddr_addr     (rd1_ddr_addr),
      .rd_ddr_num      (rd1_ddr_num),
      .rd_idle_sta     (),
      .rd_mode         (rd1_mode)
  );
  //hdmi 

  rd2_addr_ctr #(
      .START_ADDR  (BLOCK_SIZE * 32),
      .BLOCK_SIZE  (BLOCK_SIZE),
      .IMAGE_BLOCK (IMAGE_BLOCK),
      .WR_NUM      (WR_NUM),
      .ADDR_WIDTH  (30),
      .RD_NUM_WIDTH(RD_NUM_WIDTH),
      .IMAGE_W     (IMAGE_W),
      .IMAGE_H     (IMAGE_H),
      .IMAGE_SIZE  (IMAGE_SIZE)
  ) u_rd2_addr_ctr (
      .clk          (rd2_clk),
      .rst          (rd2_rst),
      .rd_vs        (rd2_vs),
      .wr0_image_cnt(wr0_image_fram_cnt),
      .wr2_image_cnt(wr2_image_fram_cnt),
      .wr3_image_cnt(wr3_image_fram_cnt),
      .rd_mode      (hdmi_out_mode),
      .rd_ddr_done  (rd2_ddr_done),
      .rd_ddr_valid (rd2_ddr_valid),
      .rd_ddr_addr  (rd2_ddr_addr),
      .rd_ddr_num   (rd2_ddr_num)
  );
  //ROTATE
  rd3_addr_ctr #(
      .START_ADDR  (32'h0000_0000),
      .BLOCK_SIZE  (BLOCK_SIZE),
      .IMAGE_BLOCK (IMAGE_BLOCK),
      .WR_NUM      (32'd1),
      .ADDR_WIDTH  (30),
      .RD_NUM_WIDTH(RD_NUM_WIDTH),
      .IMAGE_W     (IMAGE_W),
      .IMAGE_H     (IMAGE_H),
      .IMAGE_SIZE  (IMAGE_SIZE)
  )  // notice  this is 8bit addr
      u_rd3_addr_ctr (
      .clk             (rd3_clk),
      .rst             (rd3_rst),
      .rd_vs           (rotate_vs_out),
      .wr_image_cnt    (wr0_image_fram_cnt),
      .image_addr_valid(rotate_image_addr_valid),
      .image_addr      (rotate_image_addr),
      .rd_ddr_valid    (rd3_ddr_addr_valid),
      .rd_ddr_addr     (rd3_ddr_addr)
  );

endmodule
