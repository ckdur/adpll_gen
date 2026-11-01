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
    input BBPD_CK,
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
    wire OSC_LVL, INJ_LVL;
    `PLL_SYM_TOP sym(
`ifdef WITH_POWER 
        .VDD(VDD), .VSS(VSS), 
`endif
        .INJ_WIN(INJ_WIN), .DCO_EN(DCO_EN), 
        .INJ_EDGE(INJ_EDGE), .FINE_OUT(FINE_OUT),
        .SS_BBPD(SS_BBPD_WIRE), .OUT(OUT),
        .OSC_LVL(OSC_LVL), .INJ_LVL(INJ_LVL));

`ifdef SSBBPD_BYPASS
    assign SS_BBPD = SS_BBPD_WIRE;
`else
    // Bang-bang phase detector. The DCO edge (rising edge of OSC_BALANCED) at time e, relative to the
    // injected edge (rising edge of INJ_EDGE_BALANCED), both the inputs of the symmetric mux:
    //
    // 1. The SS-BBPD (NAND latch) arbitrates which edge came first. It has no offset (both inputs see
    //    the same cells and loads), so it sets the lock point: the natural edge on the injected one.
    //    Its result is captured with BBPD_CK, c = BBPD_CK - injected edge later (see injection.v), and
    //    it is only valid if OSC_BALANCED is still high then, i.e. for e in (c - T/2, c).
    // 2. LC = level of OSC_BALANCED at BBPD_CK (high: the latch result is valid).
    // 3. L0 = level of OSC_BALANCED at the injected edge: high for e in (-T/2, 0) (DCO early), low for
    //    (0, T/2). Used only when LC is low (e far from the lock point), where its offset does not matter.
    //
    // EARLY = LC ? latch : L0, a symmetric characteristic of +/- T/2 around the lock point. With only the
    // latch, the edges in (-T/2, c - T/2) were taken as "late", which biases the loop while the phase
    // slips and reduces the pull-in range. Requires c < T/2 (f_OUT < 1/(2c)).
    //
    // SS_BBPD = {X, Y}: 2'b01 DCO early (slow down), 2'b10 DCO late (speed up)
    // NOTE: The latch was captured with the falling edge of INJ_EDGE, before it arbitrates. That sampled
    // the level of FINE_OUT ~90ps before the injected edge, which locked the DCO with that offset.
    wire Y_Q, X_Q, LC_N, L0_N, EARLY;
    `ifndef SIMULATION
        PLL_CELL_DFFNQX1 dff_y(
`ifdef WITH_POWER 
            .VDD(VDD), .VSS(VSS), 
`endif
            .D(SS_BBPD_WIRE[0]), .Q(Y_Q), .CKN(BBPD_CK));
        // X_Q is not used (the decision only needs Y), dff_x keeps the two outputs of the latch balanced
        PLL_CELL_DFFNQX1 dff_x(
`ifdef WITH_POWER 
            .VDD(VDD), .VSS(VSS), 
`endif
            .D(SS_BBPD_WIRE[1]), .Q(X_Q), .CKN(BBPD_CK));
        // OSC_LVL = !OSC_BALANCED, so the flops store the inverted levels
        PLL_CELL_DFFNQX1 dff_lc(
`ifdef WITH_POWER 
            .VDD(VDD), .VSS(VSS), 
`endif
            .D(OSC_LVL), .Q(LC_N), .CKN(BBPD_CK));
        PLL_CELL_DFFNQX1 dff_l0(
`ifdef WITH_POWER 
            .VDD(VDD), .VSS(VSS), 
`endif
            .D(OSC_LVL), .Q(L0_N), .CKN(INJ_LVL));
        // EARLY = LC ? Y_Q : L0 = NAND(NAND(LC, Y_Q), NAND(!LC, L0))
        wire SEL_LATCH, SEL_LVL;
        PLL_CELL_NAND2BX1 sel_latch(
`ifdef WITH_POWER 
            .VDD(VDD), .VSS(VSS), 
`endif
            .A0(LC_N), .B0(Y_Q), .ZN(SEL_LATCH));
        PLL_CELL_NAND2BX1 sel_lvl(
`ifdef WITH_POWER 
            .VDD(VDD), .VSS(VSS), 
`endif
            .A0(L0_N), .B0(LC_N), .ZN(SEL_LVL));
        PLL_CELL_NAND2X1 sel_out(
`ifdef WITH_POWER 
            .VDD(VDD), .VSS(VSS), 
`endif
            .A0(SEL_LATCH), .A1(SEL_LVL), .ZN(EARLY));
        PLL_CELL_INVX1 sel_inv(
`ifdef WITH_POWER 
            .VDD(VDD), .VSS(VSS), 
`endif
            .I(EARLY), .ZN(SS_BBPD[1]));
        assign SS_BBPD[0] = EARLY;
    `else
        // Defined power-up state (the latch and flops of the circuit start in any state). Without it the X
        // goes into the loop filter of the post-synthesis simulation and stays there.
        reg Y_R = 1'b0, X_R = 1'b1, LC_R = 1'b0, L0_R = 1'b0;
        always @(negedge BBPD_CK) begin
            Y_R <= SS_BBPD_WIRE[0];
            X_R <= SS_BBPD_WIRE[1];
            LC_R <= OSC_LVL;
        end
        always @(negedge INJ_LVL) L0_R <= OSC_LVL;
        assign Y_Q = Y_R; assign X_Q = X_R; assign LC_N = LC_R; assign L0_N = L0_R;
        assign EARLY = !LC_N ? Y_Q : !L0_N;
        assign SS_BBPD = {!EARLY, EARLY};
    `endif
`endif

endmodule
