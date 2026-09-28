# Script for openroad/opensta to give us a SDF file

set TOP $env(TOP)
set SYN_DIR $env(SYN_DIR)
set SYN_SRC $env(SYN_SRC)

source $env(ROOT_DIR)/lib/$env(PDK)_settings.tcl

# We assume the first LIB is the standard cell lib
set LIBMAIN [lindex $LIBS 0]

read_liberty "$LIBMAIN"

puts "Reading: $env(SYN_ANA_NET)"
read_verilog $env(SYN_ANA_NET)
read_verilog $env(SYN_NET)
link_design ${TOP}

if {![file exists outputs]} {
  file mkdir outputs
  puts "Creating directory outputs"
}

read_sdc $SYN_DIR/tcl/rtl.sdc.tcl

write_sdf $SYN_DIR/outputs/${TOP}.sdf
#write_verilog $SYN_DIR/outputs/${TOP}.v

exit
