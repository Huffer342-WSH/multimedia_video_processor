
module char_buf_writer #(
    parameter STRLENDATA_SAVED_ADDR  = 100,  //字符串长度变?? ?? RAM中的位置 
    parameter CHAR_BUFFER_ADDR_WIDTH = 12

) (
    input clk,
    input resetn,

    //输入接口，接UDP接受端口
    input      [ 7:0] udp_rx_s_data_tdata,
    input             udp_rx_s_data_tlast,
    input             udp_rx_s_data_tvalid,
    output reg        udp_rx_s_data_tready,
    input      [15:0] udp_rx_s_data_tsize,

    //ram接口
    output reg [CHAR_BUFFER_ADDR_WIDTH-1:0] ram_addr,
    output reg [                       7:0] ram_din,
    output reg                              ram_wen



);

  localparam ST_IDLE = 0;

  localparam ST_READ_DATA = 1;
  localparam ST_WRITE_STRLEN = 2;

  reg [ 3:0] state;
  reg [15:0] data_size;
  reg [15:0] cnt;


  always @(posedge clk) begin
    if (~resetn) begin
      state <= ST_IDLE;
      cnt   <= 0;
    end else begin
      case (state)

        ST_IDLE: begin
          cnt <= 0;
          if (udp_rx_s_data_tvalid) begin
            state <= ST_READ_DATA;
            data_size <= udp_rx_s_data_tsize;
          end else begin
            state <= ST_IDLE;
          end
        end

        ST_READ_DATA: begin
          if (udp_rx_s_data_tvalid && udp_rx_s_data_tready) begin
            if (cnt == data_size - 1) begin
              state <= ST_WRITE_STRLEN;
              cnt   <= 0;
            end else begin
              cnt   <= cnt + 1;
              state <= ST_READ_DATA;
            end
          end else begin
            cnt   <= cnt;
            state <= ST_READ_DATA;
          end
        end

        ST_WRITE_STRLEN: begin
          if (cnt == 1) begin
            cnt   <= 0;
            state <= ST_IDLE;
          end else begin
            cnt   <= cnt + 1;
            state <= ST_WRITE_STRLEN;
          end
        end

        default: begin
          cnt   <= 0;
          state <= ST_IDLE;
        end
      endcase
    end
  end



  always @(posedge clk) begin
    if (~resetn) begin
      udp_rx_s_data_tready <= 0;
    end else begin
      case (state)
        ST_READ_DATA: begin
          if (cnt == 0) begin
            udp_rx_s_data_tready <= 1;
          end else if (udp_rx_s_data_tlast && udp_rx_s_data_tvalid && udp_rx_s_data_tready) begin
            udp_rx_s_data_tready <= 0;
          end else begin
            udp_rx_s_data_tready <= udp_rx_s_data_tready;
          end
        end

        default: udp_rx_s_data_tready <= 0;
      endcase
    end
  end


  always @(posedge clk) begin
    if (~resetn) begin
      ram_din  <= 0;
      ram_addr <= 0;
      ram_wen  <= 0;
    end else
      case (state)
        ST_READ_DATA: begin
          if (udp_rx_s_data_tready && udp_rx_s_data_tvalid) begin
            ram_din <= udp_rx_s_data_tdata;
            ram_wen <= 1;
          end else begin
            ram_din  <= ram_din;
            ram_addr <= ram_addr;
            ram_wen  <= 0;
          end
          if (ram_wen == 1) begin
            ram_addr <= ram_addr + 1;
          end else begin
            ram_addr <= ram_addr;
          end
        end

        ST_WRITE_STRLEN: begin
          case (cnt)
            0: begin
              ram_din  <= data_size[15:8];
              ram_addr <= STRLENDATA_SAVED_ADDR;
              ram_wen  <= 1;
            end
            1: begin
              ram_din  <= data_size[7:0];
              ram_addr <= STRLENDATA_SAVED_ADDR + 1;
              ram_wen  <= 1;
            end
            default: begin
              ram_din  <= 0;
              ram_addr <= 0;
              ram_wen  <= 0;
            end
          endcase

        end
        default: begin
          ram_din  <= 0;
          ram_addr <= 0;
          ram_wen  <= 0;
        end
      endcase
  end


endmodule
