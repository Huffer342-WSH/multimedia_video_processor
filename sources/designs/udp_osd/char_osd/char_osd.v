module char_osd #(
    parameter STRLENDATA_SAVED_ADDR = 1023,  //字符串长度变量 在 RAM中的位置 
    parameter CHAR_BUFFER_ADDR_WIDTH = 12,
    parameter CHAR_PIC_WIDTH = 9,
    parameter CHAR_PIC_HEIGHT = 18,
    parameter SCREEN_WIDTH = 1920,  //显示器宽度
    parameter SCREEN_HEIGHT = 1080  //显示器高度
) (
    input clk,
    input resetn,

    input [10:0] cfg_start_posX,
    input [10:0] cfg_start_posY,
    input [10:0] cfg_end_posX,
    input [10:0] cfg_end_posY,
    input [10:0] cfg_char_width,
    input [10:0] cfg_char_height,


    //ram接口
    output [CHAR_BUFFER_ADDR_WIDTH-1:0] ram_rd_addr,
    input  [                       7:0] ram_dout,

    //点阵信息输出接口
    output        m_pixel_data,   //1bit像素点
    output        m_pixel_valid,
    input         m_pixel_ready,
    output [10:0] m_pixel_posX,   // 像素点X坐标
    output [10:0] m_pixel_posY    //像素点Y坐标
);


  //用于连接char_buf_reader和char_pic_rom的wire
  wire [               7:0] char_ascii;
  wire [               5:0] char_row_index;
  wire [              10:0] char_pos_x;
  wire [              10:0] char_pos_y;
  wire                      char_valid;
  wire                      char_next;

  //用于连接char_pic_rom和pixels_shifter的wire
  wire [CHAR_PIC_WIDTH-1:0] row_pixels_data;
  wire                      row_pixels_valid;
  wire [              10:0] row_pixels_posX;
  wire [              10:0] row_pixels_posY;
  wire                      row_pixels_ready;

  //--- 从RAM中读取字符 ---//
  char_buf_reader #(
      .STRLENDATA_SAVED_ADDR(STRLENDATA_SAVED_ADDR),
      .CHAR_BUFFER_ADDR_WIDTH(CHAR_BUFFER_ADDR_WIDTH),
      .CHAR_PIC_HEIGHT(CHAR_PIC_HEIGHT),
      .SCREEN_WIDTH(SCREEN_WIDTH),
      .SCREEN_HEIGHT(SCREEN_HEIGHT)
  ) char_buf_reader_inst (
      .clk   (clk),
      .resetn(resetn),

      .cfg_start_posX (cfg_start_posX),  // input [10:0] cfg_start_posX
      .cfg_start_posY (cfg_start_posY),  // input [10:0] cfg_start_posY
      .cfg_end_posX   (cfg_end_posX),    // input [10:0] cfg_end_posX
      .cfg_end_posY   (cfg_end_posY),    // input [10:0] cfg_end_posY
      .cfg_char_width (cfg_char_width),  // input [10:0] cfg_char_width
      .cfg_char_height(cfg_char_height), // input [10:0] cfg_char_height


      .ram_addr(ram_rd_addr),
      .ram_data(ram_dout),

      //字符输出
      .char_ascii    (char_ascii),      // output [7:0]
      .char_row_index(char_row_index),  // output [5:0]
      .char_pos_x    (char_pos_x),      // output [10:0]
      .char_pos_y    (char_pos_y),      // output [10:0]
      .char_valid    (char_valid),      // output
      .char_next     (char_next)        // intput
  );


  //--- 根据字符ASCII码和row_index 输出 一行点阵 ---//
  char_pic_rom #(
      .CHAR_PIC_WIDTH(CHAR_PIC_WIDTH)
  ) char_pic_rom_inst (
      .clk   (clk),
      .resetn(resetn),

      .char_ascii    (char_ascii),
      .char_row_index(char_row_index),
      .char_pos_x    (char_pos_x),
      .char_pos_y    (char_pos_y),
      .char_valid    (char_valid),
      .char_next     (char_next),

      .m_row_pixels_data (row_pixels_data),
      .m_row_pixels_valid(row_pixels_valid),
      .m_row_pixels_posX (row_pixels_posX),
      .m_row_pixels_posY (row_pixels_posY),
      .m_row_pixels_ready(row_pixels_ready)
  );

  //--- 并行输入 一行点阵  串行输出像素点---//
  pixels_shifter #(
      .CHAR_PIC_WIDTH(CHAR_PIC_WIDTH),
      .SCREEN_WIDTH  (SCREEN_WIDTH),
      .SCREEN_HEIGHT (SCREEN_HEIGHT)
  ) pixels_shifter_inst (
      .clk   (clk),
      .resetn(resetn),

      .s_row_pixels_data (row_pixels_data),
      .s_row_pixels_valid(row_pixels_valid),
      .s_row_pixels_posX (row_pixels_posX),
      .s_row_pixels_posY (row_pixels_posY),
      .s_row_pixels_ready(row_pixels_ready),

      .m_pixel_data (m_pixel_data),
      .m_pixel_valid(m_pixel_valid),
      .m_pixel_ready(m_pixel_ready),
      .m_pixel_posX (m_pixel_posX),
      .m_pixel_posY (m_pixel_posY)
  );

endmodule
