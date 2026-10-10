#######################################################
# Proportional dimmentions
PX?=2
PY?=1
PR?=0.4

# Exact X and Y (superseeds proportional)
#X?=440
#Y?=235
#export X
#export Y

#######################################################
# Rules to create the files. 

# NOTE: the file sar_logic_1102.v is not included here. Is intended to be a blackbox from the analog
#TOP?=PLL
TOP?=pll
DIGTOP?=pll_logic
SYN_SRC?=$(ROOT_DIR)/src/pll.v \
	$(ROOT_DIR)/src/pll_analog.v \
	$(ROOT_DIR)/src/injection.v \
	$(ROOT_DIR)/src/ssbbpd.v \
	$(ROOT_DIR)/src/sym_mux.v \
	$(ROOT_DIR)/src/sym.v \
	$(ROOT_DIR)/src/il_dco.v \
	$(ROOT_DIR)/src/fine_delay.v \
	$(ROOT_DIR)/src/mid_delay.v \
	$(ROOT_DIR)/src/coarse_delay.v \
	$(ROOT_DIR)/src/pll_logic_bb.v
	

SYN_DIG_SRC=$(ROOT_DIR)/src/pll_logic.v \
	$(ROOT_DIR)/src/digital_loop_filter.v \
	$(ROOT_DIR)/src/term_decoder.v \
	$(ROOT_DIR)/src/freq_lock.v \
	$(ROOT_DIR)/src/delta_sigma.v \
	$(ROOT_DIR)/src/fix_div.v \
	$(ROOT_DIR)/src/conf_div.v

#######################################################
# Log file
LOGFILE=$(PRJ_ROOT)/$(TOP)_run.log

#######################################################
# Global settings for the technology in particular
#PDK?=ics55
PDK?=ihp-sg13g2

# Generated files are only replaced when their content changes, so editing this file
# does not re-run every simulation
update_if_changed=if cmp -s $(1).tmp $(1); then rm $(1).tmp; else mv $(1).tmp $(1); fi

# Standard cell library, only selectable in ics55:
#   ics55_LLSC_H7CR         7-track public library (default)
#   ICsprout55_9TSVT_basic  9-track private library (installed with the PDK when available)
ifeq ($(PDK),ics55)
SCL?=ics55_LLSC_H7CR
SCL_DEFAULT=ics55_LLSC_H7CR
# The LibreLane configs of the PDK read it from the environment
export STD_CELL_LIBRARY=$(SCL)
endif

# Every technology has its own outputs (SIM_DIR and SYN_DIR are defined by the including Makefile).
# A standard cell library other than the default one gets its own folder: outputs/<PDK>-<SCL>
TECH=$(PDK)$(if $(filter-out $(SCL_DEFAULT),$(SCL)),-$(SCL))
export TECH
SIM_OUT=$(SIM_DIR)/outputs/$(TECH)
SYN_OUT=$(SYN_DIR)/outputs/$(TECH)
PNR_OUT=$(PNR_DIR)/outputs/$(TECH)
SIGN_OUT=$(SIGN_DIR)/outputs/$(TECH)

SYN_ANA_NET=$(SYN_OUT)/$(TOP)_net.v
SYN_NET=$(SYN_OUT)/$(DIGTOP)_net.v

ifeq ($(PDK),ics55)
PDK_ROOT?=$(HOME)/Documents/SymbioticEDA/ics55/icsprout55-pdk
SCL_DIR=$(PDK_ROOT)/$(PDK)/libs.ref/$(SCL)
IO_DIR=$(PDK_ROOT)/$(PDK)/libs.ref/ICsprout_55LLULP1233_IO_251013

ifeq ($(SCL),ics55_LLSC_H7CR)
SYN_SRC+= $(ROOT_DIR)/src/pll_cells_ics55.v
# Cell SPICE subcircuit and the instance line of the testbench load (PLL_CELL_BUFFX0)
SCL_SPICE=$(SCL_DIR)/spice/$(SCL).spice
SCL_BUFFX0=Ximpl I VDD VSS Z BUFX0P5H7R
# The _ecos cell LEF has the signal pins on MET2 (+ VIA1), which only the _M2 GDS has.
# (The plain MET1-pin LEF/GDS leaves some pins without access points in OpenROAD)
SCL_LEF=$(SCL_DIR)/lef/$(SCL)_ecos.lef
SCL_GDS=$(SCL_DIR)/gds/$(SCL)_M2.gds
else ifeq ($(SCL),ICsprout55_9TSVT_basic)
SYN_SRC+= $(ROOT_DIR)/src/pll_cells_$(SCL).v
# Every cell has the well bias pins VNW / VPW, tied to the supplies here
SCL_SPICE=$(SCL_DIR)/spice/$(SCL).spice
SCL_BUFFX0=Ximpl I VDD VSS Z VDD VSS BUFX0P5_9TSVT
# A single cell LEF / GDS pair, with the signal pins on MET1
SCL_LEF=$(SCL_DIR)/lef/$(SCL).lef
SCL_GDS=$(SCL_DIR)/gds/$(SCL).gds
else
$(error Unknown standard cell library SCL=$(SCL) for $(PDK))
endif

