`include "uvm_macros.svh"
import uvm_pkg::*;

class unlock_fsm_item extends uvm_sequence_item;

    // inputs to the DUT 
    rand bit reset;
    rand bit zeroize_in;    
    rand bit do_compare;
    rand bit match_q;
    rand bit commit_illegal;
    `uvm_object_utils(unlock_fsm_item)

    function new(string name = "unlock_fsm_item");
        super.new(name);
    endfunction
endclass
