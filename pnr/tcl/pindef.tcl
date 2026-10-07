####################################
## Pin sides (OpenROAD)
####################################
# Only the side of each pin is constrained, place_pins decides the exact location.
# taken from the tech so this works with any PDK.

set_io_pin_constraint -region top:* -pin_names {LOCKED ERR}

set_io_pin_constraint -region bottom:* -pin_names {REF RST_N FCW[*]}

set_io_pin_constraint -region left:* -pin_names {KP[*] KI[*]}

set_io_pin_constraint -region right:* -pin_names {OUT SET_DIV[*] LOAD_DIV INJ_EN DSM_EN_DT \
                                                  DSM_EN_SHDT DSM_ORDER[*] OUT_DIV}

place_pins -hor_layers $::env(IO_PIN_H_LAYER) -ver_layers $::env(IO_PIN_V_LAYER)
