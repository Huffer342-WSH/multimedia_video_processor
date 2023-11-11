`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 2023/10/13 23:03:50
// Design Name: 
// Module Name: mix_image
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


module mix_image #(
    parameter   IMAGE_SIZE = 12,
    parameter   IMAGE_W    = 1280,
    parameter   IMAGE_H    = 720
) (
    input              clk,
    input              rst,
    input        [7:0] shift_w,
    input signed [7:0] shift_h,

    input        cmos1_vsync,  //cmos1 vsync
    input        cmos1_href,   //cmos1 hsync refrence,data valid
    input        cmos1_pclk,   //cmos1 pxiel clock
    input [15:0] cmos1_data,   //cmos1 data

    input        cmos2_vsync,  //cmos2 vsync
    input        cmos2_href,   //cmos2 hsync refrence,data valid
    input        cmos2_pclk,   //cmos2 pxiel clock
    input [15:0] cmos2_data,   //cmos2 data

    output reg        data_vs,
    output            data_out_valid,
    output     [15:0] data_out
);

  localparam SIFT_NUM = 310;
  localparam WAIT = 5'b00001, CMOS1 = 5'b00010, CMOS2 = 5'b00100, ZERO = 5'b01000, JUDGE = 5'b10000;
  reg [4:0] rd_sta, rd_sta0;

  reg  cmos1_vsync0;
  reg  cmos1_vsync1;
  wire cmos1_vsync_rise;
  assign cmos1_vsync_rise = (~cmos1_vsync1) & (cmos1_vsync0);
  always @(posedge cmos1_pclk) begin
    cmos1_vsync0 <= cmos1_vsync;
    cmos1_vsync1 <= cmos1_vsync0;

  end
  reg image1_en;

  always @(posedge cmos1_pclk or posedge rst) begin
    if (rst) image1_en <= 'd0;
    else begin
      if ((~cmos1_vsync1) & cmos1_vsync0) image1_en <= 'd1;
      else image1_en <= image1_en;
    end
  end

  reg [IMAGE_SIZE-1:0] cnt0_w, cnt0_h;

  always @(posedge cmos1_pclk) begin
    if (cmos1_vsync_rise) cnt0_w <= 'd0;
    else begin
      if (cmos1_href) begin
        if (cnt0_w == IMAGE_W - 1) cnt0_w <= 'd0;
        else cnt0_w <= cnt0_w + 1'b1;
      end else begin
        cnt0_w <= cnt0_w;
      end
    end
  end

  always @(posedge cmos1_pclk) begin
    if (cmos1_vsync_rise) cnt0_h <= 'd0;
    else begin
      if (cmos1_href && (cnt0_w == IMAGE_W - 1)) cnt0_h <= cnt0_h + 1'b1;
      else cnt0_h <= cnt0_h;
    end
  end
  reg [IMAGE_SIZE-1:0] cnt1_w, cnt1_h;
  reg  cmos2_vsync0;
  reg  cmos2_vsync1;
  wire cmos2_vsync_rise;
  reg  image2_en;

  assign cmos2_vsync_rise = (~cmos2_vsync1) & (cmos2_vsync0);
  always @(posedge cmos2_pclk or posedge rst) begin
    if (rst) image2_en <= 'd0;
    else begin
      if ((~cmos2_vsync1) & cmos2_vsync0) image2_en <= 'd1;
      else image2_en <= image2_en;
    end
  end
  always @(posedge cmos2_pclk) begin
    cmos2_vsync0 <= cmos2_vsync;
    cmos2_vsync1 <= cmos2_vsync0;
  end
  always @(posedge cmos2_pclk) begin
    if (cmos2_vsync_rise) cnt1_w <= 'd0;
    else begin
      if (cmos2_href) begin
        if (cnt1_w == IMAGE_W - 1) cnt1_w <= 'd0;
        else cnt1_w <= cnt1_w + 1'b1;
      end else begin
        cnt1_w <= cnt1_w;
      end
    end
  end
  always @(posedge cmos2_pclk) begin
    if (cmos2_vsync_rise) cnt1_h <= 'd0;
    else begin
      if (cmos2_href && (cnt1_w == IMAGE_W - 1)) cnt1_h <= cnt1_h + 1'b1;
      else cnt1_h <= cnt1_h;
    end
  end




  wire wr1_en, empty1, rd1_en;
  wire wr2_en, empty2, rd2_en;
  wire [15:0] dout1, dout2;
  assign wr1_en = (~cnt0_h[0]) & (~cnt0_w[0]) & (cmos1_href) & image1_en;
  assign rd1_en = ((~empty1) & (rd_sta == CMOS1)) ? 1'b1 : 1'b0;
  //mix_fifo u_mix_fifo1 (
  //  .rst(rst),        // input wire rst
  //  .wr_clk(cmos1_pclk),  // input wire wr_clk
  //  .rd_clk(clk),  // input wire rd_clk
  //  .din(cmos1_data),        // input wire [15 : 0] din
  //  .wr_en(wr1_en),    // input wire wr_en
  //  .rd_en(rd1_en),    // input wire rd_en
  //  .dout(dout1),      // output wire [15 : 0] dout
  //  .full(),      // output wire full
  //  .empty(empty1),    // output wire empty
  //  .valid()    // output wire valid
  //);
  mix_fifo u_mix_fifo1 (
      .wr_clk      (cmos1_pclk),  // input
      .wr_rst      (rst),         // input
      .wr_en       (wr1_en),      // input
      .wr_data     (cmos1_data),  // input [15:0]
      .wr_full     (),            // output
      .almost_full (),            // output
      .rd_clk      (clk),         // input
      .rd_rst      (rst),         // input
      .rd_en       (rd1_en),      // input
      .rd_data     (dout1),       // output [15:0]
      .rd_empty    (empty1),      // output
      .almost_empty()             // output
  );
  //mix_fifo u_mix_fifo1 (
  //  .wr_clk(cmos2_pclk),                // input
  //  .wr_rst(rst),                // input
  //  .wr_en(wr2_en),                  // input
  //  .wr_data(cmos2_data),              // input [15:0]
  //  .wr_full(),              // output
  //  .almost_full(),      // output
  //  .rd_clk(clk),                // input
  //  .rd_rst(rst),                // input
  //  .rd_en(rd1_en),                  // input
  //  .rd_data(dout1),              // output [15:0]
  //  .rd_empty(empty1),            // output
  //  .almost_empty()     // output
  //);
  assign wr2_en = (~cnt1_h[0]) & (~cnt1_w[0]) & (cmos2_href) & image2_en;
  assign rd2_en = ((~empty2) & (rd_sta == CMOS2)) ? 1'b1 : 1'b0;
  //mix_fifo u_mix_fifo2 (
  //  .rst(rst),        // input wire rst
  //  .wr_clk(cmos2_pclk),  // input wire wr_clk
  //  .rd_clk(clk),  // input wire rd_clk
  //  .din(cmos2_data),        // input wire [15 : 0] din
  //  .wr_en(wr2_en),    // input wire wr_en
  //  .rd_en(rd2_en),    // input wire rd_en
  //  .dout(dout2),      // output wire [15 : 0] dout
  //  .full(),      // output wire full
  //  .empty(empty2),    // output wire empty
  //  .valid()    // output wire valid
  //);
  mix_fifo u_mix_fifo2 (
      .wr_clk      (cmos2_pclk),  // input
      .wr_rst      (rst),         // input
      .wr_en       (wr2_en),      // input
      .wr_data     (cmos2_data),  // input [15:0]
      .wr_full     (),            // output
      .almost_full (),            // output
      .rd_clk      (clk),         // input
      .rd_rst      (rst),         // input
      .rd_en       (rd2_en),      // input
      .rd_data     (dout2),       // output [15:0]
      .rd_empty    (empty2),      // output
      .almost_empty()             // output
  );
  //mix_fifo u_mix_fifo2 (
  //  .wr_clk(cmos1_pclk),                // input
  //  .wr_rst(rst),                // input
  //  .wr_en(wr1_en),                  // input
  //  .wr_data(cmos1_data),              // input [15:0]
  //  .wr_full(),              // output
  //  .almost_full(),      // output
  //  .rd_clk(clk),                // input
  //  .rd_rst(rst),                // input
  //  .rd_en(rd2_en),                  // input
  //  .rd_data(dout2),              // output [15:0]
  //  .rd_empty(empty2),            // output
  //  .almost_empty()     // output
  //);
  reg rd_vs0;
  reg rd_vs1;
  reg rd_vs2;
  reg rd_vs_rise;

  always @(posedge clk) begin
    rd_vs0 <= cmos1_vsync;
    rd_vs1 <= rd_vs0;
    rd_vs2 <= rd_vs1;
    rd_vs_rise <= (~rd_vs2) & (rd_vs1);
  end

  reg [IMAGE_SIZE-1:0] rd_w, rd_h;
  reg signed [IMAGE_SIZE-1:0] rd_w0, rd_h0;


  reg        [7:0] shift_w0;
  reg signed [7:0] shift_h0;
  always @(posedge clk) begin
    if (rst) begin
      rd_sta <= WAIT;
    end else begin
      case (rd_sta)
        WAIT: begin
          if (~empty1) rd_sta <= CMOS1;
          else rd_sta <= WAIT;
        end
        CMOS1: begin
          if ((~empty1) && (rd_w == IMAGE_W / 2 - 1)) rd_sta <= CMOS2;
          else rd_sta <= CMOS1;
        end
        CMOS2: begin
          if ((~empty2) && (rd_w == IMAGE_W / 2 - 1)) rd_sta <= ZERO;
          else rd_sta <= CMOS2;
        end
        ZERO: begin
          if (rd_w == shift_w0) rd_sta <= JUDGE;
          else rd_sta <= ZERO;
        end
        JUDGE: begin
          if (rd_h == IMAGE_H / 2 - 1) rd_sta <= WAIT;
          else rd_sta <= CMOS1;
        end
        default: rd_sta <= WAIT;
      endcase
    end
  end
  always @(posedge clk) begin
    if (rst) begin
    end else begin
      case (rd_sta)
        WAIT: begin
          rd_w <= 'd0;
        end
        CMOS1: begin
          if (~empty1) begin
            if (rd_w == IMAGE_W / 2 - 1) rd_w <= 'd0;
            else rd_w <= rd_w + 1'b1;
          end else rd_w <= rd_w;
        end
        CMOS2: begin
          if (~empty2) begin
            if (rd_w == IMAGE_W / 2 - 1) rd_w <= 'd0;
            else rd_w <= rd_w + 1'b1;
          end else rd_w <= rd_w;
        end
        ZERO: begin
          rd_w <= rd_w + 1'b1;
        end
        JUDGE: begin
          rd_w <= 'd0;
        end
        default: ;
      endcase
    end
  end
  always @(posedge clk) begin
    if (rd_sta == WAIT) rd_h <= 'd0;
    else if (rd_sta == JUDGE) rd_h <= rd_h + 1'b1;
    else rd_h <= rd_h;
  end
  wire signed [IMAGE_SIZE-1:0] shift_h1, rd_h1;
  assign rd_h1 = rd_h;
  assign shift_h1 = shift_h0;
  always @(posedge clk) begin
    if (rd_sta == CMOS1) rd_h0 <= rd_h1 + shift_h1;
    else rd_h0 <= rd_h0;
  end
  always @(posedge clk) begin
    if (rd_sta == WAIT) begin
      shift_w0 <= shift_w;
      shift_h0 <= shift_h;
    end else begin
      shift_w0 <= shift_w0;
      shift_h0 <= shift_h0;
    end
  end

  reg [4:0] image_addr_cnt;
  always @(posedge clk) begin
    if (rst) image_addr_cnt <= 'd0;
    else begin
      if ((rd_sta == JUDGE) && (rd_h == IMAGE_H / 2 - 1)) image_addr_cnt <= image_addr_cnt + 1'b1;
      else image_addr_cnt <= image_addr_cnt;
    end
  end

  reg data_out_valid0, data_out_valid1;
  reg [15:0] data_out1;

  always @(posedge clk) begin
    if (rst) begin
    end else begin
      case (rd_sta)
        WAIT: begin
          data_out_valid0 <= 'd0;
        end
        CMOS1: begin
          if (((image_addr_cnt == SIFT_NUM) && (rd_h < 256) && (rd_w >= (IMAGE_W / 2 - 256)) ||
               (image_addr_cnt != SIFT_NUM)) && (~empty1))
            data_out_valid0 <= 1'b1;
          else data_out_valid0 <= 'd0;
        end
        CMOS2: begin
          if (((image_addr_cnt == SIFT_NUM) && (rd_h < 256) && (rd_w < 256) ||
               (image_addr_cnt != SIFT_NUM) && (rd_w >= shift_w0)) && (~empty2))
            data_out_valid0 <= 1'b1;
          else data_out_valid0 <= 'd0;
        end
        ZERO: begin
          if ((image_addr_cnt != SIFT_NUM) && (rd_w < shift_w0)) data_out_valid0 <= 1'b1;
          else data_out_valid0 <= 'd0;
        end
        JUDGE: begin
          data_out_valid0 <= 'd0;
        end
        default: ;
      endcase
    end
  end


  assign data_out       = data_out1;
  assign data_out_valid = data_out_valid1;
  always @(posedge clk) begin
    rd_sta0         <= rd_sta;
    data_out_valid1 <= data_out_valid0;
    data_vs         <= rd_vs_rise;
  end
  always @(posedge clk) begin
    if (rst) begin
    end else begin
      case (rd_sta0)
        WAIT: begin
          data_out1 <= data_out1;
        end
        CMOS1: begin
          data_out1 <= dout1;
        end
        CMOS2: begin
          data_out1 <= dout2;
        end
        ZERO: begin
          data_out1 <= 'd0;
        end
        JUDGE: begin
          data_out1 <= data_out1;
        end
        default: ;
      endcase
    end
  end

endmodule
