// �ַ���������ȡģ��
// char_ascii     ����ַ���ASCII��
// char_row_index �����ǰӦ������ַ��ĵڼ������ص���
// romģ���ڵ�ַ����char_ascii-33��*18+char_row_index �����ַ���һ�����ص�
// ÿ���һ���ַ���char_ascii�͸���һ�Ρ�
// �����һ�к�char_row_index����һ�Ρ�
// ���һ���ַ�����Ҫ3�����ڲ��������һ���ַ����������е������Ҫ������ʱ�䡣

module char_buf_reader #(
    parameter STRLENDATA_SAVED_ADDR = 1023,  //�ַ������ȱ�?? ?? RAM�е�λ�� 
    parameter CHAR_BUFFER_ADDR_WIDTH = 12,
    parameter CHAR_PIC_HEIGHT = 18,
    parameter SCREEN_WIDTH = 1920,  //��ʾ����??
    parameter SCREEN_HEIGHT = 1080  //��ʾ����??
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
    output reg [CHAR_BUFFER_ADDR_WIDTH-1:0] ram_addr,
    input      [                       7:0] ram_data,

    //rom�ӿ�
    output reg [7:0] char_ascii,
    output     [5:0] char_row_index,

    //��ǰ�ַ��ĵ���ʼ����(���Ͻ�)
    output reg [10:0] char_pos_x,
    output reg [10:0] char_pos_y,

    output reg char_valid,  //������Ч�źţ����յ�char_next�������һ���ַ���Ҫһ��ʱ�䣬��ʱvalid������
    input      char_next    //�յ����źź��л�����һ���ַ���


);

  localparam reg [7:0] ASCII_LF = 8'h0A;
  localparam reg [7:0] ASCII_CR = 8'h0D;
  localparam reg [7:0] ASCII_SPACE = 8'h20;

  localparam S_READ_STRLEN = 1;
  localparam S_SHOW_CHAR = 2;
  localparam S_CR = 3;
  localparam S_LF = 4;
  localparam S_OVER = 5;
  localparam S_WAIT_CHAR = 6;


  reg [                      10:0] start_posX;
  reg [                      10:0] start_posY;
  reg [                      10:0] end_posX;
  reg [                      10:0] end_posY;
  reg [                      10:0] char_width;
  reg [                      10:0] char_height;


  reg [                      15:0] str_len;
  reg [CHAR_BUFFER_ADDR_WIDTH-1:0] start_char_ptr;  //ָʾ��ǰ�е�??ͷ�ַ��ĵ�ַ

  reg [                       5:0] row_cnt;

  reg [                       7:0] char;

  reg [                       3:0] state;
  reg [                       5:0] cnt;


  assign char_row_index = row_cnt;


  //--- ���� ��ʼ�� ---//
  always @(posedge clk) begin
    if (~resetn) begin
      start_posX <= 10;
      start_posY <= 10;
      end_posX <= SCREEN_WIDTH - 10;
      end_posY <= SCREEN_HEIGHT - 10;
      char_width <= 10;
      char_height <= 20;
    end else if (state == S_READ_STRLEN && cnt == 0) begin
      start_posX <= cfg_start_posX;
      start_posY <= cfg_start_posY;
      end_posX <= cfg_end_posX;
      end_posY <= cfg_end_posY;
      char_width <= cfg_char_width;
      char_height <= cfg_char_height;
    end else begin
      start_posX <= start_posX;
      start_posY <= start_posY;
      end_posX <= end_posX;
      end_posY <= end_posY;
      char_width <= char_width;
      char_height <= char_height;
    end
  end

  //---------------------------------------------------------------
  // ״̬��
  //---------------------------------------------------------------
  always @(posedge clk) begin
    if (~resetn) begin
      state <= S_READ_STRLEN;
      cnt   <= 0;
    end else begin
      case (state)
        S_READ_STRLEN: begin
          if (cnt == 4) begin
            if ({str_len[15:8], ram_data} == 0) begin
              cnt   <= 0;
              state <= S_READ_STRLEN;
            end else begin
              state <= S_SHOW_CHAR;
              cnt   <= 0;
            end
          end else begin
            state <= state;
            cnt   <= cnt + 1;
          end
        end

        S_SHOW_CHAR: begin
          if (ram_addr >= str_len) begin
            state <= S_READ_STRLEN;
            cnt   <= 0;
          end else if (char_next && (ram_addr == str_len - 1) && (row_cnt == CHAR_PIC_HEIGHT - 1)) begin
            //??�����ݶ�����??
            state <= S_READ_STRLEN;
            cnt   <= 0;
          end else if (ram_data == ASCII_LF) begin
            // ��ȡ��\n
            state <= S_LF;
            cnt   <= 0;
          end else if (ram_data == ASCII_CR) begin
            // ��ȡ��\n
            state <= S_CR;
            cnt   <= 0;
          end else if ((char_next && char_valid) || (ram_data == ASCII_SPACE)) begin
            // �����ո� �� �����һ���ַ�
            state <= S_WAIT_CHAR;
            cnt   <= 0;
          end else begin
            state <= S_SHOW_CHAR;
          end
        end

        S_WAIT_CHAR: begin
          cnt <= cnt + 1;
          if (cnt == 1) begin
            cnt   <= 0;
            state <= S_SHOW_CHAR;
          end else begin
            state <= S_WAIT_CHAR;
          end
        end



        S_LF: begin
          cnt <= cnt + 1;
          if (cnt == 1) begin
            cnt   <= 0;
            state <= S_SHOW_CHAR;
          end else begin
            state <= S_LF;
          end
        end


        S_CR: begin
          if (cnt == 2) begin
            if (ram_data == ASCII_LF) begin
              state <= S_LF;
            end else begin
              if (row_cnt == CHAR_PIC_HEIGHT - 1) begin
                state <= S_SHOW_CHAR;
              end else begin
                state <= S_WAIT_CHAR;
              end
            end
            cnt <= 0;
          end else begin
            state <= S_CR;
            cnt   <= cnt + 1;
          end
        end

        default: begin
          state <= S_READ_STRLEN;
          cnt   <= 0;
        end
      endcase
    end
  end





  //---------------------------------------------------------------
  // RAM��ȡ��ַ
  //---------------------------------------------------------------
  always @(posedge clk) begin
    if (~resetn) begin
      ram_addr <= STRLENDATA_SAVED_ADDR;

    end else
      case (state)
        S_READ_STRLEN: begin
          //��ram�ж�ȡ�ַ����ĳ��� ����16bit
          if (cnt == 0) begin
            ram_addr <= STRLENDATA_SAVED_ADDR;
          end else if (cnt == 1) begin
            ram_addr <= STRLENDATA_SAVED_ADDR + 1;
          end else if (cnt == 2) begin
            ram_addr <= 0;
          end else if (cnt == 4 && ({str_len[15:8], ram_data} != 0)) begin
            ram_addr <= 0;
          end else begin
            ram_addr <= 0;
          end
        end

        S_SHOW_CHAR: begin
          if (ram_data == ASCII_LF) begin
            //��ȡ�� '\n'
            if (row_cnt == CHAR_PIC_HEIGHT - 1) begin
              ram_addr <= ram_addr + 1;
            end else begin
              ram_addr <= start_char_ptr;
            end
          end else if (ram_data == ASCII_CR) begin
            //  ��ȡ�� '\r'
            ram_addr <= ram_addr + 1;
          end else if (ram_data == ASCII_SPACE) begin
            // ��ȡ���س�����һ���ַ�
            ram_addr <= ram_addr + 1;
          end else if (char_valid & char_next) begin
            //�����һ���ַ�
            if (ram_addr >= str_len - 1) begin
              //�����ַ�����β��
              if (row_cnt == CHAR_PIC_HEIGHT - 1) begin
                // �ַ���ȫ����ʾ����ˣ����¶�ȡ�ַ�������
                ram_addr <= STRLENDATA_SAVED_ADDR;
              end else begin
                //��ǰ�л�û��ȫ��ʾ�꣬���¶�ȡ��һ�еĵ�һ���ַ���׼����ʾ�ַ�����һ�����ص�
                ram_addr <= start_char_ptr;
              end
            end else begin
              ram_addr <= ram_addr + 1;
            end
          end else begin
            ram_addr <= ram_addr;
          end
        end

        S_WAIT_CHAR: begin
          ram_addr <= ram_addr;
        end

        S_LF: begin
          ram_addr <= ram_addr;
        end

        S_CR: begin
          if (cnt == 2) begin
            if (ram_data == ASCII_LF) begin
              if (row_cnt == CHAR_PIC_HEIGHT - 1) begin
                ram_addr <= ram_addr + 1;
              end else begin
                ram_addr <= start_char_ptr;
              end
            end else begin
              if (row_cnt == CHAR_PIC_HEIGHT - 1) begin
                ram_addr <= ram_addr;
              end else begin
                ram_addr <= start_char_ptr;
              end
            end
          end else begin
            ram_addr <= ram_addr;
          end
        end

        default: ram_addr <= STRLENDATA_SAVED_ADDR;
      endcase
  end


  always @(posedge clk) begin
    if (~resetn) begin
      str_len <= 0;
    end else if (state == S_READ_STRLEN) begin
      if (cnt == 3) begin
        str_len[15:8] <= ram_data;
      end else if (cnt == 4) begin
        str_len[7:0] <= ram_data;
      end else begin
        str_len <= str_len;
      end
    end else begin
      str_len <= str_len;
    end
  end

  always @(posedge clk) begin
    if (~resetn) begin
      start_char_ptr <= 0;
    end else if (state == S_READ_STRLEN) begin
      start_char_ptr <= 0;
    end else if (state == S_LF && cnt == 0 && row_cnt == CHAR_PIC_HEIGHT - 1) begin
      start_char_ptr <= ram_addr;
    end else if (state == S_CR && cnt == 2 && ram_data != ASCII_LF && row_cnt == CHAR_PIC_HEIGHT - 1) begin
      start_char_ptr <= ram_addr;
    end else begin
      start_char_ptr <= start_char_ptr;
    end
  end



  always @(posedge clk) begin
    if (~resetn) begin
      row_cnt <= 0;
    end else if (ram_addr == str_len - 1 && char_next && char_valid) begin
      if (row_cnt == CHAR_PIC_HEIGHT - 1) begin
        row_cnt <= 0;
      end else begin
        row_cnt <= row_cnt + 1;
      end
    end else if (state == S_LF && cnt == 0) begin
      if (row_cnt == CHAR_PIC_HEIGHT - 1) begin
        row_cnt <= 0;
      end else begin
        row_cnt <= row_cnt + 1;
      end
    end else if (state == S_CR && cnt == 2 && ram_data != ASCII_LF) begin
      if (row_cnt == CHAR_PIC_HEIGHT - 1) begin
        row_cnt <= 0;
      end else begin
        row_cnt <= row_cnt + 1;
      end
    end else begin
      row_cnt <= row_cnt;
    end
  end


  always @(posedge clk) begin
    if (~resetn) begin
      char_ascii <= 0;
    end else begin
      char_ascii <= ram_data;
    end
  end

  //! char_valid ������Ч �ź�
  always @(posedge clk) begin
    if (~resetn) begin
      char_valid <= 0;
    end else if (char_valid && char_next) begin
      char_valid <= 0;
    end else if (state == S_SHOW_CHAR && (ram_data != ASCII_SPACE) && (ram_data != ASCII_LF) && (ram_data != ASCII_CR) && (ram_addr < str_len)) begin
      char_valid <= 1;
    end else begin
      char_valid <= char_valid;
    end
  end


  always @(posedge clk) begin
    if (~resetn) begin
      char_pos_x <= 0;
    end else begin
      case (state)
        S_READ_STRLEN: begin
          char_pos_x <= start_posX;
        end
        S_SHOW_CHAR: begin

          if (ram_data == ASCII_LF || ram_data == ASCII_CR) begin
            //��ȡ��'\n'��'\r'���ص���ͷ
            char_pos_x <= start_posX;
          end else if (ram_data == ASCII_SPACE) begin
            // ��ȡ���س�����һ���ַ�
            char_pos_x <= char_pos_x + char_width;
          end else if (char_next && char_valid) begin
            if (ram_addr == str_len - 1) begin
              //һ��������ˣ��ص���ͷ
              char_pos_x <= start_posX;
            end else begin
              char_pos_x <= char_pos_x + char_width;
            end
          end else begin
            char_pos_x <= char_pos_x;
          end
        end

        default: char_pos_x <= char_pos_x;

      endcase
    end
  end

  always @(posedge clk) begin
    if (~resetn) begin
      char_pos_y <= 0;
    end else begin
      case (state)
        S_READ_STRLEN: char_pos_y <= start_posY;
        S_SHOW_CHAR: begin
          if (ram_data == ASCII_LF || ram_data == ASCII_CR) begin
            //��ȡ��'\n'��'\r'������
            if (row_cnt == CHAR_PIC_HEIGHT - 1) begin
              char_pos_y <= char_pos_y + char_height;
            end else begin
              char_pos_y <= char_pos_y;
            end
          end else if (char_valid && char_next && ram_addr == str_len - 1) begin
            //ȫ�����꣬��ͷ��ʼ��
            if (row_cnt == CHAR_PIC_HEIGHT - 1) begin
              char_pos_y <= start_posY;
            end else begin
              char_pos_y <= char_pos_y;
            end
          end else begin
            char_pos_y <= char_pos_y;
          end
        end

        default: char_pos_y <= char_pos_y;
      endcase
    end
  end


endmodule
