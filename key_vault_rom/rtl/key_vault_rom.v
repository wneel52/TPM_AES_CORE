/*
128 bit Key Vault with 32 bit reads
- Always diven outputs (low when disabled)
- Latched Tamper
- Read-once lockout
*/
`timescale 1ns/1ps
module key_vault_rom(
    input wire clk,
    input wire rst_n,
    input wire chip_en, // vault enable
    input wire read_en, // read enable
    input wire zeroize, // force vault low if we suspect tamper
    input wire [1:0] word_idx, // selects 1 of 4 keywords
    output reg [31:0] data_out, // always diven
    output wire      oe, // output enable
    output reg tamper_latched,
    output reg read_once_latched
);

    
    // For now hard coded AES key -> big endian
    localparam [31:0] KEY_W0 = 32'h00112233;
    localparam [31:0] KEY_W1 = 32'h44556677;
    localparam [31:0] KEY_W2 = 32'h8899AABB;
    localparam [31:0] KEY_W3 = 32'hCCDDEEFF;
    
    // read counter and edge dect
    reg [1:0] read_count;
    reg oe_d; // delayed oe
    reg lock_pending;
    wire read_pulse;

    assign oe = chip_en && read_en && !tamper_latched && !read_once_latched; // OE defn
    assign read_pulse = oe & ~oe_d; 

    // tamper and read-once latch -> added read counter
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            tamper_latched <= 1'b0;
            read_once_latched <= 1'b0;
            read_count <= 2'd0;
            oe_d <= 1'b0;
            lock_pending <= 1'b0;
        end
        else begin
            // edge dection via delayed oe
            oe_d <= oe;
            if (lock_pending && (oe_d == 1'b1) && (oe == 1'b0)) begin
                read_once_latched <= 1'b1;
                lock_pending      <= 1'b0;
            end
            // tamper lock
            if (zeroize) begin
                tamper_latched <= 1'b1;
                read_once_latched <= 1'b1; // close read latch 
                lock_pending <= 1'b0;
            end
            // count successful reads
            if (read_pulse) begin
                if (read_count != 2'd3) begin 
                    read_count <= read_count + 2'd1;
                end
                else begin
                    lock_pending <= 1'b1;
                end    
            end
            if ((read_count == 2'd3) && (oe_d == 1'b1) && (oe == 1'b0) && (read_pulse == 1'b0)) begin
                $display("im really bored");
            end
        end
    end


    always @* begin
        data_out = 32'h0000_0000;
        if (oe) begin
            case(word_idx)
                2'd0 : data_out = KEY_W0;
                2'd1 : data_out = KEY_W1;
                2'd2 : data_out = KEY_W2;
                2'd3 : data_out = KEY_W3;
                default : data_out = 32'hXXXX_XXXX; // illegal access
            endcase
        end
    end
endmodule
