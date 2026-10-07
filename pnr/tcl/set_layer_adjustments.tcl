set_global_routing_layer_adjustment * $::env(GRT_ADJUSTMENT)

set array [split $::env(GRT_LAYER_ADJUSTMENTS) " "]

set layer_names [list]
set layers [$::tech getLayers]
foreach layer $layers {
    if { [$layer getRoutingLevel] >= 1 } {
        lappend layer_names [$layer getName]
    }
}

set i 0
foreach adjustment $array {
    set layer_name [lindex $layer_names $i]
    set_global_routing_layer_adjustment $layer_name $adjustment
    incr i
}
