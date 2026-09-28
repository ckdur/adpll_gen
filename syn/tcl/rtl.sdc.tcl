if {$TOP == "pll_logic" || $TOP == "pll"} {

  create_clock {REF} -name REF -period 10
  create_clock {OUT} -name OUT -period 1
  create_clock {MID_OUT} -name MID_OUT -period 1

  set_clock_transition -min 0.1 [all_clocks]
  set_clock_transition -max 0.3 [all_clocks]

  set_clock_uncertainty -setup 0.2 [all_clocks]
  set_clock_uncertainty -hold  0.2 [all_clocks]

  set_clock_latency -min 0.5 [all_clocks]
  set_clock_latency -max 1 [all_clocks]

  set_clock_groups \
    -asynchronous \
    -group {REF} \
    -group {OUT} \
    -group {MID_OUT}
}

if {$TOP == "pll_logic"} {

  set_false_path -from [get_ports {RST_N}]
  set_false_path -from [get_ports {SS_BBPD}]

  if { [sizeof_collection [remove_from_collection [all_outputs] [all_inputs]]] > 0 } {
    set_max_transition 1.2 [remove_from_collection [all_outputs] [all_inputs]]
  } else {
  }
 
  set_input_delay -min 1.0 -clock REF {KP KI FCW}
  set_output_delay -max 4.0 -clock REF [get_ports {COARSE_MUX MID_MUX FINE_MUX DCO_EN LOCKED ERR}]

  set_load 0.22 [all_outputs]
}

if {$TOP != "pll_logic" && $TOP != "pll"} {
  set_input_delay -min 1.0 [all_inputs]
  set_output_delay -max 4.0 [all_outputs]
}
