`include "uvm_macros.svh"
 import uvm_pkg::*;

class unlock_fsm_bad_k1_seq extends uvm_sequence #(unlock_fsm_item);
    `uvm_object_utils(unlock_fsm_bad_k1_seq)

    function new(string name = "unlock_fsm_bad_k1_seq");
        super.new(name);
    endfunction

    task body();
        unlock_fsm_item tr;
        
        // cycle 1: assert reset
        tr = unlock_fsm_item::type_id::create("tr");
        tr.reset = 1'b1;
        tr.zeroize_in = 1'b0;
        tr.do_compare = 1'b0;
        tr.match_q = 1'b0;
        tr.commit_illegal = 1'b0;
        start_item(tr);
        finish_item(tr);

        // cycle 2: idle to deassert reset
        tr = unlock_fsm_item::type_id::create("tr");
        tr.reset = 1'b0;
        tr.zeroize_in = 1'b0;
        tr.do_compare = 1'b0;
        tr.match_q = 1'b0;
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

        // cycle 4: idle after correct K0
        tr = unlock_fsm_item::type_id::create("tr");
        tr.reset = 1'b0;
        tr.zeroize_in = 1'b0;
        tr.do_compare = 1'b0;
        tr.match_q = 1'b0;
        tr.commit_illegal = 1'b0;
        start_item(tr);
        finish_item(tr);

        // cycle 5: incorrect K1
        tr = unlock_fsm_item::type_id::create("tr");
        tr.reset = 1'b0;
        tr.zeroize_in = 1'b0;
        tr.do_compare = 1'b1;
        tr.match_q = 1'b0;
        tr.commit_illegal = 1'b0;
        start_item(tr);
        finish_item(tr);

        // cycle 6: idle after wrong K1
        tr = unlock_fsm_item::type_id::create("tr");
        tr.reset = 1'b0;
        tr.zeroize_in = 1'b0;
        tr.do_compare = 1'b0;
        tr.match_q = 1'b0;
        tr.commit_illegal = 1'b0;
        start_item(tr);
        finish_item(tr);

        // cycle 7: FSM should reset
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
