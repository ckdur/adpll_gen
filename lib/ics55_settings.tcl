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

set ROOT_DIR $env(ROOT_DIR)
set LIB_PATHS "${PDK_ROOT}/${PDK}/libs.ref/ics55_LLSC_H7CR/liberty ${PDK_ROOT}/${PDK}/libs.ref/ICsprout_55LLULP1233_IO_251013/liberty"
set LIBS "${PDK_ROOT}/${PDK}/libs.ref/ics55_LLSC_H7CR/liberty/ics55_LLSC_H7CR_typ_tt_1p2_25_nldm.lib ${PDK_ROOT}/${PDK}/libs.ref/ICsprout_55LLULP1233_IO_251013/liberty/ICSIOA_N55_3P3_tt_1p2_3p3_25c.lib"
set LEFS "${PDK_ROOT}/${PDK}/libs.tech/librelane/N551P6M_ecos.lef ${PDK_ROOT}/${PDK}/libs.ref/ics55_LLSC_H7CR/lef/ics55_LLSC_H7CR_ecos.lef ${PDK_ROOT}/${PDK}/libs.ref/ICsprout_55LLULP1233_IO_251013/lef/ICSIOA_N55_3P3_1P6M1TM_ecos.lef"
set GDSS "${PDK_ROOT}/${PDK}/libs.ref/ics55_LLSC_H7CR/gds/ics55_LLSC_H7CR_M2.gds ${PDK_ROOT}/${PDK}/libs.ref/ICsprout_55LLULP1233_IO_251013/gds/ICSIOA_N55_3P3_1P6M1TM.gds"
set CDLS "${PDK_ROOT}/${PDK}/libs.ref/ics55_LLSC_H7CR/cdl/ics55_LLSC_H7CR.cdl ${PDK_ROOT}/${PDK}/libs.ref/ICsprout_55LLULP1233_IO_251013/cdl/ICSIOA_N55_3P3.cdl"
set SPICES "${PDK_ROOT}/${PDK}/libs.ref/ics55_LLSC_H7CR/spice/ics55_LLSC_H7CR.spice"
# ${PDK_ROOT}/${PDK}/libs.ref/ICsprout_55LLULP1233_IO_251013/spice/ICSIOA_N55_3P3.spice not available yet

# TODO: Do the characterization of the lib
set LIBS_BC "${PDK_ROOT}/${PDK}/libs.ref/ics55_LLSC_H7CR/liberty/ics55_LLSC_H7CR_ff_rcbest_1p32_m40_nldm.lib ${PDK_ROOT}/${PDK}/libs.ref/ICsprout_55LLULP1233_IO_251013/liberty/ICSIOA_N55_3P3_ff_1p32_3p63_m40c.lib"
set LIBS_WC "${PDK_ROOT}/${PDK}/libs.ref/ics55_LLSC_H7CR/liberty/ics55_LLSC_H7CR_ss_rcworst_1p08_125_nldm.lib ${PDK_ROOT}/${PDK}/libs.ref/ICsprout_55LLULP1233_IO_251013/liberty/ICSIOA_N55_3P3_ss_1p08_2p97_125c.lib"

set RCX_RULES "${PDK_ROOT}/${PDK}/libs.tech/librelane/rcx.rules"

set techsite "core7"
set techname "${PDK}"
set techdbname "N551P6M_ecos"
set libdbname "ics55_LLSC_H7CR_ecos"

####################################
## Cells declaration
####################################

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
