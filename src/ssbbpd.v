// Analog definition of
// Sub-Sampling Bang Bang Phase Detector (SS-BBPD)

(* keep_hierarchy = "yes" *)
module PLL_SSBBPD (
`ifdef WITH_POWER 
    inout VDD, VSS,
`endif
    input INJ_EDGE_BALANCED, OSC_BALANCED,
    output [1:0] SS_BBPD
);
    // Subsampling bang-bang PD (SS-BBPD)
    wire OUT_NANDX, OUT_NANDY;
    PLL_CELL_NAND2X1 nand_y(
`ifdef WITH_POWER 
        .VDD(VDD), .VSS(VSS), 
`endif
        .A0(INJ_EDGE_BALANCED), .A1(OUT_NANDX), .ZN(OUT_NANDY));
    PLL_CELL_NAND2X1 nand_x(
`ifdef WITH_POWER 
        .VDD(VDD), .VSS(VSS), 
`endif
        .A0(OSC_BALANCED), .A1(OUT_NANDY), .ZN(OUT_NANDX));
    PLL_CELL_BUFFX0 buf_nand_y(
`ifdef WITH_POWER 
        .VDD(VDD), .VSS(VSS), 
`endif
        .I(OUT_NANDY), .Z(SS_BBPD[0]));
    PLL_CELL_BUFFX0 buf_nand_x(
`ifdef WITH_POWER 
        .VDD(VDD), .VSS(VSS), 
`endif
        .I(OUT_NANDX), .Z(SS_BBPD[1]));
endmodule
