module hsv_modify (
    input clk,
    input resetn,

    input signed [8:0] modify_h,
    input signed [8:0] modify_s,
    input signed [8:0] modify_v,

    input [7:0] raw_h_data,
    input [7:0] raw_s_data,
    input [7:0] raw_v_data,
    input raw_valid,

    output reg [7:0] modified_h_data,
    output reg [7:0] modified_s_data,
    output reg [7:0] modified_v_data,
    output reg modified_valid

);

  reg valid_ff0;
  wire signed [9:0] h_add0, h_add1;
  wire signed [9:0] s_add0, s_add1;
  wire signed [9:0] v_add0, v_add1;
  reg signed [9:0] h_sum, s_sum, v_sum;

  assign h_add0 = modify_h;
  assign s_add0 = modify_s;
  assign v_add0 = modify_v;
  assign h_add1 = {2'b0, raw_h_data};
  assign s_add1 = {2'b0, raw_s_data};
  assign v_add1 = {2'b0, raw_v_data};


  always @(posedge clk) begin
    if (~resetn) begin
      valid_ff0 <= 0;
      modified_valid <= 0;
    end else begin
      valid_ff0 <= raw_valid;
      modified_valid <= valid_ff0;
    end
  end

  always @(posedge clk) begin

    //! 纯黑白的点，色相不做旋转
    if (raw_s_data == 0) begin
      h_sum <= 0;
    end else begin
      h_sum <= h_add0 + h_add1;
    end

    //! 纯黑白的点，饱和度也不变
    if (raw_s_data == 0) begin
      s_sum <= 0;
    end else begin
      s_sum <= s_add0 + s_add1;
    end

    v_sum <= v_add0 + v_add1;

  end

  always @(posedge clk) begin
    if (h_sum >= $signed(192)) begin
      modified_h_data <= h_sum - $signed(192);
    end else if (h_sum < $signed(0)) begin
      modified_h_data <= h_sum + $signed(192);
    end else begin
      modified_h_data <= h_sum;
    end
  end

  always @(posedge clk) begin
    if (s_sum > 255) begin
      modified_s_data <= 255;
    end else if (s_sum < $signed(0)) begin
      modified_s_data <= 0;
    end else begin
      modified_s_data <= s_sum;
    end
  end

  always @(posedge clk) begin
    if (v_sum > 255) begin
      modified_v_data <= 255;
    end else if (v_sum < $signed(0)) begin
      modified_v_data <= 0;
    end else begin
      modified_v_data <= v_sum;
    end
  end


endmodule
