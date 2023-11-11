`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 2023/11/04 13:47:24
// Design Name: 
// Module Name: mult_image_w
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


module mult_image_w #(
    parameter WIDT_A = 11,
    parameter WIDT_B = 10
) (
    input CLK,
    input signed [WIDT_A-1:0] A,
    input [WIDT_B-1:0] B,

    output reg signed [WIDT_B+WIDT_A-1:0] P
);
  wire signed [WIDT_B:0] B0;
  assign B0 = {1'b0, B};
  always @(posedge CLK) begin
    P <= A * B0;
  end


endmodule
