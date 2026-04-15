`include "uvm_macros.svh"
import uvm_pkg::*;

class unlock_fsm_seq extends uvm_sequence #(unlock_fsm_item);
    `uvm_object_utils(unlock_fsm_seq)

    function new(string name = "unlock_fsm_seq");
        super.new(name);
    endfunction

    task body();
        unlock_fsm_item tr;
        // Assert reset in cycle 1
        tr = unlock_fsm_item::type_id::create("tr");
        tr.reset = 1'b1;
        tr.zeroize_in = 1'b0;
        tr.do_compare = 1'b0;
        tr.match_q = 1'b0;
        tr.commit_illegal = 1'b0;
        start_item(tr);
        finish_item(tr);

        // Idle in cycle 2 deassert reset
        tr = unlock_fsm_item::type_id::create("tr");
        tr.reset = 1'b0;
        tr.zeroize_in = 1'b0;
        tr.do_compare = 1'b0;
        tr.match_q = 1'b0;
        tr.commit_illegal = 1'b0;
        start_item(tr);
        finish_item(tr);

        // K0 succeeds in cycle 3
        tr = unlock_fsm_item::type_id::create("tr");
        tr.reset = 1'b0;
        tr.zeroize_in = 1'b0;
        tr.do_compare = 1'b1;
        tr.match_q = 1'b1;
        tr.commit_illegal= 1'b0;
        start_item(tr);
        finish_item(tr);

        // idle cycle 4
        tr = unlock_fsm_item::type_id::create("tr");
        tr.reset = 1'b0;
        tr.zeroize_in = 1'b0;
        tr.do_compare = 1'b0;
        tr.match_q = 1'b0;
        tr.commit_illegal = 1'b0;
        start_item(tr);
        finish_item(tr);        

        // K1 succeeds in cycle 5
        tr = unlock_fsm_item::type_id::create("tr");
        tr.reset = 1'b0;
        tr.zeroize_in = 1'b0;
        tr.do_compare = 1'b1;
        tr.match_q = 1'b1;
        tr.commit_illegal = 1'b0;
        start_item(tr);
        finish_item(tr);

        // idle cycle 6
        tr = unlock_fsm_item::type_id::create("tr");
        tr.reset = 1'b0;
        tr.zeroize_in = 1'b0;
        tr.do_compare = 1'b0;
        tr.match_q = 1'b0;
        tr.commit_illegal = 1'b0;
        start_item(tr);
        finish_item(tr);

        // K2 passes in cycle 7
        tr = unlock_fsm_item::type_id::create("tr");
        tr.reset = 1'b0;
        tr.zeroize_in = 1'b0;
        tr.do_compare = 1'b1;
        tr.match_q = 1'b1;
        tr.commit_illegal = 1'b0;
        start_item(tr);
        finish_item(tr);

        // idle cycle 8 -> observe results
        tr = unlock_fsm_item::type_id::create("tr");
        tr.reset = 1'b0;
        tr.zeroize_in = 1'b0;
        tr.do_compare = 1'b0;
        tr.match_q = 1'b0;
        tr.commit_illegal = 1'b0;
        start_item(tr);
        finish_item(tr);

    endtask

endclass
