//UDP发送模块 和 想要发送UDP数据的模块 不在一个时钟领域，
// 在该模块中使用异步fifo实现时钟领转换

module udp_transmit_buffer (
    input resetn,


    input        transmit_clk_i,
    input [ 7:0] transmit_data_i,   //待发送数据 数据
    input        transmit_valid_i,  //待发送数据 有效信号
    input        transmit_start_i,  //待发送数据 开始传输
    input [15:0] transmit_num_i,    //待发送数据 数据量
    input        transmit_end_i,    //待发送数据 结束传输

    input udp_tx_m_clk_i,
    input udp_tx_m_req_i,  //UDP模块 读数据请求信号 ，该型号置为时，延迟一个时钟周期传输数据
    output udp_tx_m_start_en_o,
    output [7:0] udp_tx_m_data_o,
    output [15:0] udp_tx_m_byte_num_o

);

  reg recv_done, recv_done_ff;
  reg [15:0] data_cnt;

  reg        udp_start_en;

  assign udp_tx_m_start_en_o = udp_start_en;
  assign udp_tx_m_byte_num_o = data_cnt;


  // 发送数据 数据量 缓存
  always @(posedge transmit_clk_i) begin
    if (~resetn) begin
      data_cnt <= 0;
    end else if (transmit_start_i) begin
      data_cnt <= transmit_num_i;
    end else begin
      data_cnt <= data_cnt;
    end
  end

  //数据接收结束，一直保持拉高直到下一次开始接受待发送数据，需要拉高足够长的时间使得在UDP模块时钟域也能捕获到上升沿
  always @(posedge transmit_clk_i) begin
    if (~resetn || transmit_start_i) begin
      recv_done <= 0;
    end else if (transmit_end_i) begin
      recv_done <= 1;
    end else begin
      recv_done <= recv_done;
    end
  end

  //udp_start_en  在UDP模块时钟域捕获 recv_done 的上升沿,拉高一个时钟周期
  //recv_done拉高的时间足够长，可以捕获到上升沿
  always @(posedge udp_tx_m_clk_i) begin
    if (~resetn) begin
      udp_start_en <= 0;
      recv_done_ff <= 0;
    end else if (~recv_done_ff && recv_done) begin
      recv_done_ff <= recv_done;
      udp_start_en <= 1;
    end else begin
      recv_done_ff <= recv_done;
      udp_start_en <= 0;
    end
  end



  //待发送数据 数据 缓存
  //异步FIFO，完成时钟域转换
  // async_fifo_2048x8 udp_send_fifo (
  //     .rst(~resetn),  // input wire rst

  //     .wr_clk(transmit_clk_i),    // input wire wr_clk
  //     .din   (transmit_data_i),   // input wire [7 : 0] din
  //     .wr_en (transmit_valid_i),  // input wire wr_en
  //     .full  (),                  // output wire full

  //     .rd_clk(udp_tx_m_clk_i),   // input wire rd_clk
  //     .rd_en (udp_tx_m_req_i),   // input wire rd_en
  //     .dout  (udp_tx_m_data_o),  // output wire [7 : 0] dout
  //     .empty ()                  // output wire empty
  // );


  async_fifo_2048x8 udp_send_fifo (
      .wr_clk      (transmit_clk_i),    // input
      .wr_rst      (~resetn),           // input
      .wr_en       (transmit_valid_i),  // input
      .wr_data     (transmit_data_i),   // input [7:0]
      .wr_full     (),                  // output
      .almost_full (),                  // output
      .rd_clk      (udp_tx_m_clk_i),    // input
      .rd_rst      (~resetn),           // input
      .rd_en       (udp_tx_m_req_i),    // input
      .rd_data     (udp_tx_m_data_o),   // output [7:0]
      .rd_empty    (),                  // output
      .almost_empty()                   // output
  );

endmodule
