`timescale 1ns/1ps

module tb_tpm_aes_top;

  logic         clk;
  logic         reset;
  logic         zeroize;

  logic         key_wr_en;
  logic [1:0]   key_wr_addr;
  logic [31:0]  key_wr_data;
  logic         commit;

  logic [127:0] key_hw;

  logic         blk_wr_en;
  logic [1:0]   blk_wr_addr;
  logic [31:0]  blk_wr_data;

  logic         aes_start;

  logic         rd_en;
  logic [1:0]   rd_addr;
  wire  [31:0]  rd_data;
  wire          rd_valid;

  wire          unlocked;
  wire          trap;
  wire          aes_enable;
  wire          result_ready;

  tpm_aes_top dut (
    .clk          (clk),
    .reset        (reset),
    .zeroize      (zeroize),
    .key_wr_en    (key_wr_en),
    .key_wr_addr  (key_wr_addr),
    .key_wr_data  (key_wr_data),
    .commit       (commit),
    .key_hw       (key_hw),
    .blk_wr_en    (blk_wr_en),
    .blk_wr_addr  (blk_wr_addr),
    .blk_wr_data  (blk_wr_data),
    .aes_start    (aes_start),
    .rd_en        (rd_en),
    .rd_addr      (rd_addr),
    .rd_data      (rd_data),
    .rd_valid     (rd_valid),
    .unlocked     (unlocked),
    .trap         (trap),
    .aes_enable   (aes_enable),
    .result_ready (result_ready)
  );

  initial clk = 1'b0;
  always #5 clk = ~clk;

  task automatic apply_reset;
    begin
      reset       = 1'b1;
      zeroize     = 1'b0;
      key_wr_en   = 1'b0;
      key_wr_addr = 2'b00;
      key_wr_data = 32'h0;
      commit      = 1'b0;
      blk_wr_en   = 1'b0;
      blk_wr_addr = 2'b00;
      blk_wr_data = 32'h0;
      aes_start   = 1'b0;
      rd_en       = 1'b0;
      rd_addr     = 2'b00;

      repeat (3) @(posedge clk);
      reset = 1'b0;
      @(posedge clk);
    end
  endtask

  task automatic write_unlock_key(input [127:0] key_value);
    begin
      @(posedge clk);
      key_wr_en   <= 1'b1;
      key_wr_addr <= 2'd0;
      key_wr_data <= key_value[127:96];

      @(posedge clk);
      key_wr_addr <= 2'd1;
      key_wr_data <= key_value[95:64];

      @(posedge clk);
      key_wr_addr <= 2'd2;
      key_wr_data <= key_value[63:32];

      @(posedge clk);
      key_wr_addr <= 2'd3;
      key_wr_data <= key_value[31:0];

      @(posedge clk);
      key_wr_en   <= 1'b0;
      key_wr_addr <= 2'd0;
      key_wr_data <= 32'h0;
    end
  endtask

  task automatic do_commit;
    begin
      @(posedge clk);
      commit <= 1'b1;
      @(posedge clk);
      commit <= 1'b0;
    end
  endtask

  task automatic write_block(input [127:0] block_value);
    begin
      @(posedge clk);
      blk_wr_en   <= 1'b1;
      blk_wr_addr <= 2'd0;
      blk_wr_data <= block_value[127:96];

      @(posedge clk);
      blk_wr_addr <= 2'd1;
      blk_wr_data <= block_value[95:64];

      @(posedge clk);
      blk_wr_addr <= 2'd2;
      blk_wr_data <= block_value[63:32];

      @(posedge clk);
      blk_wr_addr <= 2'd3;
      blk_wr_data <= block_value[31:0];

      @(posedge clk);
      blk_wr_en   <= 1'b0;
      blk_wr_addr <= 2'd0;
      blk_wr_data <= 32'h0;
    end
  endtask

  task automatic start_aes;
    begin
      @(posedge clk);
      aes_start <= 1'b1;
      @(posedge clk);
      aes_start <= 1'b0;
    end
  endtask

  task automatic read_result_word(input [1:0] addr);
    begin
      @(posedge clk);
      rd_en   <= 1'b1;
      rd_addr <= addr;

      @(posedge clk);
      $display("TB: read addr=%0d rd_valid=%0b rd_data=0x%08h", addr, rd_valid, rd_data);

      rd_en   <= 1'b0;
      rd_addr <= 2'b00;
    end
  endtask

  task automatic expect_bit(
    input string name,
    input logic actual,
    input logic expected
  );
    begin
      if (actual !== expected) begin
        $display("FAIL: %s actual=%0b expected=%0b time=%0t", name, actual, expected, $time);
        $finish;
      end
      else begin
        $display("PASS: %s = %0b at time=%0t", name, actual, $time);
      end
    end
  endtask

  initial begin
    logic [127:0] test_key;
    logic [127:0] test_block;

    test_key   = 128'h00112233_44556677_8899aabb_ccddeeff;
    test_block = 128'h00112233_44556677_8899aabb_ccddeeff;

    key_hw = test_key;

    apply_reset();

    expect_bit("unlocked after reset", unlocked, 1'b0);
    expect_bit("trap after reset", trap, 1'b0);

    $display("TB: writing unlock key...");
    write_unlock_key(test_key);

    $display("TB: committing unlock key...");
    do_commit();

    repeat (4) @(posedge clk);

    expect_bit("unlocked after valid commit", unlocked, 1'b1);
    expect_bit("aes_enable after valid commit", aes_enable, 1'b1);
    expect_bit("trap remains low after valid commit", trap, 1'b0);

    $display("TB: writing AES block...");
    write_block(test_block);

    repeat (2) @(posedge clk);

    // Give the internal AES init sequence enough time to complete
    $display("TB: waiting before starting AES...");
    repeat (40) @(posedge clk);

    $display("TB: starting AES...");
    start_aes();

    // Timeout-safe wait for result
    repeat (400) begin
      @(posedge clk);
      if (result_ready) begin
        $display("TB: result_ready observed at time=%0t", $time);
        expect_bit("result_ready asserted", result_ready, 1'b1);

        $display("TB: reading AES result words...");
        read_result_word(2'd0);
        read_result_word(2'd1);
        read_result_word(2'd2);
        read_result_word(2'd3);

        $display("PASS: basic top-level unlock/encrypt/read flow completed");
        #20;
        $finish;
      end
    end

    $display("FAIL: Timeout waiting for result_ready");
    $finish;
  end

  initial begin
    $dumpfile("tb_tpm_aes_top.vcd");
    $dumpvars(0, tb_tpm_aes_top);
  end

endmodule
