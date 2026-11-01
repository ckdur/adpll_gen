# ICsprout 55 nm (ics55): 1.2 V, BSIM4 (HSPICE-format libraries)
PDK_ROOT?=$(HOME)/Documents/SymbioticEDA/ics55/icsprout55-pdk

define PDK_MODELS_INC
.LIB "$(PDK_ROOT)/$(PDK)/libs.tech/ngspice/ICsprout_55LLULP1225_V1p1_hsp.lib" tt_mos
.INCLUDE "$(PDK_ROOT)/$(PDK)/libs.ref/ics55_LLSC_H7CR/spice/ics55_LLSC_H7CR.spice"
.PARAM lvdd=1.2
* Load used by the testbenches (same mapping as in pll_cells_ics55.v)
.SUBCKT PLL_CELL_BUFFX0 VDD VSS I Z
Ximpl I VDD VSS Z BUFX0P5H7R
.ENDS
endef

define PDK_SPICEINIT
set ngbehavior=hsa
set num_threads=$(NGSPICE_THREADS)
endef

# Gate-level models (post-synthesis simulations). "functional" removes the specify delays
CELLS_SRC=$(PDK_ROOT)/$(PDK)/libs.ref/ics55_LLSC_H7CR/verilog/ics55_LLSC_H7CR.v $(PDK_ROOT)/$(PDK)/libs.ref/ICsprout_55LLULP1233_IO_251013/verilog/icsIOA_N55_3P3.v
CELLS_ADD_DEF=-D functional=1

# Design target (src/pll_target.py): the reference design of the repository, 1 GHz
PLL_FCW?=8
PLL_KP?=3967
PLL_KI?=257

#PDK_FILE ?= $(PDK_ROOT)/$(PDK)/libs.tech/magic/$(PDK).magicrc
PDK_FILE?=none
PDK_KLAYOUT_TECHFILE?=$(PDK_ROOT)/$(PDK)/libs.tech/klayout/tech/ics55.lyt
PDK_KLAYOUT_MAPFILE?=$(PDK_ROOT)/$(PDK)/libs.tech/klayout/tech/ics55.map
LEFS?=$(PDK_ROOT)/$(PDK)/libs.tech/librelane/N551P6M_ecos.lef $(PDK_ROOT)/$(PDK)/libs.ref/ics55_LLSC_H7CR/lef/ics55_LLSC_H7CR_ecos.lef $(PDK_ROOT)/$(PDK)/libs.ref/ICsprout_55LLULP1233_IO_251013/lef/ICSIOA_N55_3P3_1P6M1TM_ecos.lef
GDSS?=$(PDK_ROOT)/$(PDK)/libs.ref/ics55_LLSC_H7CR/gds/ics55_LLSC_H7CR.gds $(PDK_ROOT)/$(PDK)/libs.ref/ICsprout_55LLULP1233_IO_251013/gds/ICSIOA_N55_3P3_1P6M1TM.gds
