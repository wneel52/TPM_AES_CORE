vcs -full64 -sverilog \
  ../rtl/key_commit_buffer.v \
  ../../comparator/rtl/key_activation_compare.v \
  ../sim/tb_key_commit_buffer.sv \
  -o simv
./simv
