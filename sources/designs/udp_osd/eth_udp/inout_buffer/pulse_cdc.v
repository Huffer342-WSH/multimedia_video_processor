
//`define USE_XPM
module pulse_cdc (
    input  resetn,
    input  src_clk,
    input  dest_clk,
    input  src_pulse,
    output dest_pulse
);


`ifdef USE_XPM
  xpm_cdc_pulse #(
      .DEST_SYNC_FF  (4),  // DECIMAL; range: 2-10
      .INIT_SYNC_FF  (0),  // DECIMAL; 0=disable simulation init values, 1=enable simulation init values
      .REG_OUTPUT    (0),  // DECIMAL; 0=disable registered output, 1=enable registered output
      .RST_USED      (0),  // DECIMAL; 0=no reset, 1=implement reset
      .SIM_ASSERT_CHK(0)   // DECIMAL; 0=disable simulation messages, 1=enable simulation messages
  ) xpm_cdc_pulse_inst (
      .dest_pulse(dest_pulse),  // 1-bit output: Outputs a pulse the size of one dest_clk period when a pulse
                                // transfer is correctly initiated on src_pulse input. This output is
                                // combinatorial unless REG_OUTPUT is set to 1.

      .dest_clk (dest_clk),  // 1-bit input: Destination clock.
      .src_clk  (src_clk),   // 1-bit input: Source clock.
      .src_pulse(src_pulse)  // 1-bit input: Rising edge of this signal initiates a pulse transfer to the
                             // destination clock domain. The minimum gap between each pulse transfer must be
                             // at the minimum 2*(larger(src_clk period, dest_clk period)). This is measured
                             // between the falling edge of a src_pulse to the rising edge of the next
                             // src_pulse. This minimum gap will guarantee that each rising edge of src_pulse
                             // will generate a pulse the size of one dest_clk period in the destination
                             // clock domain. When RST_USED = 1, pulse transfers will not be guaranteed while
                             // src_rst and/or dest_rst are asserted.

  );


`else
  wire in;
  reg  out;
  reg in_req, in_req_sync0, in_req_sync1;
  reg out_ack, out_ack_sync0, out_ack_sync1;

  assign in = src_pulse;
  assign dest_pulse = out;

  always @(posedge dest_clk) begin
    if (~resetn) begin
      in_req_sync0 <= 0;
      in_req_sync1 <= 0;
      out_ack <= 0;
      out <= 0;
    end else begin
      in_req_sync0 <= in_req;
      in_req_sync1 <= in_req_sync0;
      if (~out_ack & in_req_sync1) begin
        out_ack <= 1;
        out <= 1;
      end else if (~in_req_sync1) begin
        out_ack <= 0;
        out <= 0;
      end else begin
        out_ack <= out_ack;
        out <= 0;
      end
    end
  end

  always @(posedge src_clk) begin
    if (~resetn) begin
      in_req <= 0;
    end else begin
      out_ack_sync0 <= out_ack;
      out_ack_sync1 <= out_ack_sync0;
      if (in) begin
        in_req <= 1;
      end else if (out_ack_sync1) begin
        in_req <= 0;
      end else begin
        in_req <= in_req;
      end
    end
  end


`endif

endmodule
