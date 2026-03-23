`timescale 1ns/1ps
module aes_input_block_buffer #(
    parameter int SIZE = 128
)(
    input logic clk,
    input logic reset,
    input logic zeroize,
    input logic wr_en,
    input logic [1:0] wr_addr,
    input logic [31:0] wr_data,
    output logic [SIZE-1:0] block_in,
    output logic [3:0] valid_mask,
    output logic all_valid
);

    // internal words
    logic [31:0] w0, w1, w2, w3;
    assign block_in = {w0,w1,w2,w3};
    assign all_valid = &valid_mask;

    always_ff @(posedge clk) begin
        if (reset || zeroize) begin
            w0 <= '0; w1 <= '0; w2 <= '0; w3 <= '0;
            valid_mask <= 4'b0000;    
        end
        else begin
            if (wr_en) begin
                unique case (wr_addr)
                    2'd0: begin w0 <= wr_data; valid_mask[0] <= 1'b1; end
                    2'd1: begin w1 <= wr_data; valid_mask[1] <= 1'b1; end
                    2'd2: begin w2 <= wr_data; valid_mask[2] <= 1'b1; end
                    2'd3: begin w3 <= wr_data; valid_mask[3] <= 1'b1; end
                    default:; // UNREACHABLE
                endcase
            end
        end
    end
endmodule
