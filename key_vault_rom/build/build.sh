#!/bin/bash
vcs -sverilog -full64 -debug_access+all \
  ../rtl/key_vault_rom.v \
  ../sim/tb_key_vault_rom.sv \
  -o simv && ./simv
