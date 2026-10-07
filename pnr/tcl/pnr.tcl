##############################################################################
## Preset global variables and attributes
##############################################################################
set TOP $env(TOP)
set SYN_DIR $env(SYN_DIR)
set SRC_DIR $env(SRC_DIR)
set PNR_DIR $env(PNR_DIR)
set PDK $env(PDK)
set X $env(X)
set Y $env(Y)

###############################################################
## Library setup
###############################################################
source $env(ROOT_DIR)/lib/$env(PDK)_settings.tcl
source $env(PDK_ROOT)/$env(PDK)/libs.tech/librelane/config.tcl
source $env(PDK_ROOT)/$env(PDK)/libs.tech/librelane/$::env(STD_CELL_LIBRARY)/config.tcl

# Override
set ::env(PDN_CORE_RING) 1

# We assume the first LIB is the standard cell lib
set LIBMAIN [lindex $LIBS 0]
set LIBBCMAIN [lindex $LIBS_BC 0]
set LIBWCMAIN [lindex $LIBS_WC 0]

# TODO: Figure out what is the actual set of commands work
define_corners typ
read_liberty -corner typ "$LIBMAIN"
read_liberty -min -corner typ "$LIBBCMAIN"
read_liberty -max -corner typ "$LIBWCMAIN"

# We assume the first LEF is the tech lef
set TECHLEF [lindex $LEFS 0]
set OTHERLEF [lrange $LEFS 1 end]

read_lef $TECHLEF
foreach LEFFILE $OTHERLEF {
  read_lef "$LEFFILE"
}

puts "Reading: $env(SYN_ANA_NET)"
read_verilog $env(SYN_ANA_NET)
puts "Reading: $env(SYN_NET)"
read_verilog $env(SYN_NET)
link_design ${TOP}

puts "SDC reading: ${TOP}.sdc.tcl"
read_sdc $SRC_DIR/${TOP}.sdc.tcl

unset_propagated_clock [all_clocks]

if {![file exists outputs/${PDK}]} {
  file mkdir ${PNR_DIR}/outputs
  file mkdir ${PNR_DIR}/outputs/${PDK}
  puts "Creating directory outputs"
}
if {![file exists reports/${PDK}]} {
  file mkdir ${PNR_DIR}/reports
  file mkdir ${PNR_DIR}/reports/${PDK}
  puts "Creating directory reports"
}

set OUTPUTS ${PNR_DIR}/outputs/${PDK}
set REPORTS ${PNR_DIR}/reports/${PDK}

####################################
## Floor Plan
####################################
set ::chip [[::ord::get_db] getChip]
set ::tech [[::ord::get_db] getTech]
set ::block [$::chip getBlock]
set dbu [$tech getDbUnitsPerMicron]

# TODO: Is there a way to extract from a command?
set siteobj [[[::ord::get_db] findLib ${techdbname}] findSite $::env(PLACE_SITE)]
set row   [::ord::dbu_to_microns [$siteobj getHeight]]
set track [::ord::dbu_to_microns [$siteobj getWidth]]
set pitch [expr 32*$row]
set ymargin [expr $::env(PDN_CORE_RING_VOFFSET) + 2*$::env(PDN_CORE_RING_VWIDTH) + 2*$::env(PDN_CORE_RING_VSPACING)]
set xmargin [expr $::env(PDN_CORE_RING_HOFFSET) + 2*$::env(PDN_CORE_RING_HWIDTH) + 2*$::env(PDN_CORE_RING_HSPACING)]


if {[info exists env(X)] && $::env(X) != ""} {
    set corearea "[expr $xmargin] [expr $ymargin] [expr $::env(X)-$xmargin] [expr $::env(Y)-$ymargin]"
    initialize_floorplan -site $::env(PLACE_SITE) -die_area "0 0 $::env(X) $::env(Y)" -core_area $corearea
} else {
    initialize_floorplan -utilization [expr 100.0*$::env(PR)] \
    -aspect_ratio [expr 1.0*$::env(PY)/$::env(PX)] \
    -core_space "$xmargin $ymargin $xmargin $ymargin" \
    -site $::env(PLACE_SITE) 
}

