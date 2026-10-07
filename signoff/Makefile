ROOT_DIR=$(abspath ../../)
PRJ_DIR=$(abspath ../)
PNR_DIR=$(abspath ../pnr)
SYN_DIR=$(abspath ../syn)
SIGN_DIR=$(abspath .)
include $(PRJ_DIR)/settings.mk

GDS=$(SIGN_OUT)/$(TOP).gds
export GDS
SPICE=$(SIGN_OUT)/$(TOP).spice
export SPICE
DEF=$(PNR_OUT)/$(TOP).def
export DEF
NET=$(PNR_OUT)/$(TOP).cdl
export NET
export TOP
export TECH
export SIGN_DIR
export ROOT_DIR

gds: $(GDS)

$(GDS): $(SIGN_DIR)/tcl/gds.tcl $(SIGN_DIR)/tcl/def2stream.py $(DEF)
	mkdir -p $(SIGN_OUT)
	mkdir -p $(SIGN_DIR)/reports/$(PDK)
ifeq ($(PDK_FILE),none)
	$(KLAYOUT) -zz -rd design_name=$(TOP) \
	        -rd in_def=$(DEF) \
	        -rd lef_files="$(LEFS)" \
	        -rd in_files="$(GDSS)" \
	        -rd seal_file="" \
	        -rd out_file=$(GDS) \
	        -rd tech_file=$(PDK_KLAYOUT_TECHFILE) \
	        -rd layer_map=$(PDK_KLAYOUT_MAPFILE) \
	        -r $(SIGN_DIR)/tcl/def2stream.py
else
	$(MAGIC) -dnull -noconsole -rcfile $(PDK_ROOT)/$(PDK)/libs.tech/magic/$(PDK).magicrc $(SIGN_DIR)/tcl/gds.tcl
endif

view: $(GDS)
	$(KLAYOUT) -nn $(PDK_KLAYOUT_TECHFILE) -s $(GDS)

drc: $(GDS)
	$(PYTHON) $(PDK_ROOT)/$(PDK)/libs.tech/klayout/tech/drc/run_drc.py --path=$(GDS) --mp=10 --run_dir=$(SIGN_DIR)/reports/ --topcell=$(TOP) --run_mode=flat --no_density --density_thr=10 --antenna
#	python3 $(SIGN_DIR)/tcl/klayout_gds_drc_check.py --gds_input_file_path $(GDS) --output_directory $(SIGN_DIR)/reports --design_name $(TOP) --drc_rules $(PDK_ROOT)/$(PDK)/libs.tech/klayout/tech/drc/sg13g2_minimal.lydrc

drc_magic: $(GDS)
	$(MAGIC) -dnull -noconsole -rcfile $(PDK_ROOT)/$(PDK)/libs.tech/magic/$(PDK).magicrc $(SIGN_DIR)/tcl/run_magic_drc.tcl

$(SPICE): $(ROOT_DIR)/lib/$(TECH).cdl $(NET)
	cat $(ROOT_DIR)/lib/$(TECH).cdl $(NET) > $(SPICE)

lvs: $(GDS) $(SPICE)
	$(PYTHON) $(PDK_ROOT)/$(PDK)/libs.tech/klayout/tech/lvs/run_lvs.py --layout=$(GDS) --netlist=$(SPICE) --run_dir=$(SIGN_DIR)/reports/ --topcell=$(TOP) --run_mode=flat --verbose
#	klayout -b -r $(PDK_ROOT)/$(PDK)/libs.tech/klayout/tech/lvs/sg13g2.lvs -rd in_gds=$(GDS) -rd report_file=$(SIGN_DIR)/reports/lvs_report.lvsdb -rd cdl_file=$(SPICE) -rd target_netlist=$(SIGN_DIR)/reports/$(TOP).lay.cdl

clean:
	rm -vrf  outputs reports

.PHONY: all manual clean

