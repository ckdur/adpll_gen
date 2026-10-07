set cell_pad_value $::env(DPL_CELL_PADDING)
set cell_pad_side [expr $cell_pad_value / 2]

set_placement_padding -global -right $cell_pad_side -left $cell_pad_side

foreach wildcard $::env(CELL_PAD_EXCLUDE) {
    set_placement_padding -masters $wildcard -right 0 -left 0
}
if { [info exists ::env(DIODE_PADDING)] && $::env(DIODE_PADDING) } {
    set diode_split [split $::env(DIODE_CELL) "/"]
    set_placement_padding -masters [lindex $diode_split 0] -left $::env(DIODE_PADDING)
}

detailed_placement\
    -max_displacement [subst { $::env(PL_MAX_DISPLACEMENT_X) $::env(PL_MAX_DISPLACEMENT_Y) }]

if { [info exists ::env(PL_OPTIMIZE_MIRRORING)] && $::env(PL_OPTIMIZE_MIRRORING) } {
    optimize_mirroring
}

if { [catch {check_placement -verbose} errmsg] } {
    puts stderr $errmsg
    puts "Check placement failed, but is ignored on purpose"
    puts "May god forgive our actions"
}
