interface unlock_fsm_if(input logic clk);
    logic reset;
    logic zeroize_in;
    logic do_compare;
    logic match_q;
    logic commit_illegal;
    logic aes_enable;
    logic unlocked;
    logic auth_zeroize;
    logic [1:0] key_sel;
    logic [1:0] state_debug;
endinterface
