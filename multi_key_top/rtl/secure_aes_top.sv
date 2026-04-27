`timescale 1ns/1ps
module secure_aes_top #(
    parameter int KEY_W = 128,

    // AES-128 operational key.
    // This is separate from the platform unlock keys stored inside
    parameter logic [127:0] AES_KEY = 128'h00112233_44556677_8899AABB_CCDDEEFF
)(
    input  logic clk,
    input  logic reset,

    // External security controls
    input  logic zeroize,
    input  logic tamper_in,

    // Authentication key write path.
    // CPU/host writes KEY_W bits using 32-bit chunks, then pulses commit.
    input  logic        key_wr_en,
    input  logic [2:0]  key_wr_addr,
    input  logic [31:0] key_wr_data,
    input  logic        commit,

    // AES input block write path.
    input  logic        blk_wr_en,
    input  logic [1:0]  blk_wr_addr,
    input  logic [31:0] blk_wr_data,

    input  logic aes_start,

    // AES result read path.
    input  logic        rd_en,
    input  logic [1:0]  rd_addr,
    output logic [31:0] rd_data,
    output logic        rd_valid,

    // Status
    output logic unlocked,
    output logic trap,
    output logic aes_enable,
    output logic auth_zeroize,
    output logic tamper_latched,
    output logic result_ready,
    output logic [1:0] key_sel,
    output logic [1:0] state_debug
);

    logic rst_n;
    assign rst_n = ~reset;

    logic security_clear;
    assign security_clear = reset | zeroize | auth_zeroize | tamper_latched;

    // Maintain old "trap" style status name for report/testbench compatibility.
    assign trap = tamper_latched | auth_zeroize;

    localparam int KEY_WORDS = (KEY_W + 31) / 32;

    logic [KEY_W-1:0] auth_key_in;
    logic [KEY_WORDS-1:0] key_valid_mask;
    logic key_all_valid;

    logic do_compare;
    logic commit_illegal;

    integer i;

    always_ff @(posedge clk or posedge reset) begin
        if (reset) begin
            auth_key_in      <= '0;
            key_valid_mask   <= '0;
            do_compare       <= 1'b0;
            commit_illegal   <= 1'b0;
        end
        else begin
            do_compare     <= 1'b0;
            commit_illegal <= 1'b0;

            if (zeroize || auth_zeroize || tamper_latched) begin
                auth_key_in    <= '0;
                key_valid_mask <= '0;
            end
            else begin
                if (key_wr_en) begin
                    if (key_wr_addr < KEY_WORDS[2:0]) begin
                        for (i = 0; i < 32; i = i + 1) begin
                            if ((key_wr_addr * 32 + i) < KEY_W) begin
                                auth_key_in[key_wr_addr * 32 + i] <= key_wr_data[i];
                            end
                        end
                        key_valid_mask[key_wr_addr] <= 1'b1;
                    end
                    else begin
                        commit_illegal <= 1'b1;
                    end
                end

                if (commit) begin
                    if (key_all_valid) begin
                        do_compare <= 1'b1;
                    end
                    else begin
                        commit_illegal <= 1'b1;
                    end

                    // Require each platform key entry to be freshly written.
                    // This prevents stale chunks from accidentally carrying
                    // forward between unlock stages.
                    key_valid_mask <= '0;
                end
            end
        end
    end

    assign key_all_valid = &key_valid_mask;

    // 3-stage platform authentication controller

    auth_controller_top #(
        .KEY_W(KEY_W)
    ) u_auth_controller_top (
        .clk(clk),
        .reset(reset),
        .zeroize_in(zeroize),
        .tamper_in(tamper_in),
        .do_compare(do_compare),
        .commit_illegal(commit_illegal),
        .auth_key_in(auth_key_in),

        .aes_enable(aes_enable),
        .unlocked(unlocked),
        .auth_zeroize(auth_zeroize),
        .tamper_latched(tamper_latched),
        .key_sel(key_sel),
        .state_debug(state_debug)
    );

    // AES input block buffer

    logic [127:0] block_in;
    logic [3:0]   block_valid_mask;
    logic         block_all_valid;

    always_ff @(posedge clk or posedge reset) begin
        if (reset) begin
            block_in         <= 128'h0;
            block_valid_mask <= 4'h0;
        end
        else if (security_clear) begin
            block_in         <= 128'h0;
            block_valid_mask <= 4'h0;
        end
        else if (blk_wr_en) begin
            case (blk_wr_addr)
                2'd0: begin block_in[127:96] <= blk_wr_data; block_valid_mask[3] <= 1'b1; end
                2'd1: begin block_in[95:64]  <= blk_wr_data; block_valid_mask[2] <= 1'b1; end
                2'd2: begin block_in[63:32]  <= blk_wr_data; block_valid_mask[1] <= 1'b1; end
                2'd3: begin block_in[31:0]   <= blk_wr_data; block_valid_mask[0] <= 1'b1; end
            endcase
        end
    end

    assign block_all_valid = &block_valid_mask;

    // AES control FSM

    logic [255:0] aes_key_bus;
    logic         aes_keylen;
    logic [127:0] aes_result;
    logic         aes_ready;
    logic         aes_result_valid;

    logic aes_init;
    logic aes_next;

    assign aes_key_bus = {128'h0, AES_KEY};
    assign aes_keylen  = 1'b0;  // AES-128

    typedef enum logic [1:0] {
        AES_NEED_INIT = 2'd0,
        AES_WAIT_INIT = 2'd1,
        AES_READY     = 2'd2
    } aes_ctrl_state_t;

    aes_ctrl_state_t aes_ctrl_state;

    always_ff @(posedge clk or posedge reset) begin
        if (reset) begin
            aes_ctrl_state <= AES_NEED_INIT;
        end
        else if (zeroize || auth_zeroize || tamper_latched || !unlocked) begin
            aes_ctrl_state <= AES_NEED_INIT;
        end
        else begin
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

                default: begin
                    aes_ctrl_state <= AES_NEED_INIT;
                end
            endcase
        end
    end

    always_comb begin
        aes_init = 1'b0;
        aes_next = 1'b0;

        if (aes_ctrl_state == AES_NEED_INIT &&
            unlocked &&
            aes_enable &&
            aes_ready &&
            !trap) begin
            aes_init = 1'b1;
        end

        if (aes_ctrl_state == AES_READY &&
            aes_start &&
            aes_enable &&
            block_all_valid &&
            aes_ready &&
            !trap) begin
            aes_next = 1'b1;
        end
    end

    // AES Core
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

    // AES result buffer

    logic [127:0] result_q;
    logic         result_ready_q;

    always_ff @(posedge clk or posedge reset) begin
        if (reset) begin
            result_q       <= 128'h0;
            result_ready_q <= 1'b0;
        end
        else if (security_clear) begin
            result_q       <= 128'h0;
            result_ready_q <= 1'b0;
        end
        else if (aes_result_valid && aes_enable && unlocked && !trap) begin
            result_q       <= aes_result;
            result_ready_q <= 1'b1;
        end
    end

    assign result_ready = result_ready_q;

    always_comb begin
        rd_data  = 32'h0;
        rd_valid = 1'b0;

        if (rd_en && result_ready_q && aes_enable && unlocked && !trap) begin
            rd_valid = 1'b1;
            case (rd_addr)
                2'd0: rd_data = result_q[127:96];
                2'd1: rd_data = result_q[95:64];
                2'd2: rd_data = result_q[63:32];
                2'd3: rd_data = result_q[31:0];
                default: rd_data = 32'h0;
            endcase
        end
    end

endmodule
