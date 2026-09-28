// This is the VCO defintiion for:
// Injection-Locked Digital-Controlled Oscillator (IL-DCO)

`ifndef SIMULATION
    `define COARSE_DELAY_TOP COARSE_DELAY
    `define MID_DELAY_TOP MID_DELAY
    `define FINE_DELAY_TOP FINE_DELAY
    `define PLL_SYM_TOP PLL_SYM
`else
    `define COARSE_DELAY_TOP sim_delay_coarse
    `define MID_DELAY_TOP sim_delay_mid
    `define FINE_DELAY_TOP sim_delay_fine
    `define PLL_SYM_TOP sim_SYM
`endif

(* keep_hierarchy = "yes" *)
module PLL_ILDCO #(
    parameter integer COARSE_NDELS = 15, // 4-bit coarse
    parameter integer MID_NDELS = 15, // 4-bit mid
    parameter integer FINE_NDELS = 31 // 5-bit fine
) (
`ifdef WITH_POWER 
    inout VDD, VSS,
`endif
    input [COARSE_NDELS-1:0] COARSE_MUX,
    input [MID_NDELS-1:0] MID_MUX,
    input [FINE_NDELS-1:0] FINE_MUX,
    input INJ_EDGE, INJ_WIN, DCO_EN,
    output [1:0] SS_BBPD,
    output OUT, MID_OUT
);

    wire COARSE_OUT;
    `COARSE_DELAY_TOP #(
        .NDELS(COARSE_NDELS)
    ) coarse (
`ifdef WITH_POWER 
        .VDD(VDD), .VSS(VSS),
`endif
        .MUX(COARSE_MUX),
        .IN(OUT), .OUT(COARSE_OUT)
    );

    `MID_DELAY_TOP #(
        .NDELS(MID_NDELS)
    ) mid (
`ifdef WITH_POWER 
        .VDD(VDD), .VSS(VSS),
`endif
        .MUX(MID_MUX),
        .IN(COARSE_OUT), .OUT(MID_OUT)
    );

    wire FINE_OUT;
    `FINE_DELAY_TOP #(
        .NDELS(FINE_NDELS)
    ) fine (
`ifdef WITH_POWER 
        .VDD(VDD), .VSS(VSS),
`endif
        .MUX(FINE_MUX),
        .IN(MID_OUT), .OUT(FINE_OUT)
    );

    // Symmetrical Multiplexer and Symmetrical SSBBPD
    wire [1:0] SS_BBPD_WIRE;
    `PLL_SYM_TOP sym(
`ifdef WITH_POWER 
        .VDD(VDD), .VSS(VSS), 
`endif
        .INJ_WIN(INJ_WIN), .DCO_EN(DCO_EN), 
        .INJ_EDGE(INJ_EDGE), .FINE_OUT(FINE_OUT),
        .SS_BBPD(SS_BBPD_WIRE), .OUT(OUT));

`ifdef SSBBPD_BYPASS
    assign SS_BBPD = SS_BBPD_WIRE;
`else
    // Here is negedge, because we want to disturb as less as possible the balance of the SSBBPD
    // With this we sample with the INJ_EDGE instead of the balanced version
    `ifndef SIMULATION
        PLL_CELL_DFFNQX1 dff_y(
`ifdef WITH_POWER 
            .VDD(VDD), .VSS(VSS), 
`endif
            .D(SS_BBPD_WIRE[0]), .Q(SS_BBPD[0]), .CKN(INJ_EDGE));
        PLL_CELL_DFFNQX1 dff_x(
`ifdef WITH_POWER 
            .VDD(VDD), .VSS(VSS), 
`endif
            .D(SS_BBPD_WIRE[1]), .Q(SS_BBPD[1]), .CKN(INJ_EDGE));
    `else
        reg [1:0] SS_BBPD_REG;
        always @(negedge INJ_EDGE) begin
            SS_BBPD_REG <= SS_BBPD_WIRE;
        end
        assign SS_BBPD = SS_BBPD_REG;
    `endif
`endif

endmodule
