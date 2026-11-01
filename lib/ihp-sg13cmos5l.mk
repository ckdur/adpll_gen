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

# ISF phase noise: periods of ~3.5 ns and edges of ~100 ps at the test codes, so 64 phases, an injection
# every 2 periods, a 5 ps maximum step and 4x the charge (the shifts stay >> the edge error printed by
# isf_phase_noise.py). About 4x faster than the defaults (each run is ~800 BSIM4/PSP devices)
ISF_NPHASE?=64
ISF_NPER?=2
ISF_TMAX?=5p
ISF_DQ?=200e-18

# The DCO decks of the ISF analysis are identical to the ones of ihp-sg13g2 (cell names apart), and so
# are the model files (only the compiled PSP103 OSDI differs; every characterization agrees to 6 digits):
# the ISF result of ihp-sg13g2 is reused (each run takes ~2 h with PSP). Empty it to run the ISF here.
ISF_FROM_PDK?=ihp-sg13g2

PDK_FILE?=none
