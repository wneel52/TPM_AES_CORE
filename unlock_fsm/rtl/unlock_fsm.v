`timescale 1ns/1ps

module unlock_fsm(
    input logic clk,
    input logic reset,
    input logic zeroize,

    input logic commit,
    input logic all_valid,
    input logic match_q,
    input logic commit_illegal,

    output logic aes_enable,
    output logic trap,
    output logic unlocked,
    output logic [1:0] state_debug
);

    typedef enum logic [1:0] {
        LOCKED,
        CHECK,
        UNLOCKED,
        TRAPPED
    } state_t;

    state_t state, next_state;

    assign aes_enable = (state == UNLOCKED);
    assign unlocked = (state == UNLOCKED);
    assign trap = (state == TRAPPED);
    assign state_debug = state;

    always_ff @(posedge clk) begin
        if (reset)
            state <= LOCKED;
        else
            state <= next_state;
    end

    always_comb begin
        next_state = state;
        
        case(state)
            LOCKED: begin
                if (zeroize)
                    next_state = TRAPPED;
                else if (commit_illegal)
                    next_state = TRAPPED;
                else if (commit && all_valid)
                    next_state = CHECK;
                else
                    next_state = LOCKED;
            end
            CHECK: begin
                if (zeroize)    
                    next_state = TRAPPED;
                else if (match_q)
                    next_state = UNLOCKED;
                else
                    next_state = TRAPPED;
            end
            UNLOCKED: begin
                if (zeroize)
                    next_state = TRAPPED;
                else
                    next_state = UNLOCKED;
            end
            TRAPPED: begin
                next_state = TRAPPED;
            end
            default: begin
                next_state = TRAPPED;
            end
        endcase
    end

endmodule
