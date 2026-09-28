PRJ_DIR=$(abspath ../)
DIG_DIR=$(abspath ../../../)
include $(PRJ_DIR)/settings.mk
SIM_DIR=$(abspath .)
SYN_DIR=$(abspath ../syn)
SRC_DIR=$(abspath ../src)

CELLS_ADD_DEF=-D POSTSYN=1

SIM_DIGITAL=0
include $(SIM_DIR)/tests.mk

# Clean routine
clean:
	rm -rfv *.log* *.meas logFile *.ic* *.tr* *.su* *.mt* *.st* *.pa* xcelium.d *.history *.vcd outputs

.PHONY: clean