$(SIM_OUT)/models.inc: $(ROOT_DIR)/settings.mk
	mkdir -p $(dir $@)
	@echo ".LIB \"$(PDK_ROOT)/$(PDK)/libs.tech/ngspice/ICsprout_55LLULP1225_V1p1_hsp.lib\" tt_mos" > $@.tmp
	@echo ".INCLUDE \"$(SCL_SPICE)\"" >> $@.tmp
	@echo ".PARAM lvdd=1.2" >> $@.tmp
	@echo "* Load used by the testbenches (same mapping as in the pll_cells_*.v of $(SCL))" >> $@.tmp
	@echo ".SUBCKT PLL_CELL_BUFFX0 VDD VSS I Z" >> $@.tmp
	@echo "$(SCL_BUFFX0)" >> $@.tmp
	@echo ".ENDS" >> $@.tmp
	@$(call update_if_changed,$@)

# ngspice settings for this PDK (.spiceinit next to the testbenches)
$(SIM_OUT)/.spiceinit: $(ROOT_DIR)/settings.mk
	mkdir -p $(dir $@)
	@echo "set ngbehavior=hsa" > $@.tmp
	@echo "set num_threads=$(NGSPICE_THREADS)" >> $@.tmp
	@$(call update_if_changed,$@)

CELLS_SRC=$(SCL_DIR)/verilog/$(SCL).v $(IO_DIR)/verilog/icsIOA_N55_3P3.v

#PDK_FILE ?= $(PDK_ROOT)/$(PDK)/libs.tech/magic/$(PDK).magicrc
PDK_FILE?=none
PDK_KLAYOUT_TECHFILE?=$(PDK_ROOT)/$(PDK)/libs.tech/klayout/tech/ics55.lyt
PDK_KLAYOUT_MAPFILE?=$(PDK_ROOT)/$(PDK)/libs.tech/klayout/tech/ics55.map
LEFS?=$(PDK_ROOT)/$(PDK)/libs.tech/librelane/N551P6M_ecos.lef $(SCL_LEF) $(IO_DIR)/lef/ICSIOA_N55_3P3_1P6M1TM_ecos.lef
GDSS?=$(SCL_GDS) $(IO_DIR)/gds/ICSIOA_N55_3P3_1P6M1TM.gds
# Cell netlists for the LVS schematic (pnr writes only the top subcircuit)
CDLS?=$(SCL_DIR)/cdl/$(SCL).cdl $(IO_DIR)/cdl/ICSIOA_N55_3P3.cdl
endif

ifeq ($(PDK),ihp-sg13g2)
# Use the local installation if present, otherwise the one inside the docker image
PDK_ROOT?=$(firstword $(wildcard /opt/ext/OpenPDKs) /usr/local/share/OpenPDKs)
SYN_SRC+= $(ROOT_DIR)/src/pll_cells_ihp-sg13g2.v

$(SIM_OUT)/models.inc: $(ROOT_DIR)/settings.mk
	mkdir -p $(dir $@)
	@echo ".LIB \"$(PDK_ROOT)/ihp-sg13g2/libs.tech/ngspice/models/cornerMOSlv.lib\" mos_tt" > $@.tmp
	@echo ".INCLUDE \"$(PDK_ROOT)/ihp-sg13g2/libs.ref/sg13g2_stdcell/spice/sg13g2_stdcell.spice\"" >> $@.tmp
	@echo ".PARAM lvdd=1.2" >> $@.tmp
	@echo "* Load used by the testbenches (same mapping as in pll_cells_ihp-sg13g2.v)" >> $@.tmp
	@echo ".SUBCKT PLL_CELL_BUFFX0 VDD VSS I Z" >> $@.tmp
	@echo "Ximpl Z I VDD VSS sg13g2_buf_1" >> $@.tmp
	@echo ".ENDS" >> $@.tmp
	@$(call update_if_changed,$@)

# ngspice settings for this PDK (.spiceinit next to the testbenches)
# The PSP models are OSDI-compiled, so ngspice needs to load them
$(SIM_OUT)/.spiceinit: $(ROOT_DIR)/settings.mk
	mkdir -p $(dir $@)
	@echo "set num_threads=$(NGSPICE_THREADS)" > $@.tmp
	@echo "osdi '$(PDK_ROOT)/ihp-sg13g2/libs.tech/ngspice/osdi/psp103.osdi'" >> $@.tmp
	@echo "osdi '$(PDK_ROOT)/ihp-sg13g2/libs.tech/ngspice/osdi/psp103_nqs.osdi'" >> $@.tmp
	@echo "osdi '$(PDK_ROOT)/ihp-sg13g2/libs.tech/ngspice/osdi/r3_cmc.osdi'" >> $@.tmp
	@echo "osdi '$(PDK_ROOT)/ihp-sg13g2/libs.tech/ngspice/osdi/mosvar.osdi'" >> $@.tmp
	@$(call update_if_changed,$@)

