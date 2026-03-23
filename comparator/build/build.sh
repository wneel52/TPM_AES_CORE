#!/bin/bash
set -e

vcs -full64 -sverilog \
    -debug_access+all -kdb \
    ../rtl/key_activation_compare.v \
    ../sim/tb_key_activation_compare.v \
    -o simv

./simv
