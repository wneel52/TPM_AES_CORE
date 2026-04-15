`include "uvm_macros.svh"
import uvm_pkg::*;

class unlock_fsm_sequencer extends uvm_sequencer #(unlock_fsm_item);
    `uvm_component_utils(unlock_fsm_sequencer)

    function new(string name = "unlock_fsm_sequencer", uvm_component parent = null);
        super.new(name, parent);
    endfunction

endclass
