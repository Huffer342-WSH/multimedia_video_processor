// 参数管理
// 滤波器1mode 滤波器2mode 缩放系数  旋转系数  OSD起始X OSD起始Y OSD字符间距 OSD行距  缩放系数2
// [2:0]      [10:8]     [25:16]  [39:32]  [50:40] [66:56]  [82:72]   [98:88]  [113:104]
// 0           1          2 3      4       5 6     7 8      9 10      11 12     13  14
// 0           1          2        3       4       5        6         7        8
//
// 图像位移X   图像位移Y    色域修改H    色域修改S  色域修改V
// [131:120]  [147:136]   [160:152]  [176:168] [192:184]
// 15  16     17 18       19 20      21 22     23 24
// 9          10          11         12        13
module param_manager #(
    parameter integer CLK_FREQ = 50_000000
) (
    //! 时钟
    input clk,
    //! 复位
    input resetn,

    //! 按键-左
    input akey_left,
    //! 按键-右
    input akey_right,
    //! 按键-上
    input akey_up,
    //! 按键-下
    input akey_down,
    //! 按键—恢复
    input akey_restore,

    //! 带加载参数
    input [199:0] mem,
    //! 参数变化标志
    input [ 24:0] mem_flags,

    //! 参数序号
    output reg [3:0] index,
    //! 滤波器1 模式
    output [2:0] filiter1_mode,
    //! 滤波器2 模式
    output [2:0] filiter2_mode,
    //! 双线性插值缩放系数
    output [9:0] zoom,
    //! 旋转系数
    output [7:0] rotate,
    //! OSD起始X坐标
    output [10:0] osd_startX,
    //! OSD起始Y坐标
    output [10:0] osd_startY,
    //! OSD字符宽度
    output [10:0] osd_char_width,
    //! 文本行距
    output [10:0] osd_char_height,
    //! 缩放系数2
    output [9:0] rotate_A,
    //!  图像偏移X
    output wire signed [11:0] offsetX,
    //! 图像偏移Y
    output wire signed [11:0] offsetY,
    //! 色相偏移
    output wire signed [8:0] modify_H,
    //! 饱和度偏移 
    output wire signed [8:0] modify_S,
    //! 亮度偏移
    output wire signed [8:0] modify_V
);
  localparam integer ParamNum = 14;


  //--- 时钟分频 ---//
  reg clk_ms;
  reg [29:0] ms_cnt;
  always @(posedge clk) begin
    if (~resetn) begin
      ms_cnt <= 0;
      clk_ms <= 0;
    end else begin
      if (ms_cnt == CLK_FREQ / 1000) begin
        ms_cnt <= 0;
        clk_ms <= 1;
      end else if (ms_cnt > CLK_FREQ / 2000) begin
        ms_cnt <= ms_cnt + 1;
        clk_ms <= 0;
      end else begin
        ms_cnt <= ms_cnt + 1;
        clk_ms <= 1;
      end
    end
  end


  //---------------------------------------------------------------
  // 按键控制参数选择
  //---------------------------------------------------------------
  wire pressed_left, pressed_right, pressed_restore;
  wire changed_left, changed_right, changed_restore;
  reg [ParamNum-1:0] selected;
  // reg [3:0] index;
  key_debounce #(
      .CLK_FREQ(CLK_FREQ),
      .DELAY_MS(20),
      .KEY_RELEASED_VALUE(1)
  ) key_debounce_key_left (
      .clk(clk),
      .clk_ms(clk_ms),
      .resetn(resetn),
      .key_in(akey_left),
      .pressed(pressed_left),
      .change(changed_left)
  );
  key_debounce #(
      .CLK_FREQ(CLK_FREQ),
      .DELAY_MS(20),
      .KEY_RELEASED_VALUE(1)
  ) key_debounce_key_right (
      .clk(clk),
      .clk_ms(clk_ms),
      .resetn(resetn),
      .key_in(akey_right),
      .pressed(pressed_right),
      .change(changed_right)
  );
  key_debounce #(
      .CLK_FREQ(CLK_FREQ),
      .DELAY_MS(20),
      .KEY_RELEASED_VALUE(1)
  ) key_debounce_key_restore (
      .clk(clk),
      .clk_ms(clk_ms),
      .resetn(resetn),
      .key_in(akey_restore),
      .pressed(pressed_restore),
      .change(changed_restore)
  );


  //! 按键控制当前选择的参数序号
  always @(posedge clk) begin
    if (~resetn) begin
      index <= 0;
    end else if (changed_right && pressed_right) begin
      if (index >= ParamNum - 1) begin
        index <= 0;
      end else begin
        index <= index + 1;
      end
    end else if (changed_left && pressed_left) begin
      if (index == 0) begin
        index <= ParamNum - 1;
      end else begin
        index <= index - 1;
      end
    end else begin
      index <= index;
    end
  end

  genvar i;
  generate
    for (i = 0; i < ParamNum; i = i + 1) begin : g_selected
      always @(posedge clk) begin
        if (~resetn) begin
          selected[i] <= 0;
        end else if (index == i) begin
          selected[i] <= 1;
        end else begin
          selected[i] <= 0;
        end
      end
    end
  endgenerate

  //---------------------------------------------------------------
  // 例化参数
  //---------------------------------------------------------------

  //--- 滤波器1 mode ---//
  reg filiter1_mode_flags_ff0, filiter1_mode_flags_ff1;
  reg filiter1_mode_load;
  always @(posedge clk) begin
    filiter1_mode_flags_ff0 <= mem_flags[0];
    filiter1_mode_flags_ff1 <= filiter1_mode_flags_ff0;
    if (filiter1_mode_flags_ff1 != filiter1_mode_flags_ff0) begin
      filiter1_mode_load <= 1;
    end else begin
      filiter1_mode_load <= 0;
    end
  end
  param_cell_unsigned_loop #(
      .CLK_FREQ(CLK_FREQ),
      .PARAM_WIDTH(3),
      .PRESSED_TRIG_CYCLE_MS(2000),
      .DEFAULT_VALUE(0),
      .RANGE_MIN(0),
      .RANGE_MAX(4)
  ) param_filiter1_mode (
      .clk(clk),
      .clk_ms(clk_ms),
      .resetn(resetn),
      .selected(selected[0]),
      .restore(pressed_restore),
      .load_valid(filiter1_mode_load),
      .load_data(mem[2:0]),
      .akey_up(akey_up),
      .akey_down(akey_down),
      .value(filiter1_mode)
  );

  //--- 滤波器2 mode ---//
  reg filiter2_mode_flags_ff0, filiter2_mode_flags_ff1;
  reg filiter2_mode_load;
  always @(posedge clk) begin
    filiter2_mode_flags_ff0 <= mem_flags[1];
    filiter2_mode_flags_ff1 <= filiter2_mode_flags_ff0;
    if (filiter2_mode_flags_ff1 != filiter2_mode_flags_ff0) begin
      filiter2_mode_load <= 1;
    end else begin
      filiter2_mode_load <= 0;
    end
  end
  param_cell_unsigned_loop #(
      .CLK_FREQ(CLK_FREQ),
      .PARAM_WIDTH(3),
      .PRESSED_TRIG_CYCLE_MS(2000),
      .DEFAULT_VALUE(0),
      .RANGE_MIN(0),
      .RANGE_MAX(4)
  ) param_filiter2_mode (
      .clk(clk),
      .clk_ms(clk_ms),
      .resetn(resetn),
      .selected(selected[1]),
      .restore(pressed_restore),
      .load_valid(filiter2_mode_load),
      .load_data(mem[10:8]),
      .akey_up(akey_up),
      .akey_down(akey_down),
      .value(filiter2_mode)
  );

  //--- 缩放参数 ---//
  reg zoom_flags_ff0, zoom_flags_ff1;
  reg zoom_flags_ff2, zoom_flags_ff3;
  reg zoom_load;
  always @(posedge clk) begin
    zoom_flags_ff0 <= mem_flags[2];
    zoom_flags_ff1 <= zoom_flags_ff0;
    zoom_flags_ff2 <= mem_flags[3];
    zoom_flags_ff3 <= zoom_flags_ff2;
    if ((zoom_flags_ff1 != zoom_flags_ff0) || (zoom_flags_ff3 != zoom_flags_ff2)) begin
      zoom_load <= 1;
    end else begin
      zoom_load <= 0;
    end
  end
  param_cell_unsigned #(
      .CLK_FREQ(CLK_FREQ),
      .PARAM_WIDTH(10),
      .PRESSED_TRIG_CYCLE_MS(20),
      .DEFAULT_VALUE(128),
      .RANGE_MIN(1),
      .RANGE_MAX(1023)
  ) param_zoom (
      .clk(clk),
      .clk_ms(clk_ms),
      .resetn(resetn),
      .selected(selected[2]),
      .restore(pressed_restore),
      .load_valid(zoom_load),
      .load_data(mem[25:16]),
      .akey_up(akey_up),
      .akey_down(akey_down),
      .value(zoom)
  );


  //--- 旋转系数 ---//
  reg rotate_flags_ff0, rotate_flags_ff1;
  reg rotate_load;
  always @(posedge clk) begin
    rotate_flags_ff0 <= mem_flags[4];
    rotate_flags_ff1 <= rotate_flags_ff0;
    if (rotate_flags_ff1 != rotate_flags_ff0) begin
      rotate_load <= 1;
    end else begin
      rotate_load <= 0;
    end
  end
  param_cell_unsigned_loop #(
      .CLK_FREQ(CLK_FREQ),
      .PARAM_WIDTH(8),
      .PRESSED_TRIG_CYCLE_MS(50),
      .DEFAULT_VALUE(0),
      .RANGE_MIN(0),
      .RANGE_MAX(255)
  ) param_rotate (
      .clk(clk),
      .clk_ms(clk_ms),
      .resetn(resetn),
      .selected(selected[3]),
      .restore(pressed_restore),
      .load_valid(rotate_load),
      .load_data(mem[39:32]),
      .akey_up(akey_up),
      .akey_down(akey_down),
      .value(rotate)
  );


  //--- OSD起始X ---//
  reg osd_startX_flags_ff0, osd_startX_flags_ff1;
  reg osd_startX_flags_ff2, osd_startX_flags_ff3;
  reg osd_startX_load;
  always @(posedge clk) begin
    osd_startX_flags_ff0 <= mem_flags[5];
    osd_startX_flags_ff1 <= osd_startX_flags_ff0;
    osd_startX_flags_ff2 <= mem_flags[6];
    osd_startX_flags_ff3 <= osd_startX_flags_ff2;
    if ((osd_startX_flags_ff1 != osd_startX_flags_ff0) ||
        (osd_startX_flags_ff3 != osd_startX_flags_ff2)) begin
      osd_startX_load <= 1;
    end else begin
      osd_startX_load <= 0;
    end
  end
  param_cell_unsigned #(
      .CLK_FREQ(CLK_FREQ),
      .PARAM_WIDTH(11),
      .PRESSED_TRIG_CYCLE_MS(30),
      .DEFAULT_VALUE(20),
      .RANGE_MIN(1),
      .RANGE_MAX(1900)
  ) param_osd_startX (
      .clk(clk),
      .clk_ms(clk_ms),
      .resetn(resetn),
      .selected(selected[4]),
      .restore(pressed_restore),
      .load_valid(osd_startX_load),
      .load_data(mem[50:40]),
      .akey_up(akey_up),
      .akey_down(akey_down),
      .value(osd_startX)
  );

  //--- OSD起始Y ---//
  reg osd_startY_flags_ff0, osd_startY_flags_ff1;
  reg osd_startY_flags_ff2, osd_startY_flags_ff3;
  reg osd_startY_load;
  always @(posedge clk) begin
    osd_startY_flags_ff0 <= mem_flags[7];
    osd_startY_flags_ff1 <= osd_startY_flags_ff0;
    osd_startY_flags_ff2 <= mem_flags[8];
    osd_startY_flags_ff3 <= osd_startY_flags_ff2;
    if ((osd_startY_flags_ff1 != osd_startY_flags_ff0) ||
        (osd_startY_flags_ff3 != osd_startY_flags_ff2)) begin
      osd_startY_load <= 1;
    end else begin
      osd_startY_load <= 0;
    end
  end
  param_cell_unsigned #(
      .CLK_FREQ(CLK_FREQ),
      .PARAM_WIDTH(11),
      .PRESSED_TRIG_CYCLE_MS(100),
      .DEFAULT_VALUE(10),
      .RANGE_MIN(1),
      .RANGE_MAX(1060)
  ) param_osd_startY (
      .clk(clk),
      .clk_ms(clk_ms),
      .resetn(resetn),
      .selected(selected[5]),
      .restore(pressed_restore),
      .load_valid(osd_startY_load),
      .load_data(mem[66:56]),
      .akey_up(akey_up),
      .akey_down(akey_down),
      .value(osd_startY)
  );

  //--- OSD字符间距 ---//
  reg osd_char_width_flags_ff0, osd_char_width_flags_ff1;
  reg osd_char_width_flags_ff2, osd_char_width_flags_ff3;
  reg osd_char_width_load;
  always @(posedge clk) begin
    osd_char_width_flags_ff0 <= mem_flags[9];
    osd_char_width_flags_ff1 <= osd_char_width_flags_ff0;
    osd_char_width_flags_ff2 <= mem_flags[10];
    osd_char_width_flags_ff3 <= osd_char_width_flags_ff2;
    if ((osd_char_width_flags_ff1 != osd_char_width_flags_ff0) ||
        (osd_char_width_flags_ff3 != osd_char_width_flags_ff2)) begin
      osd_char_width_load <= 1;
    end else begin
      osd_char_width_load <= 0;
    end
  end
  param_cell_unsigned #(
      .CLK_FREQ(CLK_FREQ),
      .PARAM_WIDTH(11),
      .PRESSED_TRIG_CYCLE_MS(100),
      .DEFAULT_VALUE(10),
      .RANGE_MIN(10),
      .RANGE_MAX(50)
  ) param_osd_char_width (
      .clk(clk),
      .clk_ms(clk_ms),
      .resetn(resetn),
      .selected(selected[6]),
      .restore(pressed_restore),
      .load_valid(osd_char_width_load),
      .load_data(mem[82:72]),
      .akey_up(akey_up),
      .akey_down(akey_down),
      .value(osd_char_width)
  );


  //--- OSD字符行距 ---//
  reg osd_char_height_flags_ff0, osd_char_height_flags_ff1;
  reg osd_char_height_flags_ff2, osd_char_height_flags_ff3;
  reg osd_char_height_load;
  always @(posedge clk) begin
    osd_char_height_flags_ff0 <= mem_flags[11];
    osd_char_height_flags_ff1 <= osd_char_height_flags_ff0;
    osd_char_height_flags_ff2 <= mem_flags[12];
    osd_char_height_flags_ff3 <= osd_char_height_flags_ff2;
    if ((osd_char_height_flags_ff1 != osd_char_height_flags_ff0) ||
        (osd_char_height_flags_ff3 != osd_char_height_flags_ff2)) begin
      osd_char_height_load <= 1;
    end else begin
      osd_char_height_load <= 0;
    end
  end
  param_cell_unsigned #(
      .CLK_FREQ(CLK_FREQ),
      .PARAM_WIDTH(11),
      .PRESSED_TRIG_CYCLE_MS(100),
      .DEFAULT_VALUE(18),
      .RANGE_MIN(18),
      .RANGE_MAX(100)
  ) param_osd_char_height (
      .clk(clk),
      .clk_ms(clk_ms),
      .resetn(resetn),
      .selected(selected[7]),
      .restore(pressed_restore),
      .load_valid(osd_char_height_load),
      .load_data(mem[98:88]),
      .akey_up(akey_up),
      .akey_down(akey_down),
      .value(osd_char_height)
  );

  //--- 旋转 幅度 ---//
  reg rotate_A_flags_ff0, rotate_A_flags_ff1;
  reg rotate_A_flags_ff2, rotate_A_flags_ff3;
  reg rotate_A_load;
  always @(posedge clk) begin
    rotate_A_flags_ff0 <= mem_flags[13];
    rotate_A_flags_ff1 <= rotate_A_flags_ff0;
    rotate_A_flags_ff2 <= mem_flags[14];
    rotate_A_flags_ff3 <= rotate_A_flags_ff2;
    if ((rotate_A_flags_ff1 != rotate_A_flags_ff0) ||
        (rotate_A_flags_ff3 != rotate_A_flags_ff2)) begin
      rotate_A_load <= 1;
    end else begin
      rotate_A_load <= 0;
    end
  end
  param_cell_unsigned #(
      .CLK_FREQ(CLK_FREQ),
      .PARAM_WIDTH(10),
      .PRESSED_TRIG_CYCLE_MS(20),
      .DEFAULT_VALUE(128),
      .RANGE_MIN(1),
      .RANGE_MAX(1023)
  ) param_rotate_A (
      .clk(clk),
      .clk_ms(clk_ms),
      .resetn(resetn),
      .selected(selected[8]),
      .restore(pressed_restore),
      .load_valid(rotate_A_load),
      .load_data(mem[113:104]),
      .akey_up(akey_up),
      .akey_down(akey_down),
      .value(rotate_A)
  );


  //--- 图像位移X  ---//
  reg offsetX_flags_ff0, offsetX_flags_ff1;
  reg offsetX_flags_ff2, offsetX_flags_ff3;
  reg offsetX_load;
  always @(posedge clk) begin
    offsetX_flags_ff0 <= mem_flags[15];
    offsetX_flags_ff1 <= offsetX_flags_ff0;
    offsetX_flags_ff2 <= mem_flags[16];
    offsetX_flags_ff3 <= offsetX_flags_ff2;
    if ((offsetX_flags_ff1 != offsetX_flags_ff0) || (offsetX_flags_ff3 != offsetX_flags_ff2)) begin
      offsetX_load <= 1;
    end else begin
      offsetX_load <= 0;
    end
  end
  param_cell_signed #(
      .CLK_FREQ(CLK_FREQ),
      .PARAM_WIDTH(12),
      .PRESSED_TRIG_CYCLE_MS(10),
      .DEFAULT_VALUE(0),
      .RANGE_MIN(-1920),
      .RANGE_MAX(1920)
  ) param_offsetX (
      .clk(clk),
      .clk_ms(clk_ms),
      .resetn(resetn),
      .selected(selected[9]),
      .restore(pressed_restore),
      .load_valid(offsetX_load),
      .load_data(mem[131:120]),
      .akey_up(akey_up),
      .akey_down(akey_down),
      .value(offsetX)
  );

  //--- 图像位移Y  ---//
  reg offsetY_flags_ff0, offsetY_flags_ff1;
  reg offsetY_flags_ff2, offsetY_flags_ff3;
  reg offsetY_load;
  always @(posedge clk) begin
    offsetY_flags_ff0 <= mem_flags[17];
    offsetY_flags_ff1 <= offsetY_flags_ff0;
    offsetY_flags_ff2 <= mem_flags[18];
    offsetY_flags_ff3 <= offsetY_flags_ff2;
    if ((offsetY_flags_ff1 != offsetY_flags_ff0) || (offsetY_flags_ff3 != offsetY_flags_ff2)) begin
      offsetY_load <= 1;
    end else begin
      offsetY_load <= 0;
    end
  end
  param_cell_signed #(
      .CLK_FREQ(CLK_FREQ),
      .PARAM_WIDTH(12),
      .PRESSED_TRIG_CYCLE_MS(10),
      .DEFAULT_VALUE(0),
      .RANGE_MIN(-1080),
      .RANGE_MAX(1080)
  ) param_offsetY (
      .clk(clk),
      .clk_ms(clk_ms),
      .resetn(resetn),
      .selected(selected[10]),
      .restore(pressed_restore),
      .load_valid(offsetY_load),
      .load_data(mem[147:136]),
      .akey_up(akey_up),
      .akey_down(akey_down),
      .value(offsetY)
  );


  //--- 色域修改H  ---//
  reg modify_H_flags_ff0, modify_H_flags_ff1;
  reg modify_H_flags_ff2, modify_H_flags_ff3;
  reg modify_H_load;
  always @(posedge clk) begin
    modify_H_flags_ff0 <= mem_flags[19];
    modify_H_flags_ff1 <= modify_H_flags_ff0;
    modify_H_flags_ff2 <= mem_flags[20];
    modify_H_flags_ff3 <= modify_H_flags_ff2;
    if ((modify_H_flags_ff1 != modify_H_flags_ff0) ||
        (modify_H_flags_ff3 != modify_H_flags_ff2)) begin
      modify_H_load <= 1;
    end else begin
      modify_H_load <= 0;
    end
  end
  param_cell_signed_loop #(
      .CLK_FREQ(CLK_FREQ),
      .PARAM_WIDTH(9),
      .PRESSED_TRIG_CYCLE_MS(20),
      .DEFAULT_VALUE(0),
      .RANGE_MIN(-192),
      .RANGE_MAX(191)
  ) param_modify_H (
      .clk(clk),
      .clk_ms(clk_ms),
      .resetn(resetn),
      .selected(selected[11]),
      .restore(pressed_restore),
      .load_valid(modify_H_load),
      .load_data(mem[160:152]),
      .akey_up(akey_up),
      .akey_down(akey_down),
      .value(modify_H)
  );


  //--- 色域修改S  ---//
  reg modify_S_flags_ff0, modify_S_flags_ff1;
  reg modify_S_flags_ff2, modify_S_flags_ff3;
  reg modify_S_load;
  always @(posedge clk) begin
    modify_S_flags_ff0 <= mem_flags[21];
    modify_S_flags_ff1 <= modify_S_flags_ff0;
    modify_S_flags_ff2 <= mem_flags[22];
    modify_S_flags_ff3 <= modify_S_flags_ff2;
    if ((modify_S_flags_ff1 != modify_S_flags_ff0) ||
        (modify_S_flags_ff3 != modify_S_flags_ff2)) begin
      modify_S_load <= 1;
    end else begin
      modify_S_load <= 0;
    end
  end
  param_cell_signed #(
      .CLK_FREQ(CLK_FREQ),
      .PARAM_WIDTH(9),
      .PRESSED_TRIG_CYCLE_MS(20),
      .DEFAULT_VALUE(0),
      .RANGE_MIN(-255),
      .RANGE_MAX(255)
  ) param_modify_S (
      .clk(clk),
      .clk_ms(clk_ms),
      .resetn(resetn),
      .selected(selected[12]),
      .restore(pressed_restore),
      .load_valid(modify_S_load),
      .load_data(mem[176:168]),
      .akey_up(akey_up),
      .akey_down(akey_down),
      .value(modify_S)
  );


  //--- 色域修改V  ---//
  reg modify_V_flags_ff0, modify_V_flags_ff1;
  reg modify_V_flags_ff2, modify_V_flags_ff3;
  reg modify_V_load;
  always @(posedge clk) begin
    modify_V_flags_ff0 <= mem_flags[23];
    modify_V_flags_ff1 <= modify_V_flags_ff0;
    modify_V_flags_ff2 <= mem_flags[24];
    modify_V_flags_ff3 <= modify_V_flags_ff2;
    if ((modify_V_flags_ff1 != modify_V_flags_ff0) ||
        (modify_V_flags_ff3 != modify_V_flags_ff2)) begin
      modify_V_load <= 1;
    end else begin
      modify_V_load <= 0;
    end
  end
  param_cell_signed #(
      .CLK_FREQ(CLK_FREQ),
      .PARAM_WIDTH(9),
      .PRESSED_TRIG_CYCLE_MS(20),
      .DEFAULT_VALUE(0),
      .RANGE_MIN(-255),
      .RANGE_MAX(255)
  ) param_modify_V (
      .clk(clk),
      .clk_ms(clk_ms),
      .resetn(resetn),
      .selected(selected[13]),
      .restore(pressed_restore),
      .load_valid(modify_V_load),
      .load_data(mem[192:184]),
      .akey_up(akey_up),
      .akey_down(akey_down),
      .value(modify_V)
  );


endmodule
