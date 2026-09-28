// Simulation model of the PLL_INJECTION
`timescale 1fs/1fs

module sim_pll_injection # (
    parameter integer NDELS = 4,
    parameter integer VERSION = 1 // 0 for AND-based, 1 for NOR-based
) (
    inout VDD, VSS, // ignored
    input REF, INJ_EN,
    output reg INJ_EDGE, 
    output INJ_WIN
);
    reg DEL_REF, DEL_EDGE;

    // Extracted from test_pll_injection.sp
    always @(REF) INJ_EDGE = #(74267) REF; // tedge_start = 7.4267e-11
    always @(REF) DEL_REF = #(14077) REF; // twin_start = 1.4077e-11
    always @(REF) DEL_EDGE = #(14077 + 150210) REF; // twin_start + twin = 1.4077e-11 + 1.5021e-10

    // Generation of the window
    assign INJ_WIN = !DEL_REF && DEL_EDGE && INJ_EN;

endmodule