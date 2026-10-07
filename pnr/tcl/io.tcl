# Copied from librelane

if { [namespace exists ::ord] } {
    set ::db [::ord::get_db]
    set ::chip [$::db getChip]
    set ::tech [$::db getTech]
    set ::block [$::chip getBlock]
    set ::dbu [$::tech getDbUnitsPerMicron]
    set ::libs [$::db getLibs]
}

namespace eval lln {
    proc get_corner_names {} {
        # returns: names as a Tcl list, compatible with both OpenSTA 2 and 3
        if {[string length [namespace which sta::scenes]] != 0} {
            # scenes are bridged as a list of strings
            return [sta::scenes]
        } else {
            # corners are not bridged as strings
            set result [list]
            foreach corner [sta::corners] {
                lappend result [$corner name]
            }
            return $result
        }
    }
    proc get_corner_dict {} {
        # returns: Tcl dictionary from corner names to whatever object is
        # interpreted as a corner for internal commands that expect corners:
        # - in OpenSTA 3, that's the scene's name again
        # - in OpenSTA 2, that's an opaque Tcl pointer
        set result [dict create]
        if {[string length [namespace which sta::scenes]] != 0} {
            foreach scene [sta::scenes] {
                dict set result $scene $scene
            }
        } else {
            foreach corner [sta::corners] {
                dict set result [$corner name] $corner
            }
        }
        return $result
    }

    proc set_sta_cmd_corner {corner_name} {
        if {[string length [namespace which sta::set_cmd_scene]] != 0} {
            sta::set_cmd_scene $corner_name
        } else {
            set corner_object [sta::find_corner $corner_name]
            sta::set_cmd_corner $corner_object
        }
    }
};

proc get_layers {args} {
    sta::parse_key_args "get_layers" args \
        keys {-types -map}\
        flags {-constrained}

    if { ![info exists keys(-types)] } {
        puts stderr "\[ERROR\] Invalid usage of get_layers: -types is required."
        return -code error
    }

    set layers [$::tech getLayers]
    set result [list]
    set adding [expr ![info exists flags(-constrained)]]
    foreach layer $layers {
        set name [$layer getName]
        if {"$::env(RT_MIN_LAYER)" == "$name"} {
            set adding 1
        }
        if { [lsearch $keys(-types) [$layer getType]] != -1 && $adding} {
            lappend result $layer
        }

        if {"$::env(RT_MAX_LAYER)" == "$name"} {
            set adding [info exists flags(-constrained)]
        }

    }
    if { [info exists keys(-map)] } {
        set result [lmap layer $result "\$layer $keys(-map)"]
    }
    return $result
}

proc append_if_exists_argument {list_arg glob_variable_name option} {
    upvar $list_arg local_array
    if [info exists ::env($glob_variable_name) ] {
        lappend local_array $option $::env($glob_variable_name)
    }
}

proc append_if_flag {list_arg glob_variable_name flag} {
    upvar $list_arg local_array
    if { [info exists ::env($glob_variable_name)] && $::env($glob_variable_name) } {
        lappend local_array $flag
    }
}
proc append_if_not_flag {list_arg glob_variable_name flag} {
    upvar $list_arg local_array
    if { [info exists ::env($glob_variable_name)] && !$::env($glob_variable_name) } {
        lappend local_array $flag
    }
}

proc append_if_equals {list_arg glob_variable_name value flag} {
    upvar $list_arg local_array
    if { [info exists ::env($glob_variable_name)] && $::env($glob_variable_name) == $value } {
        lappend local_array $flag
    }
}
