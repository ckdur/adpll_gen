#######################################################
# Proportional dimmentions
PX?=3
PY?=2
PR?=0.8

# Exact X and Y (superseeds proportional)
X?=440
Y?=235
export X
export Y

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
ADPLL_ROOT:=$(abspath $(dir $(lastword $(MAKEFILE_LIST))))
#PDK?=ics55
PDK?=ihp-sg13g2

ifeq ($(PDK),ics55)
PDK_ROOT?=$(HOME)/Documents/SymbioticEDA/ics55/icsprout55-pdk
SYN_SRC+= $(ROOT_DIR)/src/pll_cells_ics55.v

$(SIM_DIR)/outputs/models.inc: $(ADPLL_ROOT)/settings.mk
	mkdir -p $(dir $@)
	@echo ".LIB \"$(PDK_ROOT)/$(PDK)/libs.tech/ngspice/ICsprout_55LLULP1225_V1p1_hsp.lib\" tt_mos" > $@
	@echo ".INCLUDE \"$(PDK_ROOT)/$(PDK)/libs.ref/ics55_LLSC_H7CR/spice/ics55_LLSC_H7CR.spice\"" >> $@
	@echo ".PARAM lvdd=1.2" >> $@
	@echo "* Load used by the testbenches (same mapping as in pll_cells_ics55.v)" >> $@
	@echo ".SUBCKT PLL_CELL_BUFFX0 VDD VSS I Z" >> $@
	@echo "Ximpl I VDD VSS Z BUFX0P5H7R" >> $@
	@echo ".ENDS" >> $@

# ngspice settings for this PDK (copied as .spiceinit next to the testbenches)
$(SIM_DIR)/outputs/.spiceinit: $(ADPLL_ROOT)/settings.mk
	mkdir -p $(dir $@)
	@echo "set ngbehavior=hsa" > $@
	@echo "set num_threads=$(NGSPICE_THREADS)" >> $@

CELLS_SRC=$(PDK_ROOT)/$(PDK)/libs.ref/ics55_LLSC_H7CR/verilog/ics55_LLSC_H7CR.v $(PDK_ROOT)/$(PDK)/libs.ref/ICsprout_55LLULP1233_IO_251013/verilog/icsIOA_N55_3P3.v
endif

ifeq ($(PDK),ihp-sg13g2)
# Use the local installation if present, otherwise the one inside the docker image
PDK_ROOT?=$(firstword $(wildcard /opt/ext/OpenPDKs) /usr/local/share/OpenPDKs)
SYN_SRC+= $(ROOT_DIR)/src/pll_cells_ihp-sg13g2.v

$(SIM_DIR)/outputs/models.inc: $(ADPLL_ROOT)/settings.mk
	mkdir -p $(dir $@)
	@echo ".LIB \"$(PDK_ROOT)/ihp-sg13g2/libs.tech/ngspice/models/cornerMOSlv.lib\" mos_tt" > $@
	@echo ".INCLUDE \"$(PDK_ROOT)/ihp-sg13g2/libs.ref/sg13g2_stdcell/spice/sg13g2_stdcell.spice\"" >> $@
	@echo ".PARAM lvdd=1.2" >> $@
	@echo "* Load used by the testbenches (same mapping as in pll_cells_ihp-sg13g2.v)" >> $@
	@echo ".SUBCKT PLL_CELL_BUFFX0 VDD VSS I Z" >> $@
	@echo "Ximpl Z I VDD VSS sg13g2_buf_1" >> $@
	@echo ".ENDS" >> $@

# ngspice settings for this PDK (copied as .spiceinit next to the testbenches)
# The PSP models are OSDI-compiled, so ngspice needs to load them
$(SIM_DIR)/outputs/.spiceinit: $(ADPLL_ROOT)/settings.mk
	mkdir -p $(dir $@)
	@echo "set num_threads=$(NGSPICE_THREADS)" > $@
	@echo "osdi '$(PDK_ROOT)/ihp-sg13g2/libs.tech/ngspice/osdi/psp103.osdi'" >> $@
	@echo "osdi '$(PDK_ROOT)/ihp-sg13g2/libs.tech/ngspice/osdi/psp103_nqs.osdi'" >> $@
	@echo "osdi '$(PDK_ROOT)/ihp-sg13g2/libs.tech/ngspice/osdi/r3_cmc.osdi'" >> $@
	@echo "osdi '$(PDK_ROOT)/ihp-sg13g2/libs.tech/ngspice/osdi/mosvar.osdi'" >> $@

CELLS_SRC=$(PDK_ROOT)/ihp-sg13g2/libs.ref/sg13g2_stdcell/verilog/sg13g2_udp.v $(PDK_ROOT)/ihp-sg13g2/libs.ref/sg13g2_stdcell/verilog/sg13g2_stdcell.v
endif

export PDK
export PDK_ROOT

#######################################################
# Tools
# Fail a recipe when a tool fails, even if it is piped through tee
SHELL=/bin/bash
.SHELLFLAGS=-o pipefail -c

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
DOCKER_ENV=PDK PDK_ROOT ROOT_DIR SYN_DIR SYN_SRC TOP DIGTOP SYN_DIG_SRC SYN_ANA_NET SYN_NET TECH X Y
DOCKER_RUN=docker run --rm -i \
	-u $(shell id -u):$(shell id -g) -e HOME=/tmp -e MPLBACKEND=Agg \
	-v $(ADPLL_ROOT):$(ADPLL_ROOT) \
	$(if $(wildcard $(PDK_ROOT)),-v $(PDK_ROOT):$(PDK_ROOT)) \
	-w $$PWD \
	$(addprefix -e ,$(DOCKER_ENV)) \
	$(DOCKER_IMAGE)

# $(call tool,name): the command line used to invoke "name"
tool=$(if $(filter 1,$(USE_DOCKER)),$(DOCKER_RUN) $(1),$(if $(or $(filter 0,$(USE_DOCKER)),$(shell command -v $(1))),$(1),$(DOCKER_RUN) $(1)))

YOSYS?=$(call tool,yosys)
OPENROAD?=$(call tool,openroad)
STA?=$(call tool,sta)
IVERILOG?=$(call tool,iverilog)
VVP?=$(call tool,vvp)
NGSPICE?=$(call tool,ngspice)
# Waveform viewer for the ngspice rawfiles (view_* targets)
WAVEVIEW?=gaw
# Only for test_dco_noise (oscillator phase noise is not available in ngspice)
HSPICE?=hspice
# The post-processing scripts need numpy, scipy, matplotlib and pandas (see requirements.txt)
PYTHON?=$(if $(filter 1,$(USE_DOCKER)),$(DOCKER_RUN) python3,$(if $(or $(filter 0,$(USE_DOCKER)),$(shell python3 -c 'import numpy, scipy, matplotlib, pandas' 2>/dev/null && echo ok)),python3,$(DOCKER_RUN) python3))

