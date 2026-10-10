if { [info exists ::env(PDK_ROOT)]} {
  # Setting a default
  set PDK_ROOT $::env(PDK_ROOT)
} else {
  # Setting a default
  set PDK_ROOT "$::env(HOME)/Documents/SymbioticEDA/ics55/icsprout55-pdk"
}

if { [info exists ::env(PDK)]} {
  # Setting a default
  set PDK $::env(PDK)
} else {
  # Setting a default
  set PDK "ics55"
}

# Standard cell library (SCL in settings.mk)
if { [info exists ::env(STD_CELL_LIBRARY)] } {
  set SCL $::env(STD_CELL_LIBRARY)
} else {
  set SCL "ics55_LLSC_H7CR"
}

set ROOT_DIR $env(ROOT_DIR)
set SCL_DIR "${PDK_ROOT}/${PDK}/libs.ref/${SCL}"
set IO_DIR "${PDK_ROOT}/${PDK}/libs.ref/ICsprout_55LLULP1233_IO_251013"

if { $SCL == "ics55_LLSC_H7CR" } {
  set SCL_LIB "${SCL_DIR}/liberty/${SCL}_typ_tt_1p2_25_nldm.lib"
  set SCL_LIB_BC "${SCL_DIR}/liberty/${SCL}_ff_rcbest_1p32_m40_nldm.lib"
  set SCL_LIB_WC "${SCL_DIR}/liberty/${SCL}_ss_rcworst_1p08_125_nldm.lib"
  # The _ecos cell LEF has the signal pins on MET2 (+ VIA1), which only the _M2 GDS has
  set SCL_LEF "${SCL_DIR}/lef/${SCL}_ecos.lef"
  set SCL_GDS "${SCL_DIR}/gds/${SCL}_M2.gds"
  set libdbname "${SCL}_ecos"
} elseif { $SCL == "ICsprout55_9TSVT_basic" } {
  # The liberty files are named without the "_basic", which comes after the corner
  set lib_base [regsub {_basic$} $SCL ""]
  set SCL_LIB "${SCL_DIR}/liberty/${lib_base}_tt_v1p2_25c_basic_nldm.lib"
  set SCL_LIB_BC "${SCL_DIR}/liberty/${lib_base}_ff_v1p32_-40c_basic_nldm.lib"
  set SCL_LIB_WC "${SCL_DIR}/liberty/${lib_base}_ss_v1p08_125c_basic_nldm.lib"
  # A single cell LEF / GDS pair, with the signal pins on MET1
  set SCL_LEF "${SCL_DIR}/lef/${SCL}.lef"
  set SCL_GDS "${SCL_DIR}/gds/${SCL}.gds"
  set libdbname "${SCL}"
} else {
  error "Unknown standard cell library $SCL for ics55"
}

set LIB_PATHS "${SCL_DIR}/liberty ${IO_DIR}/liberty"
set LIBS "${SCL_LIB} ${IO_DIR}/liberty/ICSIOA_N55_3P3_tt_1p2_3p3_25c.lib"
set LEFS "${PDK_ROOT}/${PDK}/libs.tech/librelane/N551P6M_ecos.lef ${SCL_LEF} ${IO_DIR}/lef/ICSIOA_N55_3P3_1P6M1TM_ecos.lef"
set GDSS "${SCL_GDS} ${IO_DIR}/gds/ICSIOA_N55_3P3_1P6M1TM.gds"
set CDLS "${SCL_DIR}/cdl/${SCL}.cdl ${IO_DIR}/cdl/ICSIOA_N55_3P3.cdl"
set SPICES "${SCL_DIR}/spice/${SCL}.spice"
# ${IO_DIR}/spice/ICSIOA_N55_3P3.spice not available yet

# TODO: Do the characterization of the lib
set LIBS_BC "${SCL_LIB_BC} ${IO_DIR}/liberty/ICSIOA_N55_3P3_ff_1p32_3p63_m40c.lib"
set LIBS_WC "${SCL_LIB_WC} ${IO_DIR}/liberty/ICSIOA_N55_3P3_ss_1p08_2p97_125c.lib"

set RCX_RULES "${PDK_ROOT}/${PDK}/libs.tech/librelane/${SCL}/rcx.rules"

set techname "${PDK}"
set techdbname "N551P6M_ecos"

####################################
## Cells declaration
####################################

