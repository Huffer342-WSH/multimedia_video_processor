`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company:Meyesemi 
// Engineer: Will
// 
// Create Date: 2023-03-17  
// Design Name:  
// Module Name: 
// Project Name: 
// Target Devices: Pango
// Tool Versions: 
// Description: 
//      
// Dependencies: 
// 
// Revision:
// Revision 1.0 - File Created
// Additional Comments:
// 
//////////////////////////////////////////////////////////////////////////////////
//将两个8bit数据拼成一个16bit RGB565数据；
`timescale 1ns / 1ns

module cmos_8_16bit (
    input       pclk_in,
    input       rst,
    input       de_i,
    input [7:0] pdata_i,
    input       vs_i,

    output            image_data_valid,
    output     [15:0] image_data,
    output reg        vs_o,
    output            pclk
);
  reg [7:0] pdata_i0, pdata_i1, pdata_i2, pdata_i3;
  reg vs_in0, de_in0;
  reg vs_in1, de_in1;
  reg vs_in2, de_in2;
  reg image_in_en;
  assign pclk = pclk_in;

  always @(posedge pclk) begin
    pdata_i0 <= pdata_i;
    pdata_i1 <= pdata_i0;
    pdata_i2 <= pdata_i1;
    pdata_i3 <= pdata_i2;
    vs_in0   <= vs_i;
    vs_in1   <= vs_in0;
    de_in0   <= de_i;
    de_in1   <= de_in0;
    de_in2   <= de_in1;
  end
  reg [11:0] cnt_hs;
  always @(posedge pclk) begin
    if (de_in1) cnt_hs <= cnt_hs + 1'b1;
    else cnt_hs <= 'd0;
  end
  reg hs_cnt;
  always @(posedge pclk) begin
    if (vs_in1) hs_cnt <= 'd0;
    else begin
      if (cnt_hs == 1280 * 2 - 1) hs_cnt <= ~hs_cnt;
      else hs_cnt <= hs_cnt;
    end
  end


  reg de_cnt;
  always @(posedge pclk) begin
    if (de_in1) de_cnt <= ~de_cnt;
    else de_cnt <= 'd0;
  end
  always @(posedge pclk) begin
    if (rst) image_in_en <= 'd0;
    else if (vs_in1) image_in_en <= 'd1;
    else image_in_en <= image_in_en;
    vs_o <= (vs_in1) & (image_in_en);
  end

  reg [15:0] image_data0;
  reg image_data_valid0;
  //assign image_data = image_data0 ;
  assign image_data = {image_data0[4:0], image_data0[10:5], image_data0[15:11]};
  assign image_data_valid = image_data_valid0;
  always @(posedge pclk) begin
    if (de_in1 & de_cnt & image_in_en) begin
      image_data0 <= {pdata_i2, pdata_i1};
      image_data_valid0 <= 'd1;
    end else begin
      image_data0 <= image_data0;
      image_data_valid0 <= 'd0;
    end
  end

endmodule
