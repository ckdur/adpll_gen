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

PDK_FILE?=none
PDK_KLAYOUT_TECHFILE?=$(PDK_ROOT)/$(PDK)/libs.tech/klayout/tech/sg13g2.lyt
PDK_KLAYOUT_MAPFILE?=$(PDK_ROOT)/$(PDK)/libs.tech/klayout/tech/sg13g2.map
