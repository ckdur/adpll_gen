// Microdefinition of the cells
// Map the technology standard cells here
// Mapped using the icsprout 55nm ics55_LLSC_H7CR cells

//`define WITH_POWER
//`define WITH_BODY

module PLL_CELL_INVX1(
`ifdef WITH_POWER
  inout VDD, VSS,
`endif
  input I,
  output ZN
);
  // INVX1 -> INVX1H7R
  INVX1H7R impl(
`ifdef WITH_POWER
    .VDD(VDD), .VSS(VSS), 
`endif
    .A(I), .Y(ZN)
  );
endmodule

module PLL_CELL_INVX2(
`ifdef WITH_POWER
  inout VDD, VSS,
`endif
  input I,
  output ZN
);
  // INVX2 -> INVX2H7R
  INVX2H7R impl(
`ifdef WITH_POWER
    .VDD(VDD), .VSS(VSS), 
`endif
    .A(I), .Y(ZN)
  );
endmodule

module PLL_CELL_INVX5(
`ifdef WITH_POWER
  inout VDD, VSS,
`endif
  input I,
  output ZN
);
  // INVX5 -> INVX5H7R
  INVX5H7R impl(
`ifdef WITH_POWER
    .VDD(VDD), .VSS(VSS), 
`endif
    .A(I), .Y(ZN)
  );
endmodule

module PLL_CELL_INVX9(
`ifdef WITH_POWER
  inout VDD, VSS,
`endif
  input I,
  output ZN
);
  // INVX9 -> INVX8H7R
  INVX8H7R impl(
`ifdef WITH_POWER
    .VDD(VDD), .VSS(VSS), 
`endif
    .A(I), .Y(ZN)
  );
endmodule

module PLL_CELL_NAND3X8(
`ifdef WITH_POWER
  inout VDD, VSS,
`endif
  input A0, A1, A2, // NOTE: A1 should be ALWAYS the middle one. Check it on the spice.
  output ZN
);
  // NAND3X8 -> NAND3X8H7R
  NAND3X8H7R impl(
`ifdef WITH_POWER
    .VDD(VDD), .VSS(VSS), 
`endif
    // A0 Should be to the gate that goes to GND
    .A(A2), .B(A1), .C(A0), .Y(ZN)
  );

endmodule

module PLL_CELL_NAND3X1(
`ifdef WITH_POWER
  inout VDD, VSS,
`endif
  input A0, A1, A2,
  output ZN
);
  // NAND3X1 -> NAND3X1H7R
  NAND3X1H7R impl(
`ifdef WITH_POWER
    .VDD(VDD), .VSS(VSS), 
`endif
    // A0 Should be to the gate that goes to GND
    .A(A2), .B(A1), .C(A0), .Y(ZN)
  );

endmodule

module PLL_CELL_NAND2X1(
`ifdef WITH_POWER
  inout VDD, VSS,
`endif
  input A0, A1,
  output ZN
);
  // NAND2X1 -> NAND2X1H7R
  NAND2X1H7R impl(
`ifdef WITH_POWER
    .VDD(VDD), .VSS(VSS), 
`endif
    .A(A0), .B(A1), .Y(ZN)
  );

endmodule

module PLL_CELL_NOR2X1(
`ifdef WITH_POWER
  inout VDD, VSS,
`endif
  input A0, A1,
  output ZN
);
  // NAND2X1 -> NOR2X1H7R
  NOR2X1H7R impl(
`ifdef WITH_POWER
    .VDD(VDD), .VSS(VSS), 
`endif
    .A(A0), .B(A1), .Y(ZN)
  );

endmodule

module PLL_CELL_NAND2BX1(
`ifdef WITH_POWER
  inout VDD, VSS,
`endif
  input A0, B0, // A0 is the negated one
  output ZN
);
  // NAND2BX1 -> NAND2BX1H7R
  NAND2BX1H7R impl(
`ifdef WITH_POWER
    .VDD(VDD), .VSS(VSS), 
`endif
    .AN(A0), .B(B0), .Y(ZN)
  );

endmodule

module PLL_CELL_NOR2BX1(
`ifdef WITH_POWER
  inout VDD, VSS,
`endif
  input A0, B0, // A0 is the negated one
  output ZN
);
  // NAND2BX1 -> NOR2BX1H7R
  NOR2BX1H7R impl(
`ifdef WITH_POWER
    .VDD(VDD), .VSS(VSS), 
`endif
    .AN(A0), .B(B0), .Z(ZN)
  );

endmodule

module PLL_CELL_BUFFX0(
`ifdef WITH_POWER
  inout VDD, VSS,
`endif
  input I,
  output Z
);
  // BUFFX0 -> BUFX0P5H7R
  BUFX0P5H7R impl(
`ifdef WITH_POWER
    .VDD(VDD), .VSS(VSS), 
`endif
    .A(I), .Y(Z)
  );

endmodule

module PLL_CELL_AND2X1(
`ifdef WITH_POWER
  inout VDD, VSS,
`endif
  input A0, A1,
  output Z
);
  // AND2X1 -> AND2X1H7R
  AND2X1H7R impl(
`ifdef WITH_POWER
    .VDD(VDD), .VSS(VSS), 
`endif
    .A(A0), .B(A1), .Y(Z)
  );

endmodule

module PLL_CELL_CLKINVX1(
`ifdef WITH_POWER
  inout VDD, VSS,
`endif
  input I,
  output ZN
);
  // CLKINVX1 -> BUFX1H7R (No clock buffer)
  BUFX1H7R impl(
`ifdef WITH_POWER
    .VDD(VDD), .VSS(VSS), 
`endif
    .A(I), .Y(ZN)
  );
endmodule

module PLL_CELL_DFFNQX1(
`ifdef WITH_POWER
  inout VDD, VSS,
`endif
  input D, CKN,
  output Q
);
  // DFFNQX1 -> DFFNQX1H7R
  DFFNQX1H7R impl(
`ifdef WITH_POWER
    .VDD(VDD), .VSS(VSS), 
`endif
    .D(D), .CKN(CKN), .Q(Q)
  );
endmodule

module PLL_CELL_DFFQX1(
`ifdef WITH_POWER
  inout VDD, VSS,
`endif
  input D, CK,
  output Q
);
  // DFFQX1 -> DFFQX1H7R
  DFFQX1H7R impl(
`ifdef WITH_POWER
    .VDD(VDD), .VSS(VSS), 
`endif
    .D(D), .CK(CK), .Q(Q)
  );
endmodule
