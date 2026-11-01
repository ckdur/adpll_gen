if { [info exists ::env(PDK_ROOT)]} {
  set PDK_ROOT $::env(PDK_ROOT)
} else {
  set PDK_ROOT "/opt/ext/OpenPDKs"
}

set ROOT_DIR $env(ROOT_DIR)
set SC "${PDK_ROOT}/sky130A/libs.ref/sky130_fd_sc_hd"
set LIB_PATHS "${SC}/lib"
set LIBS "${SC}/lib/sky130_fd_sc_hd__tt_025C_1v80.lib"
set LEFS "${SC}/techlef/sky130_fd_sc_hd__nom.tlef ${SC}/lef/sky130_fd_sc_hd.lef"
set GDSS "${SC}/gds/sky130_fd_sc_hd.gds"
set CDLS "${SC}/cdl/sky130_fd_sc_hd.cdl"
set SPICES "${SC}/spice/sky130_fd_sc_hd.spice"

set LIBS_BC "${SC}/lib/sky130_fd_sc_hd__ff_n40C_1v95.lib"
set LIBS_WC "${SC}/lib/sky130_fd_sc_hd__ss_100C_1v60.lib"

set RCX_RULES "${PDK_ROOT}/sky130A/libs.tech/openlane/rules.openrcx.sky130A.nom.calibre"

# Supply pins of the standard cells (wells included), see syn/tcl/netlist.tcl
set POWER_PINS {^(VPWR|VPB)$}
set GROUND_PINS {^(VGND|VNB)$}

set techsite "unithd"
set techname "sky130A"

set BUFCells [list sky130_fd_sc_hd__buf_1 sky130_fd_sc_hd__buf_2 sky130_fd_sc_hd__buf_4 sky130_fd_sc_hd__buf_8 sky130_fd_sc_hd__buf_16]
set INVCells [list sky130_fd_sc_hd__inv_1 sky130_fd_sc_hd__inv_2 sky130_fd_sc_hd__inv_4 sky130_fd_sc_hd__inv_8 sky130_fd_sc_hd__inv_16]
set FILLERCells [list sky130_fd_sc_hd__fill_1 sky130_fd_sc_hd__fill_2 sky130_fd_sc_hd__fill_4 sky130_fd_sc_hd__fill_8]
set TAPCells [list sky130_fd_sc_hd__tapvpwrvgnd_1]
set DCAPCells [list sky130_fd_sc_hd__decap_3 sky130_fd_sc_hd__decap_4 sky130_fd_sc_hd__decap_6 sky130_fd_sc_hd__decap_8 sky130_fd_sc_hd__decap_12]
set DIODECells [list sky130_fd_sc_hd__diode_2]

proc make_routing {} {
  make_tracks li1  -x_offset 0.23 -x_pitch 0.46 -y_offset 0.17 -y_pitch 0.34
  make_tracks met1 -x_offset 0.17 -x_pitch 0.34 -y_offset 0.17 -y_pitch 0.34
  make_tracks met2 -x_offset 0.23 -x_pitch 0.46 -y_offset 0.23 -y_pitch 0.46
  make_tracks met3 -x_offset 0.34 -x_pitch 0.68 -y_offset 0.34 -y_pitch 0.68
  make_tracks met4 -x_offset 0.46 -x_pitch 0.92 -y_offset 0.46 -y_pitch 0.92
  make_tracks met5 -x_offset 1.70 -x_pitch 3.40 -y_offset 1.70 -y_pitch 3.40
}
