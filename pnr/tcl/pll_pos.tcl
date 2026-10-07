####################################
## Manual placement of the PLL analog cells (OpenROAD)
####################################
# The netlist is flattened by link_design, so the cells are named like
#   pll_ana_dco/coarse/stage_0_impl/upp_impl
# (yosys flattens the PLL_CELL_* wrappers into <inst>_impl, the rest keeps the hierarchy with "/").
# Some PLL_CELL_* are made of several cells (e.g. the dynamic loads are impl_1, impl_2 in ics55 and
# impl_0..impl_7 in IHP), so the dynamic loads are searched by prefix.
# Every column is: [tap] cell cell ... (from left to right), one stage per row.
# All coordinates are in microns, and the y of every cell must be the origin of a row.

proc is_intersect_tap {x sx} {
  # NOTE: Ignoring this, as now we insert our own WELLTAPS
  return $x
}

proc invert_ori {or} {
  if {$or == "R0"} {
    return "MX"
  } else {
    return "R0"
  }
  return "R0"
}

proc get_ori {or i} {
  if {[expr {$i % 2}] == 0} {
    return $or
  } else {
    return [invert_ori $or]
  }
  return $or
}

proc um2dbu {v} {
  return [expr {round($v * [$::block getDbUnitsPerMicron])}]
}

proc find_inst {name} {
  set inst [$::block findInst $name]
  if {$inst == "NULL" || $inst == ""} {
    error "Instance $name not found"
  }
  return $inst
}

# All instances whose name starts with "prefix" (e.g. the parts of a multi-cell PLL_CELL)
proc find_insts_prefix {prefix} {
  set names {}
  foreach inst [$::block getInsts] {
    set name [$inst getName]
    if {[string equal -length [string length $prefix] $prefix $name]} {
      lappend names $name
    }
  }
  if {[llength $names] == 0} {
    error "No instances found with prefix $prefix"
  }
  return [lsort -dictionary $names]
}

proc inst_w {name} {
  return [::ord::dbu_to_microns [[[find_inst $name] getMaster] getWidth]]
}

proc inst_h {name} {
  return [::ord::dbu_to_microns [[[find_inst $name] getMaster] getHeight]]
}

# Sum of the widths of a list of instances
proc insts_w {names} {
  set sx 0
  foreach name $names {
    set sx [expr $sx + [inst_w $name]]
  }
  return $sx
}

# Orientation of the row that starts at y (replaces the snapping of placeInstance)
proc row_ori {y} {
  set ydbu [um2dbu $y]
  foreach row [$::block getRows] {
    if {[lindex [$row getOrigin] 1] == $ydbu} {
      return [$row getOrient]
    }
  }
  error "There is no row at y=$y"
}

# Equivalent to "placeInstance name x y -fixed" (x y is the lower-left corner)
proc place_fixed {name x y} {
  set xs [::ord::dbu_to_microns [um2dbu $x]]
  set ys [::ord::dbu_to_microns [um2dbu $y]]
  place_inst -name $name -location [list $xs $ys] -orientation [row_ori $y] -status FIRM
}

# Equivalent to "addInst -cell TAPCell -inst name -loc x y -place_status fixed"
# Nothing is done when the PDK has no tap cells (well_w is 0 then)
proc place_tap {name x y} {
  global TAPCells
  if {[llength $TAPCells] == 0} {
    return
  }
  set xs [::ord::dbu_to_microns [um2dbu $x]]
  set ys [::ord::dbu_to_microns [um2dbu $y]]
  place_inst -name $name -cell [lindex $TAPCells 0] -location [list $xs $ys] -orientation [row_ori $y] -status FIRM
}

proc pos_balanced {stx sty} {
  global well_w
  set dco pll_ana_dco
  set balance_list [list sym/osc_slope_balancer_impl sym/osc_dummy_inv_impl sym/sym_mux/nand_ref_impl \
                         sym/ssbbpd_impl/nand_y_impl sym/ssbbpd_impl/buf_nand_y_impl dff_y_impl \
                         sym/sym_mux/norb_en_inj_impl sym/sym_mux/nand_pll_impl \
                         dff_x_impl sym/ssbbpd_impl/buf_nand_x_impl sym/ssbbpd_impl/nand_x_impl \
                         sym/sym_mux/nand_inj_impl sym/inj_dummy_inv_impl sym/inj_slope_balancer_impl ]

  # Maximum of all the balanced cells
  set sx_bal 0
  foreach elem $balance_list {
    set sx_this_bal [inst_w $dco/$elem]
    if {$sx_this_bal > $sx_bal} {
      set sx_bal $sx_this_bal
    }
  }

  set sx [expr $well_w+$sx_bal]
  set sy [inst_h $dco/sym/osc_slope_balancer_impl]

  set x [expr $stx-$sx]
  set y $sty
  set x [is_intersect_tap $x $sx]

  # The direction is up
  set dir 1

  foreach elem $balance_list {
    regsub -all {/} [regsub {_impl$} $elem {}] {_} tapname
    place_tap $dco/tap_$tapname $x $y
    place_fixed $dco/$elem [expr $x+$well_w] $y

    set y [expr $y + $dir*$sy]
  }
  return [list $x $y]
}

