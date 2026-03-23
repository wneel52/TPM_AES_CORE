vcs -full64 -sverilog \
  ../rtl/aes_result_buffer.v \
  ../sim/tb_aes_result_buffer.sv \
  -o simv

./simv
