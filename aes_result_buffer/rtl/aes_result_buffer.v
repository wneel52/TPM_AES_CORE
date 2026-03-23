`timescale 1ns/1ps
module aes_result_buffer(
    // inputs
    input logic clk,
    input logic reset,
    input logic zeroize,
    input logic [127:0] result_in,
    input logic result_valid,
    input logic rd_en,
    input logic [1:0] rd_addr,
    // outputs
    output logic [31:0] rd_data,
    output logic rd_valid,
    output logic result_ready
);

    // read words (big end)
    logic [31:0] r0,r1,r2,r3;


    // sequential logic -> capture result / clear state
    always_ff @(posedge clk) begin
        if (reset || zeroize) begin
            r0 <= '0;
            r1 <= '0;
            r2 <= '0;
            r3 <= '0;            
            result_ready <= 1'b0;
        end
        else begin
            if (result_valid) begin
                r0 <= result_in[127:96];
                r1 <= result_in[95:64];
                r2 <= result_in[63:32];
                r3 <= result_in[31:0];
                result_ready <= 1'b1;  
            end
        end
    end

    // read mux (comb logic)
    always_comb begin
        rd_data = 32'h0000_0000;
        if (rd_en && result_ready) begin
            case (rd_addr)                
                2'd0: rd_data = r0;
                2'd1: rd_data = r1;
                2'd2: rd_data = r2;
                2'd3: rd_data = r3;
                default: rd_data = 32'h0000_0000;
            endcase
        end
    end

    assign rd_valid = rd_en && result_ready;

endmodule
