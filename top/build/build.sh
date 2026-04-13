vcs -sverilog -full64 -debug_access+all \
    ../rtl/tpm_aes_top.v \
    ../sim/tb_tpm_aes_top.sv \
    ../../key_commit_buffer/rtl/*.v \
    ../../unlock_fsm/rtl/*.v \
    ../../aes_input_buffer/rtl/*.v \
    ../../aes_result_buffer/rtl/*.v \
    ../../aes-core/rtl/*.v

./simv
