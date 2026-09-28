// The "analog" part of the PLL
`timescale 1fs/1fs

`ifndef SIMULATION
    `define INJECTION_TOP PLL_INJECTION
`else
    `define INJECTION_TOP sim_pll_injection
`endif

module PLL_ANALOG #(
    parameter integer COARSE_NDELS = 15, // 4-bit coarse
    parameter integer MID_NDELS = 15, // 4-bit mid
    parameter integer FINE_NDELS = 31, // 5-bit fine
    parameter integer IL_NDELS = 4
) (
`ifdef WITH_POWER
    inout VDD, VSS,
`endif
    input [COARSE_NDELS-1:0] COARSE_MUX,
    input [MID_NDELS-1:0] MID_MUX,
    input [FINE_NDELS-1:0] FINE_MUX,
    input DCO_EN, REF, INJ_EN,
    output [1:0] SS_BBPD,
    output OUT, MID_OUT, INJ_EDGE
);
    wire INJ_WIN;

    `INJECTION_TOP #(
        .NDELS(IL_NDELS)
    ) inj (
`ifdef WITH_POWER
        .VDD(VDD), .VSS(VSS),
`endif
        .REF(REF), .INJ_EN(INJ_EN),
        .INJ_EDGE(INJ_EDGE), .INJ_WIN(INJ_WIN)
    );

    PLL_ILDCO #(
        .COARSE_NDELS(COARSE_NDELS),
        .MID_NDELS(MID_NDELS),
        .FINE_NDELS(FINE_NDELS)
    ) dco (
`ifdef WITH_POWER
        .VDD(VDD), .VSS(VSS),
`endif
        .COARSE_MUX(COARSE_MUX),
        .MID_MUX(MID_MUX),
        .FINE_MUX(FINE_MUX),
        .INJ_EDGE(INJ_EDGE), .INJ_WIN(INJ_WIN), .DCO_EN(DCO_EN),
        .SS_BBPD(SS_BBPD),
        .OUT(OUT), .MID_OUT(MID_OUT)
    );

endmodule