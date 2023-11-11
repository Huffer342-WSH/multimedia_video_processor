//紫光使用该文件，Xilinx使用gmii_to_rgmii_vivado.v


`timescale 1ns / 1ps

`define UD #1  //前仿真延迟

module gmii_to_rgmii (

    output gmii_clk,

    input       gmii_txd_valid,
    input [7:0] gmii_txd_data,

    output reg       gmii_rxd_valid,
    output reg [7:0] gmii_rxd_data,

    input       rgmii_rxc,
    input       rgmii_rx_ctl,
    input [3:0] rgmii_rxd,

    output       rgmii_txc,
    output       rgmii_tx_ctl,
    output [3:0] rgmii_txd
);
  parameter IDELAY_VALUE = 0;

  //=============================================================
  //  RGMII TX 
  //=============================================================
  wire       rgmii_txc_obuf;
  wire       rgmii_txc_tbuf;
  wire       rgmii_tx_ctl_obuf;
  wire       rgmii_tx_ctl_tbuf;
  wire [3:0] rgmii_txd_obuf;
  wire [3:0] rgmii_txd_tbuf;

  generate
    genvar i;
    for (i = 0; i < 4; i = i + 1) begin : rgmii_tx_data
      GTP_OSERDES #(
          .OSERDES_MODE("ODDR"),   //"ODDR","OMDDR","OGSER4","OMSER4","OGSER7","OGSER8",OMSER8"
          .WL_EXTEND   ("FALSE"),  //"TRUE"; "FALSE"
          .GRS_EN      ("TRUE"),   //"TRUE"; "FALSE"
          .LRS_EN      ("TRUE"),   //"TRUE"; "FALSE"
          .TSDDR_INIT  (1'b0)      //1'b0;1'b1
      ) tx_data_oddr (
          .DO    (rgmii_txd_obuf[i]),
          .TQ    (rgmii_txd_tbuf[i]),
          .DI    ({6'd0, gmii_txd_data[i+4], gmii_txd_data[i]}),
          .TI    (4'd0),
          .RCLK  (gmii_clk),
          .SERCLK(gmii_clk),
          .OCLK  (1'd0),
          .RST   (1'b0)
      );

      GTP_OUTBUFT gtp_outbuft1 (
          .I(rgmii_txd_obuf[i]),
          .T(rgmii_txd_tbuf[i]),
          .O(rgmii_txd[i])
      );
    end
  endgenerate

  GTP_OSERDES #(
      .OSERDES_MODE("ODDR"),   //"ODDR","OMDDR","OGSER4","OMSER4","OGSER7","OGSER8",OMSER8"
      .WL_EXTEND   ("FALSE"),  //"TRUE"; "FALSE"
      .GRS_EN      ("TRUE"),   //"TRUE"; "FALSE"
      .LRS_EN      ("TRUE"),   //"TRUE"; "FALSE"
      .TSDDR_INIT  (1'b0)      //1'b0;1'b1
  ) tx_ctl_oddr (
      .DO    (rgmii_tx_ctl_obuf),
      .TQ    (rgmii_tx_ctl_tbuf),
      .DI    ({6'd0, gmii_txd_valid ^ 1'b0, gmii_txd_valid}),
      .TI    (4'd0),
      .RCLK  (gmii_clk),
      .SERCLK(gmii_clk),
      .OCLK  (1'd0),
      .RST   (tx_reset_sync)
  );

  GTP_OUTBUFT gtp_outbuft1 (
      .I(rgmii_tx_ctl_obuf),
      .T(rgmii_tx_ctl_tbuf),
      .O(rgmii_tx_ctl)
  );


  GTP_OSERDES #(
      .OSERDES_MODE("ODDR"),   //"ODDR","OMDDR","OGSER4","OMSER4","OGSER7","OGSER8",OMSER8"
      .WL_EXTEND   ("FALSE"),  //"TRUE"; "FALSE"
      .GRS_EN      ("TRUE"),   //"TRUE"; "FALSE"
      .LRS_EN      ("TRUE"),   //"TRUE"; "FALSE"
      .TSDDR_INIT  (1'b0)      //1'b0;1'b1
  ) tx_clk_oddr (
      .DO    (rgmii_txc_obuf),
      .TQ    (rgmii_txc_tbuf),
      .DI    ({7'd0, 1'b1}),
      .TI    (4'd0),
      .RCLK  (gmii_clk),
      .SERCLK(gmii_clk),
      .OCLK  (1'd0),
      .RST   (tx_reset_sync)
  );
  GTP_OUTBUFT gtp_outbuft6 (

      .I(rgmii_txc_obuf),
      .T(rgmii_txc_tbuf),
      .O(rgmii_txc)
  );



  //=============================================================
  //  RGMII RX 
  //=============================================================
  wire       rgmii_rxc_ibuf;
  wire       rgmii_rxc_bufio;
  wire       rgmii_rx_ctl_ibuf;
  wire [3:0] rgmii_rxd_ibuf;

  wire [7:0] delay_step_b;
  wire [7:0] delay_step_gray;

  assign delay_step_b = 8'hA0;  // 0~247 , 10ps/step

  wire lock;

  // rgmii_rxc 延迟并缓冲
  //将输入时钟 CLKIN 和延迟单元延时之间的关系转化为数字码
  GTP_DLL #(
      .GRS_EN("TRUE"),
      .FAST_LOCK("TRUE"),
      .DELAY_STEP_OFFSET(0)  //-4~4
  ) clk_dll (
      .DELAY_STEP(delay_step_gray),  // OUTPUT[7:0]  
      .LOCK      (lock),             // OUTPUT  
      .CLKIN     (rgmii_rxc),        // INPUT  
      .PWD       (1'b0),             // INPUT  
      .RST       (1'b0),             // INPUT  
      .UPDATE_N  (1'b1)              // INPUT  
  );
  //将GTP_DLL的设置的延迟 应用到rgmii_rxc，并输出rgmii_rxc_ibuf
  GTP_IOCLKDELAY #(
      .DELAY_STEP_VALUE('d127),
      .DELAY_STEP_SEL  ("PARAMETER"),
      .SIM_DEVICE      ("LOGOS")
  ) rgmii_clk_delay (
      .DELAY_STEP(delay_step_gray),  // INPUT[7:0]  来自DLL的delay step 
      .CLKOUT    (rgmii_rxc_ibuf),   // OUTPUT         
      .DELAY_OB  (),                 // OUTPUT         
      .CLKIN     (rgmii_rxc),        // INPUT          
      .DIRECTION (1'b0),             // INPUT          
      .LOAD      (1'b0),             // INPUT          
      .MOVE      (1'b0)              // INPUT          
  );
  //延迟后的rgmii_rxc_ibuf转化为全局时钟
  GTP_CLKBUFG GTP_CLKBUFG_RXSHFT (
      .CLKIN (rgmii_rxc_ibuf),
      .CLKOUT(gmii_clk)
  );


  //rgmii_rx_ctl 缓冲，并双边沿采样
  GTP_INBUF #(
      .IOSTANDARD("DEFAULT"),
      .TERM_DDR  ("ON")
  ) u_rgmii_rx_ctl_ibuf (
      .O(rgmii_rx_ctl_ibuf),  // OUTPUT  
      .I(rgmii_rx_ctl)        // INPUT  
  );

  wire rgmii_rx_ctl_delay;
  parameter DELAY_STEP = 8'h0F;

  wire [5:0] rx_ctl_nc;
  wire       gmii_ctl;
  wire       rgmii_rx_valid_xor_error;
  GTP_ISERDES #(
      .ISERDES_MODE("IDDR"),
      .GRS_EN("TRUE"),
      .LRS_EN("TRUE")
  ) gmii_ctl_in (
      .DO    ({rgmii_rx_valid_xor_error, gmii_ctl, rx_ctl_nc[5:0]}),  // OUTPUT[7:0]  
      .RADDR (3'd0),                                                  // INPUT[2:0]  
      .WADDR (3'd0),                                                  // INPUT[2:0]  
      .DESCLK(gmii_clk),                                              // INPUT  
      .DI    (rgmii_rx_ctl_ibuf),                                     // INPUT  
      .ICLK  (1'b0),                                                  // INPUT  
      .RCLK  (gmii_clk),                                              // INPUT  
      .RST   (1'b0)                                                   // INPUT  
  );

  wire [ 3:0] rgmii_rxd_delay;
  wire [23:0] rxd_nc;
  wire [ 7:0] gmii_rxd_data_o;

  always @(posedge gmii_clk) begin
    gmii_rxd_data  <= gmii_rxd_data_o;
    gmii_rxd_valid <= gmii_ctl;
  end

  generate
    genvar j;
    for (j = 0; j < 4; j = j + 1) begin : rgmii_rx_data

      GTP_INBUF #(
          .IOSTANDARD("DEFAULT"),
          .TERM_DDR  ("ON")
      ) u_rgmii_rxd_ibuf (
          .O(rgmii_rxd_ibuf[j]),  // OUTPUT  
          .I(rgmii_rxd[j])        // INPUT  
      );

      GTP_ISERDES #(
          .ISERDES_MODE("IDDR"),  //1:2解串模式
          .GRS_EN("TRUE"),
          .LRS_EN("TRUE")
      ) gmii_rxd_in (
          .DO    ({gmii_rxd_data_o[j+4], gmii_rxd_data_o[j], rxd_nc[j*6 +: 6]}),  // OUTPUT[7:0]  
          .RADDR (3'd0),                                                          // INPUT[2:0]  
          .WADDR (3'd0),                                                          // INPUT[2:0]  
          .DESCLK(gmii_clk),                                                      // INPUT  
          .DI    (rgmii_rxd_ibuf[j]),                                             // INPUT  
          .ICLK  (1'b0),                                                          // INPUT  
          .RCLK  (gmii_clk),                                                      // INPUT  
          .RST   (1'b0)                                                           // INPUT  
      );

    end
  endgenerate

endmodule
