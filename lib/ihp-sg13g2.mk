# IHP SG13G2 130 nm BiCMOS (open PDK): 1.2 V core, PSP103 (OSDI)
# Use the local installation if present, otherwise the one inside the docker image
PDK_ROOT?=$(firstword $(wildcard /opt/ext/OpenPDKs) /usr/local/share/OpenPDKs)

define PDK_MODELS_INC
.LIB "$(PDK_ROOT)/ihp-sg13g2/libs.tech/ngspice/models/cornerMOSlv.lib" mos_tt
.INCLUDE "$(PDK_ROOT)/ihp-sg13g2/libs.ref/sg13g2_stdcell/spice/sg13g2_stdcell.spice"
.PARAM lvdd=1.2
* Load used by the testbenches (same mapping as in pll_cells_ihp-sg13g2.v)
.SUBCKT PLL_CELL_BUFFX0 VDD VSS I Z
Ximpl Z I VDD VSS sg13g2_buf_1
.ENDS
endef

# The PSP models are OSDI-compiled, so ngspice needs to load them
define PDK_SPICEINIT
set num_threads=$(NGSPICE_THREADS)
osdi '$(PDK_ROOT)/ihp-sg13g2/libs.tech/ngspice/osdi/psp103.osdi'
osdi '$(PDK_ROOT)/ihp-sg13g2/libs.tech/ngspice/osdi/psp103_nqs.osdi'
osdi '$(PDK_ROOT)/ihp-sg13g2/libs.tech/ngspice/osdi/r3_cmc.osdi'
osdi '$(PDK_ROOT)/ihp-sg13g2/libs.tech/ngspice/osdi/mosvar.osdi'
endef

CELLS_SRC=$(PDK_ROOT)/ihp-sg13g2/libs.ref/sg13g2_stdcell/verilog/sg13g2_udp.v $(PDK_ROOT)/ihp-sg13g2/libs.ref/sg13g2_stdcell/verilog/sg13g2_stdcell.v
CELLS_ADD_DEF=-D FUNCTIONAL=1

# ISF phase noise: periods of ~3.5 ns and edges of ~100 ps at the test codes, so 64 phases, an injection
# every 2 periods, a 5 ps maximum step and 4x the charge (the shifts stay >> the edge error printed by
# isf_phase_noise.py). About 4x faster than the defaults (each run is ~800 BSIM4/PSP devices)
ISF_NPHASE?=64
ISF_NPER?=2
ISF_TMAX?=5p
ISF_DQ?=200e-18

PDK_FILE?=none
PDK_KLAYOUT_TECHFILE?=$(PDK_ROOT)/$(PDK)/libs.tech/klayout/tech/sg13g2.lyt
PDK_KLAYOUT_MAPFILE?=$(PDK_ROOT)/$(PDK)/libs.tech/klayout/tech/sg13g2.map
LEFS?=$(PDK_ROOT)/$(PDK)/libs.ref/sg13g2_stdcell/lef/sg13g2_tech.lef $(PDK_ROOT)/$(PDK)/libs.ref/sg13g2_stdcell/lef/sg13g2_stdcell.lef $(PDK_ROOT)/$(PDK)/libs.ref/sg13g2_io/lef/sg13g2_io.lef
GDSS?=$(PDK_ROOT)/$(PDK)/libs.ref/sg13g2_stdcell/gds/sg13g2_stdcell.gds $(PDK_ROOT)/$(PDK)/libs.ref/sg13g2_io/gds/sg13g2_io.gds
# Cell netlists for the LVS schematic (pnr writes only the top subcircuit)
# No IO cells in the design (and KLayout cannot read the resistors of sg13g2_io.cdl)
CDLS?=$(PDK_ROOT)/$(PDK)/libs.ref/sg13g2_stdcell/cdl/sg13g2_stdcell.cdl
