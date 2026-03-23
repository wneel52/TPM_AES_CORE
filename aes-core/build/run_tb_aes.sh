#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "$0")/.." && pwd)"
cd "$ROOT/build"

rm -rf simv simv.daidir csrc ucli.key vc_hdrs.h *.vcd *.vpd *.fsdb DVEfiles

vcs -full64 -sverilog -timescale=1ns/1ps \
  -debug_access+all \
  -o simv \
  "$ROOT/rtl/aes.v" \
  "$ROOT/rtl/aes_core.v" \
  "$ROOT/rtl/aes_encipher_block.v" \
  "$ROOT/rtl/aes_decipher_block.v" \
  "$ROOT/rtl/aes_key_mem.v" \
  "$ROOT/rtl/aes_sbox.v" \
  "$ROOT/rtl/aes_inv_sbox.v" \
  "$ROOT/sim/tb_aes.v"

./simv
