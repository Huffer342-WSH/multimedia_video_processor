module random_number_generator (
    input wire clk,  // 时钟信号
    input wire resetn,  // 复位信号
    output wire [31:0] random_number
);

  reg [31:0] lfsr_state;  // LFSR 状态寄存器

  always @(posedge clk) begin
    if (~resetn) begin
      lfsr_state <= 32'h1;  // 初始状态
    end else begin
      // LFSR 的反馈多项式为 x^32 + x^22 + x^2 + x + 1
      lfsr_state <= {
        lfsr_state[30:0], lfsr_state[0] ^ lfsr_state[22] ^ lfsr_state[2] ^ lfsr_state[1] ^ 1'b1
      };
    end
  end
  assign random_number = lfsr_state;

endmodule
