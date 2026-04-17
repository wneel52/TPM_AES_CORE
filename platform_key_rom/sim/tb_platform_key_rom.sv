`timescale 1ns/1ps

module tb_platform_key_rom;

    // DUT inputs
    logic chip_en;
    logic read_en;
    logic [1:0] key_sel;
    logic [1:0] word_idx;
    // DUT outputs
    logic [31:0] data_out;
    logic oe;

    logic [31:0] expected[0:2][0:3];

    // init DUT
    platform_key_rom dut(
        .chip_en(chip_en),
        .read_en(read_en),
        .key_sel(key_sel),
        .word_idx(word_idx),
        .data_out(data_out),
        .oe(oe)
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

    task automatic check_word(
        input logic [1:0] key,
        input logic [1:0] idx,
        input [31:0] exp_data
    );
        begin
            chip_en = 1'b1;
            read_en = 1'b1;
            key_sel = key;
            word_idx = idx;

            #1; // settle
            tb_expect("oe high", oe, 1'b1);
            tb_expect32("data valid", data_out, exp_data);
        end
    endtask

    task automatic check_disabled(
        input logic chip,
        input logic read
    );
        begin
            chip_en = chip;
            read_en = read;
            key_sel = 2'd0;
            word_idx = 2'd0;
            #1;
            tb_expect("oe disabled",oe, chip&&read);
            if (!(chip && read)) begin
                tb_expect32("data zeroed", data_out, 32'h00000000);
            end
        end
    endtask

    // test seq
    initial begin

        // expected key table

        // K1
        expected[0][0] = 32'h00112233;
        expected[0][1] = 32'h44556677;
        expected[0][2] = 32'h8899AABB;
        expected[0][3] = 32'hCCDDEEFF;
        // K2
        expected[1][0] = 32'h11111111;
        expected[1][1] = 32'h22222222;
        expected[1][2] = 32'h33333333;
        expected[1][3] = 32'h44444444;
        // K2
        expected[2][0] = 32'hAAAABBBB;
        expected[2][1] = 32'hCCCCDDDD;
        expected[2][2] = 32'hEEEEFFFF;
        expected[2][3] = 32'h12345678;

        // default values
        chip_en = 1'b0;
        read_en = 1'b0;
        key_sel = 2'd0;
        word_idx = 2'd0;

        // check if init state is disabled
        // checks three states (chip_en,read_en) (0,0) : (1,0) : (0,1)
        check_disabled(1'b0 ,1'b0);
        check_disabled(1'b1 ,1'b0);
        check_disabled(1'b0 ,1'b1);

        // iter over for loop to check all keys
        for (int k = 0; k < 3; k++) begin
            for (int w = 0; w < 4; w++) begin
                check_word(k[1:0],w[1:0], expected[k][w]); // k[2bit] w[2bit]
            end
        end

        // invalid key_sel = 3 should retrun 0 with oe high
        chip_en = 1'b1;
        read_en = 1'b1;
        key_sel = 2'd3;
        word_idx = 2'd0;
        #1; // tiny delay
        // check word 0
        tb_expect("oe high for invalid key_sel", oe, 1'b1);
        tb_expect32("data zero for invalid key_sel word0", data_out, 32'h00000000);
        // check word 1
        word_idx = 2'd1; #1;
        tb_expect("oe high for invlaid key_sel", oe, 1'b1);
        tb_expect32("data zero for invalid key_sel word1", data_out, 32'h00000000);
        // check word 2
        word_idx = 2'd2; #1;
        tb_expect("oe high for invlaid key_sel", oe, 1'b1);
        tb_expect32("data zero for invalid key_sel word2", data_out, 32'h00000000);
        // check word 3
        word_idx= 2'd3; #1;
        tb_expect("oe high for invlaid key_sel", oe, 1'b1);
        tb_expect32("data zero for invalid key_sel word3", data_out, 32'h00000000);

        $display("PASS: platform_key_rom tb passed");
        $finish;

    end

  initial begin
    $monitor("t=%0t chip_en=%0b read_en=%0b key_sel=%0d word_idx=%0d | oe=%0b data_out=0x%08h",
             $time, chip_en, read_en, key_sel, word_idx, oe, data_out);
  end

endmodule
