`timescale 1ns/1ps

module tb_unlock_fsm;

    // DUT inputs
    logic clk;
    logic reset;
    logic zeroize;
    logic commit;
    logic all_valid;
    logic match_q;
    logic commit_illegal;
    
    // DUT outputs 
    logic aes_enable;
    logic trap;
    logic unlocked;
    logic [1:0] state_debug;

    // state encodings
    localparam logic [1:0] LOCKED = 2'd0;
    localparam logic [1:0] CHECK = 2'd1;
    localparam logic [1:0] UNLOCKED = 2'd2;
    localparam logic [1:0] TRAPPED = 2'd3;

    // DUT 
    unlock_fsm dut (
        .clk(clk),
        .reset(reset),
        .zeroize(zeroize),
        .commit(commit),
        .all_valid(all_valid),
        .match_q(match_q),
        .commit_illegal(commit_illegal),
        .aes_enable(aes_enable),
        .trap(trap),
        .unlocked(unlocked),
        .state_debug(state_debug)        
    );

    // clock
    initial begin
        clk = 1'b0;
        forever #5 clk = ~clk;        
    end

    // helpers
    
    // check bit
    task automatic tb_expect_bit(string name, logic actual, logic expected);
        begin
            if(actual !== expected) begin
                $display("FAIL: %s at %0t actual=%b expected=%b", name, $time, actual, expected);
                $finish;
            end
            else begin
                $display("PASS: %s at t=%0t", name, $time);
            end
        end
    endtask

    // check state
    task automatic tb_expect_state(string name, logic [1:0] actual, logic [1:0] expected);
        begin
            if (actual !== expected) begin
                $display("FAIL: %s at %0t actual=%0d expected=%0d", name, $time, actual, expected);
                $finish;
            end
            else begin
                $display("PASS: %s at t=%0t", name, $time);
            end
        end
    endtask    

    // reset circuit
    task automatic do_reset();
        begin
            @(negedge clk);
            reset = 1'b1;
            zeroize = 1'b0;
            commit = 1'b0;
            all_valid = 1'b0;
            match_q = 1'b0;
            commit_illegal = 1'b0;
            @(negedge clk);
            @(negedge clk);
            reset = 1'b0;
            @(posedge clk); #1;
        end
    endtask

    // monitor
    initial begin
        $display("time clk rst zero com valid match ill | aes_en trap unlock state");
        $monitor("%4t  %0b   %0b   %0b   %0b   %0b   %0b   %0b |  %0b    %0b    %0b    %0d",
                 $time, clk, reset, zeroize, commit, all_valid, match_q, commit_illegal,
                 aes_enable, trap, unlocked, state_debug);
    end


    // test sequence
    initial begin
        $display("=== Unlock FSM  Test Sequence ==="); 
        // initial values
        reset = 1'b0;
        zeroize = 1'b0;
        commit = 1'b0;
        all_valid = 1'b0;
        match_q = 1'b0;
        commit_illegal = 1'b0;
        // dump waves and vars
        $dumpfile("tb_unlock_fsm.vcd");
        $dumpvars(0, tb_unlock_fsm);

        // Test 1: reset -> locked
        $display("Test 1: Reset locks circuit");
        do_reset(); // call handler
        tb_expect_state("reset: state=LOCKED", state_debug, LOCKED);
        tb_expect_bit("reset: aes_enable=0", aes_enable, 1'b0);
        tb_expect_bit("reset: trap=0", trap, 1'b0);
        tb_expect_bit("reset: unlocked=0", unlocked, 1'b0);
        $display("Test 1: Pass");

        // Test 2: Locked + commit_illegal = trap
        $display("Test 2: commit_illegal when locked triggers trap");    
        do_reset();
        commit_illegal = 1'b1;
        @(posedge clk); #1;
        tb_expect_state("illegal commit: state = TRAPPED", state_debug, TRAPPED);
        tb_expect_bit("illegal commit: trap=1", trap, 1'b1);
        tb_expect_bit("illegal commit: aes_enable=0", aes_enable, 1'b0);
        @(negedge clk);
        commit_illegal = 1'b0;
        $display("Test 2: Pass");

        // Test 3: valid commit
        $display("Test 3: Valid commit then match unlocks");
        do_reset();
        
        // drive valid commit
        @(negedge clk);
        commit = 1'b1;
        all_valid = 1'b1;
        @(posedge clk); #1;
        tb_expect_state("valid: state=CHECK", state_debug, CHECK);
        tb_expect_bit("valid: aes_enable=0 -> check not done", aes_enable, 1'b0);

        // remove commit -> provide successful result
        @(negedge clk);
        commit = 1'b0;
        all_valid = 1'b0;
        match_q = 1'b1;  
        @(posedge clk); #1;
        tb_expect_state("match: expect UNLOCKED", state_debug, UNLOCKED);
        tb_expect_bit("match: aes_enable=1", aes_enable, 1'b1);
        tb_expect_bit("match: unlocked=1", unlocked, 1'b1);
        tb_expect_bit("match: trap=0", trap, 1'b0);
        $display("Test 3: Pass");


        // Test 4: Unlocked + zeroize = Trapped
        $display("Test 4: zeroize while unlocked enters trap");
        @(negedge clk);
        zeroize = 1'b1;
        @(posedge clk); #1;
        tb_expect_state("zeroize: state=TRAPPED", state_debug, TRAPPED);
        tb_expect_bit("zeroize: trap=1", trap, 1'b1);
        tb_expect_bit("zeroize: aes_enable=0", aes_enable, 1'b0);
    
        @(negedge clk);
        zeroize = 1'b0;
        match_q = 1'b0;
        $display("Test 4: Pass");

        // Test 5: Check + mismatch = trap
        $display("Test 5: Mismatched key traps circuit");
        do_reset();
        
        @(negedge clk);
        commit = 1'b1;
        all_valid = 1'b1;
        @(posedge clk); #1;
        tb_expect_state("mismatch: state=CHECK", state_debug, CHECK);
        
        @(negedge clk);
        commit = 1'b0;
        all_valid = 1'b0;
        match_q = 1'b0;
        @(posedge clk); #1;
        tb_expect_state("mismatch: state=trapped", state_debug, TRAPPED);        
        tb_expect_bit("mismatch: trap=1", trap, 1'b1);
        $display("Test 5: Pass");

        // Test 6: trapped should be sticky
        $display("Test 6: Trapped state should be sticky");
        @(negedge clk);
        commit = 1'b1;
        all_valid = 1'b1;
        match_q = 1'b1;
        commit_illegal = 1'b0;
        zeroize = 1'b0;
        @(posedge clk); #1;
        tb_expect_state("trapped stick: still trapped after a cycle", state_debug, TRAPPED);
        tb_expect_bit("trapped stick: trap=1", trap, 1'b1);
        tb_expect_bit("trapped stick: aes_enable", aes_enable, 1'b0);
        @(posedge clk); #100;   
        @(posedge clk); #100;   
        @(posedge clk); #100;   
        tb_expect_state("trapped stick: still trapped after many cycles", state_debug, TRAPPED);


        $display("Test 6: Pass");
        $display("=== All Tests Passed ===");
        $finish;
    end 

endmodule