# Only add the global connection to the digitals
add_global_connection -net $::env(VDD_NET) -inst_pattern digital/.* -pin_pattern {^VDD$} -power
add_global_connection -net $::env(VDD_NET) -inst_pattern digital/.* -pin_pattern {^VSS$} -ground

global_connect -verbose

insert_tiecells $::env(SYNTH_TIELO_CELL) -prefix "TIE_ZERO_"
insert_tiecells $::env(SYNTH_TIEHI_CELL) -prefix "TIE_ONE_"

set die_area_obj [$::block getDieArea]
set core_area_obj [$::block getCoreArea]

set die_area [list [$die_area_obj xMin] [$die_area_obj yMin] [$die_area_obj xMax] [$die_area_obj yMax]]
set core_area [list [$core_area_obj xMin] [$core_area_obj yMin] [$core_area_obj xMax] [$core_area_obj yMax]]

set mgrid [$tech getManufacturingGrid]

set die_coords {}
set core_coords {}

foreach coord $die_area {
    lappend die_coords [::ord::dbu_to_microns $coord]
}
foreach coord $core_area {
    lappend core_coords [::ord::dbu_to_microns $coord]
}

# write out the floorplan size
set die_width [expr [lindex $die_coords 2] - [lindex $die_coords 0]]
set die_height [expr [lindex $die_coords 3] - [lindex $die_coords 1]]
set core_width [expr [lindex $core_coords 2] - [lindex $core_coords 0]]
set core_height [expr [lindex $core_coords 3] - [lindex $core_coords 1]]

set corex [lindex $core_coords 0]
set corey [lindex $core_coords 1]
set coreux [lindex $core_coords 2]
set coreuy [lindex $core_coords 3]

set FPsize   "\{$die_width $die_height\}"
set CoreSize "\{$core_width $core_height\}"
set fo [open FPlanFinal.size w]
puts $fo "Core size: \{X Y\} = ${CoreSize}"
puts $fo "Floorplan size: \{X Y\} = ${FPsize}"
close $fo

make_routing

####################################
## PLL placement
####################################

source ${PNR_DIR}/tcl/pll_pos.tcl

set well_w 0
if {[llength $TAPCells] > 0} {
    set tie_lib [[::ord::get_db] findLib $libdbname]
    set tie_master [$tie_lib findMaster [lindex $TAPCells 0]]
    set well_w [::ord::dbu_to_microns [$tie_master getWidth]]
}

# NOTE: The 1e-6 avoids losing a row/track when the division gives e.g. 52.99999
set Region_yur [expr $corey + floor(($core_height)/$row + 1e-6)*$row]
set Region_xur [expr $corex + floor(($core_width)/$track + 1e-6)*$track]
set RightWell_x [expr $Region_xur - $well_w - $track*3]

set st_y_analog [expr  $Region_yur - $row*3]
set st_x_analog $RightWell_x

lassign [pos_coarse $st_x_analog $st_y_analog 15] coarse_x coarse_y
lassign [pos_mid [expr $coarse_x - $track*2] [expr $coarse_y+$row] 15] mid_x mid_y
lassign [pos_fine [expr $mid_x - $track*2] $st_y_analog 31 15] fine_x fine_y
lassign [pos_balanced [expr $fine_x - $track*2] [expr $coarse_y+$row]] balanced_x balanced_y
lassign [pos_injection [expr $balanced_x - $track*2] [expr $coarse_y+$row] 4] inj_x inj_y

write_def $OUTPUTS/${TOP}.analog.def

####################################
## Power planning
####################################

# Copied from librelane
source ${PNR_DIR}/tcl/io.tcl
source ${PNR_DIR}/tcl/pdn.tcl

