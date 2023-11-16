`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 2023/10/16 14:04:17
// Design Name: 
// Module Name: hdmi_in_top
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


module hdmi_in_top #(
    parameter IMAGE_W    = 1280,
    parameter IMAGE_H    = 720,
    parameter IMAGE_SIZE = 11
) (
    input clk,  //! 时钟
    input rst,  //! 复位

    input [7:0] r_in,  //! 像素点Red通道
    input [7:0] g_in,  //! 像素点Green通道
    input [7:0] b_in,  //! 像素点Blue通道
    input vs_in,  //! 垂直同步信号
    input hs_in,  //! 水平同步信号
    input de_in,  //! 数据有效信号

    output [15:0] hdmi_data,  //! HDMI输出数据
    output hdmi_data_valid,  //! HDMI输出有效信号
    output hdmi_vs_out  //! HDMI输出输出垂直同步

);
  //localparam   EXTRACT = 2 ;
  reg [7:0] r_in0, g_in0, b_in0;
  reg [7:0] r_in1, g_in1, b_in1;
  reg [7:0] r_in2, g_in2, b_in2;
  reg [7:0] r_in3, g_in3, b_in3;
  reg vs_in0, hs_in0, de_in0;
  reg vs_in1, hs_in1, de_in1;
  reg vs_in2, hs_in2, de_in2;
  reg hdmi_in_en;

  wire [1:0] EXTRACT;
  generate
    if (IMAGE_H == 1080) assign EXTRACT = 1;
    else assign EXTRACT = 2;
  endgenerate

  always @(posedge clk) begin
    r_in0  <= r_in;
    r_in1  <= r_in0;
    r_in2  <= r_in1;
    r_in3  <= r_in2;
    g_in0  <= g_in;
    g_in1  <= g_in0;
    g_in2  <= g_in1;
    g_in3  <= g_in2;
    b_in0  <= b_in;
    b_in1  <= b_in0;
    b_in2  <= b_in1;
    b_in3  <= b_in2;
    vs_in0 <= vs_in;
    vs_in1 <= vs_in0;
    vs_in2 <= vs_in1;
    hs_in0 <= hs_in;
    hs_in1 <= hs_in0;
    hs_in2 <= hs_in1;
    de_in0 <= de_in;
    de_in1 <= de_in0;
    de_in2 <= de_in1;
  end
  reg [1:0] hs_cnt;
  always @(posedge clk) begin
    if (vs_in1) hs_cnt <= 'd0;
    else begin
      if (hs_in1 & (~hs_in2)) begin
        if (hs_cnt == EXTRACT) hs_cnt <= 'd0;
        else hs_cnt <= hs_cnt + 1'b1;
      end else hs_cnt <= hs_cnt;
    end
  end

  reg hdmi_data_valid0;
  assign hdmi_data_valid = hdmi_data_valid0;
  assign hdmi_data       = {r_in3[7:3], g_in3[7:2], b_in3[7:3]};
  reg [1:0] de_cnt;
  always @(posedge clk) begin
    if (de_in1) begin
      if (de_cnt == EXTRACT) de_cnt <= 'd0;
      else de_cnt <= de_cnt + 1'b1;
    end else de_cnt <= 'd0;
  end
  always @(posedge clk) begin
    if (rst) hdmi_in_en <= 'd0;
    else if (vs_in1 & (~vs_in2)) hdmi_in_en <= ~hdmi_in_en;
    //hdmi_in_en <= 'd1 ;
    else
      hdmi_in_en <= hdmi_in_en;
  end
  always @(posedge clk) begin
    if (de_in2 & (hs_cnt == EXTRACT) & (de_cnt == EXTRACT) & hdmi_in_en) hdmi_data_valid0 <= 'd1;
    else hdmi_data_valid0 <= 'd0;
  end
  assign hdmi_vs_out = hdmi_in_en;
  //assign hdmi_vs_out = hdmi_in_en&vs_in2 ;

  reg [12:0] cnt_hs0, cnt_hs1;
  always @(posedge clk) begin
    if (cnt_hs1 == 639) cnt_hs0 <= cnt_hs0 + hdmi_data_valid0;
    else if (vs_in1) cnt_hs0 <= 0;
    if (de_in1) cnt_hs1 <= cnt_hs1 + hdmi_data_valid0;
    else cnt_hs1 <= 0;
  end
endmodule
