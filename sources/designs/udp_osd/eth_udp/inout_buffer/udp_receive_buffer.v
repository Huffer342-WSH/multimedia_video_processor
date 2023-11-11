//UDP模块 和 想要使用UDP的模块 不在一个时钟领域，
// 在该模块中使用异步fifo实现时钟领转换
// UDP接受到接收到的数据 先保存两字节UDP数据长度，在保存数据
//  0::num[15:8]
//  1::num[7:0]
//  2::data0
//  3::data1
//     .
//     .
//     .
//  num+1::data(num-1)
//

module udp_receive_buffer (
    input resetn,


    input        udp_rx_clk_i,
    input [ 7:0] udp_rx_data_i,   //待接受数据 数据
    input        udp_rx_valid_i,  //待接受数据 有效信号
    input [15:0] udp_rx_num_i,    //待接受数据 数据量
    input        udp_rx_start_i,  //待接受数据 结束传输
    input        udp_rx_done_i,   //待接受数据 结束传输

    input            recv_clk_i,
    output     [7:0] recv_m_data_tdata,
    output reg       recv_m_data_tlast,
    output reg       recv_m_data_tvalid,
    input            recv_m_data_tready,

    output reg [15:0] recv_m_data_tsize,
    output     [ 5:0] cached_pkt_num



);

  //---------------------------------------------------------------
  // UDP时钟域
  //---------------------------------------------------------------
  reg  [ 5:0] pkt_num;

  reg         udp_rx_start_i_ff;
  reg  [ 7:0] fifo_din;
  wire        fifo_wr_en;
  wire [ 7:0] fifo_dout;



  reg  [15:0] rd_cnt;
  wire        fifo_empty;
  reg         fifo_rd_num_en;
  reg         fifo_rd_data_en;
  wire        fifo_rd_en;

  wire        pkt_wr_done;
  wire        pkt_rd_done;




  //udp_rx_start_i 打拍一周期
  always @(posedge udp_rx_clk_i) begin
    if (~resetn) begin
      udp_rx_start_i_ff <= 0;
    end else begin
      udp_rx_start_i_ff <= udp_rx_start_i;
    end
  end

  always @(*) begin
    case ({
      udp_rx_start_i_ff, udp_rx_start_i
    })
      2'b01:   fifo_din = udp_rx_num_i[15:8];
      2'b11:   fifo_din = udp_rx_num_i[7:0];
      default: fifo_din = udp_rx_data_i;
    endcase
  end

  assign fifo_wr_en = udp_rx_start_i | udp_rx_valid_i;




  //---------------------------------------------------------------
  // SYS时钟域
  //---------------------------------------------------------------


  localparam reg [1:0] IDLE = 0;
  localparam reg [1:0] READ_NUM = 1;
  localparam reg [1:0] READ_DATA = 2;

  reg [ 1:0] state;
  reg [15:0] cnt;
  reg [ 7:0] data_size_H;
  reg        change_to_read;
  always @(posedge recv_clk_i) begin
    if (~resetn) begin
      state <= IDLE;
      fifo_rd_num_en <= 0;
    end else begin
      case (state)
        IDLE: begin
          if (pkt_num != 0) begin
            state <= READ_NUM;
            fifo_rd_num_en <=
                1;  //提前拉高fifo读取使能，下一个周期直接读取信号
            cnt <= 0;
          end else begin
            state <= IDLE;
          end
        end
        READ_NUM: begin
          cnt   <= cnt + 1;
          state <= READ_NUM;
          if (cnt == 0) begin
            fifo_rd_num_en <= 1;
          end else if (cnt == 1) begin
            data_size_H <= fifo_dout;
            fifo_rd_num_en <= 0;
          end else if (cnt == 2) begin
            fifo_rd_num_en <= 0;
            cnt <= 0;
            state <= READ_DATA;
            change_to_read = 1;
          end
        end
        READ_DATA: begin
          change_to_read = 0;
          if (recv_m_data_tvalid && recv_m_data_tready && recv_m_data_tlast) begin
            //最后一个数据读取完毕
            state <= IDLE;
          end else begin
            state <= READ_DATA;
          end
        end
        default: begin
          state <= IDLE;
        end
      endcase
    end
  end



  assign cached_pkt_num = pkt_num;
  assign pkt_rd_done = recv_m_data_tvalid && recv_m_data_tready && recv_m_data_tlast;
  assign fifo_rd_en = fifo_rd_num_en | fifo_rd_data_en;



  always @(posedge recv_clk_i) begin
    if (~resetn) begin
      pkt_num <= 0;
    end else begin
      case ({
        pkt_wr_done, pkt_rd_done
      })
        2'b01:   pkt_num <= pkt_num - 1;
        2'b10:   pkt_num <= pkt_num + 1;
        default: pkt_num <= pkt_num;
      endcase
    end
  end


  always @(posedge recv_clk_i) begin
    if (~resetn) begin
      recv_m_data_tsize <= 0;
    end else if (change_to_read) begin
      recv_m_data_tsize <= {data_size_H, fifo_dout};
    end else begin
      recv_m_data_tsize <= recv_m_data_tsize;
    end
  end

  // rd_cnt,初始化为data_size，每从fifo中读取一个数据就减1
  always @(posedge recv_clk_i) begin
    if (~resetn) begin
      rd_cnt <= 0;
    end else if (change_to_read) begin
      rd_cnt <= {data_size_H, fifo_dout};
    end else if (fifo_rd_data_en && ~fifo_empty) begin
      rd_cnt <= rd_cnt - 1;
    end else begin
      rd_cnt <= rd_cnt;
    end
  end

  // fifo_rd_data_en 当fifo不为空，且
  always @(*) begin
    if (fifo_empty || state != READ_DATA || rd_cnt == 0) begin
      // 复位 或者 FIFO为空 或 不在读取数据状态 或 数据已经读完
      fifo_rd_data_en = 0;
    end else begin
      case ({
        recv_m_data_tvalid, recv_m_data_tready
      })
        2'b00:   fifo_rd_data_en = 1;
        2'b01:   fifo_rd_data_en = 1;
        2'b10:   fifo_rd_data_en = 0;
        2'b11:   fifo_rd_data_en = 1;
        default: fifo_rd_data_en = 0;
      endcase
    end
  end

  assign recv_m_data_tdata = fifo_dout;

  always @(posedge recv_clk_i) begin
    if (~resetn) begin
      recv_m_data_tlast <= 0;
    end else if (rd_cnt == 1 && fifo_rd_data_en) begin
      recv_m_data_tlast <= 1;
    end else if (pkt_rd_done) begin
      recv_m_data_tlast <= 0;
    end else begin
      recv_m_data_tlast <= recv_m_data_tlast;
    end
  end

  //recv_m_data_tvalid  当有数据读入时拉高(rd_en=1)，当数据被读走时拉低(rd_en=0 valid&ready=1)
  always @(posedge recv_clk_i) begin
    if (~resetn || state != READ_DATA) begin
      recv_m_data_tvalid <= 0;
    end else if (fifo_rd_data_en && ~fifo_empty) begin
      recv_m_data_tvalid <= 1;
    end else if (~fifo_rd_data_en && recv_m_data_tvalid && recv_m_data_tready) begin
      recv_m_data_tvalid <= 0;
    end else begin
      recv_m_data_tvalid <= recv_m_data_tvalid;
    end
  end



  //---------------------------------------------------------------
  // 跨时钟域
  //---------------------------------------------------------------
  pulse_cdc udp_rx_done_cdc (
      .resetn    (resetn),
      .src_clk   (udp_rx_clk_i),
      .dest_clk  (recv_clk_i),
      .src_pulse (udp_rx_done_i),
      .dest_pulse(pkt_wr_done)
  );


  //待发送数据 数据 缓存
  //异步FIFO，完成时钟雨转换
  // async_fifo_2048x8 udp_rx_fifo (
  //     .rst(~resetn),  // input wire rst

  //     .wr_clk(udp_rx_clk_i),  // input wire wr_clk
  //     .din   (fifo_din),      // input wire [7 : 0] din
  //     .wr_en (fifo_wr_en),    // input wire wr_en
  //     .full  (),              // output wire full

  //     .rd_clk(recv_clk_i),  // input wire rd_clk
  //     .rd_en (fifo_rd_en),  // input wire rd_en
  //     .dout  (fifo_dout),   // output wire [7 : 0] dout
  //     .empty (fifo_empty)   // output wire empty
  // );
  async_fifo_2048x8 udp_rx_fifo (
      .wr_clk      (udp_rx_clk_i),  // input
      .wr_rst      (~resetn),       // input
      .wr_en       (fifo_wr_en),    // input
      .wr_data     (fifo_din),      // input [7:0]
      .wr_full     (),              // output
      .almost_full (),              // output
      .rd_clk      (recv_clk_i),    // input
      .rd_rst      (~resetn),       // input
      .rd_en       (fifo_rd_en),    // input
      .rd_data     (fifo_dout),     // output [7:0]
      .rd_empty    (fifo_empty),    // output
      .almost_empty()               // output
  );



endmodule
