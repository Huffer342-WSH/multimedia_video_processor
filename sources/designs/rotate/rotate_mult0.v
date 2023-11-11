`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 2023/11/04 13:47:24
// Design Name: 
// Module Name: rotate_mult0
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


module rotate_mult0 #(
    parameter WIDT_A = 11,
    parameter WIDT_B = 9
) (
    input CLK,
    input signed [WIDT_A-1:0] A,
    input signed [WIDT_B-1:0] B,

    output reg signed [WIDT_B+WIDT_A-1:0] P
);

  always @(posedge CLK) begin
    P <= A * B;
  end


endmodule
