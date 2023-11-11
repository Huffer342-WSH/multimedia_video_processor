`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 2023/10/03 20:52:03
// Design Name: 
// Module Name: rotate_image
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


module rotate_image #(
    parameter   IMAGE_SIZE = 11 ,
    parameter   MIN_NUM    = 1280 ,
    parameter   IMAGE_W    = 1280 ,
    parameter   IMAGE_H    = 720
) (
    input clk,
    input rst,

    input [7:0] rotate_angle,
    input [9:0] rotate_amplitude,
    input rotate_en,
    input wire signed [11:0] offsetX,
    input wire signed [11:0] offsetY,
    input ddr_data_in_valid,
    input [15:0] ddr_data_in,

    output rd_ddr_addr_valid,
    output [32-1:0] rd_ddr_addr,
    output data_out_valid,
    output [15:0] data_out
);


  localparam IDLE = 3'b001;
  localparam WAIT = 3'b010;
  localparam CNT = 3'b100;



  reg  [ 2:0] rotate_sta;
  reg  [ 7:0] rd_addr;
  wire [17:0] douta;
  wire signed [8:0] cos_data, sin_data;
  wire signed [19:0] cos_data_multed, sin_data_multed;
  wire signed [12:0] cos_data0, sin_data0;
  reg signed [IMAGE_SIZE+14-1:0] image_w_add_addr, image_h_add_addr;


  assign cos_data = douta[17:9];
  assign sin_data = douta[8 : 0];
  wire signed [10:0] signed_zoom;
  assign signed_zoom = {1'b0, rotate_amplitude};

  always @(posedge clk) begin
    if (rotate_sta == IDLE) rd_addr <= rotate_angle;
    else rd_addr <= rd_addr;
  end

  reg signed [11:0] offsetX_ff, offsetY_ff;
  reg signed [11:0] centerX, centerY;

  always @(posedge clk) begin
    if (rst) begin
      offsetX_ff <= 0;
      offsetY_ff <= 0;
    end else if (rotate_sta == IDLE) begin
      offsetX_ff <= offsetX;
      offsetY_ff <= offsetY;
    end else begin
      offsetX_ff <= offsetX_ff;
      offsetY_ff <= offsetY_ff;
    end
  end

  always @(posedge clk) begin
    centerX <= $signed(IMAGE_W / 2) - offsetX_ff;
    centerY <= $signed(IMAGE_H / 2) - offsetY_ff;
  end

  always @(posedge clk) begin
    image_w_add_addr <= centerX * 128 + 64;
    image_h_add_addr <= centerY * 128 + 64;
  end


  rotate_rom u_rotate_rom (
      .addr   (rd_addr),  // input [7:0]
      .clk    (clk),      // input
      .rst    (1'b0),     // input
      .rd_data(douta)     // output [8:0]
  );


  rotate_mult0 #(
      .WIDT_A(9),
      .WIDT_B(11)
  ) u_rotate_mult_zoom0 (
      .CLK(clk),             // input wire CLK
      .A  (cos_data),        // input wire [10 : 0] A
      .B  (signed_zoom),     // input wire [7 : 0] B
      .P  (cos_data_multed)  // output wire [18 : 0] P
  );
  rotate_mult0 #(
      .WIDT_A(9),
      .WIDT_B(11)
  ) u_rotate_mult_zoom1 (
      .CLK(clk),             // input wire CLK
      .A  (sin_data),        // input wire [10 : 0] A
      .B  (signed_zoom),     // input wire [7 : 0] B
      .P  (sin_data_multed)  // output wire [18 : 0] P
  );


  assign cos_data0 = cos_data_multed[19:7];
  assign sin_data0 = sin_data_multed[19:7];



  reg signed [IMAGE_SIZE-1:0] cnt_w, cnt_h;
  wire [11:0] wr_count;
  wire addr_fifo_empty;
  always @(posedge clk) begin
    if (rst) begin
      rotate_sta <= IDLE;
    end else begin
      case (rotate_sta)
        IDLE: begin
          if (rotate_en & addr_fifo_empty) rotate_sta <= WAIT;
          else rotate_sta <= IDLE;
        end
        WAIT: begin
          if (wr_count < (2047 - MIN_NUM)) rotate_sta <= CNT;
          else rotate_sta <= WAIT;
        end
        CNT: begin
          if (cnt_w >= (IMAGE_W / 2 - 1))
            if (cnt_h >= (IMAGE_H / 2 - 1)) rotate_sta <= IDLE;
            else rotate_sta <= WAIT;
          else rotate_sta <= CNT;
        end
        default: rotate_sta <= IDLE;
      endcase
    end
  end

  always @(posedge clk) begin
    if (rst) begin

    end else begin
      case (rotate_sta)
        IDLE: begin
          cnt_w <= -(IMAGE_W / 2);
          cnt_h <= -(IMAGE_H / 2);
        end
        WAIT: begin
          cnt_w <= -(IMAGE_W / 2);
          cnt_h <= cnt_h;
        end
        CNT: begin
          cnt_w <= cnt_w + 1'b1;
          if (cnt_w == (IMAGE_W / 2 - 1)) cnt_h <= cnt_h + 1'b1;
          else cnt_h <= cnt_h;
        end
        default: ;
      endcase
    end
  end

  wire signed [IMAGE_SIZE+13-1:0] mult_p0[3:0];
  reg signed [IMAGE_SIZE+14-1:0] w_mult_add, h_mult_add;
  rotate_mult0 #(
      .WIDT_A(11),
      .WIDT_B(13)
  ) u_rotate_mult0 (
      .CLK(clk),        // input wire CLK
      .A  (cnt_w),      // input wire [10 : 0] A
      .B  (cos_data0),  // input wire [7 : 0] B
      .P  (mult_p0[0])  // output wire [18 : 0] P
  );
  rotate_mult0 #(
      .WIDT_A(11),
      .WIDT_B(13)
  ) u_rotate_mult1 (
      .CLK(clk),        // input wire CLK
      .A  (cnt_h),      // input wire [10 : 0] A
      .B  (sin_data0),  // input wire [7 : 0] B
      .P  (mult_p0[1])  // output wire [18 : 0] P
  );
  rotate_mult0 #(
      .WIDT_A(11),
      .WIDT_B(13)
  ) u_rotate_mult2 (
      .CLK(clk),        // input wire CLK
      .A  (cnt_w),      // input wire [10 : 0] A
      .B  (sin_data0),  // input wire [7 : 0] B
      .P  (mult_p0[2])  // output wire [18 : 0] P
  );
  rotate_mult0 #(
      .WIDT_A(11),
      .WIDT_B(13)
  ) u_rotate_mult3 (
      .CLK(clk),        // input wire CLK
      .A  (cnt_h),      // input wire [10 : 0] A
      .B  (cos_data0),  // input wire [7 : 0] B
      .P  (mult_p0[3])  // output wire [18 : 0] P
  );
  //rotate_mult u_rotate_mult0 (
  //  .a(cnt_w),        // input [10:0]
  //  .b(cos_data0),        // input [8:0]
  //  .clk(clk),    // input
  //  .rst(rst),    // input
  //  .ce(1'b1),      // input
  //  .p(mult_p0[0])         // output [19:0]
  //);
  //rotate_mult u_rotate_mult1 (
  //  .a(cnt_h),        // input [10:0]
  //  .b(sin_data0),        // input [8:0]
  //  .clk(clk),    // input
  //  .rst(rst),    // input
  //  .ce(1'b1),      // input
  //  .p(mult_p0[1])         // output [19:0]
  //);
  //rotate_mult u_rotate_mult2 (
  //  .a(cnt_w),        // input [10:0]
  //  .b(sin_data0),        // input [8:0]
  //  .clk(clk),    // input
  //  .rst(rst),    // input
  //  .ce(1'b1),      // input
  //  .p(mult_p0[2])         // output [19:0]
  //);
  //rotate_mult u_rotate_mult3 (
  //  .a(cnt_h),        // input [10:0]
  //  .b(cos_data0),        // input [8:0]
  //  .clk(clk),    // input
  //  .rst(rst),    // input
  //  .ce(1'b1),      // input
  //  .p(mult_p0[3])         // output [19:0]
  //);
  reg [5:0] image_w_valid0;
  wire image_w_valid;
  assign image_w_valid = (rotate_sta == CNT) ? 1'b1 : 1'b0;
  always @(posedge clk) begin
    if (rst) begin
      image_w_valid0 <= 'd0;
    end else begin
      image_w_valid0 <= {image_w_valid0[4:0], image_w_valid};
    end
    w_mult_add <= mult_p0[0] + mult_p0[1];
    h_mult_add <= mult_p0[3] - mult_p0[2];
  end


  reg [IMAGE_SIZE+15-1:0] image_w_add0, image_h_add0;

  always @(posedge clk) begin
    image_w_add0 <= image_w_add_addr + w_mult_add;
    image_h_add0 <= image_h_add_addr + h_mult_add;  // image_h_add0 DELAY = 3 
  end

  reg image_w_blank_valid, image_h_blank_valid, image_blank_valid;
  reg rd_ddr_addr_valid1;
  wire rd_ddr_addr_valid0 = (image_w_valid0[3] & (~image_h_blank_valid) & (~image_w_blank_valid)) ?
      1'b1 : 1'b0;
  always @(posedge clk) begin
    if ((image_w_add0[IMAGE_SIZE+15-1] == 1'b1) || (image_w_add0 >= IMAGE_W * 128))
      image_w_blank_valid <= 1'b1;
    else image_w_blank_valid <= 1'b0;
    if ((image_h_add0[IMAGE_SIZE+15-1] == 1'b1) || (image_h_add0 >= IMAGE_H * 128))
      image_h_blank_valid <= 1'b1;
    else image_h_blank_valid <= 1'b0;
    image_blank_valid  <= image_w_blank_valid | image_h_blank_valid;  // delay = 5
    rd_ddr_addr_valid1 <= rd_ddr_addr_valid0;
  end
  reg [IMAGE_SIZE+4-1:0] image_w_add1, image_w_add2, image_h_add1, image_h_add2;
  always @(posedge clk) begin
    image_w_add1 <= image_w_add0[7+:IMAGE_SIZE+4];
    image_w_add2 <= image_w_add1;
    image_h_add1 <= image_h_add0[7+:IMAGE_SIZE+4];
    image_h_add2 <= image_h_add1;
  end

  assign rd_ddr_addr_valid = rd_ddr_addr_valid1;
  assign rd_ddr_addr = {
    {{(12 - IMAGE_SIZE) {1'b0}}, image_w_add2}, {{(12 - IMAGE_SIZE) {1'b0}}, image_h_add2}
  };
  wire [3:0] din, dout;
  wire wr_en;
  wire empty, full, addr_fifo_rd_en;

  assign din   = {3'd0, image_blank_valid};
  assign wr_en = image_w_valid0[4];
  //store_addr u_store_addr (
  //  .clk(clk),      // input wire clk
  //  .srst(rst),    // input wire srst
  //  .din(din),      // input wire [3 : 0] din
  //  .wr_en(wr_en),  // input wire wr_en
  //  .rd_en(addr_fifo_rd_en),  // input wire rd_en
  //  .dout(dout),    // output wire [3 : 0] dout
  //  .full(full),    // output wire full
  //  .empty(addr_fifo_empty),  // output wire empty
  //  .valid(addr_fifo_valid),  // output wire valid
  //  .data_count(wr_count)
  //);

  store_addr u_store_addr (
      .clk           (clk),              // input
      .rst           (rst),              // input
      .wr_en         (wr_en),            // input
      .wr_data       (din),              // input [3:0]
      .wr_full       (full),             // output
      .wr_water_level(wr_count),         // output [11:0]
      .almost_full   (),                 // output
      .rd_en         (addr_fifo_rd_en),  // input
      .rd_data       (dout),             // output [3:0]
      .rd_empty      (addr_fifo_empty),  // output
      .almost_empty  ()                  // output
  );
  reg addr_fifo_valid;
  always @(posedge clk) begin
    addr_fifo_valid <= ((~addr_fifo_empty) & addr_fifo_rd_en) ? 1'b1 : 1'b0;
  end
  reg ddr_data_in_valid0;
  reg [15:0] ddr_data_in0;
  wire [15:0] image_data;
  wire data_empty, data_rd_en;
  always @(posedge clk) begin
    ddr_data_in_valid0 <= ddr_data_in_valid;
    ddr_data_in0       <= ddr_data_in;
  end
  reg fifo_data_valid;
  //store_image_data u_store_image_data (
  //  .clk(clk),                // input wire clk
  //  .srst(rst),              // input wire srst
  //  .din(ddr_data_in0),                // input wire [15 : 0] din
  //  .wr_en(ddr_data_in_valid0),            // input wire wr_en
  //  .rd_en(data_rd_en),            // input wire rd_en
  //  .dout(image_data),              // output wire [15 : 0] dout
  //  .full(),              // output wire full
  //  .empty(data_empty),            // output wire empty
  //  .valid(fifo_data_valid),            // output wire valid
  //  .data_count()  // output wire [9 : 0] data_count
  //);


  store_image_data u_store_image_data (
      .clk           (clk),                 // input
      .rst           (rst),                 // input
      .wr_en         (ddr_data_in_valid0),  // input
      .wr_data       (ddr_data_in0),        // input [15:0]
      .wr_full       (),                    // output
      .wr_water_level(),                    // output [10:0]
      .almost_full   (),                    // output
      .rd_en         (data_rd_en),          // input
      .rd_data       (image_data),          // output [15:0]
      .rd_empty      (data_empty),          // output
      .almost_empty  ()                     // output
  );
  always @(posedge clk) begin
    fifo_data_valid <= (data_rd_en & (~data_empty)) ? 1'b1 : 1'b0;
  end
  localparam S0 = 3'b001;
  localparam S1 = 3'b010;
  localparam S2 = 3'b100;
  reg [2:0] rd_sta;
  reg rd_sta_s2;

  wire fifo_blank_valid = dout[0];
  assign addr_fifo_rd_en =
      ((~addr_fifo_empty) &&
       (rd_sta == S0 ||
        (rd_sta == S1 && (fifo_blank_valid || (~fifo_blank_valid) & (~data_empty))))) ? 1'b1 : 1'b0;
  assign data_rd_en = ((rd_sta == S1 && (~fifo_blank_valid) || (rd_sta_s2)) && (~data_empty)) ?
      1'b1 : 1'b0;
  always @(posedge clk) begin
    if (rst) begin
      rd_sta <= S0;
    end else begin
      case (rd_sta)
        S0: begin
          if (~addr_fifo_empty) rd_sta <= S1;
          else rd_sta <= S0;
        end
        S1: begin
          if ((~fifo_blank_valid) & (data_empty)) rd_sta <= S2;
          else if (addr_fifo_empty) rd_sta <= S0;
          else rd_sta <= S1;
        end
        S2: begin
          if (~data_empty)
            if (addr_fifo_empty) rd_sta <= S0;
            else rd_sta <= S1;
          else rd_sta <= S2;
        end
        default: rd_sta <= S0;
      endcase
    end
  end
  always @(posedge clk) begin
    rd_sta_s2 <= ((rd_sta == S2) && addr_fifo_empty && (~data_empty)) ? 1'b1 : 1'b0;
  end

  reg [15:0] data_out2;
  wire data_out_valid0;
  reg data_out_valid1, data_out_valid2;
  reg data_blank_out_valid;
  assign data_out_valid0 = (addr_fifo_valid & (fifo_blank_valid)) ? 1'b1 : 1'b0;
  always @(posedge clk) begin
    data_out_valid1      <= data_out_valid0;
    data_out_valid2      <= data_out_valid1 || fifo_data_valid;
    data_blank_out_valid <= data_rd_en;
    if (fifo_data_valid) data_out2 <= image_data;
    else data_out2 <= 'd0;
  end

  assign data_out_valid = data_out_valid2;
  assign data_out       = data_out2;


  // test code 
  reg [15:0] cnt_num;
  always @(posedge clk) begin
    if (rst) cnt_num <= 'd1;
    else begin
      if (data_out_valid) begin
        if (cnt_num == IMAGE_W) cnt_num <= 'd1;
        else cnt_num <= cnt_num + 1'b1;
      end else cnt_num <= cnt_num;
    end
  end
endmodule
