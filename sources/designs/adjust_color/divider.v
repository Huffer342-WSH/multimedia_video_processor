//parameter N means the actual width of dividend
//using 29/5=5...4

module divider #(
    parameter N = 5,
    parameter M = 3
) (
    input clk,
    input resetn,

    input         in_valid,
    input [N-1:0] dividend,
    input [M-1:0] divisor,

    output         out_valid,
    output [N-1:0] quotient,   //width = N-1+1
    output [M-1:0] remainder
);
  localparam integer NAct = M + N - 1;

  wire [N-1-1:0] dividend_t [N-1:0];
  wire [  M-1:0] divisor_t  [N-1:0];
  wire [  M-1:0] remainder_t[N-1:0];
  wire [  N-1:0] rdy_t;
  wire [  N-1:0] quotient_t [N-1:0];


  divider_cell #(
      .N(NAct),
      .M(M)
  ) u_divider_step0 (
      .clk        (clk),
      .resetn     (resetn),
      //input
      .en         (in_valid),
      .dividend   ({{(M) {1'b0}}, dividend[N-1]}),  //minimal cell to calculate
      .divisor    (divisor),                        //divisor
      .quotient_ci({(NAct - M + 1) {1'b0}}),        //quotient info from last cell
      .dividend_ci(dividend[N-1-1:0]),              //original dividend remained
      //output
      .dividend_kp(dividend_t[N-1]),                //keep remaind-dividend for pipeline
      .divisor_kp (divisor_t[N-1]),                 //keep divisor for pipeline
      .rdy        (rdy_t[N-1]),
      .quotient   (quotient_t[N-1]),
      .remainder  (remainder_t[N-1])
  );

  genvar i;
  generate
    for (i = 1; i <= NAct - M; i = i + 1) begin : g_sqrt_stepx
      divider_cell #(
          .N(NAct),
          .M(M)
      ) u_divider_step (
          .clk        (clk),
          .resetn     (resetn),
          //input
          .en         (rdy_t[N-1-i+1]),
          .dividend   ({remainder_t[N-1-i+1], dividend_t[N-1-i+1][N-1-i]}),
          .divisor    (divisor_t[N-1-i+1]),
          .quotient_ci(quotient_t[N-1-i+1]),
          .dividend_ci(dividend_t[N-1-i+1]),
          //output
          .divisor_kp (divisor_t[N-1-i]),
          .dividend_kp(dividend_t[N-1-i]),
          .rdy        (rdy_t[N-1-i]),
          .quotient   (quotient_t[N-1-i]),
          .remainder  (remainder_t[N-1-i])
      );
    end  // block: sqrt_stepx
  endgenerate

  assign out_valid = rdy_t[0];
  assign quotient  = quotient_t[0];
  assign remainder = remainder_t[0];

endmodule
