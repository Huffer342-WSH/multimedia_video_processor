`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 2023/10/19 09:12:38
// Design Name: 
// Module Name: async_to_sync
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


module async_to_sync #(
    parameter WIDTH = 4
) (
    input clk,

    input  [WIDTH-1:0] data_in,
    output [WIDTH-1:0] data_out

);

  reg [WIDTH-1:0] data_in0, data_in1, data_in2, data_in3;
  wire data_vary;
  reg  data_vary0;
  assign data_out  = data_in3;
  assign data_vary = (data_in2 != data_in0) ? 1'b1 : 1'b0;
  always @(posedge clk) begin
    data_in0   <= data_in;
    data_in1   <= data_in0;
    data_in2   <= data_in1;
    data_vary0 <= data_vary;
    if (data_vary0) data_in3 <= data_in0;
    else data_in3 <= data_in3;
  end

endmodule
