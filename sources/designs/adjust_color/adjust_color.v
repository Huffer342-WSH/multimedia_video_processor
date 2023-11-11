
// 数据处理需要 20+2+4=26个周期
module adjust_color (
    input clk,
    input resetn,

    input signed [8:0] h_s_data,
    input signed [8:0] s_s_data,
    input signed [8:0] v_s_data,

    input [23:0] pixel_s_data,
    input pixel_s_valid,

    output [23:0] res_m_data,
    output res_m_valid
);

  wire [7:0] raw_h_data;
  wire [7:0] raw_s_data;
  wire [7:0] raw_v_data;
  wire [7:0] modified_h_data;
  wire [7:0] modified_s_data;
  wire [7:0] modified_v_data;
  wire raw_hsv_valid, modified_hsv_valid;

  convert_rgb2hsv convert_rgb2hsv_inst (
      .clk(clk),
      .resetn(resetn),
      .rgb_s_data(pixel_s_data),
      .rgb_s_valid(pixel_s_valid),
      .h_m_data(raw_h_data),
      .s_m_data(raw_s_data),
      .v_m_data(raw_v_data),
      .hsv_m_valid(raw_hsv_valid)
  );

  hsv_modify hsv_modify_inst (
      .clk(clk),
      .resetn(resetn),
      .modify_h(h_s_data),
      .modify_s(s_s_data),
      .modify_v(v_s_data),
      .raw_h_data(raw_h_data),
      .raw_s_data(raw_s_data),
      .raw_v_data(raw_v_data),
      .raw_valid(raw_hsv_valid),
      .modified_h_data(modified_h_data),
      .modified_s_data(modified_s_data),
      .modified_v_data(modified_v_data),
      .modified_valid(modified_hsv_valid)
  );


  convert_hsv2rgb convert_hsv2rgb_inst (
      .clk(clk),
      .resetn(resetn),
      .h_s_data(modified_h_data),
      .s_s_data(modified_s_data),
      .v_s_data(modified_v_data),
      .hsv_s_valid(modified_hsv_valid),

      .rgb_m_data (res_m_data),
      .rgb_m_valid(res_m_valid)
  );

endmodule
