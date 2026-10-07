# Slight different version of rtl.sdc.tcl, but internal

create_clock {REF} -name REF -period 10
create_clock [get_pins pll_ana_dco/sym/sym_mux/nand_pll_impl/Y] -name OUT -period 1
create_clock [get_pins pll_ana_dco/mid/inv_1_impl/Y] -name MID_OUT -period 1

set_clock_transition -min 0.01 [all_clocks]
set_clock_transition -max 0.03 [all_clocks]

set_clock_uncertainty -setup 0.02 [all_clocks]
set_clock_uncertainty -hold  0.02 [all_clocks]

#set_clock_latency -min 0.5 [all_clocks]
#set_clock_latency -max 1 [all_clocks]

set_clock_groups \
  -asynchronous \
  -group {REF} \
  -group {OUT} \
  -group {MID_OUT}

set_false_path -from [get_ports {RST_N}]

#if { [sizeof_collection [remove_from_collection [all_outputs] [all_inputs]]] > 0 } {
#set_max_transition 1.2 [remove_from_collection [all_outputs] [all_inputs]]
#} else {
#}

set_input_delay -min 1.0 -clock REF {KP KI FCW}
set_input_delay -min 1.0 -clock OUT {LOAD_DIV SET_DIV}
set_output_delay -max 4.0 -clock REF [get_ports {LOCKED ERR}]

set_load 0.22 [all_outputs]

