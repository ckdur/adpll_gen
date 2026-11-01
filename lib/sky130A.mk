# SkyWater SKY130 (sky130A open PDK): 1.8 V core, BSIM4, sky130_fd_sc_hd standard cells
PDK_ROOT?=$(firstword $(wildcard /opt/ext/OpenPDKs) /usr/local/share/OpenPDKs)

define PDK_MODELS_INC
.LIB "$(PDK_ROOT)/sky130A/libs.tech/ngspice/sky130.lib.spice" tt
.INCLUDE "$(PDK_ROOT)/sky130A/libs.ref/sky130_fd_sc_hd/spice/sky130_fd_sc_hd.spice"
.PARAM lvdd=1.8
* Load used by the testbenches (same mapping as in pll_cells_sky130A.v)
.SUBCKT PLL_CELL_BUFFX0 VDD VSS I Z
Ximpl I VSS VSS VDD VDD Z sky130_fd_sc_hd__buf_1
.ENDS
endef

# Same options as the spinit of the PDK
define PDK_SPICEINIT
set ngbehavior=hsa
set skywaterpdk
set ng_nomodcheck
set num_threads=$(NGSPICE_THREADS)
endef

CELLS_SRC=$(PDK_ROOT)/sky130A/libs.ref/sky130_fd_sc_hd/verilog/primitives.v $(PDK_ROOT)/sky130A/libs.ref/sky130_fd_sc_hd/verilog/sky130_fd_sc_hd.v
CELLS_ADD_DEF=-D FUNCTIONAL=1 -D UNIT_DELAY=\#1

# Design target: 50 MHz reference (a slow technology: N up to ~12 in the supported band)
PLL_F_REF?=50e6

# ISF phase noise: periods of ~3.5 ns and edges of ~100 ps at the test codes, so 64 phases, an injection
# every 2 periods, a 5 ps maximum step and 4x the charge (the shifts stay >> the edge error printed by
# isf_phase_noise.py). About 4x faster than the defaults (each run is ~800 BSIM4/PSP devices)
ISF_NPHASE?=64
ISF_NPER?=2
ISF_TMAX?=5p
ISF_DQ?=200e-18

PDK_FILE?=none
