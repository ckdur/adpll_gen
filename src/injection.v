// Several versions of the injection

(* keep_hierarchy = "yes" *)
module PLL_INJECTION # (
    parameter integer NDELS = 4,
    parameter integer VERSION = 1, // 0 for AND-based, 1 for NOR-based
    parameter integer CK_NDELS = 2*NDELS, // Buffers from the end of the window to BBPD_CK
    parameter integer EDGE_EXTRA = 3      // Extra buffers before INJ_EDGE: the window latch of sym_mux.v
                                          // delays the opening, this keeps the edge centered in the window
) (
`ifdef WITH_POWER
    inout VDD, VSS,
`endif
    input REF, INJ_EN,
    output INJ_EDGE, INJ_WIN,
    output BBPD_CK
);
    // Timing after the falling edge of REF (NDELS buffers = one "tedge"):
    //   INJ_WIN rises:  NOR delay
    //   INJ_EDGE falls: NDELS + EDGE_EXTRA buffers (the injected edge, in the window)
    //   INJ_WIN falls:  2 NDELS + EDGE_EXTRA buffers (+ NAND + NOR)
    //   BBPD_CK falls:  CK_NDELS buffers after the end of the window. The SS-BBPD latch is captured
    //                   here, once it has arbitrated between the injected and the natural edge, and
    //                   before the natural edge goes back (half a DCO period). See il_dco.v
    genvar i;
    wire [NDELS+EDGE_EXTRA:0] CHAIN_1;
    wire [NDELS:0] CHAIN_2;
    wire [CK_NDELS:0] CHAIN_3;
    wire REF_N;
    wire CHAIN_OUT;
    assign CHAIN_1[0] = REF;
    assign CHAIN_2[0] = CHAIN_1[NDELS+EDGE_EXTRA];
    assign CHAIN_3[0] = CHAIN_2[NDELS];
    assign INJ_EDGE = CHAIN_2[0];
    assign BBPD_CK = CHAIN_3[CK_NDELS];
    generate
        for(i = 0; i < NDELS; i = i + 1) begin : stage
            PLL_CELL_BUFFX0 del_1(
`ifdef WITH_POWER 
                .VDD(VDD), .VSS(VSS), 
`endif
                .I(CHAIN_1[i]), .Z(CHAIN_1[i+1]));
            PLL_CELL_BUFFX0 del_2(
`ifdef WITH_POWER
                .VDD(VDD), .VSS(VSS), 
`endif
                .I(CHAIN_2[i]), .Z(CHAIN_2[i+1]));
        end
        for(i = 0; i < EDGE_EXTRA; i = i + 1) begin : edgestage
            PLL_CELL_BUFFX0 del_1(
`ifdef WITH_POWER
                .VDD(VDD), .VSS(VSS), 
`endif
                .I(CHAIN_1[NDELS+i]), .Z(CHAIN_1[NDELS+i+1]));
        end
        for(i = 0; i < CK_NDELS; i = i + 1) begin : ckstage
            PLL_CELL_BUFFX0 del_3(
`ifdef WITH_POWER
                .VDD(VDD), .VSS(VSS), 
`endif
                .I(CHAIN_3[i]), .Z(CHAIN_3[i+1]));
        end
        
        if(VERSION) begin : cmp_nor
            PLL_CELL_NAND2X1 del_en(
`ifdef WITH_POWER 
                .VDD(VDD), .VSS(VSS), 
`endif
                .A0(INJ_EN), .A1(CHAIN_2[NDELS]), .ZN(CHAIN_OUT));
            PLL_CELL_NOR2X1 cmp(
`ifdef WITH_POWER 
                .VDD(VDD), .VSS(VSS), 
`endif
                .A0(CHAIN_OUT), .A1(REF), .ZN(INJ_WIN));
        end else begin : cmp_and
            PLL_CELL_AND2X1 del_en(
`ifdef WITH_POWER 
                .VDD(VDD), .VSS(VSS), 
`endif
                .A0(INJ_EN), .A1(CHAIN_2[NDELS]), .Z(CHAIN_OUT));
            PLL_CELL_INVX1 del_n(
`ifdef WITH_POWER 
                .VDD(VDD), .VSS(VSS), 
`endif
                .I(REF), .ZN(REF_N));
            PLL_CELL_AND2X1 cmp(
`ifdef WITH_POWER 
                .VDD(VDD), .VSS(VSS), 
`endif
                .A0(REF_N), .A1(CHAIN_OUT), .Z(INJ_WIN));
        end
    endgenerate

endmodule
