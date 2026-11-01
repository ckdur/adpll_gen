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

# Every technology has its own outputs (SIM_DIR and SYN_DIR are defined by the including Makefile)
SIM_OUT=$(SIM_DIR)/outputs/$(PDK)
SYN_OUT=$(SYN_DIR)/outputs/$(PDK)
PNR_OUT=$(PNR_DIR)/outputs/$(PDK)
SIGN_OUT=$(SIGN_DIR)/outputs/$(PDK)

SYN_ANA_NET=$(SYN_OUT)/$(TOP)_net.v
SYN_NET=$(SYN_OUT)/$(DIGTOP)_net.v

# Every PDK is described by three files (see "Porting to a new technology" in CLAUDE.md):
#   lib/<PDK>.mk            this makefile fragment: PDK_ROOT, SPICE models, cell models, design target
#   lib/<PDK>_settings.tcl  liberty/LEF/CDL/SPICE paths and the supply pin names (tcl scripts)
#   src/pll_cells_<PDK>.v   PLL_CELL_* mapped to the standard cells
PDK_MK=$(ROOT_DIR)/lib/$(PDK).mk
ifeq ($(wildcard $(PDK_MK)),)
$(error Unknown PDK '$(PDK)': $(PDK_MK) does not exist)
endif
include $(PDK_MK)
# Default of the design target (after the include: lib/<PDK>.mk may set it, see src/pll_target.py)
PLL_F_REF?=100e6
SYN_SRC+= $(ROOT_DIR)/src/pll_cells_$(PDK).v

# models.inc: PDK_MODELS_INC (models, standard-cell SPICE, lvdd, PLL_CELL_BUFFX0)
# .spiceinit: PDK_SPICEINIT (ngspice options of the PDK, num_threads)
# Both are only replaced when their content changes
$(SIM_OUT)/models.inc: $(ROOT_DIR)/settings.mk $(PDK_MK)
	$(shell mkdir -p $(dir $@))$(file >$@.tmp,$(PDK_MODELS_INC))
	@$(call update_if_changed,$@)

$(SIM_OUT)/.spiceinit: $(ROOT_DIR)/settings.mk $(PDK_MK)
	$(shell mkdir -p $(dir $@))$(file >$@.tmp,$(PDK_SPICEINIT))
	@$(call update_if_changed,$@)

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
DOCKER_ENV=PDK PDK_ROOT ROOT_DIR SYN_DIR SYN_OUT SYN_SRC TOP DIGTOP SYN_DIG_SRC SYN_ANA_NET SYN_NET TECH X Y SRC_DIR PNR_DIR PX PY PR
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

