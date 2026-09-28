ROOT_DIR=$(abspath ..)
include $(ROOT_DIR)/settings.mk
SYN_DIR=$(abspath .)

export SYN_DIR
export SYN_SRC
export TOP
export DIGTOP
export SYN_DIG_SRC
export ROOT_DIR
export TECH

SYN_ANA_SDF=$(SYN_DIR)/outputs/$(TOP).sdf
SYN_ANA_SP=$(SYN_DIR)/outputs/$(TOP).sp
SYN_ANA_NET=$(SYN_DIR)/outputs/$(TOP)_net.v
SYN_NET=$(SYN_DIR)/outputs/$(DIGTOP)_net.v
export SYN_ANA_NET
export SYN_NET

all: $(SYN_ANA_NET) $(SYN_NET)
digital: $(SYN_NET)

$(SYN_ANA_NET): $(SYN_DIR)/tcl/synthesis_analog.tcl $(SYN_SRC)
	yosys -h tcl $(SYN_DIR)/tcl/synthesis_analog.tcl | tee -a yosys_analog.log
	python3 $(SYN_DIR)/escape_names.py $@

$(SYN_NET): $(SYN_DIR)/tcl/synthesis.tcl $(SYN_DIG_SRC)
	yosys -h tcl $(SYN_DIR)/tcl/synthesis.tcl | tee -a yosys.log
	python3 $(SYN_DIR)/escape_names.py $@

# Generating only the analog netlist (for subcircuits)
gen: $(SYN_ANA_SP)
$(SYN_ANA_SP): $(SYN_ANA_NET) $(SYN_DIR)/tcl/netlist.tcl
	openroad -exit $(SYN_DIR)/tcl/netlist.tcl | tee -a openroad.log

sdf: $(SYN_ANA_SDF)
$(SYN_ANA_SDF): $(SYN_ANA_NET) $(SYN_DIR)/tcl/sdf.tcl
	sta -exit $(SYN_DIR)/tcl/sdf.tcl | tee -a openroad.log
#	sed -i 's/\\./\//g' $@

manual: $(SYN_DIR)/tcl/synthesis.tcl $(SYN_SRC)
	yosys -h tcl

clean:
	rm -rfv *.log* *.cmd* *_intermediate.v *_net.v *.sdf fv reports outputs *.tstamp

.PHONY: clean
