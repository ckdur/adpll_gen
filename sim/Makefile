ROOT_DIR=$(abspath ../)
SIM_DIR=$(abspath .)
SYN_DIR=$(abspath ../syn)
include $(ROOT_DIR)/settings.mk
SRC_DIR=$(abspath ../src)

CELLS_ADD_DEF=-D POSTSYN=1

include $(SIM_DIR)/tests.mk

# Clean routine. Removes only the outputs of the current PDK. clean_all removes the ones of every PDK
clean:
	rm -rfv $(SIM_OUT)

clean_all:
	rm -rfv *.log* *.meas logFile *.ic* *.tr* *.su* *.mt* *.st* *.pa* xcelium.d *.history *.vcd $(SIM_DIR)/outputs

.PHONY: clean clean_all

