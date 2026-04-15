`include "uvm_macros.svh"
import uvm_pkg::*;

class unlock_fsm_scoreboard extends uvm_component;
    `uvm_component_utils(unlock_fsm_scoreboard)
    uvm_analysis_imp #(unlock_fsm_mon_item, unlock_fsm_scoreboard) analysis_export;
    
    typedef enum bit [1:0] {
        EXP_WAIT_K0 = 2'd0,
        EXP_WAIT_K1 = 2'd1,
        EXP_WAIT_K2 = 2'd2,
        EXP_UNLOCKED = 2'd3
    } exp_state_t;

    exp_state_t exp_state;

    function new(string name = "unlock_fsm_scoreboard", uvm_component parent = null);
        super.new(name, parent);
        analysis_export = new("analysis_export", this);
    endfunction    

    function void build_phase(uvm_phase phase);
        super.build_phase(phase);
        exp_state = EXP_WAIT_K0;
    endfunction

    function void write(unlock_fsm_mon_item tr);
        bit exp_aes_enable;
        bit exp_unlocked;
        bit exp_auth_zeroize;
        bit [1:0] exp_key_sel;
        exp_state_t next_state;
        
        if (tr.reset) begin
            exp_state = EXP_WAIT_K0;
            return;
        end

        next_state = exp_state;
        exp_aes_enable = 1'b0;
        exp_unlocked = 1'b0;
        exp_auth_zeroize = 1'b0;
        exp_key_sel = 2'd0;

        case (exp_state)
            EXP_WAIT_K0: begin
                exp_key_sel = 2'd0;
                
                if(tr.reset) begin
                    next_state = EXP_WAIT_K0;
                end
                else if (tr.zeroize_in) begin
                    exp_auth_zeroize = 1'b1;
                    next_state = EXP_WAIT_K0;
                end
                else if (tr.commit_illegal) begin
                    exp_auth_zeroize = 1'b1;
                    next_state = EXP_WAIT_K0;
                end
                else if (tr.do_compare) begin
                    if (tr.match_q) begin
                        next_state = EXP_WAIT_K1;
                    end
                    else begin
                        exp_auth_zeroize = 1'b1;
                        next_state = EXP_WAIT_K0;
                    end
                end
            end
            EXP_WAIT_K1: begin
                exp_key_sel = 2'd1;
                if (tr.reset) begin
                    next_state = EXP_WAIT_K0;
                end
                else if (tr.zeroize_in) begin
                    exp_auth_zeroize = 1'b1;
                    next_state = EXP_WAIT_K0;
                end
                else if (tr.commit_illegal) begin
                    exp_auth_zeroize = 1'b1;
                    next_state = EXP_WAIT_K0;
                end
                else if (tr.do_compare) begin
                    if (tr.match_q) begin
                        next_state = EXP_WAIT_K2;
                    end
                    else begin
                        exp_auth_zeroize = 1'b1;
                        next_state = EXP_WAIT_K0;
                    end
                end
            end
            EXP_WAIT_K2: begin
                exp_key_sel = 2'd2;
                if (tr.reset) begin
                    next_state = EXP_WAIT_K0;
                end
                else if (tr.zeroize_in) begin
                    exp_auth_zeroize = 1'b1;
                    next_state = EXP_WAIT_K0;
                end
                else if (tr.commit_illegal) begin
                    exp_auth_zeroize = 1'b1;
                    next_state = EXP_WAIT_K0;
                end
                else if (tr.do_compare) begin
                    if (tr.match_q) begin
                        next_state = EXP_UNLOCKED;
                    end
                    else begin
                        exp_auth_zeroize = 1'b1;
                        next_state = EXP_WAIT_K0;
                    end
                end
            end
            EXP_UNLOCKED: begin
                exp_aes_enable = 1'b1;
                exp_unlocked = 1'b1;
                exp_key_sel = 2'd0;
                if (tr.reset) begin
                    next_state = EXP_WAIT_K0;
                    exp_aes_enable = 1'b0;
                    exp_unlocked = 1'b0;
                end
                else if (tr.zeroize_in) begin
                    exp_auth_zeroize = 1'b1;
                    next_state = EXP_WAIT_K0;
                    exp_aes_enable = 1'b1;
                    exp_unlocked = 1'b1;
                end
            end
        endcase

        if (tr.state_debug !== exp_state) begin
            `uvm_error("SB", $sformatf("state mismatch exp=%0d act=%0d", exp_state, tr.state_debug))
        end
        if (tr.key_sel !== exp_key_sel) begin
            `uvm_error("SB", $sformatf("state mismatch exp=%0d act=%0d", exp_key_sel, tr.key_sel))
        end
        if (tr.unlocked !== exp_unlocked) begin
            `uvm_error("SB", $sformatf("state mismatch exp=%0d act=%0d", exp_unlocked, tr.unlocked))
        end
        if (tr.aes_enable !== exp_aes_enable) begin
            `uvm_error("SB", $sformatf("state mismatch exp=%0d act=%0d", exp_aes_enable, tr.aes_enable))
        end
        if (tr.auth_zeroize !== exp_auth_zeroize) begin
            `uvm_error("SB", $sformatf("state mismatch exp=%0d act=%0d", exp_auth_zeroize, tr.auth_zeroize))
        end
        exp_state = next_state;
    endfunction
endclass
