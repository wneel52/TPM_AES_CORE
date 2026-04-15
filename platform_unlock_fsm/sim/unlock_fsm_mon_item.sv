`include "uvm_macros.svh"
import uvm_pkg::*;

class unlock_fsm_mon_item extends uvm_sequence_item;
    `uvm_object_utils(unlock_fsm_mon_item)
    // observed inputs
    bit reset;
    bit zeroize_in;
    bit do_compare;
    bit match_q;
    bit commit_illegal;
    // outputs observed
    bit aes_enable;
    bit unlocked;
    bit auth_zeroize;
    bit [1:0] key_sel;
    bit [1:0] state_debug;

    function new(string name = "unlock_fsm_mon_item");
        super.new(name);
    endfunction
endclass
