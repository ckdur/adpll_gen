# IHP SG13CMOS5L 130 nm CMOS, 5 metals (open PDK): 1.2 V core, PSP103 (OSDI). Same devices and
# standard-cell topology as SG13G2 (cells prefixed sg13cmos5l_). Only installed in the docker image.
PDK_ROOT?=$(if $(wildcard /opt/ext/OpenPDKs/ihp-sg13cmos5l),/opt/ext/OpenPDKs,/usr/local/share/OpenPDKs)

define PDK_MODELS_INC
.LIB "$(PDK_ROOT)/ihp-sg13cmos5l/libs.tech/ngspice/models/cornerMOSlv.lib" mos_tt
.INCLUDE "$(PDK_ROOT)/ihp-sg13cmos5l/libs.ref/sg13cmos5l_stdcell/spice/sg13cmos5l_stdcell.spice"
.PARAM lvdd=1.2
* Load used by the testbenches (same mapping as in pll_cells_ihp-sg13cmos5l.v)
.SUBCKT PLL_CELL_BUFFX0 VDD VSS I Z
Ximpl Z I VDD VSS sg13cmos5l_buf_1
.ENDS
endef

define PDK_SPICEINIT
set num_threads=$(NGSPICE_THREADS)
osdi '$(PDK_ROOT)/ihp-sg13cmos5l/libs.tech/ngspice/osdi/psp103.osdi'
osdi '$(PDK_ROOT)/ihp-sg13cmos5l/libs.tech/ngspice/osdi/psp103_nqs.osdi'
osdi '$(PDK_ROOT)/ihp-sg13cmos5l/libs.tech/ngspice/osdi/r3_cmc.osdi'
osdi '$(PDK_ROOT)/ihp-sg13cmos5l/libs.tech/ngspice/osdi/mosvar.osdi'
endef

CELLS_SRC=$(PDK_ROOT)/ihp-sg13cmos5l/libs.ref/sg13cmos5l_stdcell/verilog/sg13cmos5l_udp.v $(PDK_ROOT)/ihp-sg13cmos5l/libs.ref/sg13cmos5l_stdcell/verilog/sg13cmos5l_stdcell.v
CELLS_ADD_DEF=-D FUNCTIONAL=1

PDK_FILE?=none
