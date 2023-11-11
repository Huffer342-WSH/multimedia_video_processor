module key_debounce #(
    parameter integer CLK_FREQ = 50_000000,
    parameter integer DELAY_MS = 20,
    parameter reg KEY_RELEASED_VALUE = 1
) (
    input clk,
    input resetn,

    input clk_ms,
    input key_in,  //外部输入的按键值

    output reg pressed,  //消抖后的按键值
    output reg change    //消抖后的按键值的效标志
);

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

  //reg define
  reg [23:0] cnt;
  reg key_ff0, key_ff1;

  //按键值消抖
  always @(posedge clk) begin
    if (!resetn) begin
      cnt <= 0;
      key_ff0 <= KEY_RELEASED_VALUE;
      key_ff1 <= KEY_RELEASED_VALUE;
    end else begin
      key_ff0 <= key_in;
      key_ff1 <= key_ff0;
      if (key_ff0 != KEY_RELEASED_VALUE && key_ff1 == KEY_RELEASED_VALUE) begin
        //按键被按下
        cnt <= DELAY_MS;
      end else if (key_ff0 == KEY_RELEASED_VALUE && key_ff1 != KEY_RELEASED_VALUE) begin
        //按键松开
        cnt <= 0;
      end else if (pluse_ms) begin
        //每隔1ms减1
        if (cnt > 0) begin
          cnt <= cnt - 1'b1;
        end else begin
          cnt <= 0;
        end
      end else begin
        cnt <= cnt;
      end
    end

  end

  //将消抖后的最终的按键值送出去
  always @(posedge clk) begin
    if (!resetn) begin
      pressed <= 0;
      change  <= 1'b0;
    end else if (key_ff0 == KEY_RELEASED_VALUE && key_ff1 != KEY_RELEASED_VALUE) begin
      pressed <= 0;
      if (pressed != KEY_RELEASED_VALUE) begin
        change <= 1'b1;
      end else begin
        change <= 1'b0;
      end
    end else if (pluse_ms && cnt == 1 && key_ff1 == key_ff0) begin
      //在计数器递减到1按下
      pressed <= 1'b1;
      change  <= 1'b1;
    end else begin
      pressed <= pressed;
      change  <= 1'b0;
    end
  end

endmodule
