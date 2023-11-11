//! 输入一个N维向量，向量缓存N次，形成NxN的方阵

module vector_to_matrix #(
    parameter reg [10:0] IMAGE_WIDTH = 1280,  //! 图像宽度
    parameter integer DATA_WIDTH = 16,  //! 数据位宽
    parameter integer VECTOR_SIZE = 3  //! 向量大小

) (
    input clk,    //!  时钟
    input resetn, //! 低电平复位

    input [VECTOR_SIZE*DATA_WIDTH-1:0] s_vector_data,  //!  输入向量
    input                              s_vector_valid, //! 输入有效信号

    output [VECTOR_SIZE*VECTOR_SIZE*DATA_WIDTH-1:0] m_matrix_data,  //! 输出矩阵
    output                                          m_matrix_valid  //! 输出有效信号
);


  wire [DATA_WIDTH-1:0] vector  [VECTOR_SIZE-1:0];
  reg  [DATA_WIDTH-1:0] mat     [VECTOR_SIZE-1:0] [VECTOR_SIZE-1:0];
  reg                   valid_d;

  //! valid信号打拍
  always @(posedge clk) begin : valid_filpflop
    if (~resetn) begin
      valid_d <= 0;
    end else begin
      valid_d <= s_vector_valid;
    end
  end

  genvar i, j;

  //!  输入s_vector_data 转 数组vector
  generate
    for (i = 0; i < VECTOR_SIZE; i = i + 1) begin : g_convert_data_to_vector
      assign vector[i] = s_vector_data[i*DATA_WIDTH +: DATA_WIDTH];
    end
  endgenerate

  //--- 矩阵打拍 ---//
  generate
    for (i = 0; i < VECTOR_SIZE; i = i + 1) begin : g_flipflop_vector_to_mat_row
      for (j = 0; j < VECTOR_SIZE; j = j + 1) begin : g_flipflop_vector_to_mat_col
        if (i == 0) begin : g_flipflop_vector_to_mat_first_row
          always @(posedge clk) begin
            if (~resetn) begin
              mat[i][j] <= 0;
            end else if (s_vector_valid) begin
              mat[i][j] <= vector[j];
            end else begin
              mat[i][j] <= mat[i][j];
            end
          end
        end else begin : g_flipflop_vector_to_mat_others_row
          always @(posedge clk) begin
            if (~resetn) begin
              mat[i][j] <= 0;
            end else if (s_vector_valid) begin
              mat[i][j] <= mat[i-1][j];
            end else begin
              mat[i][j] <= mat[i][j];
            end
          end
        end
      end
    end
  endgenerate

  //输出 ，二维矩阵 转 普通信号
  generate
    for (i = 0; i < VECTOR_SIZE; i = i + 1) begin : g_mat_to_data_row
      for (j = 0; j < VECTOR_SIZE; j = j + 1) begin : g_mat_to_data_col
        assign m_matrix_data[(i*VECTOR_SIZE+j)*DATA_WIDTH +: DATA_WIDTH] = mat[i][j];
      end
    end
  endgenerate

  assign m_matrix_valid = valid_d;


endmodule
