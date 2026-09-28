// See LICENSE for details

// Netlist for a mid delay single cell
(* keep_hierarchy = "yes" *)
module MID_DELAY_CELL(
`ifdef WITH_POWER 
    inout VDD, VSS,
`endif
    input MUX, IN,
    output OUT
);
    wire UNCONNECTED, LOAD, MUXB;
    PLL_CELL_INVX1   inv_b(
`ifdef WITH_POWER 
        .VDD(VDD), .VSS(VSS), 
`endif
        .I(MUX), .ZN(MUXB));
    PLL_CELL_INVX2   inv_0(
`ifdef WITH_POWER 
        .VDD(VDD), .VSS(VSS), 
`endif
        .I(IN), .ZN(LOAD));
    PLL_CELL_NAND3X8 dyn_0(
`ifdef WITH_POWER 
        .VDD(VDD), .VSS(VSS), 
`endif
        .A0(MUX), .A1(LOAD), .A2(MUXB), .ZN(UNCONNECTED));
    PLL_CELL_INVX2   inv_1(
`ifdef WITH_POWER 
        .VDD(VDD), .VSS(VSS), 
`endif
        .I(LOAD), .ZN(OUT));
endmodule

// The mid delay module, buffered
(* keep_hierarchy = "yes" *)
module MID_DELAY_BUFFERED # (
    parameter integer NDELS = 16
) (
`ifdef WITH_POWER 
    inout VDD, VSS,
`endif
    input [NDELS-1:0] MUX,
    input IN,
    output OUT
);
    genvar i;
    wire [NDELS:0] CHAIN;
    assign CHAIN[0] = IN;
    assign OUT = CHAIN[NDELS];
    generate
        for(i = 0; i < NDELS; i = i + 1) begin : stage
            MID_DELAY_CELL impl(
                .VDD(VDD), .VSS(VSS),
                .MUX(MUX[i]), .IN(CHAIN[i]),
                .OUT(CHAIN[i+1])
            );
        end
    endgenerate
endmodule

// The mid delay module, non-buffered
(* keep_hierarchy = "yes" *)
module MID_DELAY # (
    parameter integer NDELS = 15
) (
`ifdef WITH_POWER 
    inout VDD, VSS,
`endif
    input [NDELS-1:0] MUX,
    input IN,
    output OUT
);
`ifndef SIMULATION
    // Synthesizable version
    wire [NDELS-1:0] UNCONNECTED, MUXB;
    wire LOAD;

    PLL_CELL_INVX2   inv_0(
`ifdef WITH_POWER 
        .VDD(VDD), .VSS(VSS), 
`endif
        .I(IN), .ZN(LOAD));

    genvar i;
    generate
        for(i = 0; i < NDELS; i = i + 1) begin : stage
            PLL_CELL_INVX1   inv_b(
`ifdef WITH_POWER 
                .VDD(VDD), .VSS(VSS), 
`endif
                .I(MUX[i]), .ZN(MUXB[i]));
            PLL_CELL_NAND3X8 dyn(
`ifdef WITH_POWER 
                .VDD(VDD), .VSS(VSS), 
`endif
                .A0(MUX[i]), .A1(LOAD), .A2(MUXB[i]), .ZN(UNCONNECTED[i]));
        end
    endgenerate

    PLL_CELL_INVX2   inv_1(
`ifdef WITH_POWER 
        .VDD(VDD), .VSS(VSS), 
`endif
        .I(LOAD), .ZN(OUT));
`else
    // Digital simulation version
    // This circuit "can" work, but is not ideal. This is just for "sdf" tricking

    wire [NDELS:0] OUTS;
    wire [NDELS:0] LOADS;
    wire [(((NDELS+1)*NDELS)-1):0] UNCONNECTED, MUXB;
    genvar i, j;
    generate
        for(j = 0; j <= NDELS; j = j + 1) begin : superstage
            PLL_CELL_INVX2   inv_0(
`ifdef WITH_POWER 
                .VDD(VDD), .VSS(VSS), 
`endif
                .I(IN), .ZN(LOADS[j]));
            for(i = 0; i < /*NDELS*/j; i = i + 1) begin : stage
                PLL_CELL_INVX1   inv_b(
`ifdef WITH_POWER 
                    .VDD(VDD), .VSS(VSS), 
`endif
                    .I(MUX[i]), .ZN(MUXB[j*NDELS+i]));
                
                PLL_CELL_NAND3X8 dyn_2(
`ifdef WITH_POWER 
                    .VDD(VDD), .VSS(VSS), 
`endif
                    .A0(LOADS[j]), .A1(MUX[i]), .A2(MUXB[j*NDELS+i]), .ZN(UNCONNECTED[j*NDELS+i]));
            end
            PLL_CELL_INVX2   inv_1(
`ifdef WITH_POWER 
                .VDD(VDD), .VSS(VSS), 
`endif
                .I(LOADS[j]), .ZN(OUTS[j]));
        end
    endgenerate
    sim_mux #(.NDELS(NDELS)) mux_a(.MUX(MUX), .IN(OUTS), .OUT(OUT));
`endif
  
endmodule
