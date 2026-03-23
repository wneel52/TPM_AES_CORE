#!/bin/bash
vcs -full64 -sverilog \
  ../rtl/aes_input_block_buffer.v \
  ../sim/tb_aes_input_block_buffer.sv \
  -o simv

./simv
