# Dummy script for tricking openroad to give us a netlist in CDL form

set TOP $env(TOP)
set SYN_DIR $env(SYN_DIR)
set SYN_SRC $env(SYN_SRC)

source $env(ROOT_DIR)/lib/$env(PDK)_settings.tcl

# We assume the first LIB is the standard cell lib
set LIBMAIN [lindex $LIBS 0]
set LIBBCMAIN [lindex $LIBS_BC 0]
set LIBWCMAIN [lindex $LIBS_WC 0]

# TODO: Figure out what is the actual set of commands work
define_corners typ
read_liberty -corner typ "$LIBMAIN"
read_liberty -min -corner typ "$LIBBCMAIN"
read_liberty -max -corner typ "$LIBWCMAIN"

# We assume the first LEF is the tech lef
set TECHLEF [lindex $LEFS 0]
set OTHERLEF [lrange $LEFS 1 end]

read_lef $TECHLEF
foreach LEFFILE $OTHERLEF {
  read_lef "$LEFFILE"
}

puts "Reading: $env(SYN_ANA_NET)"
read_verilog $env(SYN_ANA_NET)
read_verilog $env(SYN_NET)
link_design ${TOP}

# The synthesized netlist has no supplies. Create the VDD/VSS ports and
# connect every cell supply pin to them, so the spice netlist is powered.
set block [ord::get_db_block]
foreach {supply sigtype} {VDD POWER VSS GROUND} {
  set net [$block findNet $supply]
  if {$net == "NULL"} {
    set net [odb::dbNet_create $block $supply]
  }
  $net setSpecial
  $net setSigType $sigtype
  if {[$block findBTerm $supply] == "NULL"} {
    odb::dbBTerm_create $net $supply
  }
}
# The well bias pins (VNW / VPW) of some libraries go to the supplies too
add_global_connection -net VDD -pin_pattern {^(VDD|VNW)$} -power
add_global_connection -net VSS -pin_pattern {^(VSS|VPW)$} -ground
global_connect

set OUTPUTS $env(SYN_OUT)
if {![file exists $OUTPUTS]} {
  file mkdir $OUTPUTS
  puts "Creating directory $OUTPUTS"
}

write_cdl -masters ${CDLS} $OUTPUTS/${TOP}.cdl
write_cdl -masters ${SPICES} $OUTPUTS/${TOP}.sp