###################################
## Placement
####################################

source ${PNR_DIR}/tcl/pindef.tcl
# just to output an early lef
write_abstract_lef $OUTPUTS/${TOP}.early.lef

# Give the digital its own copy of the clocks shared with the analog (before gpl, so the buffers get placed)
source ${PNR_DIR}/tcl/clk_isolate.tcl
isolate_dig_clocks

source ${PNR_DIR}/tcl/gpl.tcl
source ${PNR_DIR}/tcl/dpl.tcl

####################################
# CTS
####################################

set_global_routing_layer_adjustment * $::env(GRT_ADJUSTMENT)

set array [split $::env(GRT_LAYER_ADJUSTMENTS) " "]

set layer_names [list]
set layers [$::tech getLayers]
foreach layer $layers {
    if { [$layer getRoutingLevel] >= 1 } {
        lappend layer_names [$layer getName]
    }
}

set i 0
foreach adjustment $array {
    set layer_name [lindex $layer_names $i]
    set_global_routing_layer_adjustment $layer_name $adjustment
    incr i
}

set signal_min_layer $::env(RT_MIN_LAYER)
set signal_max_layer $::env(RT_MAX_LAYER)
set clock_min_layer $::env(RT_MIN_LAYER)
set clock_max_layer $::env(RT_MAX_LAYER)

if { [info exists ::env(RT_CLOCK_MIN_LAYER)]} {
    set clock_min_layer $::env(RT_CLOCK_MIN_LAYER)
}
if { [info exists ::env(RT_CLOCK_MAX_LAYER)]} {
    set clock_max_layer $::env(RT_CLOCK_MAX_LAYER)
}

puts "\[INFO\] Setting signal min routing layer to: $signal_min_layer and clock min routing layer to $clock_min_layer. "
puts "\[INFO\] Setting signal max routing layer to: $signal_max_layer and clock max routing layer to $clock_max_layer. "

set_routing_layers -signal [subst $signal_min_layer]-[subst $signal_max_layer] -clock [subst $clock_min_layer]-[subst $clock_max_layer]

# CTS must not touch the analog cells nor the analog side of the clocks
protect_analog
source ${PNR_DIR}/tcl/cts.tcl


###############################################
# Global routing
###############################################
source ${PNR_DIR}/tcl/grt.tcl

###############################################
# Fillers
###############################################
set fill_list [list]
foreach {pattern} $::env(DECAP_CELLS) {
    set stripped [string map {' {}} $pattern]
    lappend fill_list $stripped
}
foreach {pattern} $::env(FILL_CELLS) {
    set stripped [string map {' {}} $pattern]
    lappend fill_list $stripped
}
puts $fill_list
filler_placement $fill_list

global_connect

###############################################
# Detail routing
###############################################
set ::env(STEP_DIR) $OUTPUTS/drt
source ${PNR_DIR}/tcl/drt.tcl

#################################################
# Metal fill
#################################################
# density_fill -rules $env(ROOT_DIR)/cells/$env(TECH)_fill.json

#################################################
## Write out final files
#################################################
# NOTE: Cannot extract parasitics
set rcx_flags ""
if { !$::env(RCX_MERGE_VIA_WIRE_RES) } {
    set rcx_flags "-no_merge_via_res"
}
define_process_corner -ext_model_index 0 CURRENT_CORNER
extract_parasitics $rcx_flags\
    -ext_model_file $RCX_RULES\
    -lef_res

write_db $OUTPUTS/${TOP}.final.db

write_verilog $OUTPUTS/${TOP}.v
write_verilog -include_pwr_gnd $OUTPUTS/${TOP}_pg.v
write_def $OUTPUTS/${TOP}.def
write_abstract_lef $OUTPUTS/${TOP}.lef
write_timing_model $OUTPUTS/${TOP}.lib
write_cdl -masters ${CDLS} $OUTPUTS/${TOP}.cdl
