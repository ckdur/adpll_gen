# Top-level flow: synthesis -> place & route -> signoff (GDS, DRC, LVS)
# Variables like PDK or TOP given here (make PDK=ics55) are passed to every stage.
# In ics55, SCL selects the standard cell library (make PDK=ics55 SCL=ICsprout55_9TSVT_basic).

PDK?=ics55
export PDK

all: signoff

syn:
	$(MAKE) -C syn all

pnr: syn
	$(MAKE) -C pnr all

gds: pnr
	$(MAKE) -C signoff gds

signoff: pnr
	$(MAKE) -C signoff all

# Each stage only cleans the outputs of the current PDK where supported
clean:
	$(MAKE) -C syn clean
	$(MAKE) -C pnr clean
	$(MAKE) -C signoff clean

# The stages depend on each other, never run them in parallel
.NOTPARALLEL:
.PHONY: all syn pnr gds signoff clean
