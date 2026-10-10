ROOT_DIR=$(abspath ../)
PRJ_DIR=$(abspath ../)
PNR_DIR=$(abspath ../pnr)
SYN_DIR=$(abspath ../syn)
SIGN_DIR=$(abspath .)
include $(PRJ_DIR)/settings.mk

SIGN_REP=$(SIGN_DIR)/reports/$(TECH)
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

# Threads used by klayout in DRC and LVS
SIGN_THREADS?=10
# Python with the klayout module (lvs_summary.py), from the docker image if missing
KPYTHON?=$(if $(filter 1,$(USE_DOCKER)),$(DOCKER_RUN) python3,$(if $(or $(filter 0,$(USE_DOCKER)),$(shell python3 -c 'import klayout.db' 2>/dev/null && echo ok)),python3,$(DOCKER_RUN) python3))

all: gds drc lvs

gds: $(GDS)

$(GDS): $(SIGN_DIR)/tcl/gds.tcl $(SIGN_DIR)/tcl/def2stream.py $(DEF) $(ROOT_DIR)/settings.mk
	mkdir -p $(SIGN_OUT)
	mkdir -p $(SIGN_REP)
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

#######################################################
# DRC and LVS with the KLayout runsets of each PDK
# Each target writes a stamp only when the check passes, so make fails (and re-runs) on violations.

# LVS schematic: the cell netlists of the PDK + the top subcircuit written by pnr
$(SPICE): $(NET) $(ROOT_DIR)/settings.mk $(wildcard $(CDLS))
	mkdir -p $(SIGN_OUT)
	$(call tool,cat) $(CDLS) $(NET) > $@

DRC_OK=$(SIGN_REP)/drc.ok
LVS_OK=$(SIGN_REP)/lvs.ok
DRC_LOG=$(SIGN_REP)/$(TOP)_drc.log
LVS_LOG=$(SIGN_REP)/$(TOP)_lvs.log

drc: $(DRC_OK)
lvs: $(LVS_OK)

ifeq ($(PDK),ics55)
DRC_DB=$(SIGN_REP)/$(TOP).lyrdb
LVS_DB=$(SIGN_REP)/$(TOP).lvsdb

# No tapless / implicit_nets: FILLTAP ties the wells and substrate of the placed cells
$(DRC_OK): $(GDS)
	mkdir -p $(SIGN_REP)
	rm -f $@
	$(KLAYOUT) -b -r $(PDK_ROOT)/$(PDK)/libs.tech/klayout/tech/ics55.drc \
	        -rd input=$(GDS) -rd topcell=$(TOP) -rd report=$(DRC_DB) \
	        -rd log=$(SIGN_REP)/drc_runset.log -rd run_mode=deep -rd threads=$(SIGN_THREADS) | tee $(DRC_LOG)
	$(PYTHON) $(SIGN_DIR)/tcl/drc_summary.py $(DRC_DB) | tee $(SIGN_REP)/$(TOP)_drc.summary
	touch $@

$(LVS_OK): $(GDS) $(SPICE)
	mkdir -p $(SIGN_REP)
	rm -f $@
	$(KLAYOUT) -b -r $(PDK_ROOT)/$(PDK)/libs.tech/klayout/tech/ics55.lvs \
	        -rd input=$(GDS) -rd schematic=$(SPICE) -rd topcell=$(TOP) -rd report=$(LVS_DB) \
	        -rd target_netlist=$(SIGN_REP)/$(TOP)_extracted.cir \
	        -rd log=$(SIGN_REP)/lvs_runset.log -rd run_mode=deep -rd threads=$(SIGN_THREADS) | tee $(LVS_LOG)
	$(KPYTHON) $(SIGN_DIR)/tcl/lvs_summary.py $(LVS_DB) | tee $(SIGN_REP)/$(TOP)_lvs.summary
	touch $@
endif

ifeq ($(PDK),ihp-sg13g2)
IHP_KLAYOUT_TECH=$(PDK_ROOT)/$(PDK)/libs.tech/klayout/tech
DRC_DB=$(SIGN_REP)/drc/$(TOP)_$(TOP)_full.lyrdb
LVS_DB=$(SIGN_REP)/lvs/$(TOP).lvsdb

$(DRC_OK): $(GDS)
	mkdir -p $(SIGN_REP)
	rm -rf $@ $(SIGN_REP)/drc
	$(call tool,python3) $(IHP_KLAYOUT_TECH)/drc/run_drc.py --path=$(GDS) --topcell=$(TOP) \
	        --run_dir=$(SIGN_REP)/drc --run_mode=deep --mp=$(SIGN_THREADS) \
	        --no_density --antenna | tee $(DRC_LOG)
	$(PYTHON) $(SIGN_DIR)/tcl/drc_summary.py $(SIGN_REP)/drc/*.lyrdb | tee $(SIGN_REP)/$(TOP)_drc.summary
	touch $@

$(LVS_OK): $(GDS) $(SPICE)
	mkdir -p $(SIGN_REP)
	rm -rf $@ $(SIGN_REP)/lvs
	$(call tool,python3) $(IHP_KLAYOUT_TECH)/lvs/run_lvs.py --layout=$(GDS) --netlist=$(SPICE) \
	        --topcell=$(TOP) --run_dir=$(SIGN_REP)/lvs --run_mode=deep | tee $(LVS_LOG)
	$(KPYTHON) $(SIGN_DIR)/tcl/lvs_summary.py $(LVS_DB) | tee $(SIGN_REP)/$(TOP)_lvs.summary
	touch $@
endif

drc_magic: $(GDS)
	$(MAGIC) -dnull -noconsole -rcfile $(PDK_ROOT)/$(PDK)/libs.tech/magic/$(PDK).magicrc $(SIGN_DIR)/tcl/run_magic_drc.tcl

# Open the GDS with the DRC markers / LVS cross-reference
view_drc: $(GDS)
	$(KLAYOUT) -nn $(PDK_KLAYOUT_TECHFILE) -s $(GDS) -m $(DRC_DB)
view_lvs: $(GDS)
	$(KLAYOUT) -nn $(PDK_KLAYOUT_TECHFILE) -s $(GDS) -mn $(LVS_DB)

# Only the outputs of the current PDK
clean:
	rm -vrf $(SIGN_OUT) $(SIGN_REP)

clean_all:
	rm -vrf outputs reports

.PHONY: all gds view drc lvs drc_magic view_drc view_lvs clean clean_all
