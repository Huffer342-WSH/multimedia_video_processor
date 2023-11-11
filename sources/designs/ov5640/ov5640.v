`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 2023/10/13 23:03:50
// Design Name: 
// Module Name: mix_image
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


module ov5640 #(
    parameter   IMAGE_SIZE = 11,
    parameter   IMAGE_W    = 1280,
    parameter   IMAGE_H    = 720
) (
    input clk_50M,
    input clk_25M,
    input rst,

    inout        cmos1_scl,    //cmos1 i2c 
    inout        cmos1_sda,    //cmos1 i2c 
    input        cmos1_vsync,  //cmos1 vsync
    input        cmos1_href,   //cmos1 hsync refrence,data valid
    input        cmos1_pclk,   //cmos1 pxiel clock
    input  [7:0] cmos1_data,   //cmos1 data
    output       cmos1_reset,  //cmos1 reset

    inout        cmos2_scl,    //cmos2 i2c 
    inout        cmos2_sda,    //cmos2 i2c 
    input        cmos2_vsync,  //cmos2 vsync
    input        cmos2_href,   //cmos2 hsync refrence,data valid
    input        cmos2_pclk,   //cmos2 pxiel clock
    input  [7:0] cmos2_data,   //cmos2 data
    output       cmos2_reset,  //cmos2 reset

    input                wr_clk,
    input                wr_rst,
    input         [ 7:0] shift_w,
    input  signed [ 7:0] shift_h,
    output               data_vs,
    output               data_out_valid,
    output        [15:0] data_out
);


  wire [1:0] cmos_init_done;
  wire initial_en;
  //配置CMOS///////////////////////////////////////////////////////////////////////////////////
  //OV5640 register configure enable    
  power_on_delay power_on_delay_inst (
      .clk_50M     (clk_50M),      //input
      .reset_n     (~rst),         //input	
      .camera1_rstn(cmos1_reset),  //output
      .camera2_rstn(cmos2_reset),  //output	
      .camera_pwnd (),             //output
      .initial_en  (initial_en)    //output		
  );
  //CMOS1 Camera 
  reg_config coms1_reg_config (
      .clk_25M      (clk_25M),            //input
      .camera_rstn  (cmos1_reset),        //input
      .initial_en   (initial_en),         //input		
      .i2c_sclk     (cmos1_scl),          //output
      .i2c_sdat     (cmos1_sda),          //inout
      .reg_conf_done(cmos_init_done[0]),  //output config_finished
      .reg_index    (),                   //output reg [8:0]
      .clock_20k    ()                    //output reg
  );

  //CMOS2 Camera 
  reg_config coms2_reg_config (
      .clk_25M      (clk_25M),            //input
      .camera_rstn  (cmos2_reset),        //input
      .initial_en   (initial_en),         //input		
      .i2c_sclk     (cmos2_scl),          //output
      .i2c_sdat     (cmos2_sda),          //inout
      .reg_conf_done(cmos_init_done[1]),  //output config_finished
      .reg_index    (),                   //output reg [8:0]
      .clock_20k    ()                    //output reg
  );

  //CMOS1

  reg [7:0] cmos1_d_d0, cmos1_d_d1;
  reg cmos1_href_d0, cmos1_href_d1;
  reg cmos1_vsync_d0, cmos1_vsync_d1;
  wire [15:0] cmos1_d_16bit;
  wire cmos1_href_16bit;
  wire [15:0] cmos2_d_16bit;
  wire cmos2_href_16bit;
  wire cmos1_vsync0, cmos2_vsync0;
  wire pclk1, pclk2;


  wire cmos1_pclk_bufg;
  wire cmos1_pclk0 = ~cmos1_pclk;
  //GTP_CLKBUFG U_GTP_CLKBUFG(
  //    .CLKOUT(cmos1_pclk_bufg),// OUTPUT  
  //    .CLKIN(cmos1_pclk0)  // INPUT  
  //);
  always @(posedge cmos1_pclk) begin
    cmos1_d_d0     <= cmos1_data;
    cmos1_d_d1     <= cmos1_d_d0;
    cmos1_href_d0  <= cmos1_href;
    cmos1_href_d1  <= cmos1_href_d0;
    cmos1_vsync_d0 <= cmos1_vsync;
    cmos1_vsync_d1 <= cmos1_vsync_d0;
  end
  //cmos_8_16bit cmos1_8_16bit(
  //	.pclk_in            (cmos1_pclk       ),//input
  //	.rst             (~cmos_init_done[0]),//input
  //	//.rst             (0),//input
  //	.pdata_i         (cmos1_d_d1       ),//input[7:0]
  //	.de_i            (cmos1_href_d1    ),//input
  //	.vs_i            (cmos1_vsync_d1    ),//input
  //	
  //	.image_data_valid(cmos1_href_16bit    ),//output[15:0]
  //	.image_data      (cmos1_d_16bit ), //output cmos1_d_16bit
  //    .vs_o            (cmos1_vsync0),
  //    .pclk            (pclk1)
  //);

  //CMOS2
  reg [7:0] cmos2_d_d0, cmos2_d_d1;
  reg cmos2_href_d0, cmos2_href_d1;
  reg cmos2_vsync_d0, cmos2_vsync_d1;

  always @(posedge cmos2_pclk) begin
    cmos2_d_d0     <= cmos2_data;
    cmos2_d_d1     <= cmos2_d_d0;
    cmos2_href_d0  <= cmos2_href;
    cmos2_href_d1  <= cmos2_href_d0;
    cmos2_vsync_d0 <= cmos2_vsync;
    cmos2_vsync_d1 <= cmos2_vsync_d0;
  end
  cmos_8_16bit cmos1_8_16bit (
      .pclk_in(cmos1_pclk),          //input
      .rst    (~cmos_init_done[0]),  //input
      //.rst             (0),//input
      .pdata_i(cmos1_d_d1),          //input[7:0]
      .de_i   (cmos1_href_d1),       //input
      .vs_i   (cmos1_vsync_d1),      //input

      .image_data_valid(cmos1_href_16bit),  //output[15:0]
      .image_data      (cmos1_d_16bit),     //output cmos1_d_16bit
      .vs_o            (cmos1_vsync0),
      .pclk            (pclk1)
  );
  cmos_8_16bit cmos2_8_16bit (
      .pclk_in(cmos2_pclk),          //input
      .rst    (~cmos_init_done[1]),  //input
      //.rst             (0),//input
      .pdata_i(cmos2_d_d1),          //input[7:0]
      .de_i   (cmos2_href_d1),       //input
      .vs_i   (cmos2_vsync_d1),      //input

      .image_data_valid(cmos2_href_16bit),  //output[15:0]
      .image_data      (cmos2_d_16bit),
      //output cmos2_d_16bit
      .vs_o            (cmos2_vsync0),
      .pclk            (pclk2)
  );
  //cmos_8_16bit_v1 cmos1_8_16bit(
  //    	.pclk           (cmos1_pclk       ),//input
  //    	.rst_n          (cmos_init_done[0]),//input
  //    	.pdata_i        (cmos1_d_d0       ),//input[7:0]
  //    	.de_i           (cmos1_href_d0    ),//input
  //    	.vs_i           (cmos1_vsync_d0    ),//input
  //    	
  //    	.pixel_clk      (pclk1 ),//output
  //    	.pdata_o        (cmos1_d_16bit    ),//output[15:0]
  //    	.de_o           (cmos1_href_16bit ) //output
  //    );
  //cmos_8_16bit_v1 cmos2_8_16bit(
  //    	.pclk           (cmos2_pclk       ),//input
  //    	.rst_n          (cmos_init_done[1]),//input
  //    	.pdata_i        (cmos2_d_d0       ),//input[7:0]
  //    	.de_i           (cmos2_href_d0    ),//input
  //    	.vs_i           (cmos2_vsync_d0    ),//input
  //    	
  //    	.pixel_clk      (pclk2 ),//output
  //    	.pdata_o        (cmos2_d_16bit    ),//output[15:0]
  //    	.de_o           (cmos2_href_16bit ) //output
  //    );
  mix_image #(
      .IMAGE_SIZE(IMAGE_SIZE),
      .IMAGE_W   (IMAGE_W),
      .IMAGE_H   (IMAGE_H)
  ) u_mix_image (
      .clk    (wr_clk),
      .rst    (wr_rst),
      .shift_w(shift_w),
      .shift_h(shift_h),

      .cmos1_vsync(cmos1_vsync_d1),
      .cmos1_href (cmos1_href_16bit),
      .cmos1_pclk (pclk1),
      .cmos1_data (cmos1_d_16bit),

      .cmos2_vsync(cmos2_vsync_d1),
      .cmos2_href (cmos2_href_16bit),
      .cmos2_pclk (pclk2),
      .cmos2_data (cmos2_d_16bit),

      .data_vs       (data_vs),
      .data_out_valid(data_out_valid),
      .data_out      (data_out)
  );


endmodule
