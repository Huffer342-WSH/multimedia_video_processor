module char_osd #(
    parameter STRLENDATA_SAVED_ADDR = 1023,  //�ַ������ȱ��� �� RAM�е�λ�� 
    parameter CHAR_BUFFER_ADDR_WIDTH = 12,
    parameter CHAR_PIC_WIDTH = 9,
    parameter CHAR_PIC_HEIGHT = 18,
    parameter SCREEN_WIDTH = 1920,  //��ʾ�����
    parameter SCREEN_HEIGHT = 1080  //��ʾ���߶�
) (
    input clk,
    input resetn,

    input [10:0] cfg_start_posX,
    input [10:0] cfg_start_posY,
    input [10:0] cfg_end_posX,
    input [10:0] cfg_end_posY,
    input [10:0] cfg_char_width,
    input [10:0] cfg_char_height,


    //ram�ӿ�
    output [CHAR_BUFFER_ADDR_WIDTH-1:0] ram_rd_addr,
    input  [                       7:0] ram_dout,

    //������Ϣ����ӿ�
    output        m_pixel_data,   //1bit���ص�
    output        m_pixel_valid,
    input         m_pixel_ready,
    output [10:0] m_pixel_posX,   // ���ص�X����
    output [10:0] m_pixel_posY    //���ص�Y����
);


  //��������char_buf_reader��char_pic_rom��wire
  wire [               7:0] char_ascii;
  wire [               5:0] char_row_index;
  wire [              10:0] char_pos_x;
  wire [              10:0] char_pos_y;
  wire                      char_valid;
  wire                      char_next;

  //��������char_pic_rom��pixels_shifter��wire
  wire [CHAR_PIC_WIDTH-1:0] row_pixels_data;
  wire                      row_pixels_valid;
  wire [              10:0] row_pixels_posX;
  wire [              10:0] row_pixels_posY;
  wire                      row_pixels_ready;

  //--- ��RAM�ж�ȡ�ַ� ---//
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

      //�ַ����
      .char_ascii    (char_ascii),      // output [7:0]
      .char_row_index(char_row_index),  // output [5:0]
      .char_pos_x    (char_pos_x),      // output [10:0]
      .char_pos_y    (char_pos_y),      // output [10:0]
      .char_valid    (char_valid),      // output
      .char_next     (char_next)        // intput
  );


  //--- �����ַ�ASCII���row_index ��� һ�е��� ---//
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

  //--- �������� һ�е���  ����������ص�---//
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
