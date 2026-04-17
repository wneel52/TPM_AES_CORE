#!/bin/bash
vcs -full64 -sverilog \
  ../rtl/platform_key_rom.v \
  ../sim/tb_platform_key_rom.sv \
  -o simv

./simv
