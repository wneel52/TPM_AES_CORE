`timescale 1ns/1ps

module tb_key_commit_buffer;

    localparam int unsigned SIZE = 128;
    // DUT inputs

    logic clk;
    logic reset;
    logic zeroize;
    
    logic wr_en;
    logic [31:0] wr_data;
    logic [1:0] wr_addr;

    logic commit;
    logic [SIZE-1:0] key_hw;

    // DUT outputs
    logic [SIZE-1:0] key_in;
    logic [3:0] valid_mask;
    logic all_valid;
    logic do_compare;
    logic match_q;
    logic commit_illegal;

    // init DUT
    key_commit_buffer #(.SIZE(SIZE)) dut (
        .clk(clk),
        .reset(reset),
        .zeroize(zeroize),
        .wr_en(wr_en),
        .wr_addr(wr_addr),
        .wr_data(wr_data),
        .commit(commit),
        .key_hw(key_hw),
        .key_in(key_in),
        .valid_mask(valid_mask),
        .all_valid(all_valid),
        .do_compare(do_compare),
        .match_q(match_q),
        .commit_illegal(commit_illegal)
    );


    // generate clock signal
    initial begin
        clk = 1'b0;
        forever #5 clk = ~clk; // 5ns 
    end

    // expect bit helpers

    task automatic tb_expect_bit(string name, logic actual, logic expected);
        if (actual !== expected) begin
            $display("FAIL: %s at %t actual=%h expected=%h",name,$time,actual,expected);
            $finish;
        end
        else begin
            $display("PASS: %s at t=%0t", name, $time);    
        end
    endtask
     
    
    task automatic tb_expect_vec128(string name, logic [127:0] actual, logic [127:0] expected);
        if (actual !== expected) begin
            $display("FAIL: %s at t=%0t actual=%h expected=%h", name, $time, actual, expected);
            $finish;
        end else begin
            $display("PASS: %s at t=%0t", name, $time);
        end
    endtask

    task automatic tb_expect_mask(string name, logic [3:0] actual, logic [3:0] expected);
        if (actual !== expected) begin
            $display("FAIL: %s at t=%0t actual=%h expected=%h", name, $time, actual, expected);
            $finish;
        end else begin
            $display("PASS: %s at t=%0t", name, $time);
        end
    endtask

    // bus helpers (place holders for real signals)
    task automatic do_reset();
        begin
          @(negedge clk);
          reset   = 1'b1;
          zeroize = 1'b0;
          wr_en   = 1'b0;
          commit  = 1'b0;
          @(negedge clk);
          @(negedge clk);
          reset   = 1'b0;
          @(negedge clk);
        end
    endtask

    task automatic write_word(input logic [1:0] addr, input logic [31:0] data);
        begin
            @(negedge clk)
            wr_addr = addr;
            wr_data = data;
            wr_en = 1'b1;
            commit = 1'b0;
            @(negedge clk);
            wr_en = 1'b0;
        end
    endtask

    task automatic do_commit();
        begin
            @(negedge clk);
            commit  = 1'b1;
            wr_en = 1'b0;
            @(posedge clk); #1;
            @(negedge clk);
            commit = 1'b0;
        end
    endtask

    // handler if commit and write on same cycle ( commit should win)
    task automatic commit_conflicts_write(input logic [1:0] addr, input logic [31:0] data);
        begin
            @(negedge clk);
            wr_addr = addr;
            wr_data = data;
            wr_en = 1'b1;
            commit = 1'b1;
            @(posedge clk); #1;
            @(negedge clk);
            wr_en = 1'b0;
            commit = 1'b0;
        end
    endtask

    task automatic sample_idle_outputs(string tag);
        begin
            @(posedge clk); #1; 
            tb_expect_bit({tag, ": do compare low"}, do_compare, 1'b0);
            tb_expect_bit({tag, ": commit_illegal low"}, commit_illegal, 1'b0);
        end
    endtask


    // test sequence
    initial begin
        $display(" === begin test squenece ===");
        // initial inputs
        reset = 1'b0;
        zeroize = 1'b0;
        wr_en = 1'b0;
        wr_addr = 2'd0;
        wr_data = 32'h0;
        commit = 1'b0;

        // built in hw key -> big endian
        key_hw = 128'h00112233_44556677_8899AABB_CCDDEEFF;
        $dumpfile("tb_key_commit_buffer.vcd");
        $dumpvars(0, tb_key_commit_buffer);
        
        // 1.) reset
        $display("Test 1: Reset");
        do_reset(); // use do reset task
        tb_expect_mask("reset: valid_mask=0000", valid_mask, 4'b0000);
        tb_expect_bit("reset: all_valid=0", all_valid, 1'b0);
        tb_expect_bit("reset: do_compare=0",do_compare, 1'b0);
        tb_expect_bit("reset match_q=0",match_q,1'b0);
        tb_expect_bit("reset: commit illegal=0",commit_illegal,1'b0);
        tb_expect_vec128("reset: key_in=0", key_in, 128'h0);
        $display("Test 1: PASS");

        // 2.) partial write + commit -> expect illegal
        $display("Test 2: Partial Write then commit (expect illegal)");
        do_reset();
        write_word(2'd0, 32'h00112233);
        write_word(2'd1, 32'h44556677);
        @(posedge clk); #1;
        tb_expect_mask("partial: valid_mask=0011", valid_mask, 4'b0011);
        tb_expect_bit("partial: all_valid=0", all_valid, 1'b0);
        do_commit();
        tb_expect_bit("partial: do_compare=0",do_compare,1'b0);
        tb_expect_bit("partial: commit_illegal=1 (pulsed)",commit_illegal, 1'b1);
        tb_expect_bit("partial: match_q=0 fail-closed",match_q,1'b0);
        @(posedge clk); #1;
        tb_expect_bit("partial: commit_illegal back to 0 on following cycle",commit_illegal,1'b0);
        tb_expect_bit("partial: do_compare stays 0 next cycle",do_compare,1'b0);
        $display("Test 2: Passed");
        
        $display("Test 3: Correct Key Written");
        do_reset();
        write_word(2'd0, 32'h00112233);
        write_word(2'd1, 32'h44556677);
        write_word(2'd2, 32'h8899AABB);
        write_word(2'd3, 32'hCCDDEEFF);
        @(posedge clk); #1;
        tb_expect_mask("full: valid_mask=1111", valid_mask, 4'b1111);
        tb_expect_bit("full: all_valid=1", all_valid, 1'b1);
        tb_expect_vec128("full: key_in matches ROM key", key_in, key_hw);
        do_commit();
        tb_expect_bit("full: do_compare=1 (pulsed)", do_compare, 1'b1);
        tb_expect_bit("full: commit_illegal=0", commit_illegal, 1'b0);
        tb_expect_bit("full: match_q=1", match_q, 1'b1);
        @(posedge clk); #1;
        tb_expect_bit("full: do_compare back to 0 next cycle", do_compare, 1'b0);        
        tb_expect_bit("full: commit_illegal; stays 0 next cycle", commit_illegal, 1'b0);        
        tb_expect_bit("full: match_q stays 1 after pulse", match_q, 1'b1);        
        $display("Test 3: Passed");

        $display("Test 4: Mismatched Key");
        do_reset();
        // 1 bit difference -> should be caught by XOR compare
        write_word(2'd0, 32'h00112233);
        write_word(2'd1, 32'h44556677);
        write_word(2'd2, 32'h8899AABB);
        write_word(2'd3, 32'hCCDDEEFE);
        @(posedge clk); #1;
        tb_expect_mask("wrong: valid mask=1111", valid_mask, 4'b1111);
        tb_expect_bit("wrong: all_valid=1", all_valid, 1'b1);
        do_commit();
        tb_expect_bit("wrong: do_compare=1 (pulsed)", do_compare, 1'b1);        
        tb_expect_bit("wrong: commit_illegal=0", commit_illegal, 1'b0);
        tb_expect_bit("wrong: match_q=0", match_q, 1'b0);
        @(posedge clk); #1;
        tb_expect_bit("wrong: do_compare back to 0", do_compare, 1'b0);
        tb_expect_bit("wrong: commit_illegal stays 0 next cycle", commit_illegal, 1'b0);
        tb_expect_bit("wrong: match_q=after pulse", match_q, 1'b0);        

        $display("Test 4: Pass");

        // 5.) wr_en / commit asserted in the same cycle (expect commit to win)
        $display("Test 5: Commit wins over write conflict (expect illegal if not all_valid)");
        do_reset();
        // write 3/4 words -> not all valid
        write_word(2'd0, 32'h00112233);
        write_word(2'd1, 32'h44556677);
        write_word(2'd2, 32'h8899AABB);        
        @(posedge clk); #1;
        tb_expect_mask("conflict: valid_mask=0111 before conflict", valid_mask, 4'b0111);
        tb_expect_bit("conflict: all_valid=0 before conflict", all_valid, 1'b0);
        // call handler for conflict
        commit_conflicts_write(2'd3, 32'hCCDDEEFF);
        // check vectors
        tb_expect_bit("conflict: do_compare=0", do_compare, 1'b0);
        tb_expect_bit("conflict: commit_illegal=1 (pulsed)", commit_illegal, 1'b1);
        tb_expect_bit("conflict: match_q=0 fail-closed", match_q, 1'b0);
        tb_expect_mask("conflict: valid_mask still 0111 (ignored last write)", valid_mask, 4'b0111);     
        // next cycle pulse should drop
        @(posedge clk); #1;
        tb_expect_bit("conflict: commit_illegal back to 0 next cycle", commit_illegal, 1'b0);
        tb_expect_bit("conflict: do_compare stays 0 next cycle", do_compare, 1'b0);
        $display("Test 5: Passed");

        $display("Test 6: Zeroize");
        // reset -> write keyword -> commit
        do_reset();
        write_word(2'd0, 32'h00112233);
        write_word(2'd1, 32'h44556677);
        write_word(2'd2, 32'h8899AABB);
        write_word(2'd3, 32'hCCDDEEFF);
        do_commit();

        tb_expect_bit("pre-zeroize: do_compare=1", do_compare, 1'b1);
        tb_expect_bit("pre-zeroize: match_q=1", match_q, 1'b1);
        tb_expect_mask("pre-zeroize: valid_mask=1111", valid_mask, 4'b1111);

        // Commit performed, now zero the circuit
        @(negedge clk);
        zeroize = 1'b1;
        @(negedge clk);
        zeroize = 1'b0;

        tb_expect_mask("zeroized: valid_mask=0000", valid_mask,4'b0000);
        tb_expect_bit("zeroized: all_valid=0",all_valid, 1'b0);
        tb_expect_vec128("zeroized: key_in=0",key_in,128'h0);
        tb_expect_bit("zeroized: match_q=0", match_q, 1'b0);        
        tb_expect_bit("zeroized: do_compare=0", do_compare, 1'b0);        
        tb_expect_bit("zeroized: commit_illegal=0", commit_illegal, 1'b0);        
         
        $display("Test 6: Passed");

        $display("=== All Tests Passed ===");        
        $finish;
    end


    // Assertions
    
    // do_compare must be a 1 cyc pulse
    assert property(@(posedge clk) do_compare |-> ##1 !do_compare);
    
    // commit illegal must be a 1 cyc pulse
    assert property (@(posedge clk) commit_illegal |-> ##1 !commit_illegal);
    
    // illegal commit must never trigger compare
    assert property (@(posedge clk) commit_illegal |-> !do_compare);
    
    // if commit occurs while not all_valid, commit_illegal must assert
    assert property (@(posedge clk)
        (commit && !all_valid) |-> commit_illegal 
    );  

endmodule
