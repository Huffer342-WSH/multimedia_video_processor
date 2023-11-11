module hybrid_filter #(
    parameter integer PIXEL_DATA_WIDTH = 16,
    parameter integer R_DATA_WIDTH = 5,
    parameter integer G_DATA_WIDTH = 6,
    parameter integer B_DATA_WIDTH = 5,
    parameter integer TH = 5

) (
    input clk,
    input resetn,
    input [2:0] mode,

    input [9*PIXEL_DATA_WIDTH-1:0] s_matrix_data,
    input                          s_matrix_valid,

    output     [PIXEL_DATA_WIDTH-1:0] m_result_data,
    output reg                        m_result_valid


);

  localparam reg [2:0] ModeNone = 0;
  localparam reg [2:0] ModeGauss = 1;
  localparam reg [2:0] ModeMedian = 2;
  localparam reg [2:0] ModeAuto = 3;
  localparam reg [2:0] ModeEdge = 4;

  reg [3:0] valid_d;  //有效信号延迟
  reg [3*PIXEL_DATA_WIDTH-1:0] pixel_ff;


  wire [9*R_DATA_WIDTH-1:0] matrix_data_r;  //! RED通道3x3矩阵
  wire [9*G_DATA_WIDTH-1:0] matrix_data_g;  //! GREEN通道3x3矩阵
  wire [9*B_DATA_WIDTH-1:0] matrix_data_b;  //! BLUE通道3x3矩阵


  wire [R_DATA_WIDTH-1:0] gauss_res_r;
  wire [G_DATA_WIDTH-1:0] gauss_res_g;
  wire [B_DATA_WIDTH-1:0] gauss_res_b;

  wire [R_DATA_WIDTH-1:0] median_res_r;
  wire [G_DATA_WIDTH-1:0] median_res_g;
  wire [B_DATA_WIDTH-1:0] median_res_b;

  wire [R_DATA_WIDTH-1:0] max_res_r;
  wire [G_DATA_WIDTH-1:0] max_res_g;
  wire [B_DATA_WIDTH-1:0] max_res_b;

  wire [R_DATA_WIDTH-1:0] min_res_r;
  wire [G_DATA_WIDTH-1:0] min_res_g;
  wire [B_DATA_WIDTH-1:0] min_res_b;

  reg [R_DATA_WIDTH-1:0] raw_res_r;
  reg [G_DATA_WIDTH-1:0] raw_res_g;
  reg [B_DATA_WIDTH-1:0] raw_res_b;

  reg [R_DATA_WIDTH-1:0] res_r;
  reg [G_DATA_WIDTH-1:0] res_g;
  reg [B_DATA_WIDTH-1:0] res_b;

  //---------------------------------------------------------------
  // 拆分三个通道并例化滤波器，对原始数据打拍
  //---------------------------------------------------------------

  genvar i, j;
  //!  拆分RGB通道
  generate
    for (i = 0; i < 9; i = i + 1) begin : g_split_rgb_channel
      assign {matrix_data_r[i*R_DATA_WIDTH +: R_DATA_WIDTH], matrix_data_g[
              i*G_DATA_WIDTH +: G_DATA_WIDTH], matrix_data_b[i*B_DATA_WIDTH +: B_DATA_WIDTH]} =
          s_matrix_data[i*PIXEL_DATA_WIDTH +: PIXEL_DATA_WIDTH];
    end
  endgenerate

  //! 原始数据打拍
  always @(posedge clk) begin
    if (~resetn) begin
      pixel_ff  <= 0;
      raw_res_r <= 0;
      raw_res_g <= 0;
      raw_res_b <= 0;
    end else begin
      {raw_res_r, raw_res_g, raw_res_b, pixel_ff} <= {
        pixel_ff, s_matrix_data[4*PIXEL_DATA_WIDTH +: PIXEL_DATA_WIDTH]
      };
    end
  end

  //! R通道高斯滤波
  gaussian_conv #(
      .DATA_WIDTH(R_DATA_WIDTH)
  ) gaussian_conv_r (
      .clk(clk),
      .resetn(resetn),
      .s_matrix_data(matrix_data_r),
      .s_matrix_valid(s_matrix_valid),
      .m_result_data(gauss_res_r),
      .m_result_valid()
  );

  //! R通道中值滤波
  median_finder9 #(
      .DATA_WIDTH(R_DATA_WIDTH)
  ) median_finder9_r (
      .clk(clk),
      .resetn(resetn),
      .s_matrix_data(matrix_data_r),
      .s_matrix_valid(s_matrix_valid),
      .m_median_data(median_res_r),
      .m_max_data(max_res_r),
      .m_min_data(min_res_r),
      .m_median_valid()
  );

  //! G通道高斯滤波
  gaussian_conv #(
      .DATA_WIDTH(G_DATA_WIDTH)
  ) gaussian_conv_g (
      .clk(clk),
      .resetn(resetn),
      .s_matrix_data(matrix_data_g),
      .s_matrix_valid(s_matrix_valid),
      .m_result_data(gauss_res_g),
      .m_result_valid()
  );

  //! G通道中值滤波
  median_finder9 #(
      .DATA_WIDTH(G_DATA_WIDTH)
  ) median_finder9_g (
      .clk(clk),
      .resetn(resetn),
      .s_matrix_data(matrix_data_g),
      .s_matrix_valid(s_matrix_valid),
      .m_median_data(median_res_g),
      .m_max_data(max_res_g),
      .m_min_data(min_res_g),
      .m_median_valid()
  );

  //! B通道高斯滤波
  gaussian_conv #(
      .DATA_WIDTH(B_DATA_WIDTH)
  ) gaussian_conv_b (
      .clk(clk),
      .resetn(resetn),
      .s_matrix_data(matrix_data_b),
      .s_matrix_valid(s_matrix_valid),
      .m_result_data(gauss_res_b),
      .m_result_valid()
  );

  //! B通道中值滤波
  median_finder9 #(
      .DATA_WIDTH(B_DATA_WIDTH)
  ) median_finder9_b (
      .clk(clk),
      .resetn(resetn),
      .s_matrix_data(matrix_data_b),
      .s_matrix_valid(s_matrix_valid),
      .m_median_data(median_res_b),
      .m_max_data(max_res_b),
      .m_min_data(min_res_b),
      .m_median_valid()
  );


  //---------------------------------------------------------------
  // 根据模式输出结果
  //---------------------------------------------------------------
  always @(posedge clk) begin
    if (~resetn) begin
      res_r <= {R_DATA_WIDTH{1'b1}};
    end else begin
      case (mode)
        ModeGauss:  res_r <= gauss_res_r;
        ModeMedian: res_r <= median_res_r;
        ModeAuto: begin
          if (max_res_r > {R_DATA_WIDTH{1'b1}} - TH || min_res_r < TH) begin
            res_r <= median_res_r;
          end else begin
            res_r <= gauss_res_r;
          end
        end
        ModeEdge:   res_r <= max_res_r - min_res_r;

        default: res_r <= raw_res_r;
      endcase
    end
  end


  always @(posedge clk) begin
    if (~resetn) begin
      res_g <= {G_DATA_WIDTH{1'b1}};
    end else begin
      case (mode)
        ModeGauss: res_g <= gauss_res_g;
        ModeMedian: res_g <= median_res_g;
        ModeAuto: begin
          if (max_res_g > {G_DATA_WIDTH{1'b1}} - TH || min_res_g < TH) begin
            res_g <= median_res_g;
          end else begin
            res_g <= gauss_res_g;
          end
        end
        ModeEdge: res_g <= max_res_g - min_res_g;
        default: res_g <= raw_res_g;
      endcase
    end
  end

  always @(posedge clk) begin
    if (~resetn) begin
      res_b <= {B_DATA_WIDTH{1'b1}};
    end else begin
      case (mode)
        ModeGauss: res_b <= gauss_res_b;
        ModeMedian: res_b <= median_res_b;
        ModeAuto: begin
          if (max_res_b > {B_DATA_WIDTH{1'b1}} - TH || min_res_b < TH) begin
            res_b <= median_res_b;
          end else begin
            res_b <= gauss_res_b;
          end
        end
        ModeEdge: res_b <= max_res_b - min_res_b;
        default: res_b <= raw_res_b;
      endcase
    end
  end

  assign m_result_data = {res_r, res_g, res_b};

  //! 有效信号打拍
  always @(posedge clk) begin
    if (~resetn) begin
      {m_result_valid, valid_d} <= 0;
    end else begin
      {m_result_valid, valid_d} <= {valid_d, s_matrix_valid};
    end
  end
endmodule
