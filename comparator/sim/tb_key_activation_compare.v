`timescale 1ns/1ps

module tb_key_activation_compare;
    
    localparam int unsigned SIZE = 128;
    logic [SIZE-1:0] key_in;
    logic [SIZE-1:0] key_hw;
    logic match;

    // init DUT
    key_activation_compare #(.SIZE(SIZE)) dut (
        .key_in(key_in),
        .key_hw(key_hw),
        .match(match)
    );

    // "Reference Model"
    function automatic logic ref_match(input logic [SIZE-1:0] a, input logic [SIZE-1:0] b);
        ref_match = (a == b); // SV will return logic high if a==b
    endfunction

    // Task to check in a single step
    task automatic check(string name);
        logic exp;
        exp = ref_match(key_in, key_hw);
        #0; //short delay
        if (match !== exp) begin
            $fatal(1, "[%0t] %s FAILED: key_in=%h key_hw=%h match=%b exp=%0b",
                                        $time,name,key_in,key_hw,match,exp); // end sim if we hit this cond
        end 
        else begin
            $display("[%0t] %s PASS : match=%b", $time, name, match);
        end
     endtask


    // Test 
    initial begin
        $display("=== begin testbench sequence ===");
    
        // 1) Equal keys we expect a 1 out
        key_hw = 128'hDEADBEEF_F00DFACE_01234567_89ABCDEF;
        key_in = key_hw;
        check("equal_keys");

        // 2) single bit mismatch
        key_in = key_hw ^(128'h1 << 7); // shift 1 bit
        check("one_bit_mismatch");
     
        // 3 All zereos -> expect match
        key_in = '0;
        key_hw = '0; 
        check("all_zeros_equal");        

        // 4) Zeros vs Ones mismatch
        key_in = '1;
        key_hw = '0;
        check("zero_vs_one");

        // 5) Random tests
        for (int i = 0; i < 200; i++) begin
            key_hw = {$urandom, $urandom, $urandom, $urandom}; // 128 bits
            // 50/50 chance of match
            if ($urandom_range(0,1)) key_in = key_hw;
            
            else key_in = {$urandom, $urandom, $urandom, $urandom};

            check($sformatf("random_%0d", i));
        end

    $display("=== ALL TESTS PASSED ===");
    $finish;

    end

endmodule
