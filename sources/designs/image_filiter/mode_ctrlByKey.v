module mode_ctrlByKey #(
    parameter integer CLK_FREQ  = 50_000000,
    parameter integer ARG_WIDTH = 3

) (
    input clk,
    input resetn,

    input load_valid,
    input [ARG_WIDTH-1:0] load_data,

    input async_key,

    output reg [ARG_WIDTH-1:0] value
);

  wire sync_key, key_flag;

  key_debounce #(
      .CLK_FREQ(CLK_FREQ),
      .DELAY_MS(20),
      .KEY_DEFAULT_VALUE(1)
  ) key_debounce_inst (
      .clk(clk),
      .resetn(resetn),
      .key_in(async_key),
      .key_out(sync_key),
      .key_flag(key_flag)
  );

  always @(posedge clk) begin
    if (~resetn) begin
      value <= 0;
    end else if (load_valid) begin
      value <= load_data;
    end else if (key_flag && sync_key) begin
      if (value == 4) begin
        value <= 0;
      end else begin
        value <= value + 1;
      end
    end else begin
      value <= value;
    end
  end

endmodule
