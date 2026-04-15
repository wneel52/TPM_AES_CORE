`include "uvm_macros.svh"
import uvm_pkg::*;

module tb_top;
    logic clk;
    // 100 MHz clk
    initial clk = 1'b0;
    always #5 clk = ~clk;
    unlock_fsm_if vif(clk); // init interface and handoff clk
    // init dut
    unlock_fsm dut (
        .clk(clk),
        .reset(vif.reset),
        .zeroize_in(vif.zeroize_in),
        .do_compare(vif.do_compare),
        .match_q(vif.match_q),
        .commit_illegal(vif.commit_illegal),
        .aes_enable(vif.aes_enable),
        .unlocked(vif.unlocked),
        .auth_zeroize(vif.auth_zeroize),
        .key_sel(vif.key_sel),
        .state_debug(vif.state_debug)
    );
    
    initial begin
        $dumpfile("waves.vcd");
        $dumpvars(0, tb_top);
        // give v-inf to UVM componets
        uvm_config_db#(virtual unlock_fsm_if)::set(null, "*", "vif", vif);
        // start test 
        run_test("unlock_fsm_zeroize_test");
    end
endmodule
