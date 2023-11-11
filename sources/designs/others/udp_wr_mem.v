//
// 数据格式： INDEX,LEN,D0,D1,D2,...,D(LEN-1),INDEX,LEN,D1,D2,...,D(LEN-1)
// 
//
module udp_wr_mem #(
    parameter integer REG_NUM = 15,
    parameter reg [15:0] PORT = 16'd1000

) (
    input clk,
    input resetn,

    input [ 7:0] udp_rx_data,       //待接受数据 数据
    input        udp_rx_valid,      //待接受数据 有效信号
    input [15:0] udp_rx_dest_port,  //待接受数据 有效信号
    input [15:0] udp_rx_num,        //待接受数据 数据量
    input        udp_rx_start,      //待接受数据 结束传输

    output reg [REG_NUM*8-1:0] mem,
    output reg [  REG_NUM-1:0] flags
);


  localparam reg [1:0] IDLE = 2'b00;
  localparam reg [1:0] INDEX = 2'b01;
  localparam reg [1:0] LEN = 2'b11;
  localparam reg [1:0] DATA = 2'b10;


  reg [ 2:0] state;
  reg [ 7:0] index;
  reg [ 7:0] data_count;
  reg [15:0] pkt_data_cnt;

  //! 数据包读取计数
  always @(posedge clk) begin
    if (~resetn) begin
      pkt_data_cnt <= 0;
    end else if (udp_rx_start) begin
      pkt_data_cnt <= udp_rx_num;
    end else if (udp_rx_valid) begin
      pkt_data_cnt <= pkt_data_cnt - 1;
    end else begin
      pkt_data_cnt <= pkt_data_cnt;
    end
  end



  //! index 寄存器序号，状态为INDEX时加载
  always @(posedge clk) begin
    if (~resetn) begin
      index <= 0;
    end else if (state == INDEX && udp_rx_valid) begin
      index <= udp_rx_data;
    end else if (state == DATA && udp_rx_valid) begin
      index <= index + 1;
    end else begin
      index <= index;
    end
  end

  //! 读取计数，状态为LEN时加载，状态为DATA时递减
  always @(posedge clk) begin
    if (~resetn) begin
      data_count <= 0;
    end else if (state == LEN && udp_rx_valid) begin
      data_count <= udp_rx_data;
    end else if (state == DATA && udp_rx_valid) begin
      data_count <= data_count - 1;
    end else begin
      data_count <= data_count;
    end
  end

  genvar i;
  generate
    for (i = 0; i < REG_NUM; i = i + 1) begin : g_mem
      always @(posedge clk) begin
        if (~resetn) begin
          mem[i*8 +: 8] <= 0;
          flags[i] <= 0;
        end else if (index == i && state == DATA && udp_rx_valid) begin
          mem[i*8 +: 8] <= udp_rx_data;
          flags[i] <= ~flags[i];
        end else begin
          mem[i*8 +: 8] <= mem[i*8 +: 8];
          flags[i] <= flags[i];
        end
      end
    end
  endgenerate


  //! 状态机
  always @(posedge clk) begin
    if (~resetn) begin
      state <= IDLE;
    end else begin
      case (state)
        IDLE: begin
          if (udp_rx_start && udp_rx_dest_port == PORT) begin
            state <= INDEX;
          end else begin
            state <= IDLE;
          end
        end
        INDEX: begin
          if (pkt_data_cnt == 1 && udp_rx_valid) begin
            state <= IDLE;
          end else if (udp_rx_valid) begin
            state <= LEN;
          end else begin
            state <= INDEX;
          end
        end
        LEN: begin
          if (pkt_data_cnt == 1 && udp_rx_valid) begin
            state <= IDLE;
          end else if (udp_rx_valid) begin
            state <= DATA;
          end else begin
            state <= LEN;
          end
        end
        DATA: begin
          if (pkt_data_cnt == 1 && udp_rx_valid) begin
            state <= IDLE;
          end else if (data_count == 1) begin
            state <= LEN;
          end else begin
            state <= DATA;
          end
        end
        default: begin
          state <= IDLE;
        end
      endcase
    end
  end

endmodule
