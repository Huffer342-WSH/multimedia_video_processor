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


module mult_image_ip #(
    parameter WIDT_A = 9,
    parameter WIDT_B = 6
) (
    input CLK,
    input [WIDT_A-1:0] A,
    input [WIDT_B-1:0] B,

    output reg [WIDT_B+WIDT_A-1:0] P
);

  always @(posedge CLK) begin
    P <= A * B;
  end


endmodule
