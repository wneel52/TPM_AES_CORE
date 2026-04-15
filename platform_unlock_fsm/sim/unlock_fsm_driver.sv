`include "uvm_macros.svh"
import uvm_pkg::*;

class unlock_fsm_driver extends uvm_driver #(unlock_fsm_item);
    `uvm_component_utils(unlock_fsm_driver)

    virtual unlock_fsm_if vif;

    function new(string name = "unlock_fsm_driver", uvm_component parent = null);
        super.new(name,parent);
    endfunction

    function void build_phase(uvm_phase phase);
        super.build_phase(phase);
        if (!uvm_config_db#(virtual unlock_fsm_if)::get(this, "", "vif", vif))
            `uvm_fatal("NOVIF", "unlock_fsm_if not found in uvm_config_db")
    endfunction

    task run_phase(uvm_phase phase);
        unlock_fsm_item tr;
        vif.reset <= 0;
        vif.zeroize_in <= 0;
        vif.do_compare <= 0;
        vif.match_q <= 0;
        vif.commit_illegal <= 0;
        forever begin
            seq_item_port.get_next_item(tr);
            @(posedge vif.clk);
            vif.reset <= tr.reset;
            vif.zeroize_in <= tr.zeroize_in;
            vif.do_compare <= tr.do_compare;
            vif.match_q <= tr.match_q;
            vif.commit_illegal <= tr.commit_illegal;
            seq_item_port.item_done();
            $display("T=%0t reset=%0b cmp=%0b match=%0b state=%0d unlocked=%0b",
            $time,
            vif.reset,
            vif.do_compare,
            vif.match_q,
            vif.key_sel,
            vif.auth_zeroize,
            vif.state_debug,
            vif.unlocked);
        end
    endtask
endclass
