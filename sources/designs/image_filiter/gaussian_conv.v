/*
卷积核：
    1   2   1
    2   4   2
    1   2   1
*/

module gaussian_conv #(
    parameter integer DATA_WIDTH = 8  //数据位宽
) (
    input                    clk,
    input                    resetn,
    input [9*DATA_WIDTH-1:0] s_matrix_data,
    input                    s_matrix_valid,

    output reg [DATA_WIDTH-1:0] m_result_data,
    output                      m_result_valid
);

  //! 保存输入的3x3矩阵
  reg [DATA_WIDTH-1:0] mat[2:0][2:0];
  reg [DATA_WIDTH+3:0] sum4x1, sum4x2, sum1x4;
  reg [DATA_WIDTH+3:0] sum8, product4x2;


  reg [3:0] valid_d;  //有效信号延迟

  genvar i, j;


  //---------------------------------------------------------------
  // 第一拍 寄存器转矩阵
  //---------------------------------------------------------------
  generate
    for (i = 0; i < 3; i = i + 1) begin : g_matrix_col_connct
      for (j = 0; j < 3; j = j + 1) begin : g_matrix_row_connct
        always @(posedge clk) begin
          mat[i][j] <= s_matrix_data[(i*3+j)*DATA_WIDTH+:DATA_WIDTH];
        end
      end
    end
  endgenerate


  //---------------------------------------------------------------
  // 第二拍 计算四个角的和，四个边的和，以及中间数x4
  //---------------------------------------------------------------
  always @(posedge clk) begin
    if (~resetn) begin
      sum4x1 <= 0;
    end else begin
      sum4x1 <= mat[0][0] + mat[2][0] + mat[0][2] + mat[2][2];
    end
  end

  always @(posedge clk) begin
    if (~resetn) begin
      sum4x2 <= 0;
    end else begin
      sum4x2 <= mat[0][1] + mat[1][0] + mat[1][2] + mat[2][1];
    end
  end

  always @(posedge clk) begin
    if (~resetn) begin
      sum1x4 <= 0;
    end else begin
      sum1x4 <= mat[1][1] << 2;
    end
  end

  //---------------------------------------------------------------
  // 第三拍 计算 中间数+4角  4边x2 
  //---------------------------------------------------------------
  //! 在三个最小值中寻找最大值
  always @(posedge clk) begin
    if (~resetn) begin
      sum8 <= 0;
    end else begin
      sum8 <= sum4x1 + sum1x4 + 8;
    end
  end


  always @(posedge clk) begin
    if (~resetn) begin
      product4x2 <= 0;
    end else begin
      product4x2 <= sum4x2 << 1;
    end
  end


  //---------------------------------------------------------------
  // 第四拍 计算最终结果
  //---------------------------------------------------------------
  //! 求和/16
  always @(posedge clk) begin
    if (~resetn) begin
      m_result_data <= 0;
    end else begin
      m_result_data <= (product4x2 + sum8) >> 4;
    end
  end


  //! 有效信号打拍
  always @(posedge clk) begin
    if (~resetn) begin
      valid_d <= 0;
    end else begin
      valid_d[3:0] <= {valid_d[2:0], s_matrix_valid};
    end
  end
  assign m_result_valid = valid_d[3];




endmodule
