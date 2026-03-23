`timescale 1ns/1ps
module tb_aes_result_buffer;
    // DUT inputs
    logic clk;
    logic reset;
    logic zeroize;
    logic [127:0] result_in;
    logic result_valid;
    logic rd_en;
    logic [1:0] rd_addr;

    // DUT outputs
    logic [31:0] rd_data;
    logic rd_valid;
    logic result_ready;
    
    // DUT
    aes_result_buffer dut (
        .clk(clk),
        .reset(reset),
        .zeroize(zeroize),
        .result_in(result_in),
        .result_valid(result_valid),
        .rd_en(rd_en),
        .rd_addr(rd_addr),
        .rd_data(rd_data),
        .rd_valid(rd_valid),
        .result_ready(result_ready)
    );

    initial begin
        clk = 1'b0;
        forever #5 clk = ~clk;
    end

    task automatic tb_expect_bit(string name, logic actual, logic expected);
        if (actual !== expected) begin
            $display("FAIL: %s at t=%0t actual=%b expected=%b", name, $time, actual, expected);
            $finish;
        end
        else begin
            $display("PASS: %s at t=%0t", name, $time);
        end
    endtask

    task automatic tb_expect_32(string name, logic [31:0] actual, logic [31:0] expected);
        if (actual !== expected) begin
            $display("FAIL: %s at t=%0t actual=%h expected=%h",name, $time, actual, expected);
            $finish;
        end
        else begin
            $display("PASS: %s at t=%0t", name, $time);
        end
    endtask

    task automatic tb_expect_mask(string name, logic [3:0] actual, logic [3:0] expected);
        if (actual !== expected) begin
            $display("FAIL: %s at t=%0t actual=%b expected=%b", name, $time, actual, expected);
            $finish;
        end
        else begin
            $display("PASS: %s at t=%0t", name, $time);
        end
    endtask

    task automatic do_reset();
        begin
            @(negedge clk);
            reset = 1'b1; 
            zeroize = 1'b0;
            result_valid = 1'b0;
            rd_en = 1'b0;
            @(negedge clk);
            @(negedge clk);
            reset = 1'b0;
            @(posedge clk); #1;
        end
    endtask

    initial begin
        $display("=== aes_result_buffer TB ===");
        // initial conds
        reset = 1'b0;
        zeroize = 1'b0;
        result_in = 128'h0;
        result_valid = 1'b0;
        rd_en = 1'b0;
        rd_addr = 2'd0;
        
        // dumps
        $dumpfile("tb_aes_result_buffer.vcd");
        $dumpvars(0, tb_aes_result_buffer);
        
        // Test 1: reset
        $display("Test 1: Reset");
        do_reset();
        tb_expect_bit("reset: result_ready=0", result_ready, 1'b0);
        tb_expect_bit("reset: rd_valid=0", rd_valid, 1'b0);
        tb_expect_32("reset: rd_data=0", rd_data, 32'h0000_0000);
        $display("Test 1: Pass");

        // Test 2: capture result
        $display("Test 2: Capture Result");
        @(negedge clk);
        result_in = 128'h00112233_44556677_8899AABB_CCDDEEFF;
        result_valid = 1'b1;
        @(posedge clk); #1;
        tb_expect_bit("capture result: result_valid=1", result_valid, 1'b1);
        tb_expect_bit("capture result: rd_valid=0 -> rd_en still 0", rd_valid, 1'b0);
        @(negedge clk);
        result_valid = 1'b0;
        $display("Test 2 Complete");                

        $display("Test 3: Test Read Mux");
        @(negedge clk);
        rd_en = 1'b1;
        rd_addr = 2'd0;
        @(posedge clk); #1;
        tb_expect_bit("Read mux: rd_valid=1", rd_valid, 1'b1);
        tb_expect_32("Read mux: rd_data = (r0=00112233)", rd_data,32'h00112233);

        @(negedge clk);
        rd_addr = 2'd1;
        @(posedge clk);
        tb_expect_bit("Read mux: rd_valid=1", rd_valid, 1'b1);
        tb_expect_32("Read mux: rd_data = (r1=44556677)", rd_data,32'h44556677);
        
        @(negedge clk); rd_addr = 2'd2; @(posedge clk); 
        tb_expect_bit("Read mux: rd_valid=1", rd_valid, 1'b1); 
        tb_expect_32("Read mux: rd_data = (r2=8899AABB)", rd_data, 32'h8899AABB);

        @(negedge clk); 
        rd_addr = 2'd3; 
        @(posedge clk);
        tb_expect_bit("Read mux: rd_valid=1", rd_valid, 1'b1); 
        tb_expect_32("Read mux: rd_data = (r3=CCDDEEFF)", rd_data, 32'hCCDDEEFF);

        $display("Test 3: Complete");
        // Test 4: zeroize clears stored result
        $display("Test 4: Zeroize clears result buffer");

        // capture result again
        do_reset();

        @(negedge clk);
        result_in = 128'h00112233_44556677_8899AABB_CCDDEEFF;
        result_valid = 1'b1;

        @(posedge clk); #1;
        tb_expect_bit("zeroize-pre: result_ready=1", result_ready, 1'b1);

        @(negedge clk);
        result_valid = 1'b0;
        zeroize = 1'b1;

        @(posedge clk); #1;
        tb_expect_bit("zeroize: result_ready=0", result_ready, 1'b0);
        tb_expect_bit("zeroize: rd_valid=0", rd_valid, 1'b0);
        tb_expect_32("zeroize: rd_data=0", rd_data, 32'h0000_0000);
        
        rd_addr = 2'd0;
        @(negedge clk);
        tb_expect_32("zeroize: r0 rd_data=0", rd_data, 32'h0000_0000);

        rd_addr = 2'd1;
        @(negedge clk);
        tb_expect_32("zeroize: r1 rd_data=0", rd_data, 32'h0000_0000);

        rd_addr = 2'd2;        
        @(negedge clk);        
        tb_expect_32("zeroize: r2 rd_data=0", rd_data, 32'h0000_0000);
        
        rd_addr = 2'd3;
        @(negedge clk);
        tb_expect_32("zeroize: r3 rd_data=0", rd_data, 32'h0000_0000);

        @(negedge clk);
        zeroize = 1'b0;

        $display("Test 4: Pass");

        $display("=== All Tests Complete ==="); $finish;
    end   

endmodule