if { $SCL == "ics55_LLSC_H7CR" } {
  set techsite "core7"
  set BUFCells [list BUFX0P5H7R BUFX0P7H7R BUFX10H7R BUFX12H7R \
  BUFX16H7R BUFX1H7R BUFX1P4H7R BUFX20H7R BUFX2H7R BUFX2P5H7R \
  BUFX3H7R BUFX3P5H7R BUFX4H7R BUFX5H7R BUFX6H7R BUFX7H7R \
  BUFX8H7R]
  set INVCells [list INVX0P5H7R INVX0P7H7R INVX10H7R INVX12H7R \
  INVX16H7R INVX1H7R INVX1P4H7R INVX20H7R INVX2H7R INVX2P5H7R \
  INVX3H7R INVX3P5H7R INVX4H7R INVX5H7R INVX6H7R INVX7H7R \
  INVX8H7R]
  set FILLERCells [list FILLER16H7R FILLER1H7R FILLER2H7R FILLER32H7R \
  FILLER4H7R FILLER64H7R FILLER8H7R]
  set TAPCells [list FILLTAPH7R]
  set DCAPCells [list FILLCAP16H7R FILLCAP32H7R FILLCAP4H7R FILLCAP8H7R]
  set DIODECells [list ]

  # Layers where the PDN rail vias (one row of cuts on the MET1 rails) must keep the long enclosure
  # along the rail: pdngen puts it across (0.17 tall MET2 pads, 0.095 from the MET2 of the cells, M2_S_1)
  set PDN_RAIL_VIA_LAYERS [list MET2]
} else {
  # The 9-track libraries: same cells in every Vt flavour, only the suffix changes
  regexp {^ICsprout55(_9T[A-Z]+)_basic$} $SCL -> sfx
  set techsite "SC9T_site"
  set BUFCells [lmap x {0P5 1 2 3 4 5 6 8 10 12 16 24} {string cat BUFX $x $sfx}]
  set INVCells [lmap x {0P5 1 2 3 4 5 6 8 10 12 16 24} {string cat INVX $x $sfx}]
  set FILLERCells [lmap x {1 2 4 8 16 32} {string cat FILL $x $sfx}]
  # TAPX1 ties the wells to VDD / VSS (TAPVNPWX1 brings them out for separate biasing)
  set TAPCells [list TAPX1${sfx}]
  set DCAPCells [lmap x {4 8 16 32} {string cat FILLCAP $x $sfx}]
  set DIODECells [list ANTENNAX1${sfx}]

  # These libraries define DIODE_CELL, so the detailed routing repairs antennas (librelane defaults)
  set ::env(DRT_ANTENNA_REPAIR_ITERS) 3
  set ::env(DRT_ANTENNA_REPAIR_JUMPER_ONLY) 0
  set ::env(GRT_ANTENNA_REPAIR_MARGIN) 10
}

proc make_routing {} {
  make_tracks MET1 -x_offset 0.0 -x_pitch 0.2 -y_offset 0.0 -y_pitch 0.2
  make_tracks MET2 -x_offset 0.0 -x_pitch 0.2 -y_offset 0.0 -y_pitch 0.2
  make_tracks MET3 -x_offset 0.0 -x_pitch 0.2 -y_offset 0.0 -y_pitch 0.2
  make_tracks MET4 -x_offset 0.0 -x_pitch 0.2 -y_offset 0.0 -y_pitch 0.2
  make_tracks MET5 -x_offset 0.0 -x_pitch 0.2 -y_offset 0.0 -y_pitch 0.2
  make_tracks T4M2 -x_offset 0.0 -x_pitch 0.8 -y_offset 0.0 -y_pitch 0.8
  make_tracks RDL  -x_offset 0.0 -x_pitch 5.0 -y_offset 0.0 -y_pitch 5.0
}

# Additional librelane-related stuff
set ::env(PDN_ENABLE_RAILS) 1
set ::env(PDN_ENABLE_PINS) 1
set ::env(PDN_EXTEND_TO) "boundary"
set ::env(PDN_CORE_RING_ALLOW_OUT_OF_DIE) 1
set ::env(PDN_CORE_RING_CONNECT_TO_PADS) 0
set ::env(PDN_ENABLE_GLOBAL_CONNECTIONS) 1
set ::env(PL_SKIP_INITIAL_PLACEMENT) 0
set ::env(PL_WIRE_LENGTH_COEF) 0.25
set ::env(PL_MAX_DISPLACEMENT_X) 500
set ::env(PL_MAX_DISPLACEMENT_Y) 100
set ::env(GRT_ADJUSTMENT) 0.3
set ::env(SET_RC_VERBOSE) 0
set ::env(CLOCK_NET) "REF"
set ::env(CTS_DISTANCE_BETWEEN_BUFFERS) 0
set ::env(CTS_CLK_MAX_WIRE_LENGTH) 0
set ::env(DRT_THREADS) 1
set ::env(DRT_SAVE_SNAPSHOTS) 0
set ::env(DRT_OPT_ITERS) 64
set ::env(RCX_MERGE_VIA_WIRE_RES) 1
