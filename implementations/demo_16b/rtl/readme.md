This directory contains the RTL(Register Transfer Languge) for the demo
  - rtl/fpga_top.v  : top level module -> FPGA wrapper for controller_top.v
  - rtl/controller_top.v  : controller module wraps the three below
  - rtl/platform_unlock_fsm.v : FSM unit processes commands and manages signals from the comparator
  - rtl/key_activation_compare.v  : comparator
  - rtl/platform_key_store.v  : key vault store all 3 platfrom keys
