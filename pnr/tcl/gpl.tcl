set ::env(PL_TARGET_DENSITY_PCT) [expr 100.0*$::env(PR) + 10.0 + $::env(GPL_CELL_PADDING)]

set arg_list [list]

lappend arg_list -density [expr $::env(PL_TARGET_DENSITY_PCT) / 100.0]

if { [info exists ::env(PL_TIMING_DRIVEN)] && $::env(PL_TIMING_DRIVEN) } {
	source $::env(SCRIPTS_DIR)/openroad/common/set_rc.tcl
	lappend arg_list -timing_driven
}

if { [info exists ::env(PL_ROUTABILITY_DRIVEN)] && $::env(PL_ROUTABILITY_DRIVEN) } {
	source $::env(SCRIPTS_DIR)/openroad/common/set_routing_layers.tcl
	set_macro_extension $::env(GRT_MACRO_EXTENSION)
	source $::env(SCRIPTS_DIR)/openroad/common/set_layer_adjustments.tcl
	lappend arg_list -routability_driven
	if { [info exists ::env(PL_ROUTABILITY_OVERFLOW_THRESHOLD)] } {
		lappend arg_list -routability_check_overflow $::env(PL_ROUTABILITY_OVERFLOW_THRESHOLD)
	}
}

if { $::env(PL_SKIP_INITIAL_PLACEMENT) } {
	lappend arg_list -skip_initial_place
}

if { [info exists ::env(__PL_SKIP_IO)] && $::env(__PL_SKIP_IO) == "1" } {
	lappend arg_list -skip_io
}

if { [info exists ::env(PL_MIN_PHI_COEFFICIENT)] } {
	lappend arg_list -min_phi_coef $::env(PL_MIN_PHI_COEFFICIENT)
}

if { [info exists ::env(PL_MAX_PHI_COEFFICIENT)] } {
	lappend arg_list -max_phi_coef $::env(PL_MAX_PHI_COEFFICIENT)
}

set cell_pad_side [expr $::env(GPL_CELL_PADDING) / 2]

lappend arg_list -pad_right $cell_pad_side
lappend arg_list -pad_left $cell_pad_side
lappend arg_list -init_wirelength_coef $::env(PL_WIRE_LENGTH_COEF)
append_if_exists_argument arg_list PL_KEEP_RESIZE_BELOW_OVERFLOW -keep_resize_below_overflow

# We actually do not care
if { [catch {global_placement {*}$arg_list} errmsg] } {
    puts stderr $errmsg
    puts "Global placement failed, but is ignored on purpose"
}
