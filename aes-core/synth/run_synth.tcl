source setup_synth.tcl

create_clock -name clk -period 10 [get_ports clk]
set_clock_uncertainty 0.05 [get_clocks clk]

set_input_delay 0.100 -clock [get_clocks clk] \
  [remove_from_collection [all_inputs] [get_ports clk]]

set_output_delay 0.400 -clock [get_clocks clk] [all_outputs]

check_timing > $RPT_DIR/check_timing.rpt
report_clocks > $RPT_DIR/clocks.rpt

compile_ultra

report_qor > $RPT_DIR/qor.rpt
report_area -hierarchy > $RPT_DIR/area_hier.rpt
report_area > $RPT_DIR/area.rpt
report_timing -group clk -max_paths 10 > $RPT_DIR/timing.rpt
report_power > $RPT_DIR/power.rpt

write -format verilog -hierarchy -output $RPT_DIR/${MOD_NAME}_mapped.v
write_sdc $RPT_DIR/${MOD_NAME}.sdc
