##############################################################################
## Preset global variables and attributes
##############################################################################
set TOP $env(TOP)
set SYN_DIR $env(SYN_DIR)
set SYN_SRC $env(SYN_SRC)
set LOGS $env(SYN_OUT)/logs
set REPORTS $env(SYN_OUT)/reports
set OUTPUTS $env(SYN_OUT)
set ROOT_DIR $env(ROOT_DIR)

set SYN_EFF high
set MAP_EFF high
set INC_EFF high

if {![file exists $OUTPUTS]} {
  puts "Creating directory $OUTPUTS"
  file mkdir $OUTPUTS
}
if {![file exists $REPORTS]} {
  puts "Creating directory $REPORTS"
  file mkdir $REPORTS
}

yosys -import

###############################################################
## Library setup
###############################################################
source $env(ROOT_DIR)/lib/$env(PDK)_settings.tcl

# Prepend to all strings the -liberty
set LIBSLIB ""
foreach i $LIBS {
    append LIBSLIB "-liberty $i "
}
puts "LIBSLIB = $LIBSLIB"

# Get only the DFF library, which is the standard cell library
# TODO: Not intelligent. We assume is the first one
set LIBFF [lindex $LIBS 0]
puts "LIBFF = $LIBFF"

################################################################
## Verilog read
################################################################
foreach src $SYN_SRC {
  read_verilog -DSYNTHESIS=1 $src
}

hierarchy -check -top $::env(TOP)

####################################################################
## Load Design
####################################################################
procs
opt
fsm
opt
memory
opt
flatten
synth -run coarse 
#techmap -map $env(TECH_DIR)/verilog/yosys_techmap.v
techmap
#dffunmap -ce-only
opt

hierarchy -check

####################################################################
## Constraints Setup
####################################################################
# read_sdc $SYN_DIR/tcl/${TOP}.sdc.tcl

####################################################################################################
## Synthesizing to gates
####################################################################################################
dfflibmap -liberty $LIBFF
dfflegalize
set cmd "abc $LIBSLIB"
eval $cmd

splitnets

###################################################
## TIES
###################################################
#hilomap -hicell it18_to01_0 HI -locell it18_to01_0 LO # TODO: This command fails
hilomap

######################################################################################################
## Outputs (verilog, SDC, config, etc.)
######################################################################################################
clean -purge
#write_sdc ${OUTPUTS}/${TOP}.sdc # TODO: This command fails

# For matching the verilog with the SDF (NOTE: Commented because it makes everything unreadable)
#autoname
#renames -hide */c:*\[*
#renames -enumerate -pattern instance_% */c:\$auto\$rename*

write_verilog -renameprefix ins -noexpr -noattr -nohex ${OUTPUTS}/${TOP}_net.v

