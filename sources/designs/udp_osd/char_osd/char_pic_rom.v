// 保存字符点阵的ROM封装

module char_pic_rom #(
    parameter CHAR_PIC_WIDTH = 9  //字符点阵的宽度，例如18*9的ASCII字符，宽度位9


) (
    input clk,
    input resetn,


    //rom接口
    input [7:0] char_ascii,
    input [5:0] char_row_index,

    //字符点阵 的 当前一行 的显示的起始地址
    input [10:0] char_pos_x,
    input [10:0] char_pos_y,

    input char_valid,  //数据有效信号，从收到char_next到输出下一个字符需要一定时间，此时valid拉低
    output reg char_next,  //收到该信号后，切换到下一个字符。

    // 像素点 输出
    output     [CHAR_PIC_WIDTH-1:0] m_row_pixels_data,   //字符的一行像素点
    output reg [              10:0] m_row_pixels_posX,   // 该行像素点的起始X坐标
    output reg [              10:0] m_row_pixels_posY,   // 该行像素点的Y坐标
    output reg                      m_row_pixels_valid,
    input                           m_row_pixels_ready
);

  reg  [10 : 0] rom_addr_d;  //地址计算的中间量
  reg  [10 : 0] rom_addr;  //rom读取地址
  wire [ 8 : 0] pixels_data;  //连接线 连接rom输出和m_row_pixels_data

  reg  [   2:0] valid_d;  //上游valid信号大拍



  ascii_char_rom ascii_char_rom_inst (
      .addr   (rom_addr),    // input [10:0]
      .clk    (clk),         // input
      .rst    (~resetn),     // input
      .rd_data(pixels_data)  // output [8:0]
  );


  // 计算ROM读取地址，常数减法和乘法单独一拍，寄存器相加一拍
  always @(posedge clk) begin
    if (~resetn) begin
      rom_addr   <= 0;
      rom_addr_d <= 0;
    end else begin
      if (char_ascii >= 33 && char_ascii <= 126) begin
        rom_addr_d <= (char_ascii - 33) * 18;
      end else begin
        rom_addr_d <= 0;
      end
      rom_addr <= rom_addr_d + char_row_index;
    end
  end


  always @(posedge clk) begin
    if (~resetn) begin
      valid_d <= 0;
    end else begin
      valid_d <= {valid_d[1:0], char_valid};
    end
  end






  always @(posedge clk) begin
    if (~resetn) begin
      m_row_pixels_posY <= 0;
      m_row_pixels_posX <= 0;
    end else begin
      m_row_pixels_posX <= char_pos_x;
      m_row_pixels_posY <= char_pos_y + char_row_index;
    end
  end


  // 为了尽快更新数据，没有打拍，使用组合电路
  // 逻辑比较简单，综合器会自动优化的。
  always @(*) begin
    if (~resetn) begin
      char_next = 0;
    end else begin
      char_next = m_row_pixels_ready & m_row_pixels_valid;
    end
  end



  assign m_row_pixels_data = pixels_data;

  // 数据有效 信号
  // 当检测上游数据有效信号打拍后的上升沿时，拉高，当当前数据被读走时，立刻拉低
  always @(posedge clk) begin
    if (~resetn) begin
      m_row_pixels_valid <= 0;
    end else if (~valid_d[2] & valid_d[1]) begin
      m_row_pixels_valid <= 1;
    end else if (m_row_pixels_ready & m_row_pixels_valid) begin
      m_row_pixels_valid <= 0;
    end else begin
      m_row_pixels_valid <= m_row_pixels_valid;
    end
  end


endmodule
