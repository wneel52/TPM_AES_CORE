`timescale 1ns/1ps

module tpm_aes_top (
    input clk,
    input reset,
    input zeroize,

    // Key write path
    input key_wr_en,
    input [1:0] key_wr_addr,
    input [31:0] key_wr_data,
    input commit,

    input [127:0] key_hw,

    // AES input path
    input blk_wr_en,
    input [1:0] blk_wr_addr,
    input [31:0] blk_wr_data,

    input aes_start,

    // Read path
    input rd_en,
    input [1:0] rd_addr,
    output [31:0] rd_data,
    output rd_valid,

    // Status
    output unlocked,
    output trap,
    output aes_enable,
    output result_ready
);

    // =====================================
    // Internal signals
    // =====================================

    wire rst_n;
    assign rst_n = ~reset;

    // Key path
    wire [127:0] attempted_key_in;
    wire [3:0] key_valid_mask;
    wire key_all_valid;
    wire match_q;
    wire commit_illegal;
    wire do_compare;

    // AES input
    wire [127:0] block_in;
    wire [3:0] block_valid_mask;
    wire block_all_valid;

    // AES core
    wire [255:0] aes_key_bus;
    wire aes_keylen;
    wire [127:0] aes_result;
    wire aes_ready;
    wire aes_result_valid;

    reg aes_init;
    reg aes_next;

    assign aes_key_bus = {128'h0, key_hw};
    assign aes_keylen  = 1'b0;

    // =====================================
    // Key Commit Buffer
    // =====================================

    key_commit_buffer u_key_commit_buffer (
        .clk(clk),
        .reset(reset),
        .zeroize(zeroize),
        .wr_en(key_wr_en),
        .wr_addr(key_wr_addr),
        .wr_data(key_wr_data),
        .commit(commit),
        .key_hw(key_hw),
        .key_in(attempted_key_in),
        .valid_mask(key_valid_mask),
        .all_valid(key_all_valid),
        .do_compare(do_compare),
        .match_q(match_q),
        .commit_illegal(commit_illegal)
    );

    // =====================================
    // Unlock FSM
    // =====================================

    unlock_fsm u_unlock_fsm (
        .clk(clk),
        .reset(reset),
        .zeroize(zeroize),
        .commit(commit),
        .all_valid(key_all_valid),
        .match_q(match_q),
        .commit_illegal(commit_illegal),
        .aes_enable(aes_enable),
        .trap(trap),
        .unlocked(unlocked)
    );

    // =====================================
    // AES Input Buffer
    // =====================================

    aes_input_block_buffer u_aes_input_block_buffer (
        .clk(clk),
        .reset(reset),
        .zeroize(zeroize),
        .wr_en(blk_wr_en),
        .wr_addr(blk_wr_addr),
        .wr_data(blk_wr_data),
        .block_in(block_in),
        .valid_mask(block_valid_mask),
        .all_valid(block_all_valid)
    );

    // =====================================
    // AES control FSM (Verilog version)
    // =====================================

    reg [1:0] aes_ctrl_state;

    parameter AES_NEED_INIT = 2'd0;
    parameter AES_WAIT_INIT = 2'd1;
    parameter AES_READY     = 2'd2;

    always @(posedge clk) begin
        if (reset || zeroize || trap || !unlocked) begin
            aes_ctrl_state <= AES_NEED_INIT;
        end else begin
            case (aes_ctrl_state)
                AES_NEED_INIT: begin
                    if (aes_ready)
                        aes_ctrl_state <= AES_WAIT_INIT;
                end

                AES_WAIT_INIT: begin
                    if (aes_ready)
                        aes_ctrl_state <= AES_READY;
                end

                AES_READY: begin
                    aes_ctrl_state <= AES_READY;
                end
            endcase
        end
    end

    // Control signals
    always @(*) begin
        aes_init = 0;
        aes_next = 0;

        if (aes_ctrl_state == AES_NEED_INIT && unlocked && aes_ready && !trap)
            aes_init = 1;

        if (aes_ctrl_state == AES_READY &&
            aes_start &&
            aes_enable &&
            block_all_valid &&
            aes_ready &&
            !trap)
            aes_next = 1;
    end

    // =====================================
    // AES Core
    // =====================================

    aes_core u_aes_core (
        .clk(clk),
        .reset_n(rst_n),
        .encdec(1'b1),
        .init(aes_init),
        .next(aes_next),
        .ready(aes_ready),
        .key(aes_key_bus),
        .keylen(aes_keylen),
        .block(block_in),
        .result(aes_result),
        .result_valid(aes_result_valid)
    );

    // =====================================
    // AES Result Buffer
    // =====================================

    aes_result_buffer u_aes_result_buffer (
        .clk(clk),
        .reset(reset),
        .zeroize(zeroize),
        .result_in(aes_result),
        .result_valid(aes_result_valid),
        .rd_en(rd_en),
        .rd_addr(rd_addr),
        .rd_data(rd_data),
        .rd_valid(rd_valid),
        .result_ready(result_ready)
    );

endmodule
