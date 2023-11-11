// fifo2 -> 0
// fifo1 -> 1
// fifo0 -> 2
// in   -> 3


module multiline_buffer #(
    parameter reg [10:0] IMAGE_WIDTH = 1920,  // 图像宽度
    parameter reg [10:0] IMAGE_HEIGHT = 1080,  // 图像高度
    parameter integer PIXEL_DATA_WIDTH = 16,
    parameter integer LINES_NUM = 3

) (
    input  clk,
    input  resetn,
    output rst_busy,

    input [PIXEL_DATA_WIDTH-1:0] s_pixel_data,
    input                        s_pixel_valid,

    output reg [(LINES_NUM)*PIXEL_DATA_WIDTH-1:0] m_multiline_pixel_data,
    output reg                                    m_pixel_valid
);

  localparam integer FifoWidth = 24;
  `define ZERO_PAD {(FifoWidth - PIXEL_DATA_WIDTH) {1'b0}}


  reg  [                       10:0] hor_cnt;
  reg  [                       10:0] ver_cnt;
  reg  [                        5:0] tail_ver_cnt;
  reg  [                       10:0] tail_hor_cnt;

  //FIFO接口
  reg                                srst;


  reg  [(LINES_NUM-1)*FifoWidth-1:0] din;
  wire [(LINES_NUM-1)*FifoWidth-1:0] dout;
  reg  [              LINES_NUM-2:0] rd_en;
  reg  [              LINES_NUM-2:0] wr_en;

  wire [              LINES_NUM-2:0] full;
  wire [              LINES_NUM-2:0] empty;


  always @(posedge clk) begin
    if (~resetn) begin
      m_pixel_valid <= 0;
    end else begin
      m_pixel_valid <= rd_en[(LINES_NUM-3)/2];
    end
  end

  //异步复位同步释放
  reg rst_s1;
  always @(posedge clk or negedge resetn) begin
    if (!resetn) begin
      rst_s1 <= 1'b1;
      srst   <= 1'b1;
    end else begin
      rst_s1 <= 1'b0;
      srst   <= rst_s1;
    end
  end

  //输入端 水平计数
  always @(posedge clk) begin
    if (~resetn) begin
      hor_cnt <= 0;
    end else if (s_pixel_valid) begin
      if (hor_cnt == IMAGE_WIDTH - 1) begin
        hor_cnt <= 0;
      end else begin
        hor_cnt <= hor_cnt + 1;
      end
    end else begin
      hor_cnt <= hor_cnt;
    end
  end

  //输入端 纵向计数
  always @(posedge clk) begin
    if (~resetn) begin
      ver_cnt <= 0;
    end else if (s_pixel_valid && hor_cnt == IMAGE_WIDTH - 1) begin
      if (ver_cnt == IMAGE_HEIGHT - 1) begin
        ver_cnt <= 0;
      end else begin
        ver_cnt <= ver_cnt + 1;
      end
    end else begin
      ver_cnt <= ver_cnt;
    end
  end


  always @(posedge clk) begin
    if (~resetn) begin
      tail_ver_cnt <= LINES_NUM;
      tail_hor_cnt <= 0;
    end else if (ver_cnt == IMAGE_HEIGHT - 1 && hor_cnt == IMAGE_WIDTH - 1 && s_pixel_valid) begin
      tail_ver_cnt <= 0;
      tail_hor_cnt <= 0;
    end else if (tail_ver_cnt <= LINES_NUM - 2) begin
      tail_hor_cnt <= tail_hor_cnt + 1;
      if (tail_hor_cnt == IMAGE_WIDTH - 1) begin
        tail_hor_cnt <= 0;
        tail_ver_cnt <= tail_ver_cnt + 1;
      end else begin
        tail_hor_cnt <= tail_hor_cnt + 1;
        tail_ver_cnt <= tail_ver_cnt;
      end
    end else begin
      tail_ver_cnt <= tail_ver_cnt;
      tail_hor_cnt <= 0;
    end
  end

  always @(*) begin
    wr_en[0] = s_pixel_valid;
  end

  genvar i;
  generate
    for (i = 0; i <= LINES_NUM - 2; i = i + 1) begin : g_fifo_connect

      //！ FIFO输入端口连接
      //！ n号fifo的输入 是 n-1号fifo的输出
      always @(*) begin
        if (i == 0) begin
          din[i*FifoWidth+:FifoWidth] = {`ZERO_PAD, s_pixel_data};
        end else begin
          din[i*FifoWidth+:FifoWidth] = dout[(i-1)*FifoWidth+:FifoWidth];
        end
      end

      // n号fifo的wr_en 是n号-1fifo的rd_en的打拍
      always @(posedge clk) begin
        if (i != 0) begin
          if (~resetn) begin
            wr_en[i] <= 0;
          end else begin
            wr_en[i] <= rd_en[i-1];
          end
        end
      end


      //控制rd_en
      always @(*) begin
        if (i > tail_ver_cnt || (i == tail_ver_cnt && tail_hor_cnt <= IMAGE_WIDTH - 2)) begin
          rd_en[i] = 1;
        end else begin
          if ((i == ver_cnt && hor_cnt == IMAGE_WIDTH - 1) || (i < ver_cnt)) begin
            rd_en[i] = s_pixel_valid;
          end else begin
            rd_en[i] = 0;
          end
        end
      end

      //例化FIFO
      // sync_fifo_2048x24 line_fifo (
      //     .clk  (clk),                           // input wire clk
      //     .srst (srst),                          // input wire srst
      //     .din  (din[i*FifoWidth+:FifoWidth]),   // input wire [23 : 0] din
      //     .wr_en(wr_en[i]),                      // input wire wr_en
      //     .rd_en(rd_en[i]),                      // input wire rd_en
      //     .dout (dout[i*FifoWidth+:FifoWidth]),  // output wire [23 : 0] dout
      //     .full (full[i]),                       // output wire full
      //     .empty(empty[i])                       // output wire empty
      // );
      sync_fifo_2048x16 line_fifo (
          .clk         (clk),                           // input
          .rst         (srst),                          // input
          .wr_en       (wr_en[i]),                      // input
          .wr_data     (din[i*FifoWidth+:FifoWidth]),   // input [15:0]
          .wr_full     (full[i]),                       // output
          .almost_full (),                              // output
          .rd_en       (rd_en[i]),                      // input
          .rd_data     (dout[i*FifoWidth+:FifoWidth]),  // output [15:0]
          .rd_empty    (empty[i]),                      // output
          .almost_empty()                               // output
      );

    end
  endgenerate

  genvar j;
  generate
    for (j = 0; j < LINES_NUM; j = j + 1) begin
      always @(*) begin
        if (j == 0) begin
          if (tail_ver_cnt <= (LINES_NUM - 3) / 2) begin
            m_multiline_pixel_data[j*PIXEL_DATA_WIDTH +: PIXEL_DATA_WIDTH] =
                dout[(LINES_NUM-2-j)*FifoWidth +: PIXEL_DATA_WIDTH];
          end else begin
            m_multiline_pixel_data[j*PIXEL_DATA_WIDTH+:PIXEL_DATA_WIDTH] = s_pixel_data;
          end
        end else if (j <= (LINES_NUM - 3) / 2) begin
          if (tail_ver_cnt <= (LINES_NUM - 3) / 2 && tail_ver_cnt >= j) begin
            m_multiline_pixel_data[j*PIXEL_DATA_WIDTH +: PIXEL_DATA_WIDTH] =
                dout[(LINES_NUM-2-j)*FifoWidth +: PIXEL_DATA_WIDTH];
          end else begin
            m_multiline_pixel_data[j*PIXEL_DATA_WIDTH +: PIXEL_DATA_WIDTH] =
                dout[(j-1)*FifoWidth +: PIXEL_DATA_WIDTH];
          end
        end else if (j == (LINES_NUM - 3) / 2 + 1) begin
          m_multiline_pixel_data[j*PIXEL_DATA_WIDTH +: PIXEL_DATA_WIDTH] =
              dout[(j-1)*FifoWidth +: PIXEL_DATA_WIDTH];
        end else if (j <= LINES_NUM - 2) begin
          if ((LINES_NUM - 1) / 2 <= ver_cnt && ver_cnt <= (LINES_NUM - 2) &&
              ver_cnt >= j - 1) begin
            m_multiline_pixel_data[j*PIXEL_DATA_WIDTH +: PIXEL_DATA_WIDTH] =
                dout[(LINES_NUM-2-j)*FifoWidth +: PIXEL_DATA_WIDTH];
          end else begin
            m_multiline_pixel_data[j*PIXEL_DATA_WIDTH +: PIXEL_DATA_WIDTH] =
                dout[(j-1)*FifoWidth +: PIXEL_DATA_WIDTH];
          end
        end else begin
          if ((LINES_NUM - 1) / 2 <= ver_cnt && ver_cnt <= (LINES_NUM - 2)) begin
            m_multiline_pixel_data[j*PIXEL_DATA_WIDTH+:PIXEL_DATA_WIDTH] = s_pixel_data;
          end else begin
            m_multiline_pixel_data[j*PIXEL_DATA_WIDTH +: PIXEL_DATA_WIDTH] =
                dout[(j-1)*FifoWidth +: PIXEL_DATA_WIDTH];
          end
        end

        // if (tail_ver_cnt <= (LINES_NUM - 3) / 2) begin
        //   if (j <= tail_ver_cnt && j <= (LINES_NUM - 3) / 2) begin
        //     m_multiline_pixel_data[j*PIXEL_DATA_WIDTH +: PIXEL_DATA_WIDTH] =
        //         dout[(LINES_NUM-2-j)*FifoWidth +: PIXEL_DATA_WIDTH];
        //   end else begin
        //     m_multiline_pixel_data[j*PIXEL_DATA_WIDTH +: PIXEL_DATA_WIDTH] =
        //         dout[(j-1)*FifoWidth +: PIXEL_DATA_WIDTH];
        //   end
        // end else if ((LINES_NUM - 1) / 2 <= ver_cnt && ver_cnt <= (LINES_NUM - 2)) begin
        //   if (j == 0) begin
        //     m_multiline_pixel_data[j*PIXEL_DATA_WIDTH+:PIXEL_DATA_WIDTH] = s_pixel_data;
        //   end else if (j <= ver_cnt && j <= (LINES_NUM - 2)) begin
        //     m_multiline_pixel_data[j*PIXEL_DATA_WIDTH +: PIXEL_DATA_WIDTH] =
        //         dout[(j-1)*FifoWidth +: PIXEL_DATA_WIDTH];
        //   end else if (j <= LINES_NUM - 2) begin
        //     m_multiline_pixel_data[j*PIXEL_DATA_WIDTH +: PIXEL_DATA_WIDTH] =
        //         dout[(LINES_NUM-2-j)*FifoWidth +: PIXEL_DATA_WIDTH];
        //   end else begin
        //     m_multiline_pixel_data[j*PIXEL_DATA_WIDTH+:PIXEL_DATA_WIDTH] = s_pixel_data;
        //   end
        // end else begin
        //   if (j == 0) begin
        //     m_multiline_pixel_data[j*PIXEL_DATA_WIDTH+:PIXEL_DATA_WIDTH] = s_pixel_data;
        //   end else begin
        //     m_multiline_pixel_data[j*PIXEL_DATA_WIDTH +: PIXEL_DATA_WIDTH] =
        //         dout[(j-1)*FifoWidth +: PIXEL_DATA_WIDTH];
        //   end
        // end
      end
    end
  endgenerate
endmodule
