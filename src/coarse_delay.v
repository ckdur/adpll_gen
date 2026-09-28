// See LICENSE for details

// Netlist for a coarse delay single cell
(* keep_hierarchy = "yes" *)
module COARSE_DELAY_CELL(
`ifdef WITH_POWER 
    inout VDD, VSS,
`endif
    input MUX, IN, CHAIN_IN,
    output OUT, CHAIN_OUT
);
    wire PATH_0;
    PLL_CELL_NAND2X1  upp(
`ifdef WITH_POWER 
        .VDD(VDD), .VSS(VSS), 
`endif
        .A0(MUX), .A1(IN), .ZN(CHAIN_OUT));
    PLL_CELL_NAND2BX1 mid(
`ifdef WITH_POWER 
        .VDD(VDD), .VSS(VSS), 
`endif
        .A0(MUX), .B0(IN), .ZN(PATH_0));
    PLL_CELL_NAND2X1  dwn(
`ifdef WITH_POWER 
        .VDD(VDD), .VSS(VSS), 
`endif
        .A0(PATH_0), .A1(CHAIN_IN), .ZN(OUT));
    
endmodule

// The coarse delay module
(* keep_hierarchy = "yes" *)
module COARSE_DELAY # (
    parameter integer NDELS = 15
) (
`ifdef WITH_POWER 
    inout VDD, VSS,
`endif
    input [NDELS-1:0] MUX,
    input IN,
    output OUT
);
  
    genvar i;
    wire [NDELS:0] FCHAIN; // The ones that go forward
    wire [NDELS:0] RCHAIN; // The ones that go backwards
    assign FCHAIN[0] = IN;
    assign OUT = RCHAIN[0];
    generate
        for(i = 0; i < NDELS; i = i + 1) begin : stage
            COARSE_DELAY_CELL impl(
`ifdef WITH_POWER 
                .VDD(VDD), .VSS(VSS),
`endif
                .MUX(MUX[i]), .IN(FCHAIN[i]), .CHAIN_IN(RCHAIN[i+1]),
                .OUT(RCHAIN[i]), .CHAIN_OUT(FCHAIN[i+1])
            );
        end
    endgenerate
    // The last one probably is a buffer?
    // assign RCHAIN[NDELS] = FCHAIN[NDELS];
    PLL_CELL_BUFFX0 impl_last(
`ifdef WITH_POWER 
        .VDD(VDD), .VSS(VSS), 
`endif
        .I(FCHAIN[NDELS]), .Z(RCHAIN[NDELS]));
endmodule
