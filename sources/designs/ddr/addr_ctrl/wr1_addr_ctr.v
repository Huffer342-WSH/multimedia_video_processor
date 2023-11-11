module wr1_addr_ctr #(
    parameter START_ADDR   = 32'h0004_0000,
    parameter BLOCK_SIZE   = 32'h0008_0000,
    parameter IMAGE_BLOCK  = 32'h0007_0800,
    parameter WR_NUM       = 32'd1800,
    parameter ADDR_WIDTH   = 30,
    parameter WR_NUM_WIDTH = 28,
    parameter IMAGE_SIZE   = 12
) (
    input clk,
    input rst,

    input [4:0] image_fram_cnt,  // input 
    input wr_vs,
    input wr_ddr_done,
    output wr_addr_valid,
    output [ADDR_WIDTH-1:0] wr_ddr_addr,
    output [WR_NUM_WIDTH-1:0] wr_ddr_num,
    output [4:0] wr1_image_fram_cnt

);


  reg [1:0] wr_sta;
  reg wr_vs_flag;

  reg wr_ddr_done0;
  reg wr_ddr_done1;
  reg wr_addr_valid0;

  reg wr_vs0, wr_vs1, wr_vs2;
  wire wr_vs_rise;
  assign wr_vs_rise = (~wr_vs2) & (wr_vs1);
  always @(posedge clk) begin
    wr_vs0 <= wr_vs;
    wr_vs1 <= wr_vs0;
    wr_vs2 <= wr_vs1;
  end
  reg  wr_ddr_done2;
  wire wr_ddr_done_rise = (wr_ddr_done1) & (~wr_ddr_done2);
  always @(posedge clk) begin
    wr_ddr_done0 <= wr_ddr_done;
    wr_ddr_done1 <= wr_ddr_done0;
    wr_ddr_done2 <= wr_ddr_done1;
  end
  reg [3:0] delay_cnt;
  always @(posedge clk) begin
    if (rst) begin
      wr_sta <= 'd0;
    end else begin
      case (wr_sta)
        'd0: begin
          if (wr_vs_rise | wr_vs_flag) wr_sta <= 'd1;
          else wr_sta <= 'd0;
        end
        'd1: begin
          if (delay_cnt > 7) wr_sta <= 'd2;
          else wr_sta <= 'd1;
        end
        'd2: begin
          if (wr_ddr_done_rise) wr_sta <= 'd0;
          else wr_sta <= 'd2;
        end
        default: wr_sta <= 'd0;
      endcase
    end
  end
  reg  [4:0] image_fram_cnt1;
  wire [4:0] image_fram_cnt0;
  async_to_sync #(
      .WIDTH(5)
  ) wr0_async_to_wr1_sync (
      .clk(clk),

      .data_in (image_fram_cnt),
      .data_out(image_fram_cnt0)

  );
  reg [4:0] wr1_image_fram_cnt0;
  assign wr1_image_fram_cnt = wr1_image_fram_cnt0;

  always @(posedge clk) begin
    if (rst) begin
      wr_vs_flag          <= 'd0;
      wr1_image_fram_cnt0 <= 'd0;
    end else begin
      case (wr_sta)
        'd0: begin
          wr_vs_flag          <= 'd0;
          delay_cnt           <= 'd0;
          //image_fram_cnt1 <= (image_fram_cnt0==30)?0:image_fram_cnt0+1 ;
          image_fram_cnt1     <= image_fram_cnt0 + 1;
          wr_addr_valid0      <= 'd0;
          wr1_image_fram_cnt0 <= wr1_image_fram_cnt0;
        end
        'd1: begin
          wr1_image_fram_cnt0 <= wr1_image_fram_cnt0;
          delay_cnt <= delay_cnt + 1'b1;
          if (delay_cnt >= 4) wr_addr_valid0 <= 'd1;
          else wr_addr_valid0 <= 'd0;
        end
        'd2: begin
          wr_addr_valid0 <= 'd0;
          if (wr_ddr_done_rise) wr1_image_fram_cnt0 <= wr1_image_fram_cnt0 + 1'b1;
          else wr1_image_fram_cnt0 <= wr1_image_fram_cnt0;
          if (wr_vs_rise) wr_vs_flag <= 'd1;
          else wr_vs_flag <= wr_vs_flag;
        end
        default: ;
      endcase
    end
  end

  reg [ADDR_WIDTH-1:0] wr_ddr_addr0;

  assign wr_ddr_num    = WR_NUM ;
  assign wr_ddr_addr   = wr_ddr_addr0*4;
  assign wr_addr_valid = wr_addr_valid0;

  always @(posedge clk) begin
    if (wr_sta == 0) begin
      wr_ddr_addr0 <= IMAGE_BLOCK / 2 + image_fram_cnt1 * BLOCK_SIZE;
      //wr_ddr_addr0 <= IMAGE_BLOCK/2 + wr1_image_fram_cnt0*BLOCK_SIZE ;
    end else begin
      wr_ddr_addr0 <= wr_ddr_addr0;
    end
  end



endmodule
