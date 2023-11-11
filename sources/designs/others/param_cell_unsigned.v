module param_cell_unsigned #(
    parameter integer CLK_FREQ = 50_000000,
    parameter integer PARAM_WIDTH = 3,
    parameter integer PRESSED_TRIG_CYCLE_MS = 100,  //按键按下时，触发连续点击的周期
    parameter integer DEFAULT_VALUE = 0,
    parameter integer RANGE_MIN = 0,
    parameter integer RANGE_MAX = 1
) (
    input clk,
    input resetn,

    input clk_ms,
    input restore,
    input selected,

    input load_valid,
    input [PARAM_WIDTH-1:0] load_data,

    input akey_up,
    input akey_down,

    output reg [PARAM_WIDTH-1:0] value
);

  wire pressed_up, pressed_down, changed_up, changed_down;
  reg pluse;
  reg [11:0] cnt;

  //--- 生成周期1ms的脉冲 ---//
  reg clk_ms_ff0, clk_ms_ff1;
  reg pluse_ms;
  always @(posedge clk) begin
    clk_ms_ff0 <= clk_ms;
    clk_ms_ff1 <= clk_ms_ff0;
    if (clk_ms_ff0 && ~clk_ms_ff1) begin
      pluse_ms <= 1;
    end else begin
      pluse_ms <= 0;
    end
  end


  //---------------------------------------------------------------
  // 按键消抖
  //---------------------------------------------------------------
  key_debounce #(
      .CLK_FREQ(CLK_FREQ),
      .DELAY_MS(20),
      .KEY_RELEASED_VALUE(1)
  ) key_debounce_inst1 (
      .clk(clk),
      .clk_ms(clk_ms),
      .resetn(resetn),
      .key_in(akey_up),
      .pressed(pressed_up),
      .change(changed_up)
  );
  key_debounce #(
      .CLK_FREQ(CLK_FREQ),
      .DELAY_MS(20),
      .KEY_RELEASED_VALUE(1)
  ) key_debounce_inst2 (
      .clk(clk),
      .clk_ms(clk_ms),
      .resetn(resetn),
      .key_in(akey_down),
      .pressed(pressed_down),
      .change(changed_down)
  );

  always @(posedge clk) begin
    if (~resetn) begin
      cnt <= PRESSED_TRIG_CYCLE_MS + 20;
    end else if ((changed_up && pressed_up) || (changed_down && pressed_down)) begin
      cnt <= PRESSED_TRIG_CYCLE_MS + 20;
    end else if (pressed_up || pressed_down) begin
      if (pluse_ms) begin
        if (pluse_ms && cnt == 0) begin
          cnt <= PRESSED_TRIG_CYCLE_MS;
        end else begin
          cnt <= cnt - 1;
        end
      end else begin
        cnt <= cnt;
      end
    end else begin
      cnt <= PRESSED_TRIG_CYCLE_MS + 20;
    end
  end

  always @(posedge clk) begin
    if (~resetn) begin
      pluse <= 0;
    end else if (pluse_ms && cnt == 0) begin
      pluse <= 1;
    end else begin
      pluse <= 0;
    end
  end

  always @(posedge clk) begin
    if (~resetn) begin
      value <= DEFAULT_VALUE;
    end else if (load_valid) begin
      // 加载外部数据
      if (load_data < RANGE_MIN) begin
        value <= RANGE_MIN;
      end else if (load_data > RANGE_MAX) begin
        value <= RANGE_MAX;
      end else begin
        value <= load_data;
      end
      value <= load_data;
    end else if (selected) begin
      // 被选中
      if (restore) begin
        value <= DEFAULT_VALUE;
      end else if (pressed_down && (changed_down || pluse)) begin
        // 减小
        if (value <= RANGE_MIN) begin
          value <= RANGE_MIN;
        end else begin
          value <= value - 1;
        end
      end else if (pressed_up && (changed_up || pluse)) begin
        // 增加
        if (value >= RANGE_MAX) begin
          value <= RANGE_MAX;
        end else begin
          value <= value + 1;
        end
      end else begin
        value <= value;
      end
    end else begin
      value <= value;
    end
  end

endmodule
