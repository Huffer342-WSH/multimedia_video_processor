//UDP����ģ�� �� ��Ҫ����UDP���ݵ�ģ�� ����һ��ʱ������
// �ڸ�ģ����ʹ���첽fifoʵ��ʱ����ת��

module udp_transmit_buffer (
    input resetn,


    input        transmit_clk_i,
    input [ 7:0] transmit_data_i,   //���������� ����
    input        transmit_valid_i,  //���������� ��Ч�ź�
    input        transmit_start_i,  //���������� ��ʼ����
    input [15:0] transmit_num_i,    //���������� ������
    input        transmit_end_i,    //���������� ��������

    input udp_tx_m_clk_i,
    input udp_tx_m_req_i,  //UDPģ�� �����������ź� �����ͺ���Ϊʱ���ӳ�һ��ʱ�����ڴ�������
    output udp_tx_m_start_en_o,
    output [7:0] udp_tx_m_data_o,
    output [15:0] udp_tx_m_byte_num_o

);

  reg recv_done, recv_done_ff;
  reg [15:0] data_cnt;

  reg        udp_start_en;

  assign udp_tx_m_start_en_o = udp_start_en;
  assign udp_tx_m_byte_num_o = data_cnt;


  // �������� ������ ����
  always @(posedge transmit_clk_i) begin
    if (~resetn) begin
      data_cnt <= 0;
    end else if (transmit_start_i) begin
      data_cnt <= transmit_num_i;
    end else begin
      data_cnt <= data_cnt;
    end
  end

  //���ݽ��ս�����һֱ��������ֱ����һ�ο�ʼ���ܴ��������ݣ���Ҫ�����㹻����ʱ��ʹ����UDPģ��ʱ����Ҳ�ܲ���������
  always @(posedge transmit_clk_i) begin
    if (~resetn || transmit_start_i) begin
      recv_done <= 0;
    end else if (transmit_end_i) begin
      recv_done <= 1;
    end else begin
      recv_done <= recv_done;
    end
  end

  //udp_start_en  ��UDPģ��ʱ���򲶻� recv_done ��������,����һ��ʱ������
  //recv_done���ߵ�ʱ���㹻�������Բ���������
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



  //���������� ���� ����
  //�첽FIFO�����ʱ����ת��
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
