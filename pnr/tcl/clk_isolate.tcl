####################################
## Isolation of the digital clocks from the analog
####################################
# The clocks of pll_dig (REF, OUT, MID_OUT, INJ_EDGE) are nets shared with the analog cells. CTS walks
# through the analog buffers (e.g. the injection delay line) and rewires every sink of those nets, which
# either crashes OpenROAD or breaks the (balanced) analog loads.
# So every one of those nets gets a single buffer that drives only the pll_dig loads:
#   <net> -> analog loads + pll_dig_clkiso_<net>/A,   pll_dig_clkiso_<net>/Y -> pll_dig_<net> -> pll_dig loads
# Then the analog cells and the original nets are dont_touch, and CTS only starts from the pll_dig_<net> nets.

set dig_clk_nets {REF OUT MID_OUT INJ_EDGE}

# Smallest (by width) of the CTS buffers of the PDK
proc smallest_clk_buffer {} {
  set best ""
  set best_w 0
  foreach selector $::env(CTS_CLK_BUFFERS) {
    foreach lib [[::ord::get_db] getLibs] {
      foreach master [$lib getMasters] {
        if {[string match $selector [$master getName]]} {
          if {$best == "" || [$master getWidth] < $best_w} {
            set best [$master getName]
            set best_w [$master getWidth]
          }
        }
      }
    }
  }
  return $best
}

# Called before the global placement, so the buffers get placed
proc isolate_dig_clocks {} {
  global dig_clk_nets
  set buf [smallest_clk_buffer]
  set ::env(CTS_CLK_NETS) {}
  foreach name $dig_clk_nets {
    set net [$::block findNet $name]
    if {$net == "NULL"} {
      error "Clock net $name not found"
    }
    set loads {}
    set load_iterms {}
    foreach iterm [$net getITerms] {
      set inst_name [[$iterm getInst] getName]
      if {[$iterm isInputSignal] && [string match pll_dig/* $inst_name]} {
        lappend loads "$inst_name/[[$iterm getMTerm] getName]"
        lappend load_iterms $iterm
      }
    }
    if {[llength $loads] == 0} {
      continue
    }
    puts "\[INFO\] Isolating [llength $loads] pll_dig loads of $name with $buf"
    insert_buffer -buffer_cell $buf -net $name -load_pins [get_pins $loads] \
      -buffer_name pll_dig_clkiso_$name -net_name pll_dig_$name
    # insert_buffer prefixes the hierarchy and uniquifies the names (e.g. pll_dig/pll_dig_REF1),
    # so take the new net (and the buffer) from one of the loads
    set dig_net [[lindex $load_iterms 0] getNet]
    lappend ::env(CTS_CLK_NETS) [$dig_net getName]
    # insert_buffer marks the buffer as TIMING, and CTS skips nets already driven by a TIMING buffer
    # ("already has clock buffer"), so make it look like a netlist cell
    [[$dig_net getFirstOutput] getInst] setSourceType NETLIST
  }
}

# Called before CTS
proc protect_analog {} {
  global dig_clk_nets
  set insts {}
  foreach inst [$::block getInsts] {
    if {[string match pll_ana_* [$inst getName]]} {
      lappend insts [$inst getName]
    }
  }
  set nets $dig_clk_nets
  foreach net [$::block getNets] {
    if {[string match pll_ana_* [$net getName]]} {
      lappend nets [$net getName]
    }
  }
  set_dont_touch [get_cells $insts]
  set_dont_touch [get_nets $nets]
}
