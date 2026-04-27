module auth_controller_top #(
    parameter int KEY_W = 16
)(
    input  logic              clk,
    input  logic              reset,
    input  logic              zeroize_in,
    input  logic              do_compare,
    input  logic              commit_illegal,
    input  logic [KEY_W-1:0]  auth_key_in,

    output logic              aes_enable,
    output logic              unlocked,
    output logic              auth_zeroize,
    output logic [1:0]        key_sel,
    output logic [1:0]        state_debug
);

    logic [KEY_W-1:0] key_hw;
    logic             match_q;

    platform_key_store #(
        .KEY_W(KEY_W)
    ) unit_key_store (
        .key_sel(key_sel),
        .key_out(key_hw)
    );

    key_activation_compare #(
        .SIZE(KEY_W)
    ) unit_compare (
        .key_in(auth_key_in),
        .key_hw(key_hw),
        .match(match_q)
    );

    platform_unlock_fsm unit_fsm (
        .clk(clk),
        .reset(reset),
        .zeroize_in(zeroize_in),
        .do_compare(do_compare),
        .match_q(match_q),
        .commit_illegal(commit_illegal),
        .aes_enable(aes_enable),
        .unlocked(unlocked),
        .auth_zeroize(auth_zeroize),
        .key_sel(key_sel),
        .state_debug(state_debug)
    );

endmodule
