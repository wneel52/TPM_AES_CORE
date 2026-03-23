#!/bin/bash
vcs -sverilog ../rtl/fsm_using_one_always.v ../sim/tb_fsm_one.sv -debug_access+all -o simv
./simv