proc pos_injection {stx sty n} {
  global well_w
  set inj pll_ana_inj
  set sx_buf [inst_w $inj/stage_0_del_1_impl]
  set sx_nor [inst_w $inj/cmp_nor_cmp_impl]
  set sx [expr $well_w+max($sx_buf, $sx_nor)]
  set sy [inst_h $inj/stage_0_del_1_impl]

  set x [expr $stx-$sx]
  set y $sty
  set x [is_intersect_tap $x $sx]

  # The direction is up
  set dir 1

  # Placement of the loop
  for {set j 1} {$j <= 2} {incr j} {
    for {set i 0} {$i < $n} {incr i} {
      place_tap $inj/tap_${i}_${j} $x $y
      place_fixed $inj/stage_${i}_del_${j}_impl [expr $x+$well_w] $y

      set y [expr $y + $dir*$sy]
    }
  }
  place_tap $inj/tap_nor $x $y
  place_fixed $inj/cmp_nor_cmp_impl [expr $x+$well_w] $y
  set y [expr $y + $dir*$sy]
  return [list $x $y]
}

proc pos_fine {stx sty n s} {
  # Initial direction down
  return [pos_mid_fine $stx $sty $n pll_ana_dco/fine $s -1]
}

proc pos_mid {stx sty n} {
  # Initial direction up
  return [pos_mid_fine $stx $sty $n pll_ana_dco/mid $n 1]
}

proc pos_mid_fine {stx sty n path s init_dir} {
  global well_w
  set sx_inv [inst_w $path/stage_0_inv_b_impl]
  set sx_var [insts_w [find_insts_prefix $path/stage_0_dyn_impl]]
  set sx_del_inv [inst_w $path/inv_0_impl]
  set sx [expr $well_w+$sx_inv+$sx_var]
  set sy [inst_h $path/stage_0_inv_b_impl]

  set x [expr $stx-$sx]
  set y $sty
  set x [is_intersect_tap $x $sx]

  # The initial direction
  set dir $init_dir

  # Placement of the delay line
  for {set i 0} {$i < $n} {incr i} {
    place_tap $path/tap_${i} $x $y
    place_fixed $path/stage_${i}_inv_b_impl [expr $x+$well_w] $y
    set xdyn [expr $x+$well_w+$sx_inv]
    foreach dyn [find_insts_prefix $path/stage_${i}_dyn_impl] {
      place_fixed $dyn $xdyn $y
      set xdyn [expr $xdyn + [inst_w $dyn]]
    }

    if {$i == [expr $s-1]} {
      set dir [expr -1*$dir]
      set x [is_intersect_tap [expr $x - $sx] $sx]
    } else {
      set y [expr $y + $dir*$sy]
    }
  }
  set ne [expr floor($n/$s)]
  place_fixed $path/inv_0_impl [expr $stx-$ne*$sx-$sx_del_inv] [expr $sty]
  place_fixed $path/inv_1_impl [expr $stx-$ne*$sx-$sx_del_inv] [expr $sty+($s-1)*$init_dir*$sy]

  return [list [expr $stx-$ne*$sx-$sx_del_inv] [expr $sty-($s-1)*$init_dir*$sy]]
}

proc pos_coarse {stx sty n} {
  global well_w
  set path pll_ana_dco/coarse
  set sx_upp [inst_w $path/stage_0_impl/upp_impl]
  set sx_mid [inst_w $path/stage_0_impl/mid_impl]
  set sx_dwn [inst_w $path/stage_0_impl/dwn_impl]
  set sx [expr $well_w+$sx_upp+$sx_mid+$sx_dwn]
  set sy [inst_h $path/stage_0_impl/upp_impl]

  set x [expr $stx-$sx]
  set y $sty
  set x [is_intersect_tap $x $sx]

  # The direction is down
  set dir -1

  # Placement of the loop
  for {set i 0} {$i < $n} {incr i} {
    place_tap $path/stage_${i}_impl/tap $x $y
    place_fixed $path/stage_${i}_impl/upp_impl [expr $x+$well_w] $y
    place_fixed $path/stage_${i}_impl/mid_impl [expr $x+$well_w+$sx_upp] $y
    place_fixed $path/stage_${i}_impl/dwn_impl [expr $x+$well_w+$sx_upp+$sx_mid] $y

    set y [expr $y + $dir*$sy]
  }
  return [list $x $y]
}
