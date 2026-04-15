`include "uvm_macros.svh"
import uvm_pkg::*;

class unlock_fsm_commit_illegal_test extends uvm_test;
    `uvm_component_utils(unlock_fsm_commit_illegal_test)
    
    unlock_fsm_driver drv;
    unlock_fsm_sequencer seqr;
    unlock_fsm_monitor mon;
    unlock_fsm_scoreboard sb;
    
    function new(string name = "unlock_fsm_commit_illegal_test", uvm_component parent = null);
        super.new(name,parent);
    endfunction

    function void build_phase(uvm_phase phase);
        super.build_phase(phase);
        drv = unlock_fsm_driver::type_id::create("drv", this);
        seqr = unlock_fsm_sequencer::type_id::create("seqr", this);
        mon = unlock_fsm_monitor::type_id::create("mon", this);
        sb = unlock_fsm_scoreboard::type_id::create("sb", this);
    endfunction

    function void connect_phase(uvm_phase phase);
        super.connect_phase(phase);
        drv.seq_item_port.connect(seqr.seq_item_export);
        mon.ap.connect(sb.analysis_export);
    endfunction

    task run_phase(uvm_phase phase);
        unlock_fsm_commit_illegal_seq seq;
        
        phase.raise_objection(this);
        
        seq = unlock_fsm_commit_illegal_seq::type_id::create("seq");
        seq.start(seqr);
        
        #20;
        phase.drop_objection(this);
    endtask

endclass
