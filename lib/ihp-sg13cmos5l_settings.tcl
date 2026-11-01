if { [info exists ::env(PDK_ROOT)]} {
  # Setting a default
  set PDK_ROOT $::env(PDK_ROOT)
} else {
  # Setting a default
  set PDK_ROOT "/usr/local/share/OpenPDKs"
}

set ROOT_DIR $env(ROOT_DIR)
set LIB_PATHS "${PDK_ROOT}/ihp-sg13cmos5l/libs.ref/sg13cmos5l_stdcell/lib"
set LIBS "${PDK_ROOT}/ihp-sg13cmos5l/libs.ref/sg13cmos5l_stdcell/lib/sg13cmos5l_stdcell_typ_1p20V_25C.lib"
set LEFS "${PDK_ROOT}/ihp-sg13cmos5l/libs.ref/sg13cmos5l_stdcell/lef/sg13cmos5l_tech.lef ${PDK_ROOT}/ihp-sg13cmos5l/libs.ref/sg13cmos5l_stdcell/lef/sg13cmos5l_stdcell.lef"
set GDSS "${PDK_ROOT}/ihp-sg13cmos5l/libs.ref/sg13cmos5l_stdcell/gds/sg13cmos5l_stdcell.gds"
set CDLS "${PDK_ROOT}/ihp-sg13cmos5l/libs.ref/sg13cmos5l_stdcell/cdl/sg13cmos5l_stdcell.cdl"
# Only the standard cells (the PLL has no IO cells; the IO SPICE file name differs between PDK versions)
set SPICES "${PDK_ROOT}/ihp-sg13cmos5l/libs.ref/sg13cmos5l_stdcell/spice/sg13cmos5l_stdcell.spice"

# TODO: Do the characterization of the lib
set LIBS_BC "${PDK_ROOT}/ihp-sg13cmos5l/libs.ref/sg13cmos5l_stdcell/lib/sg13cmos5l_stdcell_fast_1p65V_m40C.lib"
set LIBS_WC "${PDK_ROOT}/ihp-sg13cmos5l/libs.ref/sg13cmos5l_stdcell/lib/sg13cmos5l_stdcell_slow_1p08V_125C.lib"

set RCX_RULES "${PDK_ROOT}/ihp-sg13cmos5l/libs.tech/librelane/openrcx/IHP_rcx_patterns.rules"

set techsite "CoreSite"
set techname "ihp-sg13cmos5l"

set BUFCells [list sg13cmos5l_buf_1 sg13cmos5l_buf_16 sg13cmos5l_buf_2 sg13cmos5l_buf_4 sg13cmos5l_buf_8]
set INVCells [list sg13cmos5l_inv_1 sg13cmos5l_inv_16 sg13cmos5l_inv_2 sg13cmos5l_inv_4 sg13cmos5l_inv_8]
set FILLERCells [list sg13cmos5l_fill_1 sg13cmos5l_fill_2 sg13cmos5l_fill_4 sg13cmos5l_fill_8]
set TAPCells [list ]
set DCAPCells [list sg13cmos5l_decap_4 sg13cmos5l_decap_8]
set DIODECells [list sg13cmos5l_antennanp]

proc make_routing {} {
  make_tracks Metal1 -x_offset 0.0  -x_pitch 0.48 -y_offset 0.0 -y_pitch  0.48
  make_tracks Metal2 -x_offset 0.0  -x_pitch 0.42 -y_offset 0.0 -y_pitch  0.42
  make_tracks Metal3 -x_offset 0.0  -x_pitch 0.48 -y_offset 0.0 -y_pitch  0.48
  make_tracks Metal4 -x_offset 0.0  -x_pitch 0.42 -y_offset 0.0 -y_pitch  0.42
  make_tracks Metal5 -x_offset 0.0  -x_pitch 3.48 -y_offset 0.0 -y_pitch  0.48
  make_tracks TopMetal1 -x_offset 1.46 -x_pitch 2.28 -y_offset 1.46 -y_pitch 2.28
  make_tracks TopMetal2 -x_offset 2.0  -x_pitch 4.0  -y_offset 2.0 -y_pitch 4.0
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
