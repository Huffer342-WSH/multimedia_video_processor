module rd3_addr_ctr #(
    parameter START_ADDR   = 32'h0080_0000,
    parameter BLOCK_SIZE   = 32'h0008_0000,
    parameter IMAGE_BLOCK  = 32'h0007_0800,
    parameter WR_NUM       = 32'd128,
    parameter ADDR_WIDTH   = 30,
    parameter RD_NUM_WIDTH = 28,
    parameter IMAGE_W      = 1280,
    parameter IMAGE_H      = 720,
    parameter IMAGE_SIZE   = 12
)  // notice  this is 8bit addr
(
    input clk,
    input rst,
    input rd_vs,
    input [4:0] wr_image_cnt,
    input image_addr_valid,
    input [32-1:0] image_addr,
    output rd_ddr_valid,
    output [ADDR_WIDTH-1:0] rd_ddr_addr


);


  reg [ADDR_WIDTH-1:0] gen_start_addr0, gen_start_addr1, gen_start_addr2, gen_start_addr3;
  reg [4:0] wr_image_cnt1, rd_image_cnt;
  reg rd_vs0, rd_vs1, rd_vs2;
  reg rd_vs_rise0;
  wire [4:0] wr_image_cnt0;
  wire rd_vs_rise;

  assign rd_vs_rise = (~rd_vs1) & (rd_vs0);
  always @(posedge clk) begin
    rd_vs0      <= rd_vs;
    rd_vs1      <= rd_vs0;
    rd_vs_rise0 <= rd_vs_rise;
  end
  async_to_sync #(
      .WIDTH(5)
  ) wr0_async_to_wr1_sync (
      .clk(clk),

      .data_in (wr_image_cnt),
      .data_out(wr_image_cnt0)

  );
  always @(posedge clk) begin
    //wr_image_cnt1 <= (wr_image_cnt0==0)?31:wr_image_cnt0; 
    wr_image_cnt1 <= wr_image_cnt0;
    if (rd_vs_rise) begin
      rd_image_cnt <= wr_image_cnt1 - 1'b1;
    end
    if (rd_vs_rise0) begin
      gen_start_addr0 <= rd_image_cnt * BLOCK_SIZE * 4 + START_ADDR * 4;
      gen_start_addr1 <= rd_image_cnt * BLOCK_SIZE * 4 + START_ADDR * 4 + IMAGE_BLOCK * 4 / 2;
    end else begin
      gen_start_addr0 <= gen_start_addr0;
      gen_start_addr1 <= gen_start_addr1;
    end
  end

  reg [ADDR_WIDTH-1:0] now_image_addr0, now_image_addr1, now_image_addr2;
  reg [ADDR_WIDTH-1:0] now_ddr_addr, rd_ddr_addr0;
  reg [IMAGE_SIZE-1:0] image_w0, image_h0, act_w, act_h, act_w0, image_h1;
  always @(posedge clk) begin
    image_w0        <= image_addr[16+:IMAGE_SIZE];
    image_h0        <= image_addr[0+:IMAGE_SIZE];
    image_h1        <= image_h0;
    act_w           <= image_w0;
    act_w0          <= act_w;
    act_h           <= (image_h0 >= IMAGE_H / 2) ? (image_h0 - IMAGE_H / 2) : image_h0;
    gen_start_addr2 <= (image_h1 >= IMAGE_H / 2) ? gen_start_addr1 : gen_start_addr0;
    now_image_addr0 <= (image_h1 >= IMAGE_H / 2) ? (act_h * IMAGE_W) : act_h * IMAGE_W * 2;
    now_image_addr1 <= now_image_addr0 + act_w0 * 2;
    gen_start_addr3 <= gen_start_addr2;
    now_ddr_addr    <= now_image_addr1 + gen_start_addr3;
  end
  reg rd_ddr_valid0, rd_ddr_valid1, rd_ddr_valid2, rd_ddr_valid3, rd_ddr_valid4, rd_ddr_valid5;
  assign rd_ddr_valid = rd_ddr_valid5;
  assign rd_ddr_addr  = now_ddr_addr;
  always @(posedge clk) begin
    rd_ddr_addr0  <= now_ddr_addr;
    rd_ddr_valid0 <= image_addr_valid;
    rd_ddr_valid1 <= rd_ddr_valid0;
    rd_ddr_valid2 <= rd_ddr_valid1;
    rd_ddr_valid3 <= rd_ddr_valid2;
    rd_ddr_valid4 <= rd_ddr_valid3;
    rd_ddr_valid5 <= rd_ddr_valid4;
  end

endmodule
