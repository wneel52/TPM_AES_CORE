set CLK_NAME clk
set MOD_NAME secure_aes_top

# Use 128 for final integrated system unless intentionally sweeping
# authentication key width. AES itself remains AES-128.
set KEY_W 128

set RPT_DIR rpt_secure_aes_top_${KEY_W}
file mkdir $RPT_DIR

set synthetic_library [list dw_foundation.sldb]
set link_library [list gpdk045_slow.db]
set target_library gpdk045_slow.db

set RTL_DIR ../rtl/

# Authentication controller RTL
analyze -format sverilog $RTL_DIR/key_activation_compare.v
analyze -format sverilog $RTL_DIR/platform_key_store.v
analyze -format sverilog $RTL_DIR/platform_unlock_fsm.v
analyze -format sverilog $RTL_DIR/auth_controller_top.v

# AES core RTL
analyze -format sverilog $RTL_DIR/aes_sbox.v
analyze -format sverilog $RTL_DIR/aes_inv_sbox.v
analyze -format sverilog $RTL_DIR/aes_key_mem.v
analyze -format sverilog $RTL_DIR/aes_encipher_block.v
analyze -format sverilog $RTL_DIR/aes_decipher_block.v
analyze -format sverilog $RTL_DIR/aes_core.v

# Integrated wrapper
analyze -format sverilog $RTL_DIR/secure_aes_top.sv

elaborate $MOD_NAME -parameters "KEY_W=$KEY_W"
current_design $MOD_NAME
link

set report_default_significant_digits 4

