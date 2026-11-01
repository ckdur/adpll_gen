# ICsprout 55 nm (ics55): 1.2 V, BSIM4 (HSPICE-format libraries)
PDK_ROOT?=$(HOME)/Documents/SymbioticEDA/ics55/icsprout55-pdk
# Standard cell library: SCL (settings.mk), ics55_LLSC_H7CR (default) or ICsprout55_9TSVT_basic
SCL_DIR=$(PDK_ROOT)/$(PDK)/libs.ref/$(SCL)
IO_DIR=$(PDK_ROOT)/$(PDK)/libs.ref/ICsprout_55LLULP1233_IO_251013

ifeq ($(SCL),ics55_LLSC_H7CR)
# Cell SPICE subcircuit and the instance line of the testbench load (PLL_CELL_BUFFX0)
SCL_SPICE=$(SCL_DIR)/spice/$(SCL).spice
SCL_BUFFX0=Ximpl I VDD VSS Z BUFX0P5H7R
# The _ecos cell LEF has the signal pins on MET2 (+ VIA1), which only the _M2 GDS has.
# (The plain MET1-pin LEF/GDS leaves some pins without access points in OpenROAD)
SCL_LEF=$(SCL_DIR)/lef/$(SCL)_ecos.lef
SCL_GDS=$(SCL_DIR)/gds/$(SCL)_M2.gds
else ifeq ($(SCL),ICsprout55_9TSVT_basic)
PLL_CELLS_V=$(ROOT_DIR)/src/pll_cells_$(SCL).v
# Every cell has the well bias pins VNW / VPW, tied to the supplies here
SCL_SPICE=$(SCL_DIR)/spice/$(SCL).spice
SCL_BUFFX0=Ximpl I VDD VSS Z VDD VSS BUFX0P5_9TSVT
# A single cell LEF / GDS pair, with the signal pins on MET1
SCL_LEF=$(SCL_DIR)/lef/$(SCL).lef
SCL_GDS=$(SCL_DIR)/gds/$(SCL).gds
else
$(error Unknown standard cell library SCL=$(SCL) for $(PDK))
endif

define PDK_MODELS_INC
.LIB "$(PDK_ROOT)/$(PDK)/libs.tech/ngspice/ICsprout_55LLULP1225_V1p1_hsp.lib" tt_mos
.INCLUDE "$(SCL_SPICE)"
.PARAM lvdd=1.2
* Load used by the testbenches (same mapping as in $(notdir $(PLL_CELLS_V)))
.SUBCKT PLL_CELL_BUFFX0 VDD VSS I Z
$(SCL_BUFFX0)
.ENDS
endef

define PDK_SPICEINIT
set ngbehavior=hsa
set num_threads=$(NGSPICE_THREADS)
endef

# Gate-level models (post-synthesis simulations). "functional" removes the specify delays
CELLS_SRC=$(SCL_DIR)/verilog/$(SCL).v $(IO_DIR)/verilog/icsIOA_N55_3P3.v
CELLS_ADD_DEF=-D functional=1

# Design target (src/pll_target.py): the reference design of the repository, 1 GHz
PLL_FCW?=8
PLL_KP?=3967
PLL_KI?=257

#PDK_FILE ?= $(PDK_ROOT)/$(PDK)/libs.tech/magic/$(PDK).magicrc
PDK_FILE?=none
PDK_KLAYOUT_TECHFILE?=$(PDK_ROOT)/$(PDK)/libs.tech/klayout/tech/ics55.lyt
PDK_KLAYOUT_MAPFILE?=$(PDK_ROOT)/$(PDK)/libs.tech/klayout/tech/ics55.map
LEFS?=$(PDK_ROOT)/$(PDK)/libs.tech/librelane/N551P6M_ecos.lef $(SCL_LEF) $(IO_DIR)/lef/ICSIOA_N55_3P3_1P6M1TM_ecos.lef
GDSS?=$(SCL_GDS) $(IO_DIR)/gds/ICSIOA_N55_3P3_1P6M1TM.gds
# Cell netlists for the LVS schematic (pnr writes only the top subcircuit)
CDLS?=$(SCL_DIR)/cdl/$(SCL).cdl $(IO_DIR)/cdl/ICSIOA_N55_3P3.cdl
