proc is_intersect_tap {x sx} {
  # NOTE: Ignoring this, as now we insert our own WELLTAPS
  #set all_well [dbGet -p top.insts.name WELLTAP*]
  #set x1 [expr $x]
  #set x2 [expr $x+$sx]
  #foreach well $all_well {
  #  set x3 [dbGet $well.box_llx]
  #  set x4 [dbGet $well.box_urx]
  #  if { $x1 <= $x4 && $x3 <= $x2 } {
  #    return $x4
  #  }
  #}
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

proc pos_balanced {stx sty} {
  global well_w
  global TAPCell
  set balance_list [list sym/osc_slope_balancer sym/osc_dummy_inv sym/sym_mux/nand_ref sym/ssbbpd_impl/nand_y sym/ssbbpd_impl/buf_nand_y dff_y \
                         sym/sym_mux/norb_en_inj sym/sym_mux/nand_pll \
                         dff_x sym/ssbbpd_impl/buf_nand_x sym/ssbbpd_impl/nand_x sym/sym_mux/nand_inj sym/inj_dummy_inv sym/inj_slope_balancer ]

  # Maximum of all the balanced cells
  set sx_bal 0
  foreach elem $balance_list {
    set obj [dbget -p top.insts.name pll_ana/dco/$elem/impl]
    set sx_this_bal [dbget $obj.cell.size_x]
    if {$sx_this_bal > $sx_bal} {
      set sx_bal $sx_this_bal
    }
  }

  set obj [dbget -p top.insts.name pll_ana/dco/sym/osc_slope_balancer/impl]
  set sx [expr $well_w+$sx_bal]
  set sy [dbget $obj.cell.size_y]

  set x [expr $stx-$sx]
  set y $sty
  set x [is_intersect_tap $x $sx]

  # Do a mock placing of the first one to know the initial orientation
  placeInstance pll_ana/dco/sym/osc_slope_balancer/impl $x $y -fixed
  set init_or [dbget $obj.orient]
  set or $init_or
  # The initial direction is down
  set dir 1

  foreach elem $balance_list {
    addInst -cell ${TAPCell} -inst pll_ana/dco/tap_$elem -loc $x $y -ori $or -place_status fixed
    placeInstance pll_ana/dco/$elem/impl [expr $x+$well_w] $y $or -fixed
      
    set y [expr $y + $dir*$sy]
    set or [invert_ori $or]
  }
  return [list $x $y]
}

proc pos_injection {stx sty n} {
  global well_w
  global TAPCell
  set inj_buf0 [dbget -p top.insts.name pll_ana/inj/stage_0_del_1/impl]
  set inj_nor0 [dbget -p top.insts.name pll_ana/inj/cmp_nor_cmp/impl]

  set sx_buf [dbget $inj_buf0.cell.size_x]
  set sx_nor [dbget $inj_nor0.cell.size_x]
  set sx [expr $well_w+max($sx_buf, $sx_nor)]
  set sy [dbget $inj_buf0.cell.size_y]

  set x [expr $stx-$sx]
  set y $sty
  set x [is_intersect_tap $x $sx]

  # Do a mock placing of the first one to know the initial orientation
  placeInstance pll_ana/inj/stage_0_del_1/impl $x $y -fixed
  set init_or [dbget $inj_buf0.orient]
  set or $init_or
  # The initial direction is up
  set dir 1

  # Placement of the loop
  for {set j 1} {$j <= 2} {incr j} {
    for {set i 0} {$i < $n} {incr i} {
      addInst -cell ${TAPCell} -inst pll_ana/inj/tap_${i}_${j} -loc $x $y -ori $or -place_status fixed
      placeInstance pll_ana/inj/stage_${i}_del_${j}/impl [expr $x+$well_w] $y $or -fixed
      
      set y [expr $y + $dir*$sy]
      set or [invert_ori $or]
    }
  }
  addInst -cell ${TAPCell} -inst pll_ana/inj/tap_nor -loc $x $y -ori $or -place_status fixed
  placeInstance pll_ana/inj/cmp_nor_cmp/impl [expr $x+$well_w] $y $or -fixed
  set y [expr $y + $dir*$sy]
  set or [invert_ori $or]
  return [list $x $y]
}

proc pos_fine {stx sty n s} {
  # Initial direction down
  return [pos_mid_fine $stx $sty $n pll_ana/dco/fine $s -1]
}

proc pos_mid {stx sty n} {
  # Initial direction up
  return [pos_mid_fine $stx $sty $n pll_ana/dco/mid $n 1]
}

proc pos_mid_fine {stx sty n path s init_dir} {
  global well_w
  global TAPCell
  set del0_inv [dbget -p top.insts.name $path/stage_0_inv_b/impl]
  set del0_var [dbget -p top.insts.name $path/stage_0_dyn/impl]
  set del_inv0 [dbget -p top.insts.name $path/inv_0/impl]
  set del_inv1 [dbget -p top.insts.name $path/inv_1/impl]
  set sx_inv [dbget $del0_inv.cell.size_x]
  set sx_var [dbget $del0_var.cell.size_x]
  set sx_del_inv [dbget $del_inv0.cell.size_x]
  set sx [expr $well_w+$sx_inv+$sx_var]
  set sy [dbget $del0_inv.cell.size_y]

  set x [expr $stx-$sx]
  set y $sty
  set x [is_intersect_tap $x $sx]

  # Do a mock placing of the first one to know the initial orientation
  placeInstance $path/stage_0_inv_b/impl $x $y -fixed
  set init_or [dbget $del0_inv.orient]
  set or $init_or
  # The initial direction
  set dir $init_dir

  # Placement of the delay line

  for {set i 0} {$i < $n} {incr i} {
    addInst -cell ${TAPCell} -inst $path/tap_${i} -loc $x $y -ori $or -place_status fixed
    placeInstance $path/stage_${i}_inv_b/impl [expr $x+$well_w] $y $or -fixed
    placeInstance $path/stage_${i}_dyn/impl [expr $x+$well_w+$sx_inv] $y $or -fixed

    if {$i == [expr $s-1]} {
      set dir [expr -1*$dir]
      set x [is_intersect_tap [expr $x - $sx] $sx]
    } else {
      set y [expr $y + $dir*$sy]
      set or [invert_ori $or]
    }
  }
  set ne [expr floor($n/$s)]
  placeInstance $path/inv_0/impl [expr $stx-$ne*$sx-$sx_del_inv] [expr $sty] $or -fixed
  placeInstance $path/inv_1/impl [expr $stx-$ne*$sx-$sx_del_inv] [expr $sty+($s-1)*$init_dir*$sy] $or -fixed
  
  return [list [expr $stx-$ne*$sx-$sx_del_inv] [expr $sty-($s-1)*$init_dir*$sy]]
}

proc pos_coarse {stx sty n} {
  global well_w
  global TAPCell
  set loop0_upp [dbget -p top.insts.name pll_ana/dco/coarse/stage_0_impl/upp/impl]
  set loop0_mid [dbget -p top.insts.name pll_ana/dco/coarse/stage_0_impl/mid/impl]
  set loop0_dwn [dbget -p top.insts.name pll_ana/dco/coarse/stage_0_impl/dwn/impl]
  set sx_upp [dbget $loop0_upp.cell.size_x]
  set sx_mid [dbget $loop0_mid.cell.size_x]
  set sx_dwn [dbget $loop0_dwn.cell.size_x]
  set sx [expr $well_w+$sx_upp+$sx_mid+$sx_dwn]
  set sy [dbget $loop0_upp.cell.size_y]

  set x [expr $stx-$sx]
  set y $sty
  set x [is_intersect_tap $x $sx]

  # Do a mock placing of the first one to know the initial orientation
  placeInstance pll_ana/dco/coarse/stage_0_impl/upp/impl $x $y -fixed
  set init_or [dbget $loop0_upp.orient]
  set or $init_or
  # The initial direction is down
  set dir -1

  # Placement of the loop
  for {set i 0} {$i < $n} {incr i} {
    addInst -cell ${TAPCell} -inst pll_ana/dco/coarse/stage_${i}_impl/tap -loc $x $y -ori $or -place_status fixed
    placeInstance pll_ana/dco/coarse/stage_${i}_impl/upp/impl [expr $x+$well_w] $y $or -fixed
    placeInstance pll_ana/dco/coarse/stage_${i}_impl/mid/impl [expr $x+$well_w+$sx_upp] $y $or -fixed
    placeInstance pll_ana/dco/coarse/stage_${i}_impl/dwn/impl [expr $x+$well_w+$sx_upp+$sx_mid] $y $or -fixed
    
    set y [expr $y + $dir*$sy]
    set or [invert_ori $or]
  }
  return [list $x $y]
}

