##############################################################################
## Cells the PDK excludes from synthesis (LibreLane SYNTH_EXCLUDED_CELL_FILE)
##############################################################################
# Sets DONT_USE_ARGS: "-dont_use <cell> ..." for dfflibmap and abc (glob patterns are allowed).
# The file is defined by the LibreLane config of the PDK, read the same way as in pnr.tcl.
source $env(PDK_ROOT)/$env(PDK)/libs.tech/librelane/config.tcl
source $env(PDK_ROOT)/$env(PDK)/libs.tech/librelane/$::env(STD_CELL_LIBRARY)/config.tcl

set DONT_USE_ARGS ""
if {[info exists ::env(SYNTH_EXCLUDED_CELL_FILE)] && [file exists $::env(SYNTH_EXCLUDED_CELL_FILE)]} {
  set fp [open $::env(SYNTH_EXCLUDED_CELL_FILE)]
  set excluded [regexp -all -inline {\S+} [read $fp]]
  close $fp
  foreach cell $excluded {
    append DONT_USE_ARGS "-dont_use $cell "
  }
  puts "Excluding cells from $::env(SYNTH_EXCLUDED_CELL_FILE): $excluded"
}
