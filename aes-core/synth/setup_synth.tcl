set CLK_NAME clk
set MOD_NAME aes_core_128_synth

set RPT_DIR aes_top_128
file mkdir $RPT_DIR

set synthetic_library [list dw_foundation.sldb]
set link_library [list gpdk045_slow.db]
set target_library gpdk045_slow.db

set RTL_DIR ../rtl/

analyze -format sverilog ../rtl/aes_sbox.v
analyze -format sverilog ../rtl/aes_inv_sbox.v
analyze -format sverilog ../rtl/aes_key_mem.v
analyze -format sverilog ../rtl/aes_encipher_block.v
analyze -format sverilog ../rtl/aes_decipher_block.v
analyze -format sverilog ../rtl/aes_core.v
analyze -format sverilog ../rtl/aes-128-wrapper.v

elaborate aes_core_128_synth
current_design aes_core_128_synth
link

set report_default_significant_digits 4
