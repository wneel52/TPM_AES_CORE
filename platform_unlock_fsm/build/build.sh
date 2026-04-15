#!/bin/bash
# Note: This script is not robust, need to change which sequence and test file are being used
# will change this  to have switches to configure different builds asap(ractical)
mkdir -p csrc simv.daidir

vcs -full64 -sverilog -ntb_opts uvm \
  ../rtl/platform_unlock_fsm.v \
  ../sim/unlock_fsm_if.sv \
  ../sim/unlock_fsm_item.sv \
  ../sim/unlock_fsm_mon_item.sv \
  ../sim/unlock_fsm_driver.sv \
  ../sim/unlock_fsm_sequencer.sv \
  ../sim/unlock_fsm_zeroize_seq.sv \
  ../sim/unlock_fsm_monitor.sv \
  ../sim/unlock_fsm_scoreboard.sv \
  ../sim/unlock_fsm_zeroize_test.sv \
  ../sim/tb_top.sv \
  -o simv

./simv

# Notes
# interface before classes using it\
# item before driver/sequence
# sequence before test
# monitor before test ok
# sb before test ok
