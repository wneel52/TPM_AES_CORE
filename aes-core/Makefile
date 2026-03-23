VCS=vcs
VCSFLAGS=-full64 -sverilog -timescale=1ns/1ps -debug_access+all
RTL=rtl/aes.v rtl/aes_core.v rtl/aes_encipher_block.v rtl/aes_decipher_block.v \
    rtl/aes_key_mem.v rtl/aes_sbox.v rtl/aes_inv_sbox.v
TB=sim/tb_aes.v

aes_regress:
    rm -rf build/simv build/simv.daidir build/csrc build/ucli.key build/*.vcd build/*.vpd
    cd build && $(VCS) $(VCSFLAGS) -o simv ../$(RTL) ../$(TB)
    cd build && ./simv -no_save

