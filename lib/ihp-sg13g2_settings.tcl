if { [info exists ::env(PDK_ROOT)]} {
  # Setting a default
  set PDK_ROOT $::env(PDK_ROOT)
} else {
  # Setting a default
  set PDK_ROOT "/opt/ext/OpenPDKs"
}

set ROOT_DIR $env(ROOT_DIR)
set LIB_PATHS "${PDK_ROOT}/ihp-sg13g2/libs.ref/sg13g2_stdcell/lib ${PDK_ROOT}/ihp-sg13g2/libs.ref/sg13g2_io/lib"
set LIBS "${PDK_ROOT}/ihp-sg13g2/libs.ref/sg13g2_stdcell/lib/sg13g2_stdcell_typ_1p20V_25C.lib ${PDK_ROOT}/ihp-sg13g2/libs.ref/sg13g2_io/lib/sg13g2_io_typ_1p2V_3p3V_25C.lib"
set LEFS "${PDK_ROOT}/ihp-sg13g2/libs.ref/sg13g2_stdcell/lef/sg13g2_tech.lef ${PDK_ROOT}/ihp-sg13g2/libs.ref/sg13g2_stdcell/lef/sg13g2_stdcell.lef ${PDK_ROOT}/ihp-sg13g2/libs.ref/sg13g2_io/lef/sg13g2_io.lef"
set GDSS "${PDK_ROOT}/ihp-sg13g2/libs.ref/sg13g2_stdcell/gds/sg13g2_stdcell.gds ${PDK_ROOT}/ihp-sg13g2/libs.ref/sg13g2_io/gds/sg13g2_io.gds"
set CDLS "${PDK_ROOT}/ihp-sg13g2/libs.ref/sg13g2_stdcell/cdl/sg13g2_stdcell.cdl ${PDK_ROOT}/ihp-sg13g2/libs.ref/sg13g2_io/cdl/sg13g2_io.cdl"
set SPICES "${PDK_ROOT}/ihp-sg13g2/libs.ref/sg13g2_stdcell/spice/sg13g2_stdcell.spice ${PDK_ROOT}/ihp-sg13g2/libs.ref/sg13g2_io/spice/sg13g2_io.spi"

# TODO: Do the characterization of the lib
set LIBS_BC "${PDK_ROOT}/ihp-sg13g2/libs.ref/sg13g2_stdcell/lib/sg13g2_stdcell_fast_1p65V_m40C.lib ${PDK_ROOT}/ihp-sg13g2/libs.ref/sg13g2_io/lib/sg13g2_io_fast_1p65V_3p6V_m40C.lib"
set LIBS_WC "${PDK_ROOT}/ihp-sg13g2/libs.ref/sg13g2_stdcell/lib/sg13g2_stdcell_slow_1p08V_125C.lib ${PDK_ROOT}/ihp-sg13g2/libs.ref/sg13g2_io/lib/sg13g2_io_slow_1p08V_3p0V_125C.lib"

set RCX_RULES "${PDK_ROOT}/ihp-sg13g2/libs.tech/librelane/openrcx/IHP_rcx_patterns.rules"

set techsite "CoreSite"
set techname "ihp-sg13g2"

set BUFCells [list sg13g2_buf_1 sg13g2_buf_16 sg13g2_buf_2 sg13g2_buf_4 sg13g2_buf_8]
set INVCells [list sg13g2_inv_1 sg13g2_inv_16 sg13g2_inv_2 sg13g2_inv_4 sg13g2_inv_8]
set FILLERCells [list sg13g2_fill_1 sg13g2_fill_2 sg13g2_fill_4 sg13g2_fill_8]
set TAPCells [list ]
set DCAPCells [list sg13g2_decap_4 sg13g2_decap_8]
set DIODECells [list sg13g2_antennanp]

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
