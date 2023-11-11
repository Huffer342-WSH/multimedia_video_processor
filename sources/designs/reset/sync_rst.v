module sync_rst (
    input clk,
    input rstn,

    output reg rst
);

  reg rst0, rst1;
  always @(posedge clk or negedge rstn) begin
    if (~rstn) begin
      rst0 <= 1'b1;
      rst1 <= 1'b1;
      rst  <= 1'b1;
    end else begin
      rst0 <= 1'b0;
      rst1 <= rst0;
      rst  <= rst1 | rst0;
    end
  end
endmodule
