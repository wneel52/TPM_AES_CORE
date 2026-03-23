`timescale 1ns/1ps

module key_commit_buffer #(
    parameter int SIZE = 128
)(
    input  logic             clk,
    input  logic             reset,
    input  logic             zeroize,       // wipes buffer + status

    // 32-bit write interface
    input  logic             wr_en,
    input  logic [1:0]       wr_addr,
    input  logic [31:0]      wr_data,

    // commit pulse
    input  logic             commit,

    // hardware key to compare against
    input  logic [SIZE-1:0]  key_hw,

    // outputs
    output logic [SIZE-1:0]  key_in,         // assembled key
    output logic [3:0]       valid_mask,     // which words have been written
    output logic             all_valid,
    output logic             do_compare,     // 1-cycle pulse when compare performed
    output logic             match_q,        // latched compare result
    output logic             commit_illegal
);

    // internal words
    logic [31:0] w0, w1, w2, w3;

    // comparator output
    logic match;

    // big-endian assembly (w0 is MSW)
    assign key_in = {w0,w1,w2,w3};

    assign all_valid = &valid_mask;

    // comparator
    key_activation_compare #(.SIZE(SIZE)) u_cmp (
        .key_in(key_in),
        .key_hw(key_hw),
        .match(match)
    );

    // sequential logic
    always_ff @(posedge clk) begin
        if (reset || zeroize) begin
            w0 <= '0; w1 <= '0; w2 <= '0; w3 <= '0;
            valid_mask     <= 4'b0000;
            do_compare     <= 1'b0;
            match_q        <= 1'b0;
            commit_illegal <= 1'b0;
        end else begin
            // defaults
            do_compare     <= 1'b0;
            commit_illegal <= 1'b0;

            // writes
            if (wr_en && !commit) begin
                unique case (wr_addr)
                    2'd0: begin w0 <= wr_data; valid_mask[0] <= 1'b1; end
                    2'd1: begin w1 <= wr_data; valid_mask[1] <= 1'b1; end
                    2'd2: begin w2 <= wr_data; valid_mask[2] <= 1'b1; end
                    2'd3: begin w3 <= wr_data; valid_mask[3] <= 1'b1; end
                    default: /* unreachable */ ;
                endcase
            end

            // commit: compare only if all 4 words are valid
            if (commit) begin
                if (all_valid) begin
                    do_compare <= 1'b1;
                    match_q    <= match;
                end else begin
                    commit_illegal <= 1'b1;
                    match_q        <= 1'b0; // fail-closed
                end
            end
        end
    end

endmodule