CELLS_SRC=$(PDK_ROOT)/ihp-sg13g2/libs.ref/sg13g2_stdcell/verilog/sg13g2_udp.v $(PDK_ROOT)/ihp-sg13g2/libs.ref/sg13g2_stdcell/verilog/sg13g2_stdcell.v

#PDK_FILE ?= $(PDK_ROOT)/$(PDK)/libs.tech/magic/$(PDK).magicrc
PDK_FILE?=none
PDK_KLAYOUT_TECHFILE?=$(PDK_ROOT)/$(PDK)/libs.tech/klayout/tech/sg13g2.lyt
PDK_KLAYOUT_MAPFILE?=$(PDK_ROOT)/$(PDK)/libs.tech/klayout/tech/sg13g2.map
LEFS?=$(PDK_ROOT)/$(PDK)/libs.ref/sg13g2_stdcell/lef/sg13g2_tech.lef $(PDK_ROOT)/$(PDK)/libs.ref/sg13g2_stdcell/lef/sg13g2_stdcell.lef $(PDK_ROOT)/$(PDK)/libs.ref/sg13g2_io/lef/sg13g2_io.lef
GDSS?=$(PDK_ROOT)/$(PDK)/libs.ref/sg13g2_stdcell/gds/sg13g2_stdcell.gds $(PDK_ROOT)/$(PDK)/libs.ref/sg13g2_io/gds/sg13g2_io.gds
# Cell netlists for the LVS schematic (pnr writes only the top subcircuit)
# No IO cells in the design (and KLayout cannot read the resistors of sg13g2_io.cdl)
CDLS?=$(PDK_ROOT)/$(PDK)/libs.ref/sg13g2_stdcell/cdl/sg13g2_stdcell.cdl
endif

export PDK
export PDK_ROOT

#######################################################
# Tools
# Fail a recipe when a tool fails, even if it is piped through tee
# (bash takes the options from SHELLOPTS. .SHELLFLAGS does not exist in make 3.81, the one of macOS)
SHELL=/bin/bash
export SHELLOPTS:=$(if $(SHELLOPTS),$(SHELLOPTS):)pipefail

# Each tool runs natively if it is installed and the PDK is available locally.
# Otherwise it runs inside the docker image (e.g. macOS has no openroad).
# Force one way or the other with USE_DOCKER=1 or USE_DOCKER=0.
DOCKER_IMAGE?=factory.symbioticeda.com/asic-all:dev
NGSPICE_THREADS?=8

ifeq ($(USE_DOCKER),)
ifeq ($(wildcard $(PDK_ROOT)),)
# The PDK only exists inside the container
USE_DOCKER=1
endif
endif

# Variables that the tcl scripts read from the environment
DOCKER_ENV=PDK PDK_ROOT STD_CELL_LIBRARY PNR_OUT ROOT_DIR SYN_DIR SYN_OUT SYN_SRC TOP DIGTOP SYN_DIG_SRC SYN_ANA_NET SYN_NET TECH X Y SRC_DIR PNR_DIR PX PY PR
DOCKER_RUN=docker run --rm -i \
	-u $(shell id -u):$(shell id -g) -e HOME=/tmp -e MPLBACKEND=Agg \
	--net=host \
	-v $(ROOT_DIR):$(ROOT_DIR) \
	$(if $(wildcard $(PDK_ROOT)),-v $(PDK_ROOT):$(PDK_ROOT)) \
	-w $$PWD \
	-e DISPLAY=$(DISPLAY) \
	$(addprefix -e ,$(DOCKER_ENV)) \
	$(DOCKER_IMAGE)

# $(call tool,name): the command line used to invoke "name"
tool=$(if $(filter 1,$(USE_DOCKER)),$(DOCKER_RUN) $(1),$(if $(or $(filter 0,$(USE_DOCKER)),$(shell command -v $(1))),$(1),$(DOCKER_RUN) $(1)))

YOSYS?=$(call tool,yosys)
OPENROAD?=$(call tool,openroad)
KLAYOUT?=$(call tool,klayout)
MAGIC?=$(call tool,magic)
STA?=$(call tool,sta)
IVERILOG?=$(call tool,iverilog)
VVP?=$(call tool,vvp)
NGSPICE?=$(call tool,ngspice)
# Waveform viewer for the ngspice rawfiles (view_* targets)
WAVEVIEW?=gaw
# The post-processing scripts need numpy, scipy, matplotlib and pandas (see requirements.txt)
PYTHON?=$(if $(filter 1,$(USE_DOCKER)),$(DOCKER_RUN) python3,$(if $(or $(filter 0,$(USE_DOCKER)),$(shell python3 -c 'import numpy, scipy, matplotlib, pandas' 2>/dev/null && echo ok)),python3,$(DOCKER_RUN) python3))

