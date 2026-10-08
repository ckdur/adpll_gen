ROOT_DIR=$(abspath ..)
SYN_DIR=$(abspath .)
include $(ROOT_DIR)/settings.mk

export SYN_DIR
export SYN_OUT
export SYN_SRC
export TOP
export DIGTOP
export SYN_DIG_SRC
export ROOT_DIR
export TECH

# Everything (netlists, logs, reports) goes to $(SYN_OUT), one folder per PDK
SYN_ANA_SDF=$(SYN_OUT)/$(TOP).sdf
SYN_ANA_SP=$(SYN_OUT)/$(TOP).sp
export SYN_ANA_NET
export SYN_NET

# Cells excluded by the PDK (only visible here when the PDK is installed locally)
SYN_EXCLUDE=$(wildcard $(PDK_ROOT)/$(PDK)/libs.tech/librelane/*/synth_exclude.cells)

all: $(SYN_ANA_NET) $(SYN_NET)
digital: $(SYN_NET)

$(SYN_ANA_NET): $(SYN_DIR)/tcl/synthesis_analog.tcl $(SYN_DIR)/tcl/dont_use.tcl $(SYN_EXCLUDE) $(SYN_SRC)
	mkdir -p $(SYN_OUT)
	$(YOSYS) -h tcl $(SYN_DIR)/tcl/synthesis_analog.tcl | tee -a $(SYN_OUT)/yosys_analog.log
	python3 $(SYN_DIR)/escape_names.py $@

$(SYN_NET): $(SYN_DIR)/tcl/synthesis.tcl $(SYN_DIR)/tcl/dont_use.tcl $(SYN_EXCLUDE) $(SYN_DIG_SRC)
	mkdir -p $(SYN_OUT)
	$(YOSYS) -h tcl $(SYN_DIR)/tcl/synthesis.tcl | tee -a $(SYN_OUT)/yosys.log
	python3 $(SYN_DIR)/escape_names.py $@

# Generating only the analog netlist (for subcircuits)
gen: $(SYN_ANA_SP)
$(SYN_ANA_SP): $(SYN_ANA_NET) $(SYN_DIR)/tcl/netlist.tcl $(SYN_DIR)/spice_ports.py
	$(OPENROAD) -exit $(SYN_DIR)/tcl/netlist.tcl | tee -a $(SYN_OUT)/openroad.log
	python3 $(SYN_DIR)/spice_ports.py $@ $(TOP) $(SYN_ANA_NET) $(SYN_NET)

sdf: $(SYN_ANA_SDF)
$(SYN_ANA_SDF): $(SYN_ANA_NET) $(SYN_DIR)/tcl/sdf.tcl
	$(STA) -exit $(SYN_DIR)/tcl/sdf.tcl | tee -a $(SYN_OUT)/openroad.log
#	sed -i 's/\\./\//g' $@

manual: $(SYN_DIR)/tcl/synthesis.tcl $(SYN_SRC)
	$(YOSYS) -h tcl

# Removes only the outputs of the current PDK. clean_all removes the ones of every PDK
clean:
	rm -rfv $(SYN_OUT)

clean_all:
	rm -rfv *.log* *.cmd* *_intermediate.v *_net.v *.sdf fv reports outputs *.tstamp

.PHONY: clean clean_all
