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
PDK_ROOT?=/opt/ext/OpenPDKs
#PDK?=ics55
PDK?=ihp-sg13g2

ifeq ($(PDK),ics55)
SYN_SRC+= $(ROOT_DIR)/src/pll_cells_ics55.v

$(SIM_DIR)/outputs/lib.sp:
	@echo ".LIB \"/path/to/main.sp\" tt_lib" > $@
	@echo ".param lvdd=1.2" >> $@

CELLS_SRC=
endif

ifeq ($(PDK),ihp-sg13g2)
SYN_SRC+= $(ROOT_DIR)/src/pll_cells_ihp-sg13g2.v

$(SIM_DIR)/outputs/lib.sp:
	@echo ".LIB \"/path/to/main.sp\" tt_lib" > $@
	@echo ".param lvdd=1.2" >> $@
CELLS_SRC=$(PDK_ROOT)/ihp-sg13g2/libs.ref/sg13g2_stdcell/verilog/sg13g2_udp.v $(PDK_ROOT)/ihp-sg13g2/libs.ref/sg13g2_stdcell/verilog/sg13g2_stdcell.v
endif

