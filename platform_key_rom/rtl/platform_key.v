`timescale 1ns/1ps
module platform_key_rom(
    input wire chip_en,
    input wire read_en,
    input wire [1:0] key_sel, // select key
    input [1:0] word_idx, // select work in key
    output reg [31:0] data_out,
    output wire oe
);
    // Platform Key 0
    localparam [31:0] PK0_W0 = 32'h00112233;
    localparam [31:0] PK0_W1 = 32'h44556677;
    localparam [31:0] PK0_W2 = 32'h8899AABB;
    localparam [31:0] PK0_W3 = 32'hCCDDEEFF;

    // Platform Key 1
    localparam [31:0] PK1_W0 = 32'h11111111;
    localparam [31:0] PK1_W1 = 32'h22222222;
    localparam [31:0] PK1_W2 = 32'h33333333;
    localparam [31:0] PK1_W3 = 32'h44444444;

    // Platform Key 2
    localparam [31:0] PK2_W0 = 32'hAAAABBBB;
    localparam [31:0] PK2_W1 = 32'hCCCCDDDD;
    localparam [31:0] PK2_W2 = 32'hEEEEFFFF;
    localparam [31:0] PK2_W3 = 32'h12345678;


    assign oe = chip_en && read_en;

    always_comb begin
        data_out = 32'h0000_0000;
        if (oe) begin
            case (key_sel)
                2'd0: begin
                    case (word_idx)
                        2'd0: data_out = PK0_W0;
                        2'd1: data_out = PK0_W1;
                        2'd2: data_out = PK0_W2;
                        2'd3: data_out = PK0_W3;
                        default: data_out = 32'h0000_0000;
                    endcase
                end
                2'd1: begin
                    case (word_idx)
                        2'd0: data_out = PK1_W0;
                        2'd1: data_out = PK1_W1;
                        2'd2: data_out = PK1_W2;
                        2'd3: data_out = PK1_W3;
                        default: data_out = 32'h0000_0000;
                    endcase
                end
                2'd2: begin
                    case (word_idx)
                        2'd0: data_out = PK2_W0;
                        2'd1: data_out = PK2_W1;
                        2'd2: data_out = PK2_W2;
                        2'd3: data_out = PK2_W3;
                        default: data_out = 32'h0000_0000;
                    endcase
                end
                default: data_out = 32'h0000_0000;
            endcase
        end
    end

endmodule
