module pixels_shifter #(
    parameter CHAR_PIC_WIDTH = 9,  //字符点阵的宽度，例如18*9的ASCII字符，宽度位9
    parameter SCREEN_WIDTH = 1920,  //显示器宽度
    parameter SCREEN_HEIGHT = 1080  //显示器高度
) (

    input clk,
    input resetn,


    input  [CHAR_PIC_WIDTH-1:0] s_row_pixels_data,
    input                       s_row_pixels_valid,
    input  [              10:0] s_row_pixels_posX,
    input  [              10:0] s_row_pixels_posY,
    output                      s_row_pixels_ready,

    output            m_pixel_data,
    output reg        m_pixel_valid,
    input             m_pixel_ready,
    output reg [10:0] m_pixel_posX,
    output reg [10:0] m_pixel_posY
);


  reg [CHAR_PIC_WIDTH-1:0] pixels_data;
  reg [               5:0] pix_cnt;

  assign m_pixel_data = pixels_data[CHAR_PIC_WIDTH-1];

  reg s_ready_c, s_ready_d;

  always @(*) begin
    if (~resetn) begin
      s_ready_c = 0;
    end else if (pix_cnt == CHAR_PIC_WIDTH - 1 && m_pixel_valid && m_pixel_ready) begin
      s_ready_c = 1;
    end else if (m_pixel_posX >= SCREEN_WIDTH - 1) begin
      s_ready_c = 1;
    end else begin
      s_ready_c = 0;
    end
  end

  always @(posedge clk) begin
    if (~resetn) begin
      s_ready_d <= 0;
    end else if (s_row_pixels_valid && s_row_pixels_ready) begin
      if ((s_row_pixels_posX <= SCREEN_WIDTH) && (s_row_pixels_posY <= SCREEN_HEIGHT)) begin
        s_ready_d <= 0;
      end else begin
        s_ready_d <= 1;
      end
    end else if (s_ready_c && ~s_row_pixels_valid) begin
      s_ready_d <= 1;
    end else if (pix_cnt == CHAR_PIC_WIDTH - 1 && ~m_pixel_valid) begin
      s_ready_d <= 1;
    end else begin
      s_ready_d <= s_ready_d;
    end
  end


  assign s_row_pixels_ready = s_ready_d | s_ready_c;




  always @(posedge clk) begin
    if (~resetn) begin
      m_pixel_valid <= 0;
    end else if (s_row_pixels_valid && s_row_pixels_ready && (s_row_pixels_posX <= SCREEN_WIDTH) && (s_row_pixels_posY <= SCREEN_HEIGHT)) begin
      m_pixel_valid <= 1;
    end else if (m_pixel_valid && m_pixel_ready && pix_cnt == CHAR_PIC_WIDTH - 1) begin
      m_pixel_valid <= 0;
    end else begin
      m_pixel_valid <= m_pixel_valid;
    end
  end


  always @(posedge clk) begin
    if (~resetn) begin
      pix_cnt <= CHAR_PIC_WIDTH - 1;
    end else if (s_row_pixels_valid && s_row_pixels_ready) begin
      pix_cnt <= 0;
    end else if (m_pixel_valid && m_pixel_ready) begin
      pix_cnt <= pix_cnt + 1;
    end else begin
      pix_cnt <= pix_cnt;
    end
  end



  always @(posedge clk) begin
    if (~resetn) begin
      pixels_data <= 0;
    end else if (s_row_pixels_valid && s_row_pixels_ready) begin
      pixels_data <= s_row_pixels_data;
    end else if (m_pixel_valid && m_pixel_ready) begin
      pixels_data <= pixels_data << 1;
    end else begin
      pixels_data <= pixels_data;
    end
  end

  always @(posedge clk) begin
    if (~resetn) begin
      m_pixel_posX <= 0;
      m_pixel_posY <= 0;
    end else if (s_row_pixels_valid && s_row_pixels_ready) begin
      m_pixel_posX <= s_row_pixels_posX;
      m_pixel_posY <= s_row_pixels_posY;
    end else if (m_pixel_valid && m_pixel_ready) begin
      m_pixel_posX <= m_pixel_posX + 1;
      m_pixel_posY <= m_pixel_posY;
    end else begin
      m_pixel_posX <= m_pixel_posX;
      m_pixel_posY <= m_pixel_posY;
    end
  end

endmodule
