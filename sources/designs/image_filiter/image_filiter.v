module image_filiter #(
    parameter reg [10:0] IMAGE_WIDTH = 1280,  // 图像宽度
    parameter reg [10:0] IMAGE_HEIGHT = 360,  // 图像高度
    parameter integer PIXEL_DATA_WIDTH = 16,
    parameter integer R_DATA_WIDTH = 5,
    parameter integer G_DATA_WIDTH = 6,
    parameter integer B_DATA_WIDTH = 5,
    parameter integer TH = 5
) (
    input  clk,
    input  resetn,
    //! FIFO初始化忙信号
    output rst_busy,

    //！ 滤波模式 0:不做处理 1:高斯滤波  2:中值滤波  3:自适应滤波
    input  [                 2:0] mode,
    //! 输入像素点
    input  [PIXEL_DATA_WIDTH-1:0] s_pixel_data,
    input                         s_pixel_valid,
    //! 输出像素点
    output [PIXEL_DATA_WIDTH-1:0] m_filtered_data,
    output                        m_filtered_valid
);

  wire [3*PIXEL_DATA_WIDTH-1:0] multiline_pixel_data;
  wire                          pixel_valid;

  wire [9*PIXEL_DATA_WIDTH-1:0] matrix_data;  //! 3x3像素点矩阵
  wire                          matrix_valid;  //! 3x3像素点矩阵有效信号


  //！ 行缓存，单行串行数据流 转 三行串行数据流
  multiline_buffer #(
      .IMAGE_WIDTH(IMAGE_WIDTH),
      .IMAGE_HEIGHT(IMAGE_HEIGHT),
      .PIXEL_DATA_WIDTH(PIXEL_DATA_WIDTH),
      .LINES_NUM(3)
  ) multiline_buffer_inst (
      .clk(clk),
      .resetn(resetn),
      .rst_busy(rst_busy),
      .s_pixel_data(s_pixel_data),
      .s_pixel_valid(s_pixel_valid),
      .m_multiline_pixel_data(multiline_pixel_data),
      .m_pixel_valid(pixel_valid)
  );

  //! 输入三行数据流，输出3x3矩阵
  vector_to_matrix #(
      .IMAGE_WIDTH(IMAGE_WIDTH),
      .DATA_WIDTH (PIXEL_DATA_WIDTH),
      .VECTOR_SIZE(3)
  ) vector_to_matrix_inst (
      .clk(clk),
      .resetn(resetn),
      .s_vector_data(multiline_pixel_data),
      .s_vector_valid(pixel_valid),
      .m_matrix_data(matrix_data),
      .m_matrix_valid(matrix_valid)
  );

  //! 对矩阵滤波
  hybrid_filter #(
      .PIXEL_DATA_WIDTH(PIXEL_DATA_WIDTH),
      .R_DATA_WIDTH(R_DATA_WIDTH),
      .G_DATA_WIDTH(G_DATA_WIDTH),
      .B_DATA_WIDTH(B_DATA_WIDTH),
      .TH(TH)
  ) hybrid_filter_inst (
      .clk(clk),
      .resetn(resetn),
      .mode(mode),
      .s_matrix_data(matrix_data),
      .s_matrix_valid(matrix_valid),
      .m_result_data(m_filtered_data),
      .m_result_valid(m_filtered_valid)
  );



endmodule
