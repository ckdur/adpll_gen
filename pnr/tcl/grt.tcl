set_propagated_clock [all_clocks]

set_macro_extension 0

pin_access
global_route -congestion_iterations 50 -congestion_report_iter_step 5 -verbose -congestion_report_file $PNR_DIR/reports/${TOP}_congestion.rpt

set_placement_padding -global -left 0 -right 0
set_propagated_clock [all_clocks]
estimate_parasitics -global_routing

# Incremental repair blob
repair_design -verbose
global_route -start_incremental
detailed_placement
global_route -end_incremental -congestion_report_file $PNR_DIR/reports/${TOP}_congestion_post_repair_design.rpt

repair_timing -verbose -setup_margin 0 -repair_tns 100

global_route -start_incremental
detailed_placement
global_route -end_incremental -congestion_report_file $PNR_DIR/reports/${TOP}_congestion_post_repair_timing.rpt

# Repair power blob
global_route -start_incremental
# recover_power_helper
global_route -end_incremental -congestion_report_file $PNR_DIR/reports/${TOP}_congestion_post_recover_power.rpt

# Repair antennas blob
repair_antennas -iterations 10
check_placement -verbose
check_antennas -report_file $PNR_DIR/reports/${TOP}_global_routing_antennas.log
estimate_parasitics -global_routing
