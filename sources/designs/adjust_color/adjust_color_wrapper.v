module adjust_color_wrapper (
    input clk,
    input resetn,
    input vs_in,
    input hs_in,
    input de_in,
    input [23:0] rgb_in,

    input signed [8:0] modify_h,
    input signed [8:0] modify_s,
    input signed [8:0] modify_v,

    //hdmi_out 
    output reg       vs_out,
    output reg       hs_out,
    output reg       de_out,
    output     [7:0] r_out,
    output     [7:0] g_out,
    output     [7:0] b_out


);

  wire [23:0] res_m_data;
  reg  [24:0] vs_ff;
  reg  [24:0] hs_ff;
  reg  [24:0] de_ff;

  adjust_color adjust_color_inst (
      .clk(clk),
      .resetn(resetn),
      .h_s_data(modify_h),
      .s_s_data(modify_s),
      .v_s_data(modify_v),
      .pixel_s_data(rgb_in),
      .pixel_s_valid(1),

      .res_m_data (res_m_data),
      .res_m_valid()
  );

  assign r_out = res_m_data[23:16];
  assign g_out = res_m_data[15:8];
  assign b_out = res_m_data[7:0];

  always @(posedge clk) begin
    if (~resetn) begin
      {vs_out, vs_ff} <= 0;
      {hs_out, hs_ff} <= 0;
      {de_out, de_ff} <= 0;
    end else begin
      {vs_out, vs_ff} <= {vs_ff, vs_in};
      {hs_out, hs_ff} <= {hs_ff, hs_in};
      {de_out, de_ff} <= {de_ff, de_in};
    end
  end

endmodule
