`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 2023/10/04 19:33:05
// Design Name: 
// Module Name: axi_wr_connect
// Project Name: 
// Target Devices: 
// Tool Versions: 
// Description: 
// 
// Dependencies: 
// 
// Revision:
// Revision 0.01 - File Created
// Additional Comments:
// 
//////////////////////////////////////////////////////////////////////////////////


module axi_wr_connect #(
    parameter WIDTH        = 16,
    parameter FIFO_MAX_NUM = 8,
    parameter ADDR_WIDTH   = 29,
    parameter WR_NUM_WIDTH = 16
) (
    input clk,
    input rst,

    input wr0_ddr_sart_addr_valid,
    input wr1_ddr_sart_addr_valid,
    input wr2_ddr_sart_addr_valid,
    input wr3_ddr_sart_addr_valid,
    input [ADDR_WIDTH-8-1:0] wr0_ddr_sart_addr,
    input [ADDR_WIDTH-8-1:0] wr1_ddr_sart_addr,
    input [ADDR_WIDTH-8-1:0] wr2_ddr_sart_addr,
    input [ADDR_WIDTH-8-1:0] wr3_ddr_sart_addr,
    input [WR_NUM_WIDTH-1:0] wr0_ddr_num,
    input [WR_NUM_WIDTH-1:0] wr1_ddr_num,
    input [WR_NUM_WIDTH-1:0] wr2_ddr_num,
    input [WR_NUM_WIDTH-1:0] wr3_ddr_num,

    output wr0_ddr_done,
    output wr1_ddr_done,
    output wr2_ddr_done,
    output wr3_ddr_done,

    input wr0_clk,
    input data_in0_valid,
    input [WIDTH-1:0] data_in0,
    output fifo0_full,

    input wr1_clk,
    input data_in1_valid,
    input [WIDTH-1:0] data_in1,
    output fifo1_full,

    input wr2_clk,
    input data_in2_valid,
    input [WIDTH-1:0] data_in2,
    output fifo2_full,

    input wr3_clk,
    input data_in3_valid,
    input [WIDTH-1:0] data_in3,
    output fifo3_full,

    input axi_fifo_full,
    output axi_addr_valid,
    output [ADDR_WIDTH-1:0] axi_addr,
    output axi_data_valid,
    output [63:0] axi_data_out

);
  localparam CNT_RD_NUM = 31;
  wire [9:0] rd0_data_count, rd1_data_count, rd2_data_count, rd3_data_count;
  wire rd0_en, fifo0_empty;
  wire [63:0] dout0, dout1, dout2, dout3;
  reg [63:0] axi_data_out0;

  //image_in_fifo image_in_fifo0 (
  //  .wr_clk(wr0_clk),                // input wire wr_clk
  //  .wr_rst(rst),                // input wire wr_rst
  //  .rd_clk(clk),                // input wire rd_clk
  //  .rd_rst(rst),                // input wire rd_rst
  //  .din(data_in0),                      // input wire [15 : 0] din
  //  .wr_en(data_in0_valid),                  // input wire wr_en
  //  .rd_en(rd0_en),                  // input wire rd_en
  //  .dout(dout0),                    // output wire [15 : 0] dout
  //  .full(),                    // output wire full
  //  .almost_full(fifo0_full),      // output wire almost_full
  //  .empty(fifo0_empty),                  // output wire empty
  //  .valid(fifo0_valid),                  // output wire valid
  //  .rd_data_count(rd0_data_count)  // output wire [9 : 0] rd_data_count
  //);

  image_in_fifo image_in_fifo0 (
      .wr_clk        (wr0_clk),         // input
      .wr_rst        (rst),             // input
      .wr_en         (data_in0_valid),  // input
      .wr_data       (data_in0),        // input [15:0]
      .wr_full       (),                // output
      .wr_water_level(),                // output [10:0]
      .almost_full   (fifo0_full),      // output
      .rd_clk        (clk),             // input
      .rd_rst        (rst),             // input
      .rd_en         (rd0_en),          // input
      .rd_data       (dout0),           // output [31:0]
      .rd_empty      (fifo0_empty),     // output
      .rd_water_level(rd0_data_count),  // output [9:0]
      .almost_empty  ()                 // output
  );



  wire rd1_en, fifo1_empty;

  //image_in_fifo image_in_fifo1 (
  //  .wr_clk(wr1_clk),                // input wire wr_clk
  //  .wr_rst(rst),                // input wire wr_rst
  //  .rd_clk(clk),                // input wire rd_clk
  //  .rd_rst(rst),                // input wire rd_rst
  //  .din(data_in1),                      // input wire [15 : 0] din
  //  .wr_en(data_in1_valid),                  // input wire wr_en
  //  .rd_en(rd1_en),                  // input wire rd_en
  //  .dout(dout1),                    // output wire [15 : 0] dout
  //  .full(),                    // output wire full
  //  .almost_full(fifo1_full),      // output wire almost_full
  //  .empty(fifo1_empty),                  // output wire empty
  //  .valid(fifo1_valid),                  // output wire valid
  //  .rd_data_count(rd1_data_count)  // output wire [9 : 0] rd_data_count
  //);
  image_in_fifo image_in_fifo1 (
      .wr_clk        (wr1_clk),         // input
      .wr_rst        (rst),             // input
      .wr_en         (data_in1_valid),  // input
      .wr_data       (data_in1),        // input [15:0]
      .wr_full       (),                // output
      .wr_water_level(),                // output [10:0]
      .almost_full   (fifo1_full),      // output
      .rd_clk        (clk),             // input
      .rd_rst        (rst),             // input
      .rd_en         (rd1_en),          // input
      .rd_data       (dout1),           // output [31:0]
      .rd_empty      (fifo1_empty),     // output
      .rd_water_level(rd1_data_count),  // output [9:0]
      .almost_empty  ()                 // output
  );

  wire rd2_en, fifo2_empty;

  //image_in_fifo image_in_fifo2 (
  //  .wr_clk(wr2_clk),                // input wire wr_clk
  //  .wr_rst(rst),                // input wire wr_rst
  //  .rd_clk(clk),                // input wire rd_clk
  //  .rd_rst(rst),                // input wire rd_rst
  //  .din(data_in2),                      // input wire [15 : 0] din
  //  .wr_en(data_in2_valid),                  // input wire wr_en
  //  .rd_en(rd2_en),                  // input wire rd_en
  //  .dout(dout2),                    // output wire [15 : 0] dout
  //  .full(),                    // output wire full
  //  .almost_full(fifo2_full),      // output wire almost_full
  //  .empty(fifo2_empty),                  // output wire empty
  //  .valid(fifo2_valid),                  // output wire valid
  //  .rd_data_count(rd2_data_count)  // output wire [9 : 0] rd_data_count
  //);
  image_in_fifo image_in_fifo2 (
      .wr_clk        (wr2_clk),         // input
      .wr_rst        (rst),             // input
      .wr_en         (data_in2_valid),  // input
      .wr_data       (data_in2),        // input [15:0]
      .wr_full       (),                // output
      .wr_water_level(),                // output [10:0]
      .almost_full   (fifo2_full),      // output
      .rd_clk        (clk),             // input
      .rd_rst        (rst),             // input
      .rd_en         (rd2_en),          // input
      .rd_data       (dout2),           // output [31:0]
      .rd_empty      (fifo2_empty),     // output
      .rd_water_level(rd2_data_count),  // output [9:0]
      .almost_empty  ()                 // output
  );

  wire rd3_en, fifo3_empty;

  //image_in_fifo image_in_fifo3 (
  //  .wr_clk(wr3_clk),                // input wire wr_clk
  //  .wr_rst(rst),                // input wire wr_rst
  //  .rd_clk(clk),                // input wire rd_clk
  //  .rd_rst(rst),                // input wire rd_rst
  //  .din(data_in3),                      // input wire [15 : 0] din
  //  .wr_en(data_in3_valid),                  // input wire wr_en
  //  .rd_en(rd3_en),                  // input wire rd_en
  //  .dout(dout3),                    // output wire [15 : 0] dout
  //  .full(),                    // output wire full
  //  .almost_full(fifo3_full),      // output wire almost_full
  //  .empty(fifo3_empty),                  // output wire empty
  //  .valid(fifo3_valid),                  // output wire valid
  //  .rd_data_count(rd3_data_count)  // output wire [9 : 0] rd_data_count
  //);
  image_in_fifo image_in_fifo3 (
      .wr_clk        (wr3_clk),         // input
      .wr_rst        (rst),             // input
      .wr_en         (data_in3_valid),  // input
      .wr_data       (data_in3),        // input [15:0]
      .wr_full       (),                // output
      .wr_water_level(),                // output [10:0]
      .almost_full   (fifo3_full),      // output
      .rd_clk        (clk),             // input
      .rd_rst        (rst),             // input
      .rd_en         (rd3_en),          // input
      .rd_data       (dout3),           // output [31:0]
      .rd_empty      (fifo3_empty),     // output
      .rd_water_level(rd3_data_count),  // output [9:0]
      .almost_empty  ()                 // output
  );
  reg fifo0_data_full, fifo1_data_full, fifo2_data_full, fifo3_data_full;
  reg fifo0_data_empty, fifo1_data_empty, fifo2_data_empty, fifo3_data_empty;


  always @(posedge clk) begin
    if (rst) begin
      fifo0_data_full  <= 'd0;
      fifo1_data_full  <= 'd0;
      fifo2_data_full  <= 'd0;
      fifo3_data_full  <= 'd0;
      fifo0_data_empty <= 'd0;
      fifo1_data_empty <= 'd0;
      fifo2_data_empty <= 'd0;
      fifo3_data_empty <= 'd0;
    end else begin
      fifo0_data_full  <= (rd0_data_count >= (FIFO_MAX_NUM * 8) / 2) ? 1'b1 : 1'b0;
      fifo1_data_full  <= (rd1_data_count >= (FIFO_MAX_NUM * 8) / 2) ? 1'b1 : 1'b0;
      fifo2_data_full  <= (rd2_data_count >= (FIFO_MAX_NUM * 8) / 2) ? 1'b1 : 1'b0;
      fifo3_data_full  <= (rd3_data_count >= (FIFO_MAX_NUM * 8) / 2) ? 1'b1 : 1'b0;
      fifo0_data_empty <= (rd0_data_count >= (64) / 2) ? 1'b1 : 1'b0;
      fifo1_data_empty <= (rd1_data_count >= (64) / 2) ? 1'b1 : 1'b0;
      fifo2_data_empty <= (rd2_data_count >= (64) / 2) ? 1'b1 : 1'b0;
      fifo3_data_empty <= (rd3_data_count >= (64) / 2) ? 1'b1 : 1'b0;
    end
  end


  localparam S0 = 8'b00000001;
  localparam S1 = 8'b00000010;
  localparam S2 = 8'b00000100;
  localparam S3 = 8'b00001000;
  localparam S4 = 8'b00010000;
  localparam S5 = 8'b00100000;
  localparam S6 = 8'b01000000;
  localparam S7 = 8'b10000000;

  reg [ADDR_WIDTH-8-1:0] wr0_ddr_sart_addr0, wr0_ddr_sart_addr1, wr0_ddr_sart_addr2;
  reg [ADDR_WIDTH-8-1:0] wr1_ddr_sart_addr0, wr1_ddr_sart_addr1, wr1_ddr_sart_addr2;
  reg [ADDR_WIDTH-8-1:0] wr2_ddr_sart_addr0, wr2_ddr_sart_addr1, wr2_ddr_sart_addr2;
  reg [ADDR_WIDTH-8-1:0] wr3_ddr_sart_addr0, wr3_ddr_sart_addr1, wr3_ddr_sart_addr2;
  reg [WR_NUM_WIDTH-1:0] wr0_ddr_num0, wr0_ddr_num1, wr0_ddr_num2;
  reg [WR_NUM_WIDTH-1:0] wr1_ddr_num0, wr1_ddr_num1, wr1_ddr_num2;
  reg [WR_NUM_WIDTH-1:0] wr2_ddr_num0, wr2_ddr_num1, wr2_ddr_num2;
  reg [WR_NUM_WIDTH-1:0] wr3_ddr_num0, wr3_ddr_num1, wr3_ddr_num2;
  reg wr0_ddr_done0;
  reg wr1_ddr_done0;
  reg wr2_ddr_done0;
  reg wr3_ddr_done0;
  reg wr0_ddr_sart_addr_valid0, wr0_ddr_sart_addr_valid1, wr0_ddr_sart_addr_valid2;
  reg wr1_ddr_sart_addr_valid0, wr1_ddr_sart_addr_valid1, wr1_ddr_sart_addr_valid2;
  reg wr2_ddr_sart_addr_valid0, wr2_ddr_sart_addr_valid1, wr2_ddr_sart_addr_valid2;
  reg wr3_ddr_sart_addr_valid0, wr3_ddr_sart_addr_valid1, wr3_ddr_sart_addr_valid2;

  wire ddr0_valid_fall, ddr1_valid_fall, ddr2_valid_fall, ddr3_valid_fall;

  reg ddr0_valid_fall0, ddr0_valid_fall2;
  reg ddr1_valid_fall0, ddr1_valid_fall2;
  reg ddr2_valid_fall0, ddr2_valid_fall2;
  reg ddr3_valid_fall0, ddr3_valid_fall2;



  reg [ADDR_WIDTH-8-1:0] axi_addr0;


  reg [WR_NUM_WIDTH-1:0] wr0_cnt_num;
  reg [WR_NUM_WIDTH-1:0] wr1_cnt_num;
  reg [WR_NUM_WIDTH-1:0] wr2_cnt_num;
  reg [WR_NUM_WIDTH-1:0] wr3_cnt_num;
  reg [6:0] cnt_times;
  reg [7:0] rd_sta;
  reg axi_data_valid0;
  reg axi_addr_valid0;
  reg rx0_addr_valid, rx1_addr_valid, rx2_addr_valid, rx3_addr_valid;
  reg rd_sta1[3:0];

  reg fifo0_all_empty, fifo1_all_empty, fifo2_all_empty, fifo3_all_empty;

  assign wr0_ddr_done = wr0_ddr_done0;
  assign wr1_ddr_done = wr1_ddr_done0;
  assign wr2_ddr_done = wr2_ddr_done0;
  assign wr3_ddr_done = wr3_ddr_done0;

  assign rd0_en = (rd_sta == S1) ? 1'b1 : 1'b0;
  assign rd1_en = (rd_sta == S3) ? 1'b1 : 1'b0;
  assign rd2_en = (rd_sta == S5) ? 1'b1 : 1'b0;
  assign rd3_en = (rd_sta == S7) ? 1'b1 : 1'b0;

  always @(posedge clk) begin
    if (rst) begin
      rd_sta <= S0;
    end else begin
      case (rd_sta)
        S0: begin
          if (~axi_fifo_full) begin
            if (rx0_addr_valid & (fifo0_data_full)) rd_sta <= S1;
            else rd_sta <= S2;
          end else rd_sta <= S0;
        end
        S1: begin
          if (cnt_times == CNT_RD_NUM) rd_sta <= S0;
          else rd_sta <= S1;
        end
        S2: begin
          if (~axi_fifo_full) begin
            if (rx1_addr_valid & fifo1_data_full) rd_sta <= S3;
            else rd_sta <= S4;
          end else rd_sta <= S2;
        end
        S3: begin
          if (cnt_times == CNT_RD_NUM) rd_sta <= S2;
          else rd_sta <= S3;
        end
        S4: begin
          if (~axi_fifo_full) begin
            if (rx2_addr_valid & fifo2_data_full) rd_sta <= S5;
            else rd_sta <= S6;
          end else rd_sta <= S4;
        end
        S5: begin
          if (cnt_times == CNT_RD_NUM) rd_sta <= S4;
          else rd_sta <= S5;
        end
        S6: begin
          if (~axi_fifo_full) begin
            if (rx3_addr_valid & fifo3_data_full) rd_sta <= S7;
            else rd_sta <= S0;
          end else rd_sta <= S6;
        end
        S7: begin
          if (cnt_times == CNT_RD_NUM) rd_sta <= S6;
          else rd_sta <= S7;
        end
        default: rd_sta <= S0;
      endcase
    end
  end

  assign axi_addr_valid = axi_addr_valid0;
  assign axi_addr       = {axi_addr0, 8'd0};
  assign axi_data_out   = axi_data_out0;
  assign axi_data_valid = axi_data_valid0;
  always @(posedge clk) begin
    if (rst) begin
    end else begin
      case (rd_sta)
        S0: begin
          if ((~axi_fifo_full) & rx0_addr_valid & (fifo0_data_full)) begin
            axi_addr0 <= wr0_ddr_sart_addr2 + wr0_cnt_num;
            axi_addr_valid0 <= 1'b1;
          end else begin
            axi_addr_valid0 <= 1'b0;
          end
        end
        S2: begin
          if ((~axi_fifo_full) & rx1_addr_valid & (fifo1_data_full)) begin
            axi_addr0 <= wr1_ddr_sart_addr2 + wr1_cnt_num;
            axi_addr_valid0 <= 1'b1;
          end else begin
            axi_addr_valid0 <= 1'b0;
          end
        end
        S4: begin
          if ((~axi_fifo_full) & rx2_addr_valid & (fifo2_data_full)) begin
            axi_addr0 <= wr2_ddr_sart_addr2 + wr2_cnt_num;
            axi_addr_valid0 <= 1'b1;
          end else begin
            axi_addr_valid0 <= 1'b0;
          end
        end
        S6: begin
          if ((~axi_fifo_full) & rx3_addr_valid & (fifo3_data_full)) begin
            axi_addr0 <= wr3_ddr_sart_addr2 + wr3_cnt_num;
            axi_addr_valid0 <= 1'b1;
          end else begin
            axi_addr_valid0 <= 1'b0;
          end
        end
        default: begin
          axi_addr_valid0 <= 1'b0;
          axi_addr0       <= axi_addr0;
        end
      endcase
    end
  end
  always @(posedge clk) begin
    fifo0_all_empty <= fifo1_data_empty | fifo2_data_empty | fifo3_data_empty;
    fifo1_all_empty <= fifo0_data_empty | fifo2_data_empty | fifo3_data_empty;
    fifo2_all_empty <= fifo1_data_empty | fifo0_data_empty | fifo3_data_empty;
    fifo3_all_empty <= fifo1_data_empty | fifo2_data_empty | fifo0_data_empty;
  end
  always @(posedge clk) begin
    if (rd_sta == S1) rd_sta1[0] <= 1'b1;
    else rd_sta1[0] <= 'd0;
    if (rd_sta == S3) rd_sta1[1] <= 1'b1;
    else rd_sta1[1] <= 'd0;
    if (rd_sta == S5) rd_sta1[2] <= 1'b1;
    else rd_sta1[2] <= 'd0;
    if (rd_sta == S7) rd_sta1[3] <= 1'b1;
    else rd_sta1[3] <= 'd0;
  end
  reg [7:0] rd_sta0;
  always @(posedge clk) begin
    rd_sta0 <= rd_sta;
  end
  always @(posedge clk) begin
    case (rd_sta0)
      S1: begin
        axi_data_out0   <= dout0;
        axi_data_valid0 <= 1'b1;
      end
      S3: begin
        axi_data_out0   <= dout1;
        axi_data_valid0 <= 1'b1;
      end
      S5: begin
        axi_data_out0   <= dout2;
        axi_data_valid0 <= 1'b1;
      end
      S7: begin
        axi_data_out0   <= dout3;
        axi_data_valid0 <= 1'b1;
      end
      default: begin
        axi_data_out0   <= axi_data_out0;
        axi_data_valid0 <= 1'b0;
      end
    endcase
  end
  always @(posedge clk) begin
    if (rst) wr0_cnt_num <= 'd0;
    else begin
      if ((rd_sta == S0) && (~axi_fifo_full) & (fifo0_data_full & rx0_addr_valid))
        wr0_cnt_num <= wr0_cnt_num + 1'b1;
      else if (wr0_cnt_num == wr0_ddr_num2) wr0_cnt_num <= 'd0;
      else wr0_cnt_num <= wr0_cnt_num;
    end
    if (rst) wr1_cnt_num <= 'd0;
    else begin
      if ((rd_sta == S2) && (~axi_fifo_full) & (fifo1_data_full & rx1_addr_valid))
        wr1_cnt_num <= wr1_cnt_num + 1'b1;
      else if (wr1_cnt_num == wr1_ddr_num2) wr1_cnt_num <= 'd0;
      else wr1_cnt_num <= wr1_cnt_num;
    end
    if (rst) wr2_cnt_num <= 'd0;
    else begin
      if ((rd_sta == S4) && (~axi_fifo_full) & (fifo2_data_full & rx2_addr_valid))
        wr2_cnt_num <= wr2_cnt_num + 1'b1;
      else if (wr2_cnt_num == wr2_ddr_num2) wr2_cnt_num <= 'd0;
      else wr2_cnt_num <= wr2_cnt_num;
    end
    if (rst) wr3_cnt_num <= 'd0;
    else begin
      if ((rd_sta == S6) && (~axi_fifo_full) & (fifo3_data_full & rx3_addr_valid))
        wr3_cnt_num <= wr3_cnt_num + 1'b1;
      else if (wr3_cnt_num == wr3_ddr_num2) wr3_cnt_num <= 'd0;
      else wr3_cnt_num <= wr3_cnt_num;
    end
  end
  reg [2:0] delay_cnt0, delay_cnt1, delay_cnt2, delay_cnt3;
  always @(posedge clk) begin
    if (rst) delay_cnt0 <= 'd0;
    else if ((wr0_cnt_num == wr0_ddr_num2) && (rx0_addr_valid)) delay_cnt0 <= 3'd7;
    else if (delay_cnt0 != 0) delay_cnt0 <= delay_cnt0 - 1'b1;
    if (rst) delay_cnt1 <= 'd0;
    else if ((wr1_cnt_num == wr1_ddr_num2) && (rx1_addr_valid)) delay_cnt1 <= 3'd7;
    else if (delay_cnt1 != 0) delay_cnt1 <= delay_cnt1 - 1'b1;
    if (rst) delay_cnt2 <= 'd0;
    else if ((wr2_cnt_num == wr2_ddr_num2) && (rx2_addr_valid)) delay_cnt2 <= 3'd7;
    else if (delay_cnt2 != 0) delay_cnt2 <= delay_cnt2 - 1'b1;
    if (rst) delay_cnt3 <= 'd0;
    else if ((wr3_cnt_num == wr3_ddr_num2) && (rx3_addr_valid)) delay_cnt3 <= 3'd7;
    else if (delay_cnt3 != 0) delay_cnt3 <= delay_cnt3 - 1'b1;
    wr0_ddr_done0 <= (delay_cnt0 > 0) ? 1'b1 : 1'b0;
    wr1_ddr_done0 <= (delay_cnt1 > 0) ? 1'b1 : 1'b0;
    wr2_ddr_done0 <= (delay_cnt2 > 0) ? 1'b1 : 1'b0;
    wr3_ddr_done0 <= (delay_cnt3 > 0) ? 1'b1 : 1'b0;
  end

  //assign ddr0_valid_fall = (wr0_ddr_sart_addr_valid1)&(~wr0_ddr_sart_addr_valid2);
  //assign ddr1_valid_fall = (wr1_ddr_sart_addr_valid1)&(~wr1_ddr_sart_addr_valid2);
  //assign ddr2_valid_fall = (wr2_ddr_sart_addr_valid1)&(~wr2_ddr_sart_addr_valid2);
  //assign ddr3_valid_fall = (wr3_ddr_sart_addr_valid1)&(~wr3_ddr_sart_addr_valid2);

  assign ddr0_valid_fall = (~wr0_ddr_sart_addr_valid1) & (wr0_ddr_sart_addr_valid2);
  assign ddr1_valid_fall = (~wr1_ddr_sart_addr_valid1) & (wr1_ddr_sart_addr_valid2);
  assign ddr2_valid_fall = (~wr2_ddr_sart_addr_valid1) & (wr2_ddr_sart_addr_valid2);
  assign ddr3_valid_fall = (~wr3_ddr_sart_addr_valid1) & (wr3_ddr_sart_addr_valid2);
  always @(posedge clk) begin
    wr0_ddr_sart_addr_valid0 <= wr0_ddr_sart_addr_valid;
    wr1_ddr_sart_addr_valid0 <= wr1_ddr_sart_addr_valid;
    wr2_ddr_sart_addr_valid0 <= wr2_ddr_sart_addr_valid;
    wr3_ddr_sart_addr_valid0 <= wr3_ddr_sart_addr_valid;
    wr0_ddr_sart_addr_valid1 <= wr0_ddr_sart_addr_valid0;
    wr1_ddr_sart_addr_valid1 <= wr1_ddr_sart_addr_valid0;
    wr2_ddr_sart_addr_valid1 <= wr2_ddr_sart_addr_valid0;
    wr3_ddr_sart_addr_valid1 <= wr3_ddr_sart_addr_valid0;
    wr0_ddr_sart_addr_valid2 <= wr0_ddr_sart_addr_valid1;
    wr1_ddr_sart_addr_valid2 <= wr1_ddr_sart_addr_valid1;
    wr2_ddr_sart_addr_valid2 <= wr2_ddr_sart_addr_valid1;
    wr3_ddr_sart_addr_valid2 <= wr3_ddr_sart_addr_valid1;
    ddr0_valid_fall0         <= ddr0_valid_fall;
    ddr1_valid_fall0         <= ddr1_valid_fall;
    ddr2_valid_fall0         <= ddr2_valid_fall;
    ddr3_valid_fall0         <= ddr3_valid_fall;
    ddr0_valid_fall2         <= ddr0_valid_fall0;
    ddr1_valid_fall2         <= ddr1_valid_fall0;
    ddr2_valid_fall2         <= ddr2_valid_fall0;
    ddr3_valid_fall2         <= ddr3_valid_fall0;
  end
  always @(posedge clk) begin
    wr0_ddr_sart_addr0 <= wr0_ddr_sart_addr;
    wr1_ddr_sart_addr0 <= wr1_ddr_sart_addr;
    wr2_ddr_sart_addr0 <= wr2_ddr_sart_addr;
    wr3_ddr_sart_addr0 <= wr3_ddr_sart_addr;
    wr0_ddr_sart_addr1 <= wr0_ddr_sart_addr0;
    wr1_ddr_sart_addr1 <= wr1_ddr_sart_addr0;
    wr2_ddr_sart_addr1 <= wr2_ddr_sart_addr0;
    wr3_ddr_sart_addr1 <= wr3_ddr_sart_addr0;
    wr0_ddr_num0       <= wr0_ddr_num;
    wr1_ddr_num0       <= wr1_ddr_num;
    wr2_ddr_num0       <= wr2_ddr_num;
    wr3_ddr_num0       <= wr3_ddr_num;
    wr0_ddr_num1       <= wr0_ddr_num0;
    wr1_ddr_num1       <= wr1_ddr_num0;
    wr2_ddr_num1       <= wr2_ddr_num0;
    wr3_ddr_num1       <= wr3_ddr_num0;
  end
  always @(posedge clk) begin
    if (ddr0_valid_fall0) begin
      wr0_ddr_num2       <= wr0_ddr_num1;
      wr0_ddr_sart_addr2 <= wr0_ddr_sart_addr1;
    end else begin
      wr0_ddr_num2       <= wr0_ddr_num2;
      wr0_ddr_sart_addr2 <= wr0_ddr_sart_addr2;
    end
    if (ddr1_valid_fall0) begin
      wr1_ddr_num2       <= wr1_ddr_num1;
      wr1_ddr_sart_addr2 <= wr1_ddr_sart_addr1;
    end else begin
      wr1_ddr_num2       <= wr1_ddr_num2;
      wr1_ddr_sart_addr2 <= wr1_ddr_sart_addr2;
    end
    if (ddr2_valid_fall0) begin
      wr2_ddr_num2       <= wr2_ddr_num1;
      wr2_ddr_sart_addr2 <= wr2_ddr_sart_addr1;
    end else begin
      wr2_ddr_num2       <= wr2_ddr_num2;
      wr2_ddr_sart_addr2 <= wr2_ddr_sart_addr2;
    end
    if (ddr3_valid_fall0) begin
      wr3_ddr_num2       <= wr3_ddr_num1;
      wr3_ddr_sart_addr2 <= wr3_ddr_sart_addr1;
    end else begin
      wr3_ddr_num2       <= wr3_ddr_num2;
      wr3_ddr_sart_addr2 <= wr3_ddr_sart_addr2;
    end
  end
  reg wr0_ddr_done1;
  reg wr1_ddr_done1;
  reg wr2_ddr_done1;
  reg wr3_ddr_done1;
  always @(posedge clk) begin
    if (rst) begin
      rx0_addr_valid <= 'd0;
    end else begin
      if (ddr0_valid_fall2) rx0_addr_valid <= 'd1;
      else if (wr0_ddr_done1) rx0_addr_valid <= 'd0;
      else rx0_addr_valid <= rx0_addr_valid;
    end
    if (rst) begin
      rx1_addr_valid <= 'd0;
    end else begin
      if (ddr1_valid_fall2) rx1_addr_valid <= 'd1;
      else if (wr1_ddr_done1) rx1_addr_valid <= 'd0;
      else rx1_addr_valid <= rx1_addr_valid;
    end
    if (rst) begin
      rx2_addr_valid <= 'd0;
    end else begin
      if (ddr2_valid_fall2) rx2_addr_valid <= 'd1;
      else if (wr2_ddr_done1) rx2_addr_valid <= 'd0;
      else rx2_addr_valid <= rx2_addr_valid;
    end
    if (rst) begin
      rx3_addr_valid <= 'd0;
    end else begin
      if (ddr3_valid_fall2) rx3_addr_valid <= 'd1;
      else if (wr3_ddr_done1) rx3_addr_valid <= 'd0;
      else rx3_addr_valid <= rx3_addr_valid;
    end
  end

  always @(posedge clk) begin
    wr0_ddr_done1 <= ((wr0_cnt_num == wr0_ddr_num2) && rx0_addr_valid) ? 1'b1 : 1'b0;
    wr1_ddr_done1 <= ((wr1_cnt_num == wr1_ddr_num2) && rx1_addr_valid) ? 1'b1 : 1'b0;
    wr2_ddr_done1 <= ((wr2_cnt_num == wr2_ddr_num2) && rx2_addr_valid) ? 1'b1 : 1'b0;
    wr3_ddr_done1 <= ((wr3_cnt_num == wr3_ddr_num2) && rx3_addr_valid) ? 1'b1 : 1'b0;
    //wr1_ddr_done1 <= (wr1_cnt_num == wr1_ddr_num2)?1'b1:1'b0;
    //wr2_ddr_done1 <= (wr2_cnt_num == wr2_ddr_num2)?1'b1:1'b0;
    //wr3_ddr_done1 <= (wr3_cnt_num == wr3_ddr_num2)?1'b1:1'b0;
  end

  always @(posedge clk) begin
    if ((rd_sta == S1) || (rd_sta == S3) || (rd_sta == S5) || (rd_sta == S7))
      cnt_times <= cnt_times + 1'b1;
    else cnt_times <= 'd0;
  end


endmodule
