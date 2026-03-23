#!/bin/bash
vcs -full64 -sverilog \
  ../rtl/unlock_fsm.v \
  ../sim/unlock_fsm_tb.sv \
  -o simv

./simv
#EOF
