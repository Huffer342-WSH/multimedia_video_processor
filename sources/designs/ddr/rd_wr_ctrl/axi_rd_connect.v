`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 2023/10/05 15:40:16
// Design Name: 
// Module Name: axi_rd_connect
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


module axi_rd_connect #(
    parameter WIDTH = 16,
    parameter DDR_DWIDTH = 256,
    parameter AXI_RD_LEN = 16

) (
    input clk,
    input rst,

    input rd0_clk,
    input rd0_en,
    output rd0_data_valid,
    output rd0_empty,
    output [WIDTH-1:0] rd0_data,

    input rd1_clk,
    input rd1_en,
    output rd1_data_valid,
    output rd1_empty,
    output [WIDTH-1:0] rd1_data,

    input rd2_clk,
    input rd2_en,
    output rd2_data_valid,
    output rd2_empty,
    output [WIDTH-1:0] rd2_data,

    input [3:0] axi_rid,
    input axi_rdata_valid,
    input [DDR_DWIDTH-1:0] axi_rdata,

    output rd0_fifo_empty,
    output rd0_fifo_full,
    output rd1_fifo_full,
    output rd2_fifo_full,
    output ddr_fifo_full

);

  wire rid_en, rd_ddr_en, rd_ddr_almost_full;
  wire wr_en, rd_ddr_empty, wr_rid_en;
  wire [  9:0] ddr_wr_count;
  wire [ 63:0] rd_ddr_dout;
  wire [  3:0] rid_dout;
  reg  [  2:0] rid_valid_cnt;
  reg  [255:0] rd_ddr_fifo_din;
  //generate 
  //genvar i;
  //for(i=0;i<16;i=i+1)
  //begin 
  //always @(*)
  //begin 
  //    rd_ddr_fifo_din[16*i+:16] = axi_rdata[16*(15-i)+:16] ;
  //end 
  //end 
  //endgenerate 
  assign wr_en     = (axi_rdata_valid) && (~axi_rid[3]);
  assign wr_rid_en = (axi_rdata_valid) && (~axi_rid[3]) && (rid_valid_cnt == 0);
  //rd_ddr_fifo u_rd_ddr_fifo (
  //  .clk(clk),                      // input wire clk
  //  .srst(rst),                    // input wire srst
  //  .din(rd_ddr_fifo_din),                      // input wire [255 : 0] din
  //  .wr_en(wr_en),                  // input wire wr_en
  //  .rd_en(rd_ddr_en),                  // input wire rd_en
  //  .dout(rd_ddr_dout),                    // output wire [31 : 0] dout
  //  .full(),                    // output wire full
  //  .almost_full(rd_ddr_almost_full),      // output wire almost_full
  //  .empty(rd_ddr_empty),                  // output wire empty
  //  .valid(rd_ddr_valid),                  // output wire valid
  //  .wr_data_count(ddr_wr_count)  // output wire [8 : 0] rd_data_count
  //);
  rd_ddr_fifo u_rd_ddr_fifo (
      .clk           (clk),                // input
      .rst           (rst),                // input
      .wr_en         (wr_en),              // input
      .wr_data       (axi_rdata),          // input [255:0]
      .wr_full       (),                   // output
      .wr_water_level(ddr_wr_count),       // output [9:0]
      .almost_full   (almost_full),        // output
      .rd_en         (rd_ddr_en),          // input
      .rd_data       (rd_ddr_dout),        // output [31:0]
      .rd_empty      (rd_ddr_empty),       // output
      .almost_empty  (rd_ddr_almost_full)  // output
  );
  reg rd_ddr_valid;
  always @(posedge clk) begin
    rd_ddr_valid <= rd_ddr_en & (~rd_ddr_empty);
  end

  //axi_rid_fifo u_axi_rid_fifo (
  //  .clk(clk),                  // input wire clk
  //  .srst(rst),                // input wire srst
  //  .din(axi_rid),                  // input wire [3 : 0] din
  //  .wr_en(wr_rid_en),              // input wire wr_en
  //  .rd_en(rid_en),              // input wire rd_en
  //  .dout(rid_dout),                // output wire [3 : 0] dout
  //  .full(),                // output wire full
  //  .almost_full(),  // output wire almost_full
  //  .empty(),              // output wire empty
  //  .valid(),              // output wire valid
  //  .data_count()    // output wire [9 : 0] data_count
  //);
  axi_rid_fifo u_axi_rid_fifo (
      .clk         (clk),        // input
      .rst         (rst),        // input
      .wr_en       (wr_rid_en),  // input
      .wr_data     (axi_rid),    // input [3:0]
      .wr_full     (),           // output
      .almost_full (),           // output
      .rd_en       (rid_en),     // input
      .rd_data     (rid_dout),   // output [3:0]
      .rd_empty    (),           // output
      .almost_empty()            // output
  );

  reg ddr_fifo_full0;
  assign ddr_fifo_full = ddr_fifo_full0;
  always @(posedge clk) begin
    ddr_fifo_full0 <= (ddr_wr_count >= (512 - 16 * 8)) ? 1'b1 : 1'b0;
  end
  always @(posedge clk) begin
    if (rst) rid_valid_cnt <= 'd0;
    else begin
      if ((axi_rdata_valid) && (~axi_rid[3])) rid_valid_cnt <= rid_valid_cnt + 1'b1;
    end
  end
  localparam S0 = 4'b0001;
  localparam S1 = 4'b0010;
  localparam S2 = 4'b0100;
  localparam S3 = 4'b1000;
  reg [3:0] rd_sta;
  reg [7:0] cnt_times;
  always @(posedge clk) begin
    if (rst) begin
      rd_sta <= S0;
    end else begin
      case (rd_sta)
        S0: begin
          //if(~rd_ddr_empty)
          if (ddr_wr_count >= 2) rd_sta <= S1;
          else rd_sta <= S0;
        end
        S1: begin
          rd_sta <= S2;
        end
        S2: begin
          if ((cnt_times == 32 - 1) && (~rd_ddr_empty)) rd_sta <= S3;
          else rd_sta <= S2;
        end
        S3: begin
          rd_sta <= S0;
        end
        default: rd_sta <= S0;
      endcase
    end
  end
  assign rd_ddr_en = (rd_sta == S2)?1'b1:1'b0;
  assign rid_en    = (rd_sta == S1)?1'b1:1'b0;
  always @(posedge clk) begin
    if ((rd_sta == S2)) begin
      if (~rd_ddr_empty) cnt_times <= cnt_times + 1'b1;
      else cnt_times <= cnt_times;
    end else cnt_times <= 'd0;
  end

  reg [3:0] rid_dout0;
  always @(posedge clk) begin
    rid_dout0 <= rid_dout;
  end

  wire wr0_en;
  wire rd0_almost_full, rd1_almost_full, rd2_almost_full;
  assign wr0_en = (rd_ddr_valid & rid_dout0[0]) ? 1'b1 : 1'b0;

  wire [9:0] wr0_data_count, wr1_data_count, wr2_data_count;
  //rd0_fifo u_rd0_fifo (
  //  .wr_clk(clk),                // input wire wr_clk
  //  .wr_rst(rst),                // input wire wr_rst
  //  .rd_clk(rd0_clk),                // input wire rd_clk
  //  .rd_rst(rst),                // input wire rd_rst
  //  .din(rd_ddr_dout),                      // input wire [31 : 0] din
  //  .wr_en(wr0_en),                  // input wire wr_en
  //  .rd_en(rd0_en),                  // input wire rd_en
  //  .dout(rd0_data),                    // output wire [15 : 0] dout
  //  .full(),                    // output wire full
  //  .almost_full(rd0_almost_full),      // output wire almost_full
  //  .empty(rd0_empty),                  // output wire empty
  //  .valid(rd0_data_valid),                  // output wire valid
  //  .wr_data_count(wr0_data_count)  // output wire [9 : 0] wr_data_count
  //);
  reg rd0_data_valid0, rd1_data_valid0, rd2_data_valid0;
  always @(posedge rd0_clk) begin
    rd0_data_valid0 <= (rd0_en) & (~rd0_empty);
  end
  always @(posedge rd1_clk) begin
    rd1_data_valid0 <= (rd1_en) & (~rd1_empty);
  end
  always @(posedge rd2_clk) begin
    rd2_data_valid0 <= (rd2_en) & (~rd2_empty);
  end
  assign rd0_data_valid = rd0_data_valid0;
  assign rd1_data_valid = rd1_data_valid0;
  assign rd2_data_valid = rd2_data_valid0;
  rd0_fifo u_rd0_fifo (
      .wr_clk        (clk),              // input
      .wr_rst        (rst),              // input
      .wr_en         (wr0_en),           // input
      .wr_data       (rd_ddr_dout),      // input [31:0]
      .wr_full       (),                 // output
      .wr_water_level(wr0_data_count),   // output [10:0]
      .almost_full   (rd0_almost_full),  // output
      .rd_clk        (rd0_clk),          // input
      .rd_rst        (rst),              // input
      .rd_en         (rd0_en),           // input
      .rd_data       (rd0_data),         // output [15:0]
      .rd_empty      (rd0_empty),        // output
      .almost_empty  ()                  // output
  );

  wire wr1_en;
  assign wr1_en = (rd_ddr_valid & rid_dout0[1]) ? 1'b1 : 1'b0;


  //rd0_fifo u_rd1_fifo (
  //  .wr_clk(clk),                // input wire wr_clk
  //  .wr_rst(rst),                // input wire wr_rst
  //  .rd_clk(rd1_clk),                // input wire rd_clk
  //  .rd_rst(rst),                // input wire rd_rst
  //  .din(rd_ddr_dout),                      // input wire [31 : 0] din
  //  .wr_en(wr1_en),                  // input wire wr_en
  //  .rd_en(rd1_en),                  // input wire rd_en
  //  .dout(rd1_data),                    // output wire [15 : 0] dout
  //  .full(),                    // output wire full
  //  .almost_full(rd1_almost_full),      // output wire almost_full
  //  .empty(rd1_empty),                  // output wire empty
  //  .valid(rd1_data_valid),                  // output wire valid
  //  .wr_data_count(wr1_data_count)  // output wire [9 : 0] wr_data_count
  //);
  rd0_fifo u_rd1_fifo (
      .wr_clk        (clk),              // input
      .wr_rst        (rst),              // input
      .wr_en         (wr1_en),           // input
      .wr_data       (rd_ddr_dout),      // input [31:0]
      .wr_full       (),                 // output
      .wr_water_level(wr1_data_count),   // output [10:0]
      .almost_full   (rd1_almost_full),  // output
      .rd_clk        (rd1_clk),          // input
      .rd_rst        (rst),              // input
      .rd_en         (rd1_en),           // input
      .rd_data       (rd1_data),         // output [15:0]
      .rd_empty      (rd1_empty),        // output
      .almost_empty  ()                  // output
  );
  wire wr2_en;
  assign wr2_en = (rd_ddr_valid & rid_dout0[2]) ? 1'b1 : 1'b0;


  //rd0_fifo u_rd2_fifo (
  //  .wr_clk(clk),                // input wire wr_clk
  //  .wr_rst(rst),                // input wire wr_rst
  //  .rd_clk(rd2_clk),                // input wire rd_clk
  //  .rd_rst(rst),                // input wire rd_rst
  //  .din(rd_ddr_dout),                      // input wire [31 : 0] din
  //  .wr_en(wr2_en),                  // input wire wr_en
  //  .rd_en(rd2_en),                  // input wire rd_en
  //  .dout(rd2_data),                    // output wire [15 : 0] dout
  //  .full(),                    // output wire full
  //  .almost_full(rd2_almost_full),      // output wire almost_full
  //  .empty(rd2_empty),                  // output wire empty
  //  .valid(rd2_data_valid),                  // output wire valid
  //  .wr_data_count(wr2_data_count)  // output wire [9 : 0] wr_data_count
  //);
  rd0_fifo u_rd2_fifo (
      .wr_clk        (clk),              // input
      .wr_rst        (rst),              // input
      .wr_en         (wr2_en),           // input
      .wr_data       (rd_ddr_dout),      // input [31:0]
      .wr_full       (),                 // output
      .wr_water_level(wr2_data_count),   // output [10:0]
      .almost_full   (rd2_almost_full),  // output
      .rd_clk        (rd2_clk),          // input
      .rd_rst        (rst),              // input
      .rd_en         (rd2_en),           // input
      .rd_data       (rd2_data),         // output [15:0]
      .rd_empty      (rd2_empty),        // output
      .almost_empty  ()                  // output
  );
  reg rd0_fifo_full0;
  reg rd1_fifo_full0;
  reg rd2_fifo_full0;
  reg rd0_fifo_empty0;


  assign rd0_fifo_full  = rd0_fifo_full0;
  assign rd1_fifo_full  = rd1_fifo_full0;
  assign rd2_fifo_full  = rd2_fifo_full0;
  assign rd0_fifo_empty = rd0_fifo_empty0;

  always @(posedge clk) begin
    rd0_fifo_full0  <= (wr0_data_count >= (256)) ? 1'b1 : 1'b0;
    rd1_fifo_full0  <= (wr1_data_count >= (256)) ? 1'b1 : 1'b0;
    rd2_fifo_full0  <= (wr2_data_count >= (256)) ? 1'b1 : 1'b0;
    rd0_fifo_empty0 <= (wr0_data_count <= (256)) ? 1'b1 : 1'b0;
  end




endmodule
