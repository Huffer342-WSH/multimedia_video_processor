module rd1_addr_ctr #(
    parameter START_ADDR   = 32'h0000_0000,
    parameter BLOCK_SIZE   = 32'h0008_0000,
    parameter IMAGE_BLOCK  = 32'h0007_0800,
    parameter WR_NUM       = 32'd1800,
    parameter ADDR_WIDTH   = 30,
    parameter RD_NUM_WIDTH = 28,
    parameter IMAGE_W      = 1280,
    parameter IMAGE_H      = 720,
    parameter IMAGE_SIZE   = 12
) (
    input clk,
    input rst,
    input rd_vs,  // notic  imag_addr_valid and rd_vs delay 
    input signed [7:0] shift_h,
    input [4:0] wr0_image_cnt,
    input [2:0] wr3_image_cnt,
    input image_addr_valid,
    input [IMAGE_SIZE-1:0] image_addr,
    input rd_ddr_done,
    output rd_ddr_valid,
    output [ADDR_WIDTH-1:0] rd_ddr_addr,
    output [RD_NUM_WIDTH-1:0] rd_ddr_num,
    output reg rd_idle_sta,

    input [1:0] rd_mode


);

  localparam S0 = 'd0;
  localparam S1 = 'd1;
  localparam S2 = 'd2;
  localparam S3 = 'd3;
  localparam S4 = 'd4;
  localparam S5 = 'd5;
  reg [2:0] rd1_sta;
  reg [2:0] delay_cnt;
  reg addr_valid_flag;
  reg image_half;
  reg [1:0] rd_mode0;

  wire [9:0] dout;
  wire rd_en, empty;

  reg [ADDR_WIDTH-1:0] gen_start_addr0, gen_start_addr1, gen_start_addr3;
  reg [4:0] rd0_image_cnt;
  reg [2:0] rd3_image_cnt;
  reg rd_vs0, rd_vs1, rd_vs2;
  reg  rd_vs_rise0;
  wire rd_vs_rise;
  reg rd_ddr_done0, rd_ddr_done1, rd_ddr_done2;
  wire rd_ddr_done_rise;

  assign rd_vs_rise = (~rd_vs1) & (rd_vs0);
  assign rd_ddr_done_rise = (~rd_ddr_done2) & (rd_ddr_done1);
  always @(posedge clk) begin
    rd_vs0       <= rd_vs;
    rd_vs1       <= rd_vs0;
    rd_vs_rise0  <= rd_vs_rise;
    rd_ddr_done0 <= rd_ddr_done;
    rd_ddr_done1 <= rd_ddr_done0;
    rd_ddr_done2 <= rd_ddr_done1;
  end
  reg  [4:0] wr0_image_fram_cnt1;
  wire [4:0] wr0_image_fram_cnt0;
  wire [2:0] wr3_image_fram_cnt0;
  reg  [2:0] wr3_image_fram_cnt1;
  async_to_sync #(
      .WIDTH(5)
  ) wr0_async_to_rd2_sync (
      .clk(clk),

      .data_in (wr0_image_cnt),
      .data_out(wr0_image_fram_cnt0)

  );
  async_to_sync #(
      .WIDTH(3)
  ) wr3_async_to_rd2_sync (
      .clk(clk),

      .data_in (wr3_image_cnt),
      .data_out(wr3_image_fram_cnt0)

  );
  localparam START3_ADDR = BLOCK_SIZE * 48;
  reg signed [7:0] shift_h0;
  always @(posedge clk) begin
    //wr0_image_fram_cnt1 <= (wr0_image_fram_cnt0==0)?30:wr0_image_fram_cnt0-1 ;
    wr0_image_fram_cnt1 <= wr0_image_fram_cnt0 - 1;
    wr3_image_fram_cnt1 <= wr3_image_fram_cnt0 - 1;
    //image_fram_cnt1 <= 0 ;
    if (rd_vs_rise && (rd1_sta == S0)) begin
      rd0_image_cnt <= wr0_image_fram_cnt1;
      rd3_image_cnt <= wr3_image_fram_cnt1;
      shift_h0      <= shift_h;
      rd_mode0      <= rd_mode;
    end
    if (rd_vs_rise0) begin
      gen_start_addr0 <= rd0_image_cnt * BLOCK_SIZE + START_ADDR;
      gen_start_addr1 <= rd0_image_cnt * BLOCK_SIZE + START_ADDR + IMAGE_BLOCK / 2;
      gen_start_addr3 <= rd3_image_cnt * BLOCK_SIZE + START3_ADDR;
    end else begin
      gen_start_addr0 <= gen_start_addr0;
      gen_start_addr1 <= gen_start_addr1;
      gen_start_addr3 <= gen_start_addr3;
    end
  end



  assign rd_en = ((~empty) && (rd1_sta == S0)) ? 1'b1 : 1'b0;
  //rd1_ddr_addr_fifo u_rd1_ddr_addr_fifo (
  //  .clk(clk),      // input wire clk
  //  .srst(rst),    // input wire srst
  //  .din(image_addr[9:0]),      // input wire [9 : 0] din
  //  .wr_en(image_addr_valid),  // input wire wr_en
  //  .rd_en(rd_en),  // input wire rd_en
  //  .dout(dout),    // output wire [9 : 0] dout
  //  .full(),    // output wire full
  //  .empty(empty)  // output wire empty
  //);

  rd1_ddr_addr_fifo1 u_rd1_ddr_addr_fifo1 (
      .clk         (clk),               // input
      .rst         (rst),               // input
      .wr_en       (image_addr_valid),  // input
      .wr_data     (image_addr[9:0]),   // input [9:0]
      .wr_full     (),                  // output
      .almost_full (),                  // output
      .rd_en       (rd_en),             // input
      .rd_data     (dout),              // output [9:0]
      .rd_empty    (empty),             // output
      .almost_empty()                   // output
  );



  always @(posedge clk) begin
    if (rst) begin
      rd1_sta <= S0;
    end else begin
      case (rd1_sta)
        S0: begin
          if (~empty) rd1_sta <= S1;
          else rd1_sta <= S0;
        end
        S1: begin
          if (delay_cnt == 3'd7) begin
            if (image_half) rd1_sta <= S3;
            else rd1_sta <= S3;
            // rd1_sta <= S2 ;
          end else rd1_sta <= S1;
        end
        S2: begin
          if (rd_ddr_done_rise) rd1_sta <= S3;
          else rd1_sta <= S2;
        end
        S3: begin
          if (rd_ddr_done_rise) rd1_sta <= S0;
          else rd1_sta <= S3;
        end
        default: ;
      endcase
    end
  end

  always @(posedge clk) begin
    if (rd1_sta == S1) image_half <= ((dout >= IMAGE_H / 2) && (rd_mode0[1] == 1'b0)) ? 1'b1 : 1'b0;
    //image_half <= ((dout>=IMAGE_H/2))?1'b1:1'b0;
    else
      image_half <= image_half;
  end



  reg rd_ddr_valid0;
  reg [ADDR_WIDTH-1:0] rd_ddr_addr0, mult_addr;
  reg [IMAGE_SIZE-1:0] dec_h, mult_h;
  reg signed [10:0] add_sift_h;
  reg [9:0] abs_add_sift_h, dec_sift;
  reg rd_ddr_valid1;
  reg [RD_NUM_WIDTH-1:0] rd_ddr_num0;
  wire signed [10:0] shift_h1, dout1;
  assign rd_ddr_valid = rd_ddr_valid0;
  assign rd_ddr_addr  = rd_ddr_addr0 * 4;
  //assign rd_ddr_num   = WR_NUM*2 ;
  assign rd_ddr_num   = rd_ddr_num0;
  always @(posedge clk) begin
    mult_addr <= mult_h * IMAGE_W / 4;
  end
  always @(posedge clk) begin
    if (rst) begin
    end else begin
      case (rd1_sta)
        S0: begin
          rd_ddr_valid0 <= 'd0;
          rd_ddr_addr0  <= rd_ddr_addr0;
          mult_h        <= mult_h;
          delay_cnt     <= 'd0;
        end
        S1: begin
          delay_cnt <= delay_cnt + 1'b1;
          rd_ddr_valid0 <= 'd1;
          //if(delay_cnt==3'd7)
          //begin 
          //   // rd_ddr_valid0 <= 'd1 ;
          //	if(image_half)
          //	    rd_ddr_addr0 <= gen_start_addr1 + mult_addr ;
          //	else 
          //	    rd_ddr_addr0 <= gen_start_addr0 + mult_addr ;
          //end 
          //else begin 
          //   // rd_ddr_valid0 <= 'd0 ;
          //	rd_ddr_addr0  <= rd_ddr_addr0 ;
          // end 
          if (rd_mode0[1] == 1'b0) begin
            // rd_ddr_valid0 <= 'd1 ;
            if (image_half)
              //rd_ddr_addr0 <= gen_start_addr1 + mult_addr ;
              rd_ddr_addr0 <= gen_start_addr1 + mult_addr;
            else rd_ddr_addr0 <= gen_start_addr0 + mult_addr;
          end else begin
            rd_ddr_addr0 <= gen_start_addr3 + mult_addr;
          end
          if (image_half) begin
            mult_h <= dec_h;
            rd_ddr_num0 <= WR_NUM;
          end else begin
            mult_h <= dout * 2;
            rd_ddr_num0 <= WR_NUM * 2;
          end
        end
        S2: begin
          mult_h <= (dec_sift * 2 + 1);
          if (rd_ddr_done_rise) begin
            rd_ddr_addr0  <= gen_start_addr0 + mult_addr;  //+ IMAGE_W/4 ;
            rd_ddr_valid0 <= 'd1;
          end else begin
            rd_ddr_valid0 <= 'd0;
            rd_ddr_addr0  <= rd_ddr_addr0;
          end
        end
        S3: begin
          rd_ddr_valid0 <= rd_ddr_valid1;
          rd_ddr_addr0  <= rd_ddr_addr0;
          mult_h        <= mult_h;
        end
        default: ;
      endcase
    end
  end
  always @(posedge clk) begin
    rd_ddr_valid1 <= rd_ddr_done_rise;
  end

  assign shift_h1 = shift_h0 ;
  assign dout1    = dout ;
  always @(posedge clk) begin
    dec_h          <= dout - IMAGE_H / 2;
    add_sift_h     <= shift_h1 + dout1;
    abs_add_sift_h <= (add_sift_h[10]) ? -add_sift_h : add_sift_h;
    if (add_sift_h[10]) dec_sift <= 'd0;
    else if (abs_add_sift_h >= IMAGE_H / 2) dec_sift <= IMAGE_H / 2 - 1;
    else dec_sift <= abs_add_sift_h;
  end
  always @(posedge clk) begin
    rd_idle_sta <= (rd1_sta == S0) ? 1'b1 : 1'b0;
  end
endmodule
