`timescale 1ns/1ps
module tb_aes_input_block_buffer;
    localparam int unsigned SIZE = 128;

    // DUT inputs 
    logic clk;
    logic reset;
    logic zeroize;  
    logic wr_en;
    logic [1:0] wr_addr;
    logic [31:0] wr_data;

    // DUT outputs
    logic [SIZE-1:0] block_in;
    logic [3:0] valid_mask;
    logic all_valid;

    // init DUT
    aes_input_block_buffer #(.SIZE(SIZE)) dut (
        .clk(clk),
        .reset(reset),
        .zeroize(zeroize),
        .wr_en(wr_en),
        .wr_addr(wr_addr),
        .wr_data(wr_data),
        .block_in(block_in),
        .valid_mask(valid_mask),
        .all_valid(all_valid)
    );

    // clock
    initial begin
        clk = 1'b0;
        forever #5 clk = ~clk;
    end

    // helper tasks
    task automatic tb_expect_bit(string name, logic actual, logic expected);
        if (actual !== expected) begin
            $display("FAIL: %s at t=%0t actual=%b expected=%b", name, $time, actual, expected);
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

    task automatic tb_expect_vec128(string name, logic [127:0] actual, logic [127:0] expected);
        if (actual !== expected) begin
            $display("FAIL: %s at t=%0t actual=%h expected=%h", name, $time, actual, expected);
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
            wr_en = 1'b0;
            @(negedge clk);
            @(negedge clk);
            reset = 1'b0;
            @(posedge clk); #1;
        end
    endtask

    task automatic write_word(input logic [1:0] addr, input logic [31:0] data);
        begin
            @(negedge clk); 
            wr_addr = addr;
            wr_data = data;
            wr_en = 1'b1;
            @(negedge clk);
            wr_en = 1'b0;
        end
    endtask


    // test sequence
    initial begin
        $display("=== aes_input_block_buffer TB ===");
        reset = 1'b0;
        zeroize = 1'b0;
        wr_en = 1'b0;
        wr_data = 32'h0;
        $dumpfile("tb_aes_input_block_buffer.vcd");
        $dumpvars(0, tb_aes_input_block_buffer);
        $display("Test 1: reset clears buffer");
        do_reset();
        tb_expect_mask("reset: valid_mask=0000", valid_mask, 4'b0000);
        tb_expect_bit("reset: all_valid=0", all_valid, 1'b0);
        tb_expect_vec128("reset: block_in=0", block_in, 128'h0);        
        $display("Test 1: Pass");
    
        $display("Test 2: Partial Write");
        do_reset();
        
        write_word(2'd0, 32'hDEADBEEF);
        write_word(2'd1, 32'hCAFEBABE);
    
        @(posedge clk); #1;
        tb_expect_mask("partial write: valid_mask=0011", valid_mask, 4'b0011);
        tb_expect_bit("partial write: all_valid=0", all_valid, 1'b0);
        tb_expect_vec128("partial_write: block_in=DEADBEEF_CAFEBABE_00000000_00000000", block_in, 128'hDEADBEEF_CAFEBABE_00000000_00000000);

        $display("Test 2: Pass");

        $display("Test 3: Full Write");
        do_reset();
        write_word(2'd0, 32'h00112233);
        write_word(2'd1, 32'h44556677);
        write_word(2'd2, 32'h8899AABB);
        write_word(2'd3, 32'hCCDDEEFF);
        @(posedge clk); #1;
        tb_expect_mask("full write: valid_mask=1111", valid_mask, 4'b1111);
        tb_expect_bit("full write: all_valid", all_valid, 1'b1);
        tb_expect_vec128("full write: block_in fully written", block_in, 128'h00112233_44556677_8899AABB_CCDDEEFF);
        $display("Test 3: Pass");
        
        $display("Test 4: overwrite behavior");
        do_reset();
        
        // orig write 
        
        write_word(2'd0, 32'hDEADBEEF);
        write_word(2'd1, 32'hCAFEBABE);

        @(posedge clk); #1;
        tb_expect_mask("partial write: valid_mask=0011", valid_mask, 4'b0011);
        tb_expect_bit("partial write: all_valid=0", all_valid, 1'b0);
        tb_expect_vec128("partial_write: block_in=DEADBEEF_CAFEBABE_00000000_00000000", block_in, 128'hDEADBEEF_CAFEBABE_00000000_00000000);

        //@(posedge clk); #1;
        // overwrite
        write_word(2'd0, 32'h11223344);
        write_word(2'd1, 32'hCAFEBABE);

        @(posedge clk); #1;
        tb_expect_mask("partial write: valid_mask=0011", valid_mask, 4'b0011);
        tb_expect_bit("partial write: all_valid=0", all_valid, 1'b0);
        tb_expect_vec128("partial_write: block_in=11223344_CAFEBABE_00000000_00000000", block_in, 128'h11223344_CAFEBABE_00000000_00000000);        
        $display("Test 4: Pass");


        $display("Test 5: zeroize");
        do_reset();
        write_word(2'd0, 32'h00112233);
        write_word(2'd1, 32'h44556677);
        write_word(2'd2, 32'h8899AABB);
        write_word(2'd3, 32'hCCDDEEFF);
        @(posedge clk); #1;
        tb_expect_mask("before zeroize: valid_mask=1111", valid_mask, 4'b1111);
        tb_expect_bit("before zeroize: all_valid", all_valid, 1'b1);
        tb_expect_vec128("before zeroize: block_in fully written", block_in, 128'h11223344_55667788_99AABBCC_DDEEFF);
        @(negedge clk);
        zeroize = 1'b1;
        @(negedge clk);
        zeroize = 1'b0;
        @(posedge clk); #1;
        tb_expect_mask("after zeroize: valid_mask=0000", valid_mask, 4'b0000);       
        tb_expect_bit("after zeroize: all_valid=0", all_valid, 1'b0);
        tb_expect_vec128("after zeroize: block_in=0", block_in, 128'd0);
        $display("Test 5: Pass");

        $display("=== All tests passed ===");
        $finish;
    end

endmodule
