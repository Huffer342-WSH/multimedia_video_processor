//数据计算需要20个周期
module convert_rgb2hsv (
    input clk,
    input resetn,

    input [23:0] rgb_s_data,
    input rgb_s_valid,

    output reg [7:0] h_m_data,
    output reg [7:0] s_m_data,
    output reg [7:0] v_m_data,
    output reg hsv_m_valid
);
  localparam integer Delay = 13;
  reg [7:0] r, g, b;
  reg [7:0] max, med, min;
  reg [2:0] flags;  //第一位代表4  第二位代表2 第三位代表负数
  reg [2:0] valid_ff;

  always @(posedge clk) begin
    if (~resetn) begin
      valid_ff <= 0;
    end else begin
      valid_ff <= {valid_ff[1:0], rgb_s_valid};
    end
  end
  //---------------------------------------------------------------
  // 第1级 缓存数据
  //---------------------------------------------------------------

  always @(posedge clk) begin
    {r, g, b} <= rgb_s_data;
  end
  //---------------------------------------------------------------
  // 第二级 得到最大值，最小值和中间值
  //---------------------------------------------------------------

  always @(posedge clk) begin
    case ({
      (r >= g) ? 1'b1 : 1'b0, (r >= b) ? 1'b1 : 1'b0, (g >= b) ? 1'b1 : 1'b0
    })
      3'b111: begin  //r>g>b
        max   <= r;
        med   <= g;
        min   <= b;
        flags <= 3'b000;
      end
      3'b011: begin  //g>r>b
        max   <= g;
        med   <= r;
        min   <= b;
        flags <= 3'b011;
      end
      3'b001: begin  //g>b>r
        max   <= g;
        med   <= b;
        min   <= r;
        flags <= 3'b010;
      end
      3'b000: begin  //b>g>r
        max   <= b;
        med   <= g;
        min   <= r;
        flags <= 3'b101;
      end
      3'b100: begin
        max   <= b;
        med   <= r;
        min   <= g;
        flags <= 3'b100;
      end
      3'b110: begin
        max   <= r;
        med   <= b;
        min   <= g;
        flags <= 3'b111;
      end
      default: ;
    endcase
  end

  //---------------------------------------------------------------
  // 第三级计算被除数与除数
  //---------------------------------------------------------------
  wire [12:0] dividend_h;  //(med - min)*32
  wire [15:0] dividend_s;  //(max - min)*256

  reg  [ 7:0] diff_med_min;  //  med - min
  reg  [ 7:0] diff_max_min;  //  med - min
  reg  [ 7:0] divisor_h;

  reg  [ 7:0] max_d0;
  reg  [ 2:0] flags_d0;
  always @(posedge clk) begin
    diff_max_min <= max - min;
    diff_med_min <= med - min;
    max_d0 <= max;
    flags_d0 <= flags;
    if (max == min) begin
      divisor_h <= 1;
    end else begin
      divisor_h <= max - min;
    end
  end

  assign dividend_h = {diff_med_min, 5'b0};
  assign dividend_s = {diff_max_min, 8'b0};
  //---------------------------------------------------------------
  // 例化除法器 计算H 然后打拍
  //---------------------------------------------------------------
  genvar i;
  reg [2:0] flags_ff[13:0];
  wire [12:0] quotient_h;
  wire [15:0] quotient_s;
  reg [7:0] h_part1;
  reg [7:0] h_part2;
  reg [7:0] h_ff[1:0];

  generate
    for (i = 0; i < 14; i = i + 1) begin : g_flags_ff
      if (i == 0) begin : g_flags_ff0
        always @(posedge clk) begin
          flags_ff[i] <= flags_d0;
        end
      end else begin : g_flags_ff_others
        always @(posedge clk) begin
          flags_ff[i] <= flags_ff[i-1];
        end
      end
    end
  endgenerate

  divider #(
      .N(13),
      .M(8)
  ) divider_inst_h (
      .clk(clk),
      .resetn(resetn),
      .in_valid(valid_ff[2]),
      .dividend(dividend_h),
      .divisor(divisor_h),
      .out_valid(),
      .quotient(quotient_h),
      .remainder()
  );






  always @(posedge clk) begin
    h_part1 <= {flags_ff[12][2:1], 6'b0};
    h_part2 <= quotient_h[7:0];
  end


  generate
    for (i = 0; i < 2; i = i + 1) begin : g_h_ff
      if (i == 0) begin : g_h_ff0
        always @(posedge clk) begin
          if (flags_ff[13][0]) begin
            h_ff[i] <= h_part1 - h_part2;
          end else begin
            h_ff[i] <= h_part1 + h_part2;
          end
        end
      end else begin : g_h_ff_others
        always @(posedge clk) begin
          h_ff[i] <= h_ff[i-1];
        end
      end
    end
  endgenerate

  //---------------------------------------------------------------
  // 例化除法器计算S，S是计算最慢的，不需要打拍
  //---------------------------------------------------------------
  wire s_valid;
  divider #(
      .N(16),
      .M(8)
  ) divider_inst_s (
      .clk(clk),
      .resetn(resetn),
      .in_valid(valid_ff[2]),
      .dividend(dividend_s),
      .divisor(max_d0),
      .out_valid(s_valid),
      .quotient(quotient_s),
      .remainder()
  );


  //---------------------------------------------------------------
  // V打拍
  //---------------------------------------------------------------

  reg [7:0] v_ff[15:0];
  generate
    for (i = 0; i < 16; i = i + 1) begin : g_v_ff
      if (i == 0) begin : g_v_ff0
        always @(posedge clk) begin
          v_ff[i] <= max_d0;
        end
      end else begin : g_v_ff_others
        always @(posedge clk) begin
          v_ff[i] <= v_ff[i-1];
        end
      end
    end
  endgenerate
  //---------------------------------------------------------------
  // 输出级
  //---------------------------------------------------------------
  always @(posedge clk) begin
    hsv_m_valid <= s_valid;
    h_m_data <= h_ff[1][7:0];
    v_m_data <= v_ff[15][7:0];
    if (v_ff[15][7:0] == 0) begin
      s_m_data <= 0;
    end else if (quotient_s[8:0] > 255) begin
      s_m_data <= 255;
    end else begin
      s_m_data <= quotient_s[7:0];
    end
  end


endmodule
