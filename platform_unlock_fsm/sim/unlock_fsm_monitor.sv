`include "uvm_macros.svh"
import uvm_pkg::*;

class unlock_fsm_monitor extends uvm_monitor;
    `uvm_component_utils(unlock_fsm_monitor)
    
    virtual unlock_fsm_if vif;
    uvm_analysis_port #(unlock_fsm_mon_item) ap;
    
    function new(string name = "unlock_fsm_monitor", uvm_component parent = null);
        super.new(name, parent);
        ap = new("ap", this);
    endfunction

    function void build_phase(uvm_phase phase);
        super.build_phase(phase);
        if (!uvm_config_db#(virtual unlock_fsm_if)::get(this, "", "vif", vif))
            `uvm_fatal("NOVIF", "unlock_fsm_if not found in uvm_config_db")
    endfunction

    task run_phase(uvm_phase phase);
        unlock_fsm_mon_item mon_tr;
        forever begin
            @(negedge vif.clk);
            mon_tr = unlock_fsm_mon_item::type_id::create("mon_tr");
            
            mon_tr.reset = vif.reset;
            mon_tr.zeroize_in = vif.zeroize_in;
            mon_tr.do_compare = vif.do_compare;
            mon_tr.match_q = vif.match_q;
            mon_tr.commit_illegal = vif.commit_illegal;
            
            mon_tr.aes_enable = vif.aes_enable;
            mon_tr.unlocked = vif.unlocked;
            mon_tr.auth_zeroize = vif.auth_zeroize;
            mon_tr.key_sel = vif.key_sel;
            mon_tr.state_debug = vif.state_debug;
            

            ap.write(mon_tr);
            $display("MON T=%0t state=%0d key_sel=%0d cmp=%0b match=%0b unlocked=%0b aes=%0b auth_zeroize=%0b",
                     $time,
                     mon_tr.state_debug,
                     mon_tr.key_sel,
                     mon_tr.do_compare,
                     mon_tr.match_q,
                     mon_tr.unlocked,
                     mon_tr.aes_enable,
                     mon_tr.auth_zeroize);        
        end
    endtask
endclass
