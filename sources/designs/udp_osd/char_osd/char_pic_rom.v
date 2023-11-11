// �����ַ������ROM��װ

module char_pic_rom #(
    parameter CHAR_PIC_WIDTH = 9  //�ַ�����Ŀ�ȣ�����18*9��ASCII�ַ������λ9


) (
    input clk,
    input resetn,


    //rom�ӿ�
    input [7:0] char_ascii,
    input [5:0] char_row_index,

    //�ַ����� �� ��ǰһ�� ����ʾ����ʼ��ַ
    input [10:0] char_pos_x,
    input [10:0] char_pos_y,

    input char_valid,  //������Ч�źţ����յ�char_next�������һ���ַ���Ҫһ��ʱ�䣬��ʱvalid����
    output reg char_next,  //�յ����źź��л�����һ���ַ���

    // ���ص� ���
    output     [CHAR_PIC_WIDTH-1:0] m_row_pixels_data,   //�ַ���һ�����ص�
    output reg [              10:0] m_row_pixels_posX,   // �������ص����ʼX����
    output reg [              10:0] m_row_pixels_posY,   // �������ص��Y����
    output reg                      m_row_pixels_valid,
    input                           m_row_pixels_ready
);

  reg  [10 : 0] rom_addr_d;  //��ַ������м���
  reg  [10 : 0] rom_addr;  //rom��ȡ��ַ
  wire [ 8 : 0] pixels_data;  //������ ����rom�����m_row_pixels_data

  reg  [   2:0] valid_d;  //����valid�źŴ���



  ascii_char_rom ascii_char_rom_inst (
      .addr   (rom_addr),    // input [10:0]
      .clk    (clk),         // input
      .rst    (~resetn),     // input
      .rd_data(pixels_data)  // output [8:0]
  );


  // ����ROM��ȡ��ַ�����������ͳ˷�����һ�ģ��Ĵ������һ��
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


  // Ϊ�˾���������ݣ�û�д��ģ�ʹ����ϵ�·
  // �߼��Ƚϼ򵥣��ۺ������Զ��Ż��ġ�
  always @(*) begin
    if (~resetn) begin
      char_next = 0;
    end else begin
      char_next = m_row_pixels_ready & m_row_pixels_valid;
    end
  end



  assign m_row_pixels_data = pixels_data;

  // ������Ч �ź�
  // ���������������Ч�źŴ��ĺ��������ʱ�����ߣ�����ǰ���ݱ�����ʱ����������
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
