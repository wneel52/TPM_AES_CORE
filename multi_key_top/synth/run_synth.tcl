source setup_synth.tcl
source constraints_synth.tcl

check_design > $RPT_DIR/check_design.precompile.rpt

compile_ultra

report_qor > $RPT_DIR/qor.rpt
report_area -hierarchy > $RPT_DIR/area_hier.rpt
report_area > $RPT_DIR/area.rpt
report_timing -max_paths 10 > $RPT_DIR/timing.rpt
report_power > $RPT_DIR/power.rpt
report_units > $RPT_DIR/unit_sanity.rpt

write -format verilog -hierarchy -output $RPT_DIR/${MOD_NAME}_mapped.v
write_sdc $RPT_DIR/${MOD_NAME}.sdc

# EOF

