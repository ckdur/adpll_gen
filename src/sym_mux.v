// Analog definition of
// Symmetrical multiplexer 

(* keep_hierarchy = "yes" *)
module PLL_SYM_MUX (
`ifdef WITH_POWER 
    inout VDD, VSS,
`endif
    input INJ_WIN, DCO_EN,
    input INJ_EDGE_BALANCED, OSC_BALANCED,
    input OSC_LVL,  // !OSC_BALANCED, from the dummy inverter of PLL_SYM (does not load OSC_BALANCED)
    output OUT
);
    // Guarded window. The select of the mux only switches without a glitch while both inputs have the same
    // level, so the window may only open while the DCO is still low (before its rising edge, like the
    // injected edge). If the DCO is already high when INJ_WIN rises (its edge came early, or the ring is on
    // the other half period), this injection is skipped: SKIP is set and blocks the window until INJ_WIN
    // falls. The window always closes with INJ_WIN (holding it until the DCO is high can deadlock: the mux is
    // inside the ring, so the DCO edge may never come while OUT is held).
    // Without the guard, an early DCO edge gives a runt pulse on OUT, and the ring can stay locked on the
    // edges of the window (seen in the transistor-level simulation with the injection enabled at an
    // arbitrary phase).
    //   SKIP: set by INJ_WIN && !OSC_LVL, reset by !INJ_WIN
    //   WIN:  set by INJ_WIN && OSC_LVL && !SKIP, reset by !INJ_WIN
    wire OSC_LVL_N, SKIP, SKIP_N, SKIP_SET_N, WIN, WIN_N, SET_N;
    PLL_CELL_INVX1 lvl_inv(
`ifdef WITH_POWER 
        .VDD(VDD), .VSS(VSS), 
`endif
        .I(OSC_LVL), .ZN(OSC_LVL_N));
    PLL_CELL_NAND2X1 skip_set(
`ifdef WITH_POWER 
        .VDD(VDD), .VSS(VSS), 
`endif
        .A0(INJ_WIN), .A1(OSC_LVL_N), .ZN(SKIP_SET_N));
    PLL_CELL_NAND2X1 skip_q(
`ifdef WITH_POWER 
        .VDD(VDD), .VSS(VSS), 
`endif
        .A0(SKIP_SET_N), .A1(SKIP_N), .ZN(SKIP));
    PLL_CELL_NAND2X1 skip_qn(
`ifdef WITH_POWER 
        .VDD(VDD), .VSS(VSS), 
`endif
        .A0(INJ_WIN), .A1(SKIP), .ZN(SKIP_N));
    PLL_CELL_NAND3X1 win_set(
`ifdef WITH_POWER 
        .VDD(VDD), .VSS(VSS), 
`endif
        .A0(INJ_WIN), .A1(OSC_LVL), .A2(SKIP_N), .ZN(SET_N));
    PLL_CELL_NAND2X1 win_q(
`ifdef WITH_POWER 
        .VDD(VDD), .VSS(VSS), 
`endif
        .A0(SET_N), .A1(WIN_N), .ZN(WIN));
    PLL_CELL_NAND2X1 win_qn(
`ifdef WITH_POWER 
        .VDD(VDD), .VSS(VSS), 
`endif
        .A0(INJ_WIN), .A1(WIN), .ZN(WIN_N));

    wire DCO_EN_INJ_WIN;
    PLL_CELL_NOR2BX1 norb_en_inj(
`ifdef WITH_POWER 
        .VDD(VDD), .VSS(VSS), 
`endif
        .A0(DCO_EN), .B0(WIN), .ZN(DCO_EN_INJ_WIN));

    // OUT = WIN ? INJ_EDGE_BALANCED : (OSC_BALANCED & DCO_EN)
    // Both inputs go through the same cells (NAND2 + NAND2, after the balancing inverters of PLL_SYM),
    // and they are the same nets compared by the SS-BBPD latch. So the injected edge is the rising
    // edge of OUT, the same edge that the loop aligns to the reference.
    // NOTE: It was a NAND2B (inverted INJ_EDGE_BALANCED), which injected the falling edge of OUT while
    // the loop aligned the rising one: a glitch on OUT on every injection.
    wire OSC_INJ, REF_INJ;
    PLL_CELL_NAND2X1 nand_ref(
`ifdef WITH_POWER 
        .VDD(VDD), .VSS(VSS), 
`endif
        .A0(INJ_EDGE_BALANCED), .A1(WIN), .ZN(REF_INJ));
    PLL_CELL_NAND2X1 nand_inj(
`ifdef WITH_POWER 
        .VDD(VDD), .VSS(VSS), 
`endif
        .A0(OSC_BALANCED), .A1(DCO_EN_INJ_WIN), .ZN(OSC_INJ));
    PLL_CELL_NAND2X1 nand_pll(
`ifdef WITH_POWER 
        .VDD(VDD), .VSS(VSS), 
`endif
        .A0(REF_INJ), .A1(OSC_INJ), .ZN(OUT));
endmodule
