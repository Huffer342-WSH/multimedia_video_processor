`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: Myminieye
// Engineer: Ori
// 
// Create Date:    2021-08-06 15:16 
// Design Name:  
// Module Name:    sync_vg
// QQ Group   :    
// Project Name: 
// Target Devices: 
// Tool Versions: 
// Description: 
// 
// Dependencies: 
//    VS     ______                                       ______
//HS  __    |      |_______________鈥︼拷?锟絖___________________|      |
//   |       h_sync  h_bp       h_act                h_fp
//   |__                    _______________________
//DE    |   _______________|                       |_____________
//      |
//      .
//      |
//    __|
//   |  
//   |__ 
//      |
// Revision: v1.0
// Revision 0.01 - File Created
// Additional Comments:
// 
//////////////////////////////////////////////////////////////////////////////////
`define UD #1

module sync_vg #(
    parameter X_BITS        = 12,
    parameter Y_BITS        = 12,
    parameter HDMI_1080P_EN = 0,

    // //MODE_720p 
    //   parameter V_TOTAL = 12'd750,
    //   parameter V_FP = 12'd5,
    //   parameter V_BP = 12'd20,
    //   parameter V_SYNC = 12'd5,
    //   parameter V_ACT = 12'd720,
    //   parameter H_TOTAL = 12'd1650,
    //   parameter H_FP = 12'd110,
    //   parameter H_BP = 12'd220,
    //   parameter H_SYNC = 12'd40,
    //   parameter H_ACT = 12'd1280,
    //   parameter HV_OFFSET = 12'd0 

    //MODE_1080p
    parameter V_TOTAL = 12'd1125,
    parameter V_FP = 12'd4,
    parameter V_BP = 12'd36,
    parameter V_SYNC = 12'd5,
    parameter V_ACT = 12'd1080,
    parameter H_TOTAL = 12'd2200,
    parameter H_FP = 12'd88,
    parameter H_BP = 12'd148,
    parameter H_SYNC = 12'd44,
    parameter H_ACT = 12'd1920,
    parameter HV_OFFSET = 12'd0

) (
    input  clk,
    input  rst,
    output vs_out,
    output hs_out,
    output de_re,
    output ddr_rd_en,

    input [1:0] rd_mode,
    input [15:0] ddr_image_data,
    output [15:0] hdmi_image_data,
    output reg [11:0] pos_x,
    output reg [11:0] pos_y
);

  reg [X_BITS-1:0] h_count;
  reg [Y_BITS-1:0] v_count;
  reg vs_out0, vs_out1, vs_out2, vs_out3;
  reg hs_out0, hs_out1, hs_out2, hs_out3;
  /* horizontal counter */
  always @(posedge clk) begin
    if (rst) h_count <= 0;
    else begin
      if (h_count < H_TOTAL - 1) h_count <= h_count + 1;
      else h_count <= 0;
    end
  end

  /* vertical counter */
  always @(posedge clk) begin
    if (rst) v_count <= 0;
    else if (h_count == H_TOTAL - 1) begin
      if (v_count == V_TOTAL - 1) v_count <= 0;
      else v_count <= v_count + 1;
    end
  end

  always @(posedge clk) begin
    if (rst) hs_out0 <= 0;
    else hs_out0 <= ((h_count < H_SYNC));
  end

  always @(posedge clk) begin
    if (rst) vs_out0 <= 0;
    else begin
      if ((v_count == 0) && (h_count == HV_OFFSET)) vs_out0 <= 1'b1;
      else if ((v_count == V_SYNC) && (h_count == HV_OFFSET)) vs_out0 <= 1'b0;
      else vs_out0 <= vs_out0;
    end
  end

  reg de_re0, de_re1;
  always @(posedge clk) begin
    if (rst) de_re0 <= 0;
    else
      de_re0 <= (((v_count >= V_SYNC + V_BP) && (v_count < V_SYNC + V_BP + V_ACT)) &&
                 ((h_count >= H_SYNC + H_BP) && (h_count < H_SYNC + H_BP + H_ACT)));
  end
  reg zero_valid0, zero_valid1;
  reg pixel_show_en0, pixel_show_en1;
  reg [1:0] rd_mode0;
  always @(posedge clk) begin
    if (vs_out0) rd_mode0 <= rd_mode;
    else rd_mode0 <= rd_mode0;
  end
  always @(posedge clk) begin
    zero_valid0 <= ((v_count >= V_SYNC + V_BP + V_ACT / 2) &&
                    (h_count >= H_SYNC + H_BP + H_ACT / 2)) ? 1'b1 : 1'b0;
    pixel_show_en0 <= ((v_count >= V_SYNC + V_BP + (V_ACT - 720) / 2) &&
                       (v_count < V_SYNC + V_BP + V_ACT - (V_ACT - 720) / 2) &&
                       (h_count >= H_SYNC + H_BP + (H_ACT - 1280) / 2) &&
                       (h_count < H_SYNC + H_BP + H_ACT - (H_ACT - 1280) / 2)) ? 1'b1 : 1'b0;
    zero_valid1 <= (zero_valid0 & (rd_mode0[1] == 0)) ? 1'b1 : 1'b0;
    pixel_show_en1 <= ~pixel_show_en0;

  end
  reg [15:0] hdmi_image_data0, hdmi_image_data1;
  always @(posedge clk) begin
    if (de_re1 & zero_valid1 | pixel_show_en1)
      // hdmi_image_data0 <= 'd0 ;
      hdmi_image_data0 <= 16'hffff;
    else hdmi_image_data0 <= ddr_image_data;
    //hdmi_image_data0 <= 16'hffff ;
  end

  reg de_re2, de_re3;
  assign vs_out = vs_out3;
  assign hs_out = hs_out3;
  assign de_re  = de_re3;
  generate
    if (HDMI_1080P_EN == 0)
      assign ddr_rd_en = de_re0 & (~(zero_valid0 & (rd_mode0[1] == 0))) & (pixel_show_en0);
    else assign ddr_rd_en = de_re0 & (~(zero_valid0 & (rd_mode0[1] == 0)));
  endgenerate
  assign hdmi_image_data = hdmi_image_data1;
  always @(posedge clk) begin
    if (rst) begin
      hs_out1 <= 0;
      hs_out2 <= 0;
      hs_out3 <= 0;
      vs_out1 <= 0;
      vs_out2 <= 0;
      vs_out3 <= 0;
      de_re1  <= 0;
      de_re2  <= 0;
      de_re3  <= 0;
    end else begin
      hs_out1 <= hs_out0;
      hs_out2 <= hs_out1;
      hs_out3 <= hs_out2;
      vs_out1 <= vs_out0;
      vs_out2 <= vs_out1;
      vs_out3 <= vs_out2;
      de_re1  <= de_re0;
      de_re2  <= de_re1;
      de_re3  <= de_re2;
    end
    hdmi_image_data1 <= hdmi_image_data0;
  end

  always @(posedge clk) begin
    if (h_count >= H_SYNC + H_BP + 4 && h_count < H_SYNC + H_BP + H_ACT + 4) begin
      pos_x <= h_count - H_SYNC - H_BP - 4;
    end else begin
      pos_x <= pos_x;
    end
  end

  always @(posedge clk) begin
    if (v_count >= V_SYNC + V_BP && v_count < V_SYNC + V_BP + V_ACT) begin
      pos_y <= v_count - V_SYNC - V_BP;
    end else begin
      pos_y <= pos_y;
    end
  end




endmodule
