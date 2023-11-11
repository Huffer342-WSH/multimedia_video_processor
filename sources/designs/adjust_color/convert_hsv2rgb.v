module convert_hsv2rgb (
    input clk,
    input resetn,

    input [7:0] h_s_data,
    input [7:0] s_s_data,
    input [7:0] v_s_data,
    input hsv_s_valid,

    output [23:0] rgb_m_data,
    output reg rgb_m_valid
);

  reg [7:0] r, g, b;

  reg [15:0] diff;  //diff = s*v/256 = diff[12:8]
  reg [15:0] med;  //n=1时，med =(2*K-h)*diff/K+min;
  reg [20:0] med2;  //med2=（medss*diff[15:0]）/32/256
  reg [15:0] med1;  //med1=(2*K-h)

  reg [7:0] min, min_ff0;  //diff = s*v/256
  reg [7:0] max_ff1, max_ff2, max_ff3;
  reg [2:0] n_ff1, n_ff2, n_ff3;

  reg [2:0] valid_ff;
  always @(posedge clk) begin
    if (~resetn) begin
      {rgb_m_valid, valid_ff} <= 0;
    end else begin
      {rgb_m_valid, valid_ff} <= {valid_ff, hsv_s_valid};
    end
  end

  //第一个周期：算出diff、max_ff11、n、medss
  always @(posedge clk) begin
    diff <= s_s_data * v_s_data
        ;  //diff的高8位就是正确的diff=s_s_data*v_s_data/256值，后续直接用diff[15:8]
    max_ff1 <= v_s_data;

    if ((0 <= h_s_data) && (h_s_data < 32)) begin
      n_ff1 <= 3'b000;
      med1  <= h_s_data;
    end else if ((32 <= h_s_data) && (h_s_data < 64)) begin
      n_ff1 <= 3'b001;
      med1  <= 64 - h_s_data;
    end else if ((64 <= h_s_data) && (h_s_data < 96)) begin
      n_ff1 <= 3'b010;
      med1  <= h_s_data - 64;
    end else if ((96 <= h_s_data) && (h_s_data < 128)) begin
      n_ff1 <= 3'b011;
      med1  <= 128 - h_s_data;
    end else if ((128 <= h_s_data) && (h_s_data < 160)) begin
      n_ff1 <= 3'b100;
      med1  <= h_s_data - 128;
    end else if ((160 <= h_s_data) && (h_s_data < 192)) begin
      n_ff1 <= 3'b101;
      med1  <= 192 - h_s_data;
    end else begin
      n_ff1 <= 3'b000;
      med1  <= h_s_data;
    end
  end

  //第二个周期：算出meds和min,并且对max_ff1、n_ff0延迟一个周期
  always @(posedge clk) begin
    max_ff2 <= max_ff1;
    n_ff2 <= n_ff1;
    min <= max_ff1 - diff[15:8];
    med2 <= med1 * diff;  //这里直接乘，在后面算med时，对diff和medss总体/32/256，也就是右移5+8=13位，减少除法提升精度
  end

  //第三个周期：算出med/32,并且对max_ff2、n_ff1、min_ff0延迟一个周期
  always @(posedge clk) begin
    max_ff3 <= max_ff2;
    n_ff3 <= n_ff2;
    min_ff0 <= min;
    med <= med2[20:13] + min;
  end

  //第四个周期：用n_ff0判断，给r、g、b赋值
  always @(posedge clk) begin
    case (n_ff3)
      3'b000: begin
        r <= max_ff3;
        g <= med;
        b <= min_ff0;
      end
      3'b001: begin
        g <= max_ff3;
        r <= med;
        b <= min_ff0;
      end
      3'b010: begin
        g <= max_ff3;
        b <= med;
        r <= min_ff0;
      end
      3'b011: begin
        b <= max_ff3;
        g <= med;
        r <= min_ff0;
      end
      3'b100: begin
        b <= max_ff3;
        r <= med;
        g <= min_ff0;
      end
      3'b101: begin
        r <= max_ff3;
        b <= med;
        g <= min_ff0;
      end
      default: begin
        r <= max_ff3;
        b <= med;
        g <= min_ff0;
      end
    endcase
  end

  assign rgb_m_data = {r, g, b};

endmodule
