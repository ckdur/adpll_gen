// Analog definition of
// The total implementation of Symmetrical Multiplexer and Symmetrical SSBBPD

(* keep_hierarchy = "yes" *)
module PLL_SYM (
`ifdef WITH_POWER 
    inout VDD, VSS,
`endif
    input INJ_WIN, DCO_EN,
    input INJ_EDGE, FINE_OUT,
    output [1:0] SS_BBPD,
    output OUT,
    // Copies (inverted) of the two balanced nets, from the dummy inverters that balance their loads.
    // Used by il_dco.v to sample the level of the DCO (OSC_LVL) at the injected edge (INJ_LVL falls)
    output OSC_LVL, INJ_LVL
);
    // Symmetric balancer
    wire OSC_BALANCED, INJ_EDGE_BALANCED;
    PLL_CELL_CLKINVX1 osc_slope_balancer(
`ifdef WITH_POWER 
        .VDD(VDD), .VSS(VSS), 
`endif
        .I(FINE_OUT), .ZN(OSC_BALANCED));
    PLL_CELL_CLKINVX1 inj_slope_balancer(
`ifdef WITH_POWER 
        .VDD(VDD), .VSS(VSS), 
`endif
        .I(INJ_EDGE), .ZN(INJ_EDGE_BALANCED));

    wire OSC_DUMMY, INJ_DUMMY;
    assign OSC_LVL = OSC_DUMMY;
    assign INJ_LVL = INJ_DUMMY;
    PLL_CELL_CLKINVX1 osc_dummy_inv(
`ifdef WITH_POWER 
        .VDD(VDD), .VSS(VSS), 
`endif
        .I(OSC_BALANCED), .ZN(OSC_DUMMY));
    PLL_CELL_CLKINVX1 inj_dummy_inv(
`ifdef WITH_POWER 
        .VDD(VDD), .VSS(VSS), 
`endif
        .I(INJ_EDGE_BALANCED), .ZN(INJ_DUMMY));

    // Sym. MUX
    PLL_SYM_MUX sym_mux(
`ifdef WITH_POWER 
        .VDD(VDD), .VSS(VSS), 
`endif    
        .INJ_WIN(INJ_WIN), .DCO_EN(DCO_EN), 
        .INJ_EDGE_BALANCED(INJ_EDGE_BALANCED), .OSC_BALANCED(OSC_BALANCED),
        .OSC_LVL(OSC_DUMMY),
        .OUT(OUT));

    // Subsampling bang-bang PD (SS-BBPD)
    PLL_SSBBPD ssbbpd_impl(
`ifdef WITH_POWER 
        .VDD(VDD), .VSS(VSS), 
`endif   
        .INJ_EDGE_BALANCED(INJ_EDGE_BALANCED), .OSC_BALANCED(OSC_BALANCED),
        .SS_BBPD(SS_BBPD));
endmodule
