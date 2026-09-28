// Analog definition of
// Symmetrical multiplexer 

(* keep_hierarchy = "yes" *)
module PLL_SYM_MUX (
`ifdef WITH_POWER 
    inout VDD, VSS,
`endif
    input INJ_WIN, DCO_EN,
    input INJ_EDGE_BALANCED, OSC_BALANCED,
    output OUT
);
    // Sym. MUX
    wire DCO_EN_INJ_WIN;
    PLL_CELL_NOR2BX1 norb_en_inj(
`ifdef WITH_POWER 
        .VDD(VDD), .VSS(VSS), 
`endif
        .A0(DCO_EN), .B0(INJ_WIN), .ZN(DCO_EN_INJ_WIN));

    wire OSC_INJ, REF_INJ;
    PLL_CELL_NAND2BX1 nand_ref(
`ifdef WITH_POWER 
        .VDD(VDD), .VSS(VSS), 
`endif
        .A0(INJ_EDGE_BALANCED), .B0(INJ_WIN), .ZN(REF_INJ));
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
