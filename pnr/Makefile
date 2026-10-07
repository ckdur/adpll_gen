ROOT_DIR=$(abspath ../)
SYN_DIR=$(abspath ../syn)
PNR_DIR=$(abspath .)
include $(ROOT_DIR)/settings.mk
SRC_DIR=$(abspath ../src)

export SYN_DIR
export PNR_DIR
export SYN_SRC
export SRC_DIR
export TOP
export ROOT_DIR
export X
export Y
export PX
export PY
export PR
export TECH
export PDK_ROOT
export SYN_ANA_NET
export SYN_NET

all: $(PNR_OUT)/$(TOP).def

$(PNR_OUT)/$(TOP).def: $(SYN_ANA_NET) $(SYN_NET) $(PNR_DIR)/tcl/pnr.tcl
	$(OPENROAD) -exit $(PNR_DIR)/tcl/pnr.tcl | tee -a openroad.log

manual: $(SYN_ANA_NET) $(SYN_NET) $(PNR_DIR)/tcl/pnr.tcl
	$(OPENROAD) -gui $(PNR_DIR)/tcl/pnr.tcl

clean:
	rm -vrf fv/ outputs reports *.size *.log DesignLib

.PHONY: all manual clean

