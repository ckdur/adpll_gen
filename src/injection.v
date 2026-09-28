// Several versions of the injection

(* keep_hierarchy = "yes" *)
module PLL_INJECTION # (
    parameter integer NDELS = 4,
    parameter integer VERSION = 1 // 0 for AND-based, 1 for NOR-based
) (
`ifdef WITH_POWER
    inout VDD, VSS,
`endif
    input REF, INJ_EN,
    output INJ_EDGE, INJ_WIN
);
    genvar i;
    wire [NDELS:0] CHAIN_1;
    wire [NDELS:0] CHAIN_2;
    wire REF_N;
    wire CHAIN_OUT;
    assign CHAIN_1[0] = REF;
    assign CHAIN_2[0] = CHAIN_1[NDELS];
    assign INJ_EDGE = CHAIN_2[0];
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
