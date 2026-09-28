// Digital-simulated definition of
// The total implementation of Symmetrical Multiplexer and Symmetrical SSBBPD

module sim_SYM (
    inout VDD, VSS, // ignored
    input INJ_WIN, DCO_EN,
    input INJ_EDGE, FINE_OUT,
    output reg [1:0] SS_BBPD,
    output reg OUT
);
    // Symmetric balancer (Nothing)
    wire OSC_BALANCED, INJ_EDGE_BALANCED;
    assign OSC_BALANCED = !FINE_OUT;
    assign INJ_EDGE_BALANCED = !INJ_EDGE;

    // Sym. MUX
    wire DCO_EN_INJ_WIN;
    assign DCO_EN_INJ_WIN = !(!DCO_EN || INJ_WIN); // NOR2B

    wire OSC_INJ, REF_INJ;
    assign REF_INJ = !(!INJ_EDGE_BALANCED && INJ_WIN); // NAND2B
    assign OSC_INJ = !(OSC_BALANCED && DCO_EN_INJ_WIN); // NAND2
    wire OUT_WIRE = !(REF_INJ && OSC_INJ); // NAND2

    // Subsampling bang-bang PD (SS-BBPD)
    wire [1:0] SS_BBPD_WIRE;
    sim_SSBBPD ssbbpd_impl(
        .CLK_REF(INJ_EDGE_BALANCED), .CLK_VCO(OSC_BALANCED),
        .SS_BBPD(SS_BBPD_WIRE));
    
    always @(OUT_WIRE) OUT = #(51910) OUT_WIRE; // Delay of symmetrical multiplexer
    always @(SS_BBPD_WIRE) SS_BBPD = #(82260) SS_BBPD_WIRE; // Delay of the SS_BBPD

endmodule
