`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 2023/09/28 15:36:41
// Design Name: 
// Module Name: zoom_image
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


module zoom_image_v1 #(
    parameter IMAGE_SIZE = 11,
    parameter FRA_WIDTH  = 7,
    parameter IMAGE_W    = 1920,
    parameter IMAGE_H    = 1080
) (
    input clk,
    input rst,
    input zoom_en,
    input hdmi_out_en,
    input data_half_en,
    input fifo_full,
    input [3+FRA_WIDTH-1:0] zoom_num,
    input data_in_valid,
    input [15:0] data_in,

    output data_out_valid,
    output [15:0] data_out,
    output imag_addr_valid,
    output [IMAGE_SIZE-1:0] imag_addr,
    output reg zoom_done
);

  localparam IDLE = 7'b000_0001;
  localparam JUDGE = 7'b000_0010;
  localparam PARAM = 7'b000_0100;
  localparam WAIT0 = 7'b000_1000;
  localparam WAIT1 = 7'b001_0000;
  localparam ZOOM = 7'b010_0000;
  localparam BLANK = 7'b100_0000;
  localparam FRA_WIDTH_power = 1 << FRA_WIDTH;
  localparam MULT_DELAY = 1;
  reg [6:0] zoom_sta;


  reg signed [IMAGE_SIZE-1:0] cnt_w, cnt_h, mult_cnt_h;
  reg signed [IMAGE_SIZE+3-1:0] judge_cnt_h;
  reg judge_cnt_h_valid;
  reg ram_idle;
  reg no_need_rd_ddr;
  reg no_one_need_rd_ddr;
  reg record_ram[0:3];
  reg [2:0] delay_cnt;
  reg [3:0] param_delay;
  reg [2:0] cnt_record_ram;
  reg record_ram_valid;
  reg [15:0] data_in0;
  reg [15:0] data_in1;
  reg [15:0] data_in2;
  reg [15:0] data_in3;
  reg [6:0] coe_valid;
  reg data_in_valid0;
  reg data_in_valid1;
  reg data_in_valid2;
  reg data_in_valid3;
  reg rd_one_ram;
  reg fifo_full0;
  wire signed [IMAGE_SIZE+FRA_WIDTH+3-1:0] mult_w, mult_h;
  always @(posedge clk) begin
    data_in0       <= data_in;
    data_in1       <= data_in;
    data_in2       <= data_in;
    data_in3       <= data_in;
    data_in_valid0 <= data_in_valid;
    data_in_valid1 <= data_in_valid;
    data_in_valid2 <= data_in_valid;
    data_in_valid3 <= data_in_valid;
    fifo_full0     <= fifo_full;
  end

  always @(posedge clk) begin
    if (rst) begin
      zoom_sta <= IDLE;
    end else begin
      case (zoom_sta)
        IDLE: begin
          if (zoom_en) zoom_sta <= JUDGE;
          else zoom_sta <= IDLE;
        end
        JUDGE: begin
          if (delay_cnt == MULT_DELAY + 3) begin
            if (judge_cnt_h_valid) zoom_sta <= PARAM;
            else if (fifo_full0) zoom_sta <= BLANK;
            else zoom_sta <= JUDGE;
          end else begin
            zoom_sta <= JUDGE;
          end
        end
        PARAM: begin
          if (ram_idle) zoom_sta <= WAIT1;
          else zoom_sta <= WAIT0;
        end
        WAIT0: begin
          if (record_ram_valid) zoom_sta <= PARAM;
          else zoom_sta <= WAIT0;
        end
        WAIT1: begin
          if (record_ram_valid && fifo_full0) zoom_sta <= ZOOM;
          else zoom_sta <= WAIT1;
        end
        ZOOM: begin
          if ((cnt_w == (IMAGE_W / 2 - 1))) begin
            if (cnt_h == (IMAGE_H / 2 - 1)) zoom_sta <= IDLE;
            else zoom_sta <= JUDGE;
          end else zoom_sta <= ZOOM;
        end
        BLANK: begin
          if ((cnt_w == (IMAGE_W / 2) - 1)) begin
            if (cnt_h == (IMAGE_H / 2 - 1)) zoom_sta <= IDLE;
            else zoom_sta <= JUDGE;
          end else zoom_sta <= BLANK;
        end
        default: zoom_sta <= IDLE;
      endcase
    end
  end
  always @(posedge clk) begin
    if (rst) begin

    end else begin
      case (zoom_sta)
        IDLE: begin
          cnt_h      <= -(IMAGE_H / 2);
          cnt_w      <= -(IMAGE_W / 2);
          mult_cnt_h <= cnt_h;
          ram_idle   <= 'd0;
        end
        JUDGE: begin
          cnt_w      <= -(IMAGE_W / 2);
          mult_cnt_h <= cnt_h;
        end
        PARAM: begin
          if (~ram_idle) mult_cnt_h <= cnt_h;
          else mult_cnt_h <= cnt_h + 1'b1;
        end
        WAIT0: begin
          if (record_ram_valid) ram_idle <= 'd1;
          else ram_idle <= 'd0;
        end
        WAIT1: begin
          mult_cnt_h <= cnt_h;
        end
        ZOOM: begin
          cnt_w <= cnt_w + 1'b1;
          if ((cnt_w == (IMAGE_W / 2 - 1))) cnt_h <= cnt_h + 1'b1;
        end
        BLANK: begin
          cnt_w <= cnt_w + 1'b1;
          if ((cnt_w == (IMAGE_W / 2 - 1))) cnt_h <= cnt_h + 1'b1;
        end
        default: ;
      endcase
    end
  end

  reg signed [IMAGE_SIZE+3-1:0] store_mult_h, store_mult_h0;
  reg ram_idle0;
  reg ram_idle1;
  reg zoom_sta_param;
  reg [1:0] ram_ch;



  always @(posedge clk) begin
    record_ram_valid <= (cnt_record_ram >= 2) ? 1'b1 : 1'b0;
    ram_idle0 <= ram_idle;
    ram_idle1 <= ram_idle0;
    zoom_sta_param <= (zoom_sta == PARAM) ? 1'b1 : 1'b0;
    judge_cnt_h_valid <= (((judge_cnt_h < (IMAGE_H / 2 - 1)) && (judge_cnt_h >= -(IMAGE_H / 2))) &&
                          (delay_cnt == MULT_DELAY + 2)) ? 1'b1 : 1'b0;
    if (zoom_sta == JUDGE) param_delay <= param_delay + 1'b1;
    else param_delay <= 'd0;
    if (delay_cnt == MULT_DELAY + 1) judge_cnt_h <= mult_h[FRA_WIDTH+:IMAGE_SIZE+3];
    if (zoom_sta == JUDGE) begin
      delay_cnt <= delay_cnt + 1'b1;
    end else delay_cnt <= 'd0;
    if ((zoom_sta == ZOOM) && (cnt_w == (IMAGE_W / 2 - 1))) rd_one_ram <= 1'b1;
    else rd_one_ram <= 'd0;
    if ((zoom_sta == ZOOM) && (cnt_w == (IMAGE_W / 2) - 1) && (cnt_h == (IMAGE_H / 2) - 1))
      zoom_done <= 1'b1;
    else zoom_done <= 'd0;
    if ((zoom_sta == PARAM) && (~ram_idle || (ram_idle0))) begin
      store_mult_h  <= mult_h[FRA_WIDTH+:IMAGE_SIZE+3];
      store_mult_h0 <= store_mult_h;
    end else begin
      store_mult_h  <= store_mult_h;
      store_mult_h0 <= store_mult_h0;
    end
    if (ram_idle1)
      if (zoom_sta_param) ram_ch <= ram_ch + (store_mult_h - store_mult_h0);
      else ram_ch <= ram_ch;
    else ram_ch <= 'd0;
  end
  reg [3+FRA_WIDTH-1:0] zoom_num0;
  reg wr_ram_done;
  always @(posedge clk) begin
    if (zoom_sta == IDLE) begin
      zoom_num0      <= zoom_num;
      cnt_record_ram <= 'd0;
    end else begin
      zoom_num0 <= zoom_num0;
      cnt_record_ram <= cnt_record_ram + (no_need_rd_ddr * 2) + wr_ram_done - (rd_one_ram * 2) +
          no_one_need_rd_ddr;
    end
  end
  mult_image_w u_image_w_mult (
      .CLK(clk),        // input wire CLK
      .A  (cnt_w),      // input wire [10 : 0] A
      .B  (zoom_num0),  // input wire [9 : 0] B
      .P  (mult_w)      // output wire [20 : 0] P
  );

  mult_image_w u_image_h_mult (
      .CLK(clk),         // input wire CLK
      .A  (mult_cnt_h),  // input wire [10 : 0] A
      .B  (zoom_num0),   // input wire [7 : 0] B
      .P  (mult_h)       // output wire [18 : 0] P
  );

  //image_w_mult u_image_w_mult (
  //  .a(cnt_w),        // input [10:0]
  //  .b(zoom_num0),        // input [9:0]
  //  .clk(clk),    // input
  //  .rst(rst),    // input
  //  .ce(1'b1),      // input
  //  .p(mult_w)         // output [20:0]
  //);
  //
  //image_w_mult u_image_h_mult (
  //  .a(cnt_h),        // input [10:0]
  //  .b(zoom_num0),        // input [9:0]
  //  .clk(clk),    // input
  //  .rst(rst),    // input
  //  .ce(1'b1),      // input
  //  .p(mult_h)         // output [20:0]
  //);
  // STORE RAM 

  reg [IMAGE_SIZE - 1:0] wr_addr0;
  reg [IMAGE_SIZE - 1:0] wr_addr1;
  reg [IMAGE_SIZE - 1:0] wr_addr2;
  reg [IMAGE_SIZE - 1:0] wr_addr3;
  reg [IMAGE_SIZE - 1:0] rd_addr;
  reg [IMAGE_SIZE - 1:0] rd_addr0;
  reg [IMAGE_SIZE - 1:0] rd_addr1;
  reg [IMAGE_SIZE - 1:0] rd_addr2;
  reg [IMAGE_SIZE - 1:0] rd_addr3;

  wire [15:0] doutb0, doutb0_0;
  wire [15:0] doutb1, doutb1_0;
  wire [15:0] doutb2, doutb2_0;
  wire [15:0] doutb3, doutb3_0;
  reg [3:0] ram_sta;
  //zoom_ram u_zoom_ram0 (
  //  .clka(clk),    // input wire clka
  //  .ena(data_in_valid0&(ram_sta[0])),      // input wire ena
  //  .wea(1'b1),      // input wire [0 : 0] wea
  //  .addra(wr_addr0),  // input wire [10 : 0] addra
  //  .dina(data_in0),    // input wire [15 : 0] dina
  //  .clkb(clk),    // input wire clkb
  //  .addrb(rd_addr0),  // input wire [10 : 0] addrb
  //  .doutb(doutb0)  // output wire [15 : 0] doutb
  //);
  //zoom_ram u_zoom_ram1 (
  //  .clka(clk),    // input wire clka
  //  .ena(data_in_valid1&(ram_sta[1])),      // input wire ena
  //  .wea(1'b1),      // input wire [0 : 0] wea
  //  .addra(wr_addr1),  // input wire [10 : 0] addra
  //  .dina(data_in1),    // input wire [15 : 0] dina
  //  .clkb(clk),    // input wire clkb
  //  .addrb(rd_addr1),  // input wire [10 : 0] addrb
  //  .doutb(doutb1)  // output wire [15 : 0] doutb
  //);
  //zoom_ram u_zoom_ram2 (
  //  .clka(clk),    // input wire clka
  //  .ena(data_in_valid2&(ram_sta[2])),      // input wire ena
  //  .wea(1'b1),      // input wire [0 : 0] wea
  //  .addra(wr_addr2),  // input wire [10 : 0] addra
  //  .dina(data_in2),    // input wire [15 : 0] dina
  //  .clkb(clk),    // input wire clkb
  //  .addrb(rd_addr2),  // input wire [10 : 0] addrb
  //  .doutb(doutb2)  // output wire [15 : 0] doutb
  //);
  //zoom_ram u_zoom_ram3 (
  //  .clka(clk),    // input wire clka
  //  .ena(data_in_valid3&(ram_sta[3])),      // input wire ena
  //  .wea(1'b1),      // input wire [0 : 0] wea
  //  .addra(wr_addr3),  // input wire [10 : 0] addra
  //  .dina(data_in3),    // input wire [15 : 0] dina
  //  .clkb(clk),    // input wire clkb
  //  .addrb(rd_addr3),  // input wire [10 : 0] addrb
  //  .doutb(doutb3)  // output wire [15 : 0] doutb
  //);
  //zoom_ram u_zoom_ram0_0 (
  //  .clka(clk),    // input wire clka
  //  .ena(data_in_valid0&(ram_sta[0])),      // input wire ena
  //  .wea(1'b1),      // input wire [0 : 0] wea
  //  .addra(wr_addr0),  // input wire [10 : 0] addra
  //  .dina(data_in0),    // input wire [15 : 0] dina
  //  .clkb(clk),    // input wire clkb
  //  .addrb(rd_addr0+1),  // input wire [10 : 0] addrb
  //  .doutb(doutb0_0)  // output wire [15 : 0] doutb
  //);
  //zoom_ram u_zoom_ram1_0 (
  //  .clka(clk),    // input wire clka
  //  .ena(data_in_valid1&(ram_sta[1])),      // input wire ena
  //  .wea(1'b1),      // input wire [0 : 0] wea
  //  .addra(wr_addr1),  // input wire [10 : 0] addra
  //  .dina(data_in1),    // input wire [15 : 0] dina
  //  .clkb(clk),    // input wire clkb
  //  .addrb(rd_addr1+1),  // input wire [10 : 0] addrb
  //  .doutb(doutb1_0)  // output wire [15 : 0] doutb
  //);
  //zoom_ram u_zoom_ram2_0 (
  //  .clka(clk),    // input wire clka
  //  .ena(data_in_valid2&(ram_sta[2])),      // input wire ena
  //  .wea(1'b1),      // input wire [0 : 0] wea
  //  .addra(wr_addr2),  // input wire [10 : 0] addra
  //  .dina(data_in2),    // input wire [15 : 0] dina
  //  .clkb(clk),    // input wire clkb
  //  .addrb(rd_addr2+1),  // input wire [10 : 0] addrb
  //  .doutb(doutb2_0)  // output wire [15 : 0] doutb
  //);
  //zoom_ram u_zoom_ram3_0 (
  //  .clka(clk),    // input wire clka
  //  .ena(data_in_valid3&(ram_sta[3])),      // input wire ena
  //  .wea(1'b1),      // input wire [0 : 0] wea
  //  .addra(wr_addr3),  // input wire [10 : 0] addra
  //  .dina(data_in3),    // input wire [15 : 0] dina
  //  .clkb(clk),    // input wire clkb
  //  .addrb(rd_addr3+1),  // input wire [10 : 0] addrb
  //  .doutb(doutb3_0)  // output wire [15 : 0] doutb
  //);
  zoom_ram zoom_ram0 (
      .wr_data(data_in0),                       // input [15:0]
      .wr_addr(wr_addr0),                       // input [10:0]
      .wr_en  (data_in_valid0 & (ram_sta[0])),  // input
      .wr_clk (clk),                            // input
      .wr_rst (1'b0),                           // input
      .rd_addr(rd_addr0),                       // input [10:0]
      .rd_data(doutb0),                         // output [15:0]
      .rd_clk (clk),                            // input
      .rd_rst (1'b0)                            // input
  );
  zoom_ram zoom_ram1 (
      .wr_data(data_in1),                       // input [15:0]
      .wr_addr(wr_addr1),                       // input [10:0]
      .wr_en  (data_in_valid1 & (ram_sta[1])),  // input
      .wr_clk (clk),                            // input
      .wr_rst (1'b0),                           // input
      .rd_addr(rd_addr1),                       // input [10:0]
      .rd_data(doutb1),                         // output [15:0]
      .rd_clk (clk),                            // input
      .rd_rst (1'b0)                            // input
  );
  zoom_ram zoom_ram2 (
      .wr_data(data_in2),                       // input [15:0]
      .wr_addr(wr_addr2),                       // input [10:0]
      .wr_en  (data_in_valid2 & (ram_sta[2])),  // input
      .wr_clk (clk),                            // input
      .wr_rst (1'b0),                           // input
      .rd_addr(rd_addr2),                       // input [10:0]
      .rd_data(doutb2),                         // output [15:0]
      .rd_clk (clk),                            // input
      .rd_rst (1'b0)                            // input
  );
  zoom_ram zoom_ram3 (
      .wr_data(data_in3),                       // input [15:0]
      .wr_addr(wr_addr3),                       // input [10:0]
      .wr_en  (data_in_valid3 & (ram_sta[3])),  // input
      .wr_clk (clk),                            // input
      .wr_rst (1'b0),                           // input
      .rd_addr(rd_addr3),                       // input [10:0]
      .rd_data(doutb3),                         // output [15:0]
      .rd_clk (clk),                            // input
      .rd_rst (1'b0)                            // input
  );
  //
  zoom_ram zoom_ram0_0 (
      .wr_data(data_in0),                       // input [15:0]
      .wr_addr(wr_addr0),                       // input [10:0]
      .wr_en  (data_in_valid0 & (ram_sta[0])),  // input
      .wr_clk (clk),                            // input
      .wr_rst (1'b0),                           // input
      .rd_addr(rd_addr0 + 1),                   // input [10:0]
      .rd_data(doutb0_0),                       // output [15:0]
      .rd_clk (clk),                            // input
      .rd_rst (1'b0)                            // input
  );
  zoom_ram zoom_ram1_0 (
      .wr_data(data_in1),                       // input [15:0]
      .wr_addr(wr_addr1),                       // input [10:0]
      .wr_en  (data_in_valid1 & (ram_sta[1])),  // input
      .wr_clk (clk),                            // input
      .wr_rst (1'b0),                           // input
      .rd_addr(rd_addr1 + 1),                   // input [10:0]
      .rd_data(doutb1_0),                       // output [15:0]
      .rd_clk (clk),                            // input
      .rd_rst (1'b0)                            // input
  );
  zoom_ram zoom_ram2_0 (
      .wr_data(data_in2),                       // input [15:0]
      .wr_addr(wr_addr2),                       // input [10:0]
      .wr_en  (data_in_valid2 & (ram_sta[2])),  // input
      .wr_clk (clk),                            // input
      .wr_rst (1'b0),                           // input
      .rd_addr(rd_addr2 + 1),                   // input [10:0]
      .rd_data(doutb2_0),                       // output [15:0]
      .rd_clk (clk),                            // input
      .rd_rst (1'b0)                            // input
  );
  zoom_ram zoom_ram3_0 (
      .wr_data(data_in3),                       // input [15:0]
      .wr_addr(wr_addr3),                       // input [10:0]
      .wr_en  (data_in_valid3 & (ram_sta[3])),  // input
      .wr_clk (clk),                            // input
      .wr_rst (1'b0),                           // input
      .rd_addr(rd_addr3 + 1),                   // input [10:0]
      .rd_data(doutb3_0),                       // output [15:0]
      .rd_clk (clk),                            // input
      .rd_rst (1'b0)                            // input
  );
  reg data_half_valid, data_half_valid0, data_half_valid1;
  always @(posedge clk) begin
    if (zoom_sta == IDLE) begin
      ram_sta <= 4'b0001;
      wr_ram_done <= 1'b0;
    end else begin
      case (ram_sta)
        4'b0001: begin
          if (((wr_addr0 == IMAGE_W - 1) || (data_half_valid && (wr_addr0 == IMAGE_W / 2 - 1))) &&
              (data_in_valid0)) begin
            wr_ram_done <= 1'b1;
            ram_sta <= 4'b0010;
          end else begin
            wr_ram_done <= 1'b0;
            ram_sta <= 4'b0001;
          end
        end
        4'b0010: begin
          if (((wr_addr1 == IMAGE_W - 1) || (data_half_valid && (wr_addr1 == IMAGE_W / 2 - 1))) &&
              (data_in_valid0)) begin
            wr_ram_done <= 1'b1;
            ram_sta <= 4'b0100;
          end else begin
            wr_ram_done <= 1'b0;
            ram_sta <= 4'b0010;
          end
        end
        4'b0100: begin
          if (((wr_addr2 == IMAGE_W - 1) || (data_half_valid && (wr_addr2 == IMAGE_W / 2 - 1))) &&
              (data_in_valid0)) begin
            wr_ram_done <= 1'b1;
            ram_sta <= 4'b1000;
          end else begin
            wr_ram_done <= 1'b0;
            ram_sta <= 4'b0100;
          end
        end
        4'b1000: begin
          if (((wr_addr3 == IMAGE_W - 1) || (data_half_valid && (wr_addr3 == IMAGE_W / 2 - 1))) &&
              (data_in_valid0)) begin
            wr_ram_done <= 1'b1;
            ram_sta <= 4'b0001;
          end else begin
            wr_ram_done <= 1'b0;
            ram_sta <= 4'b1000;
          end
        end
        default: ram_sta <= 4'b1000;
      endcase
    end
  end
  always @(posedge clk) begin
    if (rst) begin
      wr_addr0 <= 'd0;
    end else begin
      if (ram_sta[0]) begin
        if (data_in_valid0) wr_addr0 <= wr_addr0 + 1'b1;
        else wr_addr0 <= wr_addr0;
      end else wr_addr0 <= 'd0;
    end
    if (ram_sta[1]) begin
      if (data_in_valid1) wr_addr1 <= wr_addr1 + 1'b1;
      else wr_addr1 <= wr_addr1;
    end else wr_addr1 <= 'd0;
    if (ram_sta[2]) begin
      if (data_in_valid2) wr_addr2 <= wr_addr2 + 1'b1;
      else wr_addr2 <= wr_addr2;
    end else wr_addr2 <= 'd0;
    if (ram_sta[3]) begin
      if (data_in_valid3) wr_addr3 <= wr_addr3 + 1'b1;
      else wr_addr3 <= wr_addr3;
    end else wr_addr3 <= 'd0;
  end




  reg imag_addr_valid0, imag_addr_valid1;





  reg signed [IMAGE_SIZE+FRA_WIDTH-1:0] imag_addr0;
  wire signed [IMAGE_SIZE-1:0] mult_h1;
  wire signed [IMAGE_SIZE+3-1:0] mult_h2, store_addr_add_one;
  reg signed [IMAGE_SIZE+3-1:0] store_addr;


  reg signed [IMAGE_SIZE+3-1:0] mult_h0;
  reg zoom_sta_param0;
  reg zoom_sta_param1;
  assign mult_h1 = mult_h0[0+:IMAGE_SIZE];
  assign mult_h2 = mult_h0[0+:IMAGE_SIZE+3];
  assign store_addr_add_one = store_addr + 1'b1;

  always @(posedge clk) begin
    zoom_sta_param0 <= zoom_sta_param;
    zoom_sta_param1 <= zoom_sta_param0;
    if (zoom_sta_param0) mult_h0 <= mult_h[FRA_WIDTH+:IMAGE_SIZE+3];
    else mult_h0 <= mult_h0;
  end
  reg [4:0] addr_sta;
  always @(posedge clk) begin
    if (rst) begin
      addr_sta <= 'd1;
    end else begin
      no_need_rd_ddr = 1'b0;
      no_one_need_rd_ddr = 1'b0;
      case (addr_sta)
        'd1: begin
          imag_addr0 <= imag_addr0;
          //if((mult_h0>=-(IMAGE_H/2)&&mult_h0<(IMAGE_H/2-1)&&(zoom_sta_param1)))
          if ((mult_h2 < (IMAGE_H / 2) && (zoom_sta_param1)))
            //if(zoom_sta_param1)
            addr_sta <= 'd2;
          else addr_sta <= 'd1;
        end
        'd2: begin
          imag_addr0 <= imag_addr0;
          //if((mult_h0[0+:IMAGE_SIZE+3] != store_addr)|(~ram_idle))
          if ((mult_h2 != store_addr) | (~ram_idle)) addr_sta <= 'd4;
          else begin
            no_need_rd_ddr = 1'b1;
            addr_sta <= 'd1;
          end
        end
        'd4: begin
          //if(mult_h0[0+:IMAGE_SIZE+3] == (store_addr+1))
          if (mult_h2 == (store_addr_add_one)) begin
            addr_sta   <= 'd16;
            //no_one_need_rd_ddr = 1'b1 ;
            imag_addr0 <= mult_h1 + 1'b1;
          end else begin
            addr_sta   <= 'd8;
            imag_addr0 <= mult_h1;
          end
        end
        'd8: begin
          addr_sta   <= 'd1;
          imag_addr0 <= mult_h1 + 1'b1;
        end
        'd16: begin
          if (wr_ram_done) begin
            addr_sta <= 'd1;
            no_one_need_rd_ddr = 1'b1;
          end else begin
            addr_sta <= 'd16;
            no_one_need_rd_ddr = 1'b0;
          end
        end
        default: ;
      endcase
    end
  end
  reg data_half_en0;
  always @(posedge clk) begin
    if (zoom_sta == IDLE) data_half_en0 <= data_half_en;
    else data_half_en0 <= data_half_en0;
    if (zoom_sta == IDLE) data_half_valid <= 'd0;
    else if ((imag_addr_valid & (~imag_addr_valid0)) && (imag_addr >= IMAGE_H / 2))
      data_half_valid <= data_half_en0;
    else data_half_valid <= data_half_valid;
  end
  reg signed  [IMAGE_SIZE-1:0] imag_addr1;
  wire signed [IMAGE_SIZE-1:0] add_imag_addr = IMAGE_H / 2;
  always @(posedge clk) begin
    if (addr_sta == 'd4) store_addr <= mult_h0[0+:IMAGE_SIZE+3];
    else store_addr <= store_addr;
  end
  assign imag_addr_valid = imag_addr_valid1;
  assign imag_addr       = imag_addr1;
  always @(posedge clk) begin
    imag_addr_valid0 <= ((addr_sta == 'd8) || (addr_sta == 'd4)) ? 1'b1 : 1'b0;
    imag_addr_valid1 <= imag_addr_valid0;
    imag_addr1       <= imag_addr0 + add_imag_addr;
  end



  reg signed [IMAGE_SIZE+FRA_WIDTH+3-1:0]
      image_w0, image_w1, image_w2, image_h0, image_h1, image_h2;
  wire [IMAGE_SIZE+FRA_WIDTH+3-1:0] image_w2_unsigned, image_h2_unsigned;
  reg [IMAGE_SIZE+FRA_WIDTH+3-1:0] zoom_num1;
  wire signed [IMAGE_SIZE+FRA_WIDTH+3-1:0] add_image_w, add_image_h;
  assign add_image_w = (IMAGE_W / 2) * FRA_WIDTH_power - FRA_WIDTH_power / 2;
  assign add_image_h = (IMAGE_H / 2) * FRA_WIDTH_power - FRA_WIDTH_power / 2;
  assign image_w2_unsigned = image_w2[FRA_WIDTH+:IMAGE_SIZE+3];
  assign image_h2_unsigned = image_h2[FRA_WIDTH+:IMAGE_SIZE+3];
  always @(posedge clk) begin
    image_w0 <= mult_w + add_image_w;
    image_h0 <= mult_h + add_image_h;
    image_w1 <= image_w0 + zoom_num1;
    image_h1 <= image_h0 + zoom_num1;
    if (coe_valid[2]) rd_addr <= image_w1[FRA_WIDTH+:IMAGE_SIZE];
    else rd_addr <= rd_addr + 1'b1;
    rd_addr0 <= rd_addr;
    rd_addr1 <= rd_addr;
    rd_addr2 <= rd_addr;
    rd_addr3 <= rd_addr;
    //	rd_addr0  <= image_w1[FRA_WIDTH+:IMAGE_SIZE];// rd_addr valid ->delay = 3 
    //	rd_addr1  <= image_w1[FRA_WIDTH+:IMAGE_SIZE];
    //	rd_addr2  <= image_w1[FRA_WIDTH+:IMAGE_SIZE];
    //	rd_addr3  <= image_w1[FRA_WIDTH+:IMAGE_SIZE];

  end
  reg [1:0] ram_ch0;
  reg [1:0] ram_ch1;
  reg [1:0] ram_ch2;
  reg [16*2-1:0] rd_data, rd_data0;
  reg [16*2-1:0] rd_data_0, rd_data0_0;
  reg [6:0]
      image_w2_coe,
      image_w2_coe0,
      image_w2_coe1,
      image_w2_coe2,
      image_w2_coe3,
      image_h2_coe,
      image_h2_coe0,
      image_h2_coe1,
      image_h2_coe2;
  always @(posedge clk) begin
    zoom_num1 <= zoom_num0 >> 1;
    ram_ch0 <= ram_ch;
    ram_ch1 <= ram_ch0;
    ram_ch2 <= ram_ch1;
    image_w2 <= image_w1;
    image_h2 <= image_h1;
    image_w2_coe <= image_w2[FRA_WIDTH-1:0];
    image_h2_coe <= image_h2[FRA_WIDTH-1:0];
  end
  always @(posedge clk) begin
    rd_data0   <= rd_data;
    rd_data0_0 <= rd_data_0;
    case (ram_ch2)
      2'd0: begin
        rd_data   <= {doutb0, doutb1};
        rd_data_0 <= {doutb0_0, doutb1_0};
      end
      2'd1: begin
        rd_data   <= {doutb1, doutb2};
        rd_data_0 <= {doutb1_0, doutb2_0};
      end
      2'd2: begin
        rd_data   <= {doutb2, doutb3};
        rd_data_0 <= {doutb2_0, doutb3_0};
      end
      2'd3: begin
        rd_data   <= {doutb3, doutb0};
        rd_data_0 <= {doutb3_0, doutb0_0};
      end
      default: begin
        rd_data   <= rd_data;
        rd_data_0 <= rd_data_0;
      end
    endcase
  end



  reg [7:0] coe0, coe1, coe2, coe3;
  reg [7:0] coe0_0, coe1_0, coe2_0, coe3_0;

  reg [2:0] image_valid[7:0];
  reg [1:0] image_w_valid, image_h_valid;
  reg image_blank_valid;
  generate
    genvar a;
    for (a = 0; a < 8; a = a + 1) begin
      always @(posedge clk)
        if (a == 0) image_valid[a] <= {image_blank_valid, image_h_valid | image_w_valid};
        else image_valid[a] <= image_valid[a-1];
    end
  endgenerate
  always @(posedge clk) begin
    coe_valid <= {coe_valid[5:0], {((zoom_sta == ZOOM || zoom_sta == BLANK)) ? 1'b1 : 1'b0}};
    if (coe_valid[3]) begin
      if ((image_w2[IMAGE_SIZE+FRA_WIDTH+3-1] == 1'b1) || (image_w2 >= (IMAGE_W) * FRA_WIDTH_power))
        image_w_valid <= 2'b01;
      else image_w_valid <= 2'b10;
      if ((image_h2[IMAGE_SIZE+FRA_WIDTH+3-1] == 1'b1) ||
          (image_h2 >= (IMAGE_H - 1) * FRA_WIDTH_power))
        image_h_valid <= 2'b01;
      else image_h_valid <= 2'b10;
      if ((image_h2 >= (IMAGE_H / 2) * FRA_WIDTH_power) &
          (image_w2 >= (IMAGE_W / 2) * FRA_WIDTH_power))
        image_blank_valid <= 'b1;
      else image_blank_valid <= 'b0;
    end else begin
      image_h_valid <= 'd0;
      image_w_valid <= 'd0;
      image_blank_valid <= 'd0;
    end
    coe0 <= FRA_WIDTH_power - image_w2_coe1;  // image_w2_coe ->delay =  5
    coe2 <= FRA_WIDTH_power - image_w2_coe1;
    coe1 <= FRA_WIDTH_power - image_h2_coe1;
    coe3 <= image_h2_coe1;
    coe0_0 <= image_w2_coe1;  // image_w2_coe ->delay =  5
    coe2_0 <= image_w2_coe1;
    coe1_0 <= FRA_WIDTH_power - image_h2_coe1;
    coe3_0 <= image_h2_coe1;
    image_w2_coe0 <= image_w2_coe;
    image_w2_coe1 <= image_w2_coe0;
    image_w2_coe2 <= image_w2_coe1;
    image_w2_coe3 <= image_w2_coe2;
    image_h2_coe0 <= image_h2_coe;
    image_h2_coe1 <= image_h2_coe0;
    image_h2_coe2 <= image_h2_coe1;
  end
  wire [15:0] coe_mult_p0, coe_mult_p1;
  wire [15:0] coe_mult_p0_0, coe_mult_p1_0;
  mult_fra0 mult_fra0 (
      .CLK(clk),         // input wire CLK
      .A  (coe0),        // input wire [7 : 0] A
      .B  (coe1),        // input wire [7 : 0] B
      .P  (coe_mult_p0)  // output wire [15 : 0] P
  );
  mult_fra0 mult_fra1 (
      .CLK(clk),         // input wire CLK
      .A  (coe2),        // input wire [7 : 0] A
      .B  (coe3),        // input wire [7 : 0] B
      .P  (coe_mult_p1)  // output wire [15 : 0] P
  );
  mult_fra0 mult_fra0_0 (
      .CLK(clk),           // input wire CLK
      .A  (coe0_0),        // input wire [7 : 0] A
      .B  (coe1_0),        // input wire [7 : 0] B
      .P  (coe_mult_p0_0)  // output wire [15 : 0] P
  );
  mult_fra0 mult_fra1_0 (
      .CLK(clk),           // input wire CLK
      .A  (coe2_0),        // input wire [7 : 0] A
      .B  (coe3_0),        // input wire [7 : 0] B
      .P  (coe_mult_p1_0)  // output wire [15 : 0] P
  );

  wire [14:0] mult_image0  [5:0];
  wire [14:0] mult_image0_0[5:0];
  // rd_data valid -> delay = 4 
  mult_image_ip mult_image_r0 (
      .CLK(clk),                      // input wire CLK
      .A  (coe_mult_p0[15:7]),        // input wire [8 : 0] A
      .B  ({1'b0, rd_data0[15:11]}),  // input wire [5 : 0] B
      .P  (mult_image0[0])            // output wire [14 : 0] P
  );
  mult_image_ip mult_image_r1 (
      .CLK(clk),                      // input wire CLK
      .A  (coe_mult_p1[15:7]),        // input wire [8 : 0] A
      .B  ({1'b0, rd_data0[31:27]}),  // input wire [5 : 0] B
      .P  (mult_image0[1])            // output wire [14 : 0] P
  );
  mult_image_ip mult_image_g0 (
      .CLK(clk),                // input wire CLK
      .A  (coe_mult_p0[15:7]),  // input wire [8 : 0] A
      .B  ({rd_data0[10:5]}),   // input wire [5 : 0] B
      .P  (mult_image0[2])      // output wire [14 : 0] P
  );
  mult_image_ip mult_image_g1 (
      .CLK(clk),                // input wire CLK
      .A  (coe_mult_p1[15:7]),  // input wire [8 : 0] A
      .B  ({rd_data0[26:21]}),  // input wire [5 : 0] B
      .P  (mult_image0[3])      // output wire [14 : 0] P
  );
  mult_image_ip mult_image_b0 (
      .CLK(clk),                    // input wire CLK
      .A  (coe_mult_p0[15:7]),      // input wire [8 : 0] A
      .B  ({1'b0, rd_data0[4:0]}),  // input wire [5 : 0] B
      .P  (mult_image0[4])          // output wire [14 : 0] P
  );
  mult_image_ip mult_image_b1 (
      .CLK(clk),                      // input wire CLK
      .A  (coe_mult_p1[15:7]),        // input wire [8 : 0] A
      .B  ({1'b0, rd_data0[20:16]}),  // input wire [5 : 0] B
      .P  (mult_image0[5])            // output wire [14 : 0] P
  );
  // new add 
  mult_image_ip mult_image_r0_0 (
      .CLK(clk),                        // input wire CLK
      .A  (coe_mult_p0_0[15:7]),        // input wire [8 : 0] A
      .B  ({1'b0, rd_data0_0[15:11]}),  // input wire [5 : 0] B
      .P  (mult_image0_0[0])            // output wire [14 : 0] P
  );
  mult_image_ip mult_image_r1_0 (
      .CLK(clk),                        // input wire CLK
      .A  (coe_mult_p1_0[15:7]),        // input wire [8 : 0] A
      .B  ({1'b0, rd_data0_0[31:27]}),  // input wire [5 : 0] B
      .P  (mult_image0_0[1])            // output wire [14 : 0] P
  );
  mult_image_ip mult_image_g0_0 (
      .CLK(clk),                  // input wire CLK
      .A  (coe_mult_p0_0[15:7]),  // input wire [8 : 0] A
      .B  ({rd_data0_0[10:5]}),   // input wire [5 : 0] B
      .P  (mult_image0_0[2])      // output wire [14 : 0] P
  );
  mult_image_ip mult_image_g1_0 (
      .CLK(clk),                  // input wire CLK
      .A  (coe_mult_p1_0[15:7]),  // input wire [8 : 0] A
      .B  ({rd_data0_0[26:21]}),  // input wire [5 : 0] B
      .P  (mult_image0_0[3])      // output wire [14 : 0] P
  );
  mult_image_ip mult_image_b0_0 (
      .CLK(clk),                      // input wire CLK
      .A  (coe_mult_p0_0[15:7]),      // input wire [8 : 0] A
      .B  ({1'b0, rd_data0_0[4:0]}),  // input wire [5 : 0] B
      .P  (mult_image0_0[4])          // output wire [14 : 0] P
  );
  mult_image_ip mult_image_b1_0 (
      .CLK(clk),                        // input wire CLK
      .A  (coe_mult_p1_0[15:7]),        // input wire [8 : 0] A
      .B  ({1'b0, rd_data0_0[20:16]}),  // input wire [5 : 0] B
      .P  (mult_image0_0[5])            // output wire [14 : 0] P
  );
  reg [15:0] mult_image1  [2:0];
  reg [15:0] mult_image2  [2:0];
  //reg [16:0] mult_image3[2:0];
  reg [15:0] mult_image1_0[2:0];
  generate
    genvar i;
    for (i = 0; i < 3; i = i + 1) begin
      always @(posedge clk) begin
        mult_image1[i]   <= mult_image0[2*i] + mult_image0[2*i+1];
        mult_image2[i]   <= mult_image1[i] + mult_image1_0[i];
        //mult_image3[i] <= mult_image1[i] + mult_image2[i] ;
        mult_image1_0[i] <= mult_image0_0[2*i] + mult_image0_0[2*i+1];
      end
    end
  endgenerate


  wire [15:0] data_out0;
  reg [15:0] data_out1;
  reg data_out_valid1;
  assign data_out0 = {
    mult_image2[0][FRA_WIDTH+:5], mult_image2[1][FRA_WIDTH+:6], mult_image2[2][FRA_WIDTH+:5]
  };
  // 3 + 4 + 4 
  always @(posedge clk) begin
    //hdmi_out_en0 <= hdmi_out_en ;
    if (image_valid[6][0]) data_out1 <= 'd0;
    else data_out1 <= data_out0;
    //if((((~image_valid[7][2])|hdmi_out_en0)&(image_valid[7][1]|image_valid[7][0])))
    //data_out1 <= data_out0 ;
    if (image_valid[6][1] | image_valid[6][0]) data_out_valid1 <= 1'b1;
    else data_out_valid1 <= 1'b0;
  end




  reg [15:0] data_out2;
  reg data_out_valid2;
  reg hdmi_out_en0;
  always @(posedge clk) begin
    if (rst) hdmi_out_en0 <= 'd0;
    else if (zoom_sta == IDLE) hdmi_out_en0 <= hdmi_out_en;
    else hdmi_out_en0 <= hdmi_out_en0;
    //data_out2    <= data_out1 ;
  end


  reg [IMAGE_SIZE-1:0] cnt_ww, cnt_hh;
  always @(posedge clk) begin
    if (rst) cnt_ww <= 'd0;
    else begin
      if (data_out_valid1)
        if (cnt_ww == IMAGE_W - 1) cnt_ww <= 'd0;
        else cnt_ww <= cnt_ww + 1'b1;
    end
  end
  always @(posedge clk) begin
    if (rst) cnt_hh <= 'd0;
    else begin
      if ((data_out_valid1) && ((cnt_ww == IMAGE_W - 1))) begin
        if ((cnt_hh == IMAGE_H - 1)) cnt_hh <= 'd0;
        else cnt_hh <= cnt_hh + 1'b1;
      end
    end
  end
  reg hdmi_out_en1;
  always @(posedge clk) begin
    hdmi_out_en1    <= hdmi_out_en0 ;
    data_out_valid2 <= data_out_valid1 ;
    //if((cnt_hh>=IMAGE_H/2)&&((cnt_ww >= IMAGE_W/2))&&hdmi_out_en0)
    //     data_out_valid2 <= 'd0 ;
    //else 
    //     data_out_valid2 <= data_out_valid1 ;
  end
  always @(posedge clk) begin
    data_out2 <= data_out1;
    //if((cnt_hh>=IMAGE_H/2))
    //     data_out2 <= 16'hffff ;
    //else 
    //     data_out2 <= data_out1 ;
  end

  assign data_out = data_out2;
  assign data_out_valid = data_out_valid2;

endmodule
