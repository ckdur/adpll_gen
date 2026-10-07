source ${PNR_DIR}/tcl/set_rc.tcl

estimate_parasitics -placement

# Clone clock tree inverters next to register loads
# so cts does not try to buffer the inverted clocks.
repair_clock_inverters

set cts_characterization_args [list]
if { [info exists ::env(CTS_MAX_CAP)] } {
    lappend cts_characterization_args -max_cap [expr {$::env(CTS_MAX_CAP) * 1e-12}]; # pF -> F
}
if { [info exists ::env(CTS_MAX_SLEW)] } {
    lappend cts_characterization_args -max_slew [expr {$::env(CTS_MAX_SLEW) * 1e-9}]; # ns -> S
}
configure_cts_characterization {*}$cts_characterization_args


puts "\[INFO\] Performing clock tree synthesis…"
puts "\[INFO\] Looking for the following net(s): $::env(CLOCK_NET)"
puts "\[INFO\] Running Clock Tree Synthesis…"

proc get_buflist {} {
    set result [list]
    foreach selector $::env(CTS_CLK_BUFFERS) {
        # if we can find an exact match, avoid expensive search operation
        set exact_match [$::db findMaster $selector]
        if { "$exact_match" == "NULL" } {
            # time to dig for matches…
            foreach lib $::libs {
                foreach master [$lib getMasters] {
                    set name [$master getName]
                    if { [string match $selector $name] } {
                        lappend result $name
                    }
                }
            }
        } else {
            lappend result [$exact_match getName]
        }
    }
    return $result
}

set arg_list [list]
lappend arg_list -buf_list [get_buflist]
lappend arg_list -root_buf $::env(CTS_ROOT_BUFFER)
# Only these clock roots (set by clk_isolate.tcl, so CTS does not walk into the analog)
if { [info exists ::env(CTS_CLK_NETS)] } {
    lappend arg_list -clk_nets $::env(CTS_CLK_NETS)
}

append_if_exists_argument arg_list CTS_SINK_CLUSTERING_SIZE -sink_clustering_size
append_if_exists_argument arg_list CTS_SINK_CLUSTERING_MAX_DIAMETER -sink_clustering_max_diameter
append_if_flag arg_list CTS_SINK_CLUSTERING_ENABLE -sink_clustering_enable
append_if_exists_argument arg_list CTS_MACRO_CLUSTERING_SIZE -macro_clustering_size
append_if_exists_argument arg_list CTS_MACRO_CLUSTERING_MAX_DIAMETER -macro_clustering_max_diameter
append_if_flag arg_list CTS_DISABLE_POST_PROCESSING -post_cts_disable
append_if_flag arg_list CTS_OBSTRUCTION_AWARE -obstruction_aware
append_if_flag arg_list CTS_BALANCE_LEVELS -balance_levels
append_if_exists_argument arg_list CTS_APPLY_NDR -apply_ndr

if { $::env(CTS_DISTANCE_BETWEEN_BUFFERS) != 0 } {
    lappend arg_list -distance_between_buffers $::env(CTS_DISTANCE_BETWEEN_BUFFERS)
}

if { [info exists ::env(CTS_SINK_BUFFER_MAX_CAP_DERATE_PCT)] } {
    lappend arg_list -sink_buffer_max_cap_derate [expr $::env(CTS_SINK_BUFFER_MAX_CAP_DERATE_PCT) / 100.0]
}

if { [info exists ::env(CTS_DELAY_BUFFER_DERATE_PCT)] } {
    lappend arg_list -delay_buffer_derate [expr $::env(CTS_DELAY_BUFFER_DERATE_PCT) / 100]
}

log_cmd clock_tree_synthesis {*}$arg_list

set_propagated_clock [all_clocks]

estimate_parasitics -placement
puts "\[INFO\] Repairing long wires on clock nets…"
# CTS leaves a long wire from the pad to the clock tree root.
repair_clock_nets -max_wire_length $::env(CTS_CLK_MAX_WIRE_LENGTH)

estimate_parasitics -placement

puts "\[INFO\] Legalizing…"
source ${PNR_DIR}/tcl/dpl.tcl
estimate_parasitics -placement

report_cts -out_file $OUTPUTS/cts.rpt
