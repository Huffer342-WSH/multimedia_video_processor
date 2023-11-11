module rd2_addr_ctr #(
    parameter START_ADDR   = 32'h0080_0000,
    parameter BLOCK_SIZE   = 32'h0008_0000,
    parameter IMAGE_BLOCK  = 32'h0007_0800,
    parameter WR_NUM       = 32'd7200,
    parameter ADDR_WIDTH   = 30,
    parameter RD_NUM_WIDTH = 28,
    parameter IMAGE_W      = 1280,
    parameter IMAGE_H      = 720,
    parameter IMAGE_SIZE   = 12
) (
    input clk,
    input rst,
    input rd_vs,
    input [4:0] wr0_image_cnt,
    input [2:0] wr2_image_cnt,
    input [2:0] wr3_image_cnt,
    input [1:0] rd_mode,
    input rd_ddr_done,
    output rd_ddr_valid,
    output [ADDR_WIDTH-1:0] rd_ddr_addr,
    output [RD_NUM_WIDTH-1:0] rd_ddr_num
);


  reg [ADDR_WIDTH-1:0] gen_start_addr0, gen_start_addr1, gen_start_addr2;
  reg rd_vs0, rd_vs1, rd_vs2;
  reg  rd_vs_rise0;
  wire rd_vs_rise;
  reg rd_ddr_done0, rd_ddr_done1, rd_ddr_done2;
  wire rd_ddr_done_rise;

  assign rd_vs_rise = (~rd_vs1) & (rd_vs0);
  assign rd_ddr_done_rise = (~rd_ddr_done2) & (rd_ddr_done1);
  always @(posedge clk) begin
    rd_vs0       <= rd_vs;
    rd_vs1       <= rd_vs0;
    rd_vs_rise0  <= rd_vs_rise;
    rd_ddr_done0 <= rd_ddr_done;
    rd_ddr_done1 <= rd_ddr_done0;
    rd_ddr_done2 <= rd_ddr_done1;
  end
  reg [4:0] wr0_image_cnt1, rd0_image_cnt;
  reg  [2:0] rd2_image_cnt;
  reg  [2:0] rd3_image_cnt;
  wire [4:0] wr0_image_cnt0;
  wire [2:0] wr2_image_cnt0;
  wire [2:0] wr3_image_cnt0;


  localparam START0_ADDR = 32'h0000_0000;
  localparam START1_ADDR = BLOCK_SIZE * 32;
  localparam START2_ADDR = BLOCK_SIZE * 48;


  async_to_sync #(
      .WIDTH(5)
  ) wr0_async_to_sync (
      .clk(clk),

      .data_in (wr0_image_cnt),
      .data_out(wr0_image_cnt0)

  );
  async_to_sync #(
      .WIDTH(3)
  ) wr2_async_to_sync (
      .clk(clk),

      .data_in (wr2_image_cnt),
      .data_out(wr2_image_cnt0)

  );
  async_to_sync #(
      .WIDTH(3)
  ) wr3_async_to_sync (
      .clk(clk),

      .data_in (wr3_image_cnt),
      .data_out(wr3_image_cnt0)

  );
  always @(posedge clk) begin
    wr0_image_cnt1 <= wr0_image_cnt0;
    if (rd_vs_rise) begin
      //rd0_image_cnt  <= (wr0_image_cnt1==0)?30:wr0_image_cnt1-1;
      rd0_image_cnt <= wr0_image_cnt1 - 1;
      rd2_image_cnt <= wr2_image_cnt0 - 1'b1;
      rd3_image_cnt <= wr3_image_cnt0 - 1'b1;
    end
    if (rd_vs_rise0) begin
      gen_start_addr0 <= rd0_image_cnt * BLOCK_SIZE + START0_ADDR;
      gen_start_addr1 <= rd2_image_cnt * BLOCK_SIZE + START1_ADDR;
      gen_start_addr2 <= rd3_image_cnt * BLOCK_SIZE + START2_ADDR;
    end else begin
      gen_start_addr0 <= gen_start_addr0;
      gen_start_addr1 <= gen_start_addr1;
      gen_start_addr2 <= gen_start_addr2;
    end
  end
  reg [1:0] rd_mode0;
  always @(posedge clk) begin
    rd_mode0 <= rd_mode;
  end

  localparam S0 = 4'b0001;
  localparam S1 = 4'b0010;
  localparam S2 = 4'b0100;
  localparam S3 = 4'b1000;
  reg [3:0] rd2_sta;
  reg [3:0] delay_cnt;
  always @(posedge clk) begin
    if (rst) begin
      rd2_sta <= S0;
    end else begin
      case (rd2_sta)
        S0: begin
          if (rd_vs_rise0) rd2_sta <= S1;
          else rd2_sta <= S0;
        end
        S1: begin
          rd2_sta <= S2;
        end
        S2: begin
          if (delay_cnt == 7) rd2_sta <= S3;
          else rd2_sta <= S2;
        end
        S3: begin
          if (rd_ddr_done_rise) rd2_sta <= S0;
          else rd2_sta <= S3;
        end
        default: rd2_sta <= S0;
      endcase
    end
  end
  reg rd_ddr_valid0;
  reg [ADDR_WIDTH-1:0] rd_ddr_addr0;
  reg [RD_NUM_WIDTH-1:0] rd_ddr_num0;
  assign rd_ddr_valid = rd_ddr_valid0;
  assign rd_ddr_addr  = rd_ddr_addr0 * 4;
  assign rd_ddr_num   = rd_ddr_num0;
  always @(posedge clk) begin
    if (rst) begin
    end else begin
      case (rd2_sta)
        S0: begin
          rd_ddr_valid0 <= 'd0;
          delay_cnt     <= 'd0;
          rd_ddr_num0   <= rd_ddr_num0;
          rd_ddr_addr0  <= rd_ddr_addr0;
        end
        S1: begin
          if (rd_mode0[1] == 1'b0)
            // rd_ddr_num0 <= WR_NUM ;
            rd_ddr_num0 <= WR_NUM * 3 / 4;
          else rd_ddr_num0 <= WR_NUM;
          if (rd_mode0 == 0) rd_ddr_addr0 <= gen_start_addr0;
          else if (rd_mode0 == 1) rd_ddr_addr0 <= gen_start_addr1;
          else rd_ddr_addr0 <= gen_start_addr2;
          // rd_ddr_addr0 <= gen_start_addr0 ;
        end
        S2: begin
          delay_cnt <= delay_cnt + 1'b1;
          if (delay_cnt >= 6) rd_ddr_valid0 <= 'd1;
          else rd_ddr_valid0 <= 'd0;
        end
        S3: begin
          rd_ddr_valid0 <= 'd0;
          rd_ddr_addr0  <= rd_ddr_addr0;
          rd_ddr_num0   <= rd_ddr_num0;
        end
        default: ;
      endcase
    end
  end


endmodule
