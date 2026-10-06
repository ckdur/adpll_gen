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
set GDSS "${PDK_ROOT}/${PDK}/libs.ref/ics55_LLSC_H7CR/gds/ics55_LLSC_H7CR.gds ${PDK_ROOT}/${PDK}/libs.ref/ICsprout_55LLULP1233_IO_251013/gds/ICSIOA_N55_3P3_1P6M1TM.gds"
set CDLS "${PDK_ROOT}/${PDK}/libs.ref/ics55_LLSC_H7CR/cdl/ics55_LLSC_H7CR.cdl ${PDK_ROOT}/${PDK}/libs.ref/ICsprout_55LLULP1233_IO_251013/cdl/ICSIOA_N55_3P3.cdl"
set SPICES "${PDK_ROOT}/${PDK}/libs.ref/ics55_LLSC_H7CR/spice/ics55_LLSC_H7CR.spice"
# ${PDK_ROOT}/${PDK}/libs.ref/ICsprout_55LLULP1233_IO_251013/spice/ICSIOA_N55_3P3.spice not available yet

# TODO: Do the characterization of the lib
set LIBS_BC "${PDK_ROOT}/${PDK}/libs.ref/ics55_LLSC_H7CR/liberty/ics55_LLSC_H7CR_ff_rcbest_1p32_m40_nldm.lib ${PDK_ROOT}/${PDK}/libs.ref/ICsprout_55LLULP1233_IO_251013/liberty/ICSIOA_N55_3P3_ff_1p32_3p63_m40c.lib"
set LIBS_WC "${PDK_ROOT}/${PDK}/libs.ref/ics55_LLSC_H7CR/liberty/ics55_LLSC_H7CR_ss_rcworst_1p08_125_nldm.lib ${PDK_ROOT}/${PDK}/libs.ref/ICsprout_55LLULP1233_IO_251013/liberty/ICSIOA_N55_3P3_ss_1p08_2p97_125c.lib"

set RCX_RULES "${PDK_ROOT}/${PDK}/libs.tech/librelane/ics55_LLSC_H7CR/rcx.rules"

set techsite "CoreSite"
set techname "${PDK}"
