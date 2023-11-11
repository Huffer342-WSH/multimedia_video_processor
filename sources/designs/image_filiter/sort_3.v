module sort_3 #(
    parameter integer DATA_WIDTH = 8  //数据位宽

) (
    input clk,
    input resetn,

    input [3*DATA_WIDTH-1:0] original_data,
    input                    original_valid,

    output     [3*DATA_WIDTH-1:0] sorted_data,
    output reg                    sorted_valid
);


  wire [DATA_WIDTH-1:0] a, b, c;
  reg [DATA_WIDTH-1:0] min, med, max;

  assign a = original_data[DATA_WIDTH*0 +: DATA_WIDTH];
  assign b = original_data[DATA_WIDTH*1 +: DATA_WIDTH];
  assign c = original_data[DATA_WIDTH*2 +: DATA_WIDTH];

  always @(posedge clk) begin
    if (~resetn) begin
      min <= 0;
      med <= 0;
      max <= 0;
    end else begin
      if (a > b && a > c) begin
        max <= a;
        if (b > c) begin
          med <= b;
          min <= c;
        end else begin
          med <= c;
          min <= b;
        end
      end else if (b > a && b > c) begin
        max <= b;
        if (a > c) begin
          med <= a;
          min <= c;
        end else begin
          med <= c;
          min <= a;
        end
      end else begin
        max <= c;
        if (a > b) begin
          med <= a;
          min <= b;
        end else begin
          med <= b;
          min <= a;
        end
      end
    end
  end

  assign sorted_data = {min, med, max};
  always @(posedge clk) begin
    if (~resetn) begin
      sorted_valid <= 0;
    end else begin
      sorted_valid <= original_valid;
    end
  end
endmodule
