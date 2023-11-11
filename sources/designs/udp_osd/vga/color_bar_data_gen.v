
module color_bar_data_gen #(  //parameter define
    parameter H_DISP = 11'd1920,  //?????D?D??
    parameter V_DISP = 11'd1080   //?????D?D??
) (
    input clk,
    input resetn,


    output reg [23:0] rgb_data,   //?????????
    output reg        rgb_valid,
    output reg [10:0] y_cnt,
    input             rgb_ready
);



  localparam WHITE = 24'b11111111_11111111_11111111;  //RGB888 ???
  localparam GRAY = 24'b10000000_10000000_10000000;  //RGB888 ???
  localparam BLACK = 24'b00000000_00000000_00000000;  //RGB888 ???
  localparam RED = 24'b10000000_00001100_00000000;  //RGB888 ???
  localparam GREEN = 24'b00000000_11111111_00000000;  //RGB888 ???
  localparam BLUE = 24'b00000000_00000000_11111111;  //RGB888 ???


  reg [10:0] x_cnt;
  // reg [10:0] y_cnt;
  wire [31:0] random_number;

  wire signed [4:0] noise_r;
  wire signed [4:0] noise_g;
  wire signed [4:0] noise_b;

  assign noise_r = random_number[4:0];
  assign noise_g = random_number[9:5];
  assign noise_b = random_number[20:16];

  always @(posedge clk) begin
    if (~resetn) begin
      x_cnt <= 0;
    end else if (rgb_valid && rgb_ready) begin
      if (x_cnt == H_DISP - 1) begin
        x_cnt <= 0;
      end else begin
        x_cnt <= x_cnt + 1;
      end
    end else begin
      x_cnt <= x_cnt;
    end
  end

  always @(posedge clk) begin
    if (~resetn) begin
      y_cnt <= 0;
    end else if (rgb_valid && rgb_ready && (x_cnt == H_DISP - 1)) begin
      if (y_cnt == V_DISP - 1) begin
        y_cnt <= 0;
      end else begin
        y_cnt <= y_cnt + 1;
      end
    end else begin
      y_cnt <= y_cnt;
    end
  end

  always @(*) begin
    if (!resetn) begin
      rgb_data  = 0;
      rgb_valid = 0;
    end else begin
      rgb_valid = 1;
      if ((x_cnt >= 0) && (x_cnt < (H_DISP / 5) * 1)) begin
        rgb_data = {GRAY[23:16] + noise_r, GRAY[15:8] + noise_g, GRAY[7:0] + noise_b};
      end else if ((x_cnt >= (H_DISP / 5) * 1) && (x_cnt < (H_DISP / 5) * 2)) begin
        rgb_data = GRAY;
      end else if ((x_cnt >= (H_DISP / 5) * 2) && (x_cnt < (H_DISP / 5) * 3)) begin
        rgb_data = {RED[23:16] - noise_r, RED[15:8] + noise_g, RED[7:0] + noise_b};
      end else if ((x_cnt >= (H_DISP / 5) * 3) && (x_cnt < (H_DISP / 5) * 4)) begin
        rgb_data = RED;
      end else begin
        rgb_data = (noise_r >= 5'b11110) ? BLACK : ((noise_r <= 5'b00010) ? WHITE : GRAY);
      end
    end
  end

  random_number_generator random_number_generator_inst (
      .clk(clk),
      .resetn(resetn),
      .random_number(random_number)
  );


endmodule
