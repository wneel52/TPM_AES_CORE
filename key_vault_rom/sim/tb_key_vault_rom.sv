`timescale 1ns/1ps

module tb_key_vault_rom;

  // DUT inputs
  logic        clk;
  logic        rst_n;
  logic        chip_en;
  logic        read_en;
  logic        zeroize;
  logic [1:0]  word_idx;

  // DUT outputs
  wire [31:0]  data_out;
  wire         oe;
  wire         tamper_latched;
  wire         read_once_latched;

  // Instantiate DUT
  key_vault_rom dut (
    .clk(clk),
    .rst_n(rst_n),
    .chip_en(chip_en),
    .read_en(read_en),
    .zeroize(zeroize),
    .word_idx(word_idx),
    .data_out(data_out),
    .oe(oe),
    .tamper_latched(tamper_latched),
    .read_once_latched(read_once_latched)
  );

  // Simple expect task (4-state aware)
  task automatic tb_expect(string name, logic actual, logic expected);
    if (actual !== expected) begin
      $display("FAIL: %s at t=%0t actual=%b expected=%b", name, $time, actual, expected);
      $finish;
    end else begin
      $display("PASS: %s at t=%0t", name, $time);
    end
  endtask

  task automatic tb_expect32(string name, logic [31:0] actual, logic [31:0] expected);
    if (actual !== expected) begin
      $display("FAIL: %s at t=%0t actual=0x%08h expected=0x%08h", name, $time, actual, expected);
      $finish;
    end else begin
      $display("PASS: %s at t=%0t data=0x%08h", name, $time, actual);
    end
  endtask

  // Pulse a read transaction (one oe rising edge)
  task automatic do_read(input logic [1:0] idx, input logic [31:0] exp_data);
    // set up address while disabled
    @(negedge clk);
    word_idx = idx;

    // start transaction: raise enables before a posedge
    @(negedge clk);
    chip_en = 1'b1;
    read_en = 1'b1;

    // sample on next posedge + small delay
    @(posedge clk); #1;

    tb_expect($sformatf("oe asserted for idx=%0d", idx), oe, 1'b1);
    tb_expect32($sformatf("data_out matches idx=%0d", idx), data_out, exp_data);

    // end transaction: deassert read_en to create a new oe rising edge next time
    @(negedge clk);
    read_en = 1'b0;
    chip_en = 1'b0;

    // allow one posedge to settle
    @(posedge clk); #1;
    tb_expect("oe deasserted after transaction", oe, 1'b0);
  endtask

  // Attempt a read after lockout; expect oe low and data_out zero
  task automatic expect_locked_read(input logic [1:0] idx);
    @(negedge clk);
    word_idx = idx;

    @(negedge clk);
    chip_en = 1'b1;
    read_en = 1'b1;

    @(posedge clk); #1;
    tb_expect($sformatf("oe stays low after lockout idx=%0d", idx), oe, 1'b0);
    tb_expect32("data_out stays zero when disabled", data_out, 32'h0000_0000);

    @(negedge clk);
    read_en = 1'b0;
    chip_en = 1'b0;
  endtask

  // Clock generator
  initial begin
    clk = 0;
    forever #5 clk = ~clk;
  end

  // Monitor (helpful while bringing up)
  initial begin
    $display("time  rst_n chip read zer idx | oe data_out        | tamper read_once");
    $monitor("%4t   %0b    %0b    %0b   %0b  %0d | %0b 0x%08h |   %0b      %0b",
             $time, rst_n, chip_en, read_en, zeroize, word_idx, oe, data_out, tamper_latched, read_once_latched);
  end

  // Main test
  initial begin
    $display("=== Begin ROM TB ===");

    // init
    rst_n   = 1'b0;
    chip_en = 1'b0;
    read_en = 1'b0;
    zeroize = 1'b0;
    word_idx= 2'd0;

    $dumpfile("tb_key_vault_rom.vcd");
    $dumpvars(0, tb_key_vault_rom);

    // reset release
    repeat (2) @(negedge clk);
    rst_n = 1'b1;
    @(posedge clk); #1;

    // Sanity: disabled outputs
    tb_expect("oe low when disabled", oe, 1'b0);
    tb_expect32("data_out zero when disabled", data_out, 32'h0000_0000);
    tb_expect("tamper not latched after reset", tamper_latched, 1'b0);
    tb_expect("read_once not latched after reset", read_once_latched, 1'b0);

    // Read all 4 words (big-endian order)
    do_read(2'd0, 32'h00112233);
    do_read(2'd1, 32'h44556677);
    do_read(2'd2, 32'h8899AABB);
    do_read(2'd3, 32'hCCDDEEFF);

    // After 4 reads, read_once should be latched (may latch at/after 4th read posedge)
    @(posedge clk); #1;
    tb_expect("read_once latched after 4 reads", read_once_latched, 1'b1);

    // 5th read should be blocked
    expect_locked_read(2'd0);

    // Reset again, then test zeroize tamper lock
    $display("=== Reset + zeroize test ===");
    @(negedge clk);
    rst_n = 1'b0;
    chip_en = 1'b0;
    read_en = 1'b0;
    zeroize = 1'b0;
    repeat (2) @(negedge clk);
    rst_n = 1'b1;

    // Trip zeroize
    @(negedge clk);
    zeroize = 1'b1;
    @(posedge clk); #1;
    tb_expect("tamper latched after zeroize", tamper_latched, 1'b1);

    // Attempts should be blocked
    expect_locked_read(2'd2);

    $display("=== ALL ROM TB TESTS PASSED ===");
    $finish;
  end

endmodule
