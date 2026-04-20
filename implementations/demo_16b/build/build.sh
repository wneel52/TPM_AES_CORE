#!/bin/bash
set -e

mkdir -p out

yosys -p "
read_verilog -sv ../rtl/fpga_top.v
read_verilog -sv ../rtl/key_activation_compare.v
read_verilog -sv ../rtl/platform_key_store.v
read_verilog -sv ../rtl/platform_unlock_fsm.v
read_verilog -sv ../rtl/controller_top.v
synth_ice40 -top fpga_top -json out/fpga_top.json
"

nextpnr-ice40 \
  --lp1k \
  --package cm36 \
  --pcf ../constraints/icesugar_nano.pcf \
  --json out/fpga_top.json \
  --asc out/fpga_top.asc

icepack out/fpga_top.asc out/fpga_top.bin
