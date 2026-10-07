getPinAssignMode -pinEditInBatch -quiet

editPin -fixOverlap 1 -unit TRACK -spreadDirection clockwise -side Top -layer 4 \
-spreadType side -spacing 2 \
-pin {{LOCKED} {ERR}}

editPin -fixOverlap 1 -unit TRACK -spreadDirection counterclockwise -side Bottom -layer 4 \
-spreadType side -spacing 2 \
-pin {{REF} {RST_N} \
      {FCW[0]} {FCW[1]} {FCW[2]} {FCW[3]} {FCW[4]} {FCW[5]} {FCW[6]} {FCW[7]}}

editPin -fixOverlap 1 -unit TRACK -spreadDirection clockwise -side Left -layer 5 \
-spreadType side -spacing 2 \
-pin {{KP[0]} {KP[1]} {KP[2]}  {KP[3]}  {KP[4]}  {KP[5]}  {KP[6]}  {KP[7]} \
      {KP[8]} {KP[9]} {KP[10]} {KP[11]} {KP[12]} {KP[13]} {KP[14]} {KP[15]} \
      {KI[0]} {KI[1]} {KI[2]}  {KI[3]}  {KI[4]}  {KI[5]}  {KI[6]}  {KI[7]} \
      {KI[8]} {KI[9]} {KI[10]} {KI[11]} {KI[12]} {KI[13]} {KI[14]} {KI[15]} \
}

editPin -fixOverlap 1 -unit TRACK -spreadDirection clockwise -side Right -layer 5 \
-spreadType side -spacing 2 \
-pin {{OUT} {SET_DIV[0]} {SET_DIV[1]} {SET_DIV[2]} {SET_DIV[3]} {SET_DIV[4]} \
      {SET_DIV[5]} {SET_DIV[6]} {SET_DIV[7]} {LOAD_DIV} {INJ_EN} {DSM_EN_DT} \
      {DSM_EN_SHDT} {DSM_ORDER[0]} {DSM_ORDER[1]} {OUT_DIV} \
}

setPinAssignMode -pinEditInBatch false
