module rd0_addr_ctr #(
    parameter START_ADDR   = 32'h0078_0000,
    parameter BLOCK_SIZE   = 32'h0000_0100,
    parameter IMAGE_BLOCK  = 32'h0000_0200,
    parameter WR_NUM       = 32'd512,
    parameter ADDR_WIDTH   = 30,
    parameter RD_NUM_WIDTH = 28,
    parameter IMAGE_SIZE   = 12
) (
    input clk,
    input rst,
    input [4:0] wr_image_cnt,
    input sift_done,
    input rd_ddr_done,
    output rd_ddr_valid,
    output [ADDR_WIDTH-1:0] rd_ddr_addr,
    output [RD_NUM_WIDTH-1:0] rd_ddr_num
);


  reg [4:0] wr_image_cnt0;
  reg image_perimt;
  always @(posedge clk) begin
    wr_image_cnt0 <= wr_image_cnt;
    image_perimt  <= (wr_image_cnt0 == 31) ? 1'b1 : 1'b0;
  end
  reg image_perimt0, image_perimt1;
  reg rd_ddr_done0, rd_ddr_done1, rd_ddr_done_rise;
  reg sift_done0, sift_done1;
  wire image_perimt_fall;

  assign image_perimt_fall = (~image_perimt1) & (image_perimt0);
  always @(posedge clk) begin
    image_perimt0 <= image_perimt ;
    image_perimt1 <= image_perimt0;
    rd_ddr_done0  <= rd_ddr_done ;
    rd_ddr_done1  <= rd_ddr_done0;
    rd_ddr_done_rise <= (~rd_ddr_done1)&(rd_ddr_done0);
    sift_done0    <= sift_done ;
    sift_done1    <= sift_done0 ;
  end


  reg [7:0] rd_done_cnt;
  reg [1:0] rd0_sta;
  localparam S0 = 'd0;
  localparam S1 = 'd1;
  localparam S2 = 'd2;
  localparam S3 = 'd3;
  always @(posedge clk) begin
    if (rst) begin
      rd0_sta <= S0;
    end else begin
      case (rd0_sta)
        S0: begin
          if (image_perimt_fall) rd0_sta <= S1;
          else rd0_sta <= S0;
        end
        S1: begin
          if ((rd_done_cnt == 255) && (rd_ddr_done_rise)) rd0_sta <= S2;
          else rd0_sta <= S1;
        end
        S2: begin
          if (sift_done1) rd0_sta <= S3;
          else rd0_sta <= S2;
        end
        S3: begin
          if ((rd_done_cnt == 255) && (rd_ddr_done_rise)) rd0_sta <= S0;
          else rd0_sta <= S3;
        end
        default: rd0_sta <= S0;
      endcase
    end
  end
  reg rd_ddr_valid0;
  reg [ADDR_WIDTH-1:0] rd_ddr_addr0;

  assign rd_ddr_valid = rd_ddr_valid0;
  assign rd_ddr_addr  = rd_ddr_addr0 * 4;
  assign rd_ddr_num   = WR_NUM;

  always @(posedge clk) begin
    if (rst) begin
    end else begin
      case (rd0_sta)
        S0: begin
          rd_done_cnt  <= 'd0;
          rd_ddr_addr0 <= START_ADDR;
          if (image_perimt_fall) rd_ddr_valid0 <= 'd1;
          else rd_ddr_valid0 <= 'd0;
        end
        S1: begin
          if (rd_ddr_done_rise) rd_done_cnt <= rd_done_cnt + 1'b1;
          else rd_done_cnt <= rd_done_cnt;
          if (rd_ddr_done_rise) begin
            rd_ddr_addr0  <= rd_ddr_addr0 + BLOCK_SIZE;
            rd_ddr_valid0 <= 'd1;
          end else begin
            rd_ddr_addr0  <= rd_ddr_addr0;
            rd_ddr_valid0 <= 'd0;
          end
        end
        S2: begin
          rd_done_cnt <= 'd0;
          if (sift_done1) begin
            rd_ddr_addr0  <= START_ADDR + BLOCK_SIZE / 2;
            rd_ddr_valid0 <= 'd1;
          end else begin
            rd_ddr_addr0  <= rd_ddr_addr0;
            rd_ddr_valid0 <= 'd0;
          end
        end
        S3: begin
          if (rd_ddr_done_rise) rd_done_cnt <= rd_done_cnt + 1'b1;
          else rd_done_cnt <= rd_done_cnt;
          if (rd_ddr_done_rise) begin
            rd_ddr_addr0  <= rd_ddr_addr0 + BLOCK_SIZE;
            rd_ddr_valid0 <= 'd1;
          end else begin
            rd_ddr_addr0  <= rd_ddr_addr0;
            rd_ddr_valid0 <= 'd0;
          end
        end
        default: ;
      endcase
    end
  end




endmodule
