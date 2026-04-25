module aes_core_128_synth (
    input  wire         clk,
    input  wire         reset_n,
    input  wire         init,
    input  wire         next,
    input  wire [127:0] key,
    input  wire [127:0] block,
    output wire         ready,
    output wire [127:0] result,
    output wire         result_valid
);

  aes_core core (
    .clk(clk),
    .reset_n(reset_n),
    .encdec(1'b1),
    .init(init),
    .next(next),
    .ready(ready),
    .key({128'h0, key}),
    .keylen(1'b0),
    .block(block),
    .result(result),
    .result_valid(result_valid)
  );

endmodule
