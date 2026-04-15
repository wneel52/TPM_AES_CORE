`include "uvm_macros.svh"
import uvm_pkg::*;

class unlock_fsm_commit_illegal_seq extends uvm_sequence #(unlock_fsm_item);
    `uvm_object_utils(unlock_fsm_commit_illegal_seq)

    function new(string name = "unlock_fsm_commit_illegal_seq");
        super.new(name);
    endfunction

    task body();
        unlock_fsm_item tr;

        // cycle 1: reset
        tr = unlock_fsm_item::type_id::create("tr");
        tr.reset = 1'b1;
        tr.zeroize_in = 1'b0;
        tr.do_compare = 1'b0;
        tr.match_q = 1'b0;
        tr.commit_illegal = 1'b0;
        start_item(tr);
        finish_item(tr);
        
        // cycle 2 idle
        tr = unlock_fsm_item::type_id::create("tr");
        tr.reset = 1'b0;
        tr.zeroize_in = 1'b0;
        tr.do_compare = 1'b0;
        tr.match_q  = 1'b0;
        tr.commit_illegal = 1'b0;
        start_item(tr);
        finish_item(tr);

        // cycle 3: correct K0
        tr = unlock_fsm_item::type_id::create("tr");
        tr.reset = 1'b0;
        tr.zeroize_in = 1'b0;
        tr.do_compare = 1'b1;
        tr.match_q = 1'b1;
        tr.commit_illegal = 1'b0;
        start_item(tr);
        finish_item(tr);


        // cycle 4 idle
        tr = unlock_fsm_item::type_id::create("tr");
        tr.reset = 1'b0;
        tr.zeroize_in = 1'b0;
        tr.do_compare = 1'b0;
        tr.match_q  = 1'b0;
        tr.commit_illegal = 1'b0;
        start_item(tr);
        finish_item(tr);

        // cycle 5: correct K1
        tr = unlock_fsm_item::type_id::create("tr");
        tr.reset = 1'b0;
        tr.zeroize_in = 1'b0;
        tr.do_compare = 1'b1;
        tr.match_q = 1'b1;
        tr.commit_illegal = 1'b0;
        start_item(tr);
        finish_item(tr);

        // cycle 6 idle
        tr = unlock_fsm_item::type_id::create("tr");
        tr.reset = 1'b0;
        tr.zeroize_in = 1'b0;
        tr.do_compare = 1'b0;
        tr.match_q  = 1'b0;
        tr.commit_illegal = 1'b0;
        start_item(tr);
        finish_item(tr);

        // cycle 7: commit_illegal asserted while wating for K2
        tr = unlock_fsm_item::type_id::create("tr");
        tr.reset = 1'b0;
        tr.zeroize_in = 1'b0;
        tr.do_compare = 1'b0;
        tr.match_q  = 1'b0;
        tr.commit_illegal = 1'b1;
        start_item(tr);
        finish_item(tr);

        // cycle 8: observe reset
        tr = unlock_fsm_item::type_id::create("tr");
        tr.reset = 1'b0;
        tr.zeroize_in = 1'b0;
        tr.do_compare = 1'b0;
        tr.match_q = 1'b0;
        tr.commit_illegal = 1'b0;
        start_item(tr);
        finish_item(tr);

        // cycle 9: idle
        tr = unlock_fsm_item::type_id::create("tr");
        tr.reset = 1'b0;
        tr.zeroize_in = 1'b0;
        tr.do_compare = 1'b0;
        tr.match_q  = 1'b0;
        tr.commit_illegal = 1'b0;
        start_item(tr);
        finish_item(tr);

    endtask

endclass
