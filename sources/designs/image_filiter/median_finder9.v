module median_finder9 #(
    parameter integer DATA_WIDTH = 8  //数据位宽
) (
    input                    clk,
    input                    resetn,
    input [9*DATA_WIDTH-1:0] s_matrix_data,
    input                    s_matrix_valid,

    output [DATA_WIDTH-1:0] m_max_data,
    output [DATA_WIDTH-1:0] m_min_data,
    output [DATA_WIDTH-1:0] m_median_data,
    output                  m_median_valid

);

  //! 保存输入的3x3矩阵
  reg  [DATA_WIDTH-1:0] mat                            [2:0] [2:0];

  wire [DATA_WIDTH-1:0] vector_max                     [2:0];
  wire [DATA_WIDTH-1:0] vector_med                     [2:0];
  wire [DATA_WIDTH-1:0] vector_min                     [2:0];

  reg  [DATA_WIDTH-1:0] min_of_vector_min;
  reg  [DATA_WIDTH-1:0] max_of_vector_min;
  reg  [DATA_WIDTH-1:0] med_of_vector_med;
  reg  [DATA_WIDTH-1:0] min_of_vector_max;
  reg  [DATA_WIDTH-1:0] max_of_vector_max;

  reg  [DATA_WIDTH-1:0] med;
  reg  [DATA_WIDTH-1:0] max;
  reg  [DATA_WIDTH-1:0] min;


  reg  [           3:0] valid_d;  //有效信号延迟

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
  // 第二拍 将每一行排序
  //---------------------------------------------------------------
  // 每一行分别排序
  generate
    for (i = 0; i < 3; i = i + 1) begin : g_sort_for_per_three_reg
      sort_3 #(
          .DATA_WIDTH(DATA_WIDTH)
      ) sort_3_inst (
          .clk           (clk),
          .resetn        (resetn),
          .original_data ({mat[i][0], mat[i][1], mat[i][2]}),
          .original_valid(),
          .sorted_data   ({vector_min[i], vector_med[i], vector_max[i]}),
          .sorted_valid  ()
      );
    end
  endgenerate

  //---------------------------------------------------------------
  // 第三拍 在三个最小值中找到最大值 三个中间值中找到中间值 三个最大值中找到最小值
  //---------------------------------------------------------------
  //! 在三个最小值中寻找最大值
  always @(posedge clk) begin
    if (~resetn) begin
      max_of_vector_min <= 0;
    end else begin
      case ({
        vector_min[0] > vector_min[1] ? 1'b1 : 1'b0,
        vector_min[0] > vector_min[2] ? 1'b1 : 1'b0,
        vector_min[1] > vector_min[2] ? 1'b1 : 1'b0
      })
        3'b110:  max_of_vector_min <= vector_min[0];
        3'b111:  max_of_vector_min <= vector_min[0];
        3'b001:  max_of_vector_min <= vector_min[1];
        3'b011:  max_of_vector_min <= vector_min[1];
        3'b000:  max_of_vector_min <= vector_min[2];
        3'b100:  max_of_vector_min <= vector_min[2];
        default: max_of_vector_min <= vector_min[0];
      endcase
    end
  end

  //! 在三个最小值中寻找最小值
  always @(posedge clk) begin
    if (~resetn) begin
      min_of_vector_min <= 0;
    end else begin
      case ({
        vector_min[0] > vector_min[1] ? 1'b1 : 1'b0,
        vector_min[0] > vector_min[2] ? 1'b1 : 1'b0,
        vector_min[1] > vector_min[2] ? 1'b1 : 1'b0
      })
        3'b000:  min_of_vector_min <= vector_min[0];
        3'b001:  min_of_vector_min <= vector_min[0];
        3'b100:  min_of_vector_min <= vector_min[1];
        3'b110:  min_of_vector_min <= vector_min[1];
        3'b011:  min_of_vector_min <= vector_min[2];
        3'b111:  min_of_vector_min <= vector_min[2];
        default: min_of_vector_min <= vector_min[0];
      endcase
    end
  end

  //! 在三个中间值中找到中间值
  always @(posedge clk) begin
    if (~resetn) begin
      med_of_vector_med <= 0;
    end else begin
      case ({
        vector_med[0] > vector_med[1] ? 1'b1 : 1'b0,
        vector_med[0] > vector_med[2] ? 1'b1 : 1'b0,
        vector_med[1] > vector_med[2] ? 1'b1 : 1'b0
      })
        3'b100:  med_of_vector_med <= vector_med[0];
        3'b011:  med_of_vector_med <= vector_med[0];
        3'b111:  med_of_vector_med <= vector_med[1];
        3'b000:  med_of_vector_med <= vector_med[1];
        3'b110:  med_of_vector_med <= vector_med[2];
        3'b001:  med_of_vector_med <= vector_med[2];
        default: med_of_vector_med <= vector_med[1];
      endcase
    end
  end

  //! 在三个最大值中找到最小值
  always @(posedge clk) begin
    if (~resetn) begin
      min_of_vector_max <= 0;
    end else begin
      case ({
        vector_max[0] > vector_max[1] ? 1'b1 : 1'b0,
        vector_max[1] > vector_max[2] ? 1'b1 : 1'b0,
        vector_max[0] > vector_max[2] ? 1'b1 : 1'b0
      })
        3'b000:  min_of_vector_max <= vector_max[0];
        3'b100:  min_of_vector_max <= vector_max[1];
        3'b011:  min_of_vector_max <= vector_max[2];
        3'b010:  min_of_vector_max <= vector_max[0];
        3'b101:  min_of_vector_max <= vector_max[1];
        3'b111:  min_of_vector_max <= vector_max[2];
        default: min_of_vector_max <= vector_max[0];
      endcase
    end
  end

  //! 在三个最大值中找到最大值
  always @(posedge clk) begin
    if (~resetn) begin
      max_of_vector_max <= 0;
    end else begin
      case ({
        vector_max[0] > vector_max[1] ? 1'b1 : 1'b0,
        vector_max[0] > vector_max[2] ? 1'b1 : 1'b0,
        vector_max[1] > vector_max[2] ? 1'b1 : 1'b0
      })
        3'b110:  max_of_vector_max <= vector_max[0];
        3'b111:  max_of_vector_max <= vector_max[0];
        3'b001:  max_of_vector_max <= vector_max[1];
        3'b011:  max_of_vector_max <= vector_max[1];
        3'b000:  max_of_vector_max <= vector_max[2];
        3'b100:  max_of_vector_max <= vector_max[2];
        default: max_of_vector_max <= vector_max[0];
      endcase
    end
  end
  //---------------------------------------------------------------
  // 第四拍 在三个最小值中的最大值、三个中间值中的中间值、三个最大值中的最小值中找到中间值
  //---------------------------------------------------------------

  //! 在max_of_vector_min，med_of_vector_med，min_of_vector_max中找到中间值
  always @(posedge clk) begin
    if (~resetn) begin
      med <= 0;
    end else begin
      case ({
        max_of_vector_min > med_of_vector_med ? 1'b1 : 1'b0,
        max_of_vector_min > min_of_vector_max ? 1'b1 : 1'b0,
        med_of_vector_med > min_of_vector_max ? 1'b1 : 1'b0
      })
        3'b100:  med <= max_of_vector_min;
        3'b011:  med <= max_of_vector_min;
        3'b111:  med <= med_of_vector_med;
        3'b000:  med <= med_of_vector_med;
        3'b110:  med <= min_of_vector_max;
        3'b001:  med <= min_of_vector_max;
        default: med <= med_of_vector_med;
      endcase
    end
  end


  always @(posedge clk) begin
    if (~resetn) begin
      max <= 0;
    end else begin
      max <= max_of_vector_max;
    end
  end

  always @(posedge clk) begin
    if (~resetn) begin
      min <= 0;
    end else begin
      min <= min_of_vector_min;
    end
  end



  assign m_median_data = med;
  assign m_max_data = max;
  assign m_min_data = min;

  assign m_median_valid = valid_d[3];

  //! 有效信号打拍
  always @(posedge clk) begin
    if (~resetn) begin
      valid_d <= 0;
    end else begin
      valid_d[3:0] <= {valid_d[2:0], s_matrix_valid};
    end
  end




endmodule
