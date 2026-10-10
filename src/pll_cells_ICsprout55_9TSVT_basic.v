// Microdefinition of the cells
// Map the technology standard cells here
// Mapped using the icsprout 55nm ICsprout55_9TSVT_basic cells (private 9-track library)
// Same cells as pll_cells_ics55.v (ics55_LLSC_H7CR). Every cell also has the well bias pins
// VNW / VPW, tied to VDD / VSS

//`define YOSYS
//`define WITH_POWER
//`define WITH_BODY

module PLL_CELL_INVX1(
`ifdef WITH_POWER
  inout VDD, VSS,
`endif
  input I,
  output ZN
);
  // INVX1 -> INVX1_9TSVT
  (* keep *) (* dont_touch = "true" *)
  INVX1_9TSVT impl(
`ifdef WITH_POWER
    .VDD(VDD), .VSS(VSS), .VNW(VDD), .VPW(VSS),
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
  // INVX2 -> INVX2_9TSVT
  // Mainly affects the base delay of the mid-delay. INVX2>LOAD(NAND3X8)>INVX2
  (* keep *) (* dont_touch = "true" *)
  INVX2_9TSVT impl(
`ifdef WITH_POWER
    .VDD(VDD), .VSS(VSS), .VNW(VDD), .VPW(VSS),
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
  // INVX5 -> INVX5_9TSVT
  // Mainly affects the base delay of the fine-delay. INVX5>LOAD(NAND3X1)>INVX5
  (* keep *) (* dont_touch = "true" *)
  INVX5_9TSVT impl(
`ifdef WITH_POWER
    .VDD(VDD), .VSS(VSS), .VNW(VDD), .VPW(VSS),
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
  // INVX9 -> INVX8_9TSVT
  // Not actually used
  (* keep *) (* dont_touch = "true" *)
  INVX8_9TSVT impl(
`ifdef WITH_POWER
    .VDD(VDD), .VSS(VSS), .VNW(VDD), .VPW(VSS),
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
  // NAND3X8 -> NAND3X6_9TSVT x2
  // Mainly affects the base delay of the mid-delay. INVX2>LOAD(NAND3X8)>INVX2
  (* keep *) (* dont_touch = "true" *)
  NAND3X8_9TSVT impl_1(
`ifdef WITH_POWER
    .VDD(VDD), .VSS(VSS), .VNW(VDD), .VPW(VSS),
`endif
    // A0 Should be to the gate that goes to GND
    // NOTE: A0 gate ground makes the delays inverted.
    // In this library C is the NMOS next to VSS and A the one next to Y (the opposite of H7R)
    .A(A2), .B(A1), .C(A0), .Y(ZN)
  );

  (* keep *) (* dont_touch = "true" *)
  NAND3X6_9TSVT impl_2(
`ifdef WITH_POWER
    .VDD(VDD), .VSS(VSS), .VNW(VDD), .VPW(VSS),
`endif
    // A0 Should be to the gate that goes to GND
    // NOTE: A0 gate ground makes the delays inverted.
    // In this library C is the NMOS next to VSS and A the one next to Y (the opposite of H7R)
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
  // NAND3X1 -> NAND3X1_9TSVT
  // Mainly affects the base delay of the fine-delay. INVX5>LOAD(NAND3X1)>INVX5
  (* keep *) (* dont_touch = "true" *)
  NAND3X1_9TSVT impl(
`ifdef WITH_POWER
    .VDD(VDD), .VSS(VSS), .VNW(VDD), .VPW(VSS),
`endif
    // A0 Should be to the gate that goes to GND
    // NOTE: A0 gate ground makes the delays inverted.
    // In this library C is the NMOS next to VSS and A the one next to Y (the opposite of H7R)
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
  // NAND2X1 -> NAND2X1_9TSVT
  (* keep *) (* dont_touch = "true" *)
  NAND2X1_9TSVT impl(
`ifdef WITH_POWER
    .VDD(VDD), .VSS(VSS), .VNW(VDD), .VPW(VSS),
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
  // NAND2X1 -> NOR2X1_9TSVT
  (* keep *) (* dont_touch = "true" *)
  NOR2X1_9TSVT impl(
`ifdef WITH_POWER
    .VDD(VDD), .VSS(VSS), .VNW(VDD), .VPW(VSS),
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
  // NAND2BX1 -> NAND2BX1_9TSVT
  // Mainly used for the coarse delay. If want to increase coarse delay, do it here.
  (* keep *) (* dont_touch = "true" *)
  NAND2BX1_9TSVT impl(
`ifdef WITH_POWER
    .VDD(VDD), .VSS(VSS), .VNW(VDD), .VPW(VSS),
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
  // NAND2BX1 -> NOR2BX1_9TSVT
  (* keep *) (* dont_touch = "true" *)
  NOR2BX1_9TSVT impl(
`ifdef WITH_POWER
    .VDD(VDD), .VSS(VSS), .VNW(VDD), .VPW(VSS),
`endif
    .AN(A0), .B(B0), .Y(ZN)
  );

endmodule

module PLL_CELL_BUFFX0(
`ifdef WITH_POWER
  inout VDD, VSS,
`endif
  input I,
  output Z
);
  // BUFFX0 -> BUFX0P5_9TSVT
  (* keep *) (* dont_touch = "true" *)
  BUFX0P5_9TSVT impl(
`ifdef WITH_POWER
    .VDD(VDD), .VSS(VSS), .VNW(VDD), .VPW(VSS),
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
  // AND2X1 -> AND2X1_9TSVT
  (* keep *) (* dont_touch = "true" *)
  AND2X1_9TSVT impl(
`ifdef WITH_POWER
    .VDD(VDD), .VSS(VSS), .VNW(VDD), .VPW(VSS),
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
  // CLKINVX1 -> INVX1_9TSVT (No clock inverter)
  (* keep *) (* dont_touch = "true" *)
  INVX1_9TSVT impl(
`ifdef WITH_POWER
    .VDD(VDD), .VSS(VSS), .VNW(VDD), .VPW(VSS),
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
  // DFFNQX1 -> DFFNQX1_9TSVT
  (* keep *) (* dont_touch = "true" *)
  DFFNQX1_9TSVT impl(
`ifdef WITH_POWER
    .VDD(VDD), .VSS(VSS), .VNW(VDD), .VPW(VSS),
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
  // DFFQX1 -> DFFQX1_9TSVT
  (* keep *) (* dont_touch = "true" *)
  DFFQX1_9TSVT impl(
`ifdef WITH_POWER
    .VDD(VDD), .VSS(VSS), .VNW(VDD), .VPW(VSS),
`endif
    .D(D), .CK(CK), .Q(Q)
  );
endmodule

// We also define the used cells as blackboxes for yosys synthesis
`ifdef YOSYS
(* blackbox *)
module INVX1_9TSVT (
`ifdef WITH_POWER
  VDD, VSS, VNW, VPW,
`endif
  Y, A);
`ifdef WITH_POWER
  inout VDD, VSS, VNW, VPW;
`endif
	output Y;
	input A;
endmodule
(* blackbox *)
module INVX2_9TSVT (
`ifdef WITH_POWER
  VDD, VSS, VNW, VPW,
`endif
  Y, A);
`ifdef WITH_POWER
  inout VDD, VSS, VNW, VPW;
`endif
	output Y;
	input A;
endmodule
(* blackbox *)
module INVX4_9TSVT (
`ifdef WITH_POWER
  VDD, VSS, VNW, VPW,
`endif
  Y, A);
`ifdef WITH_POWER
  inout VDD, VSS, VNW, VPW;
`endif
	output Y;
	input A;
endmodule
(* blackbox *)
module INVX5_9TSVT (
`ifdef WITH_POWER
  VDD, VSS, VNW, VPW,
`endif
  Y, A);
`ifdef WITH_POWER
  inout VDD, VSS, VNW, VPW;
`endif
	output Y;
	input A;
endmodule
(* blackbox *)
module INVX8_9TSVT (
`ifdef WITH_POWER
  VDD, VSS, VNW, VPW,
`endif
  Y, A);
`ifdef WITH_POWER
  inout VDD, VSS, VNW, VPW;
`endif
	output Y;
	input A;
endmodule
(* blackbox *)
module NAND3X6_9TSVT (
`ifdef WITH_POWER
  VDD, VSS, VNW, VPW,
`endif
  Y, A, B, C);
`ifdef WITH_POWER
  inout VDD, VSS, VNW, VPW;
`endif
	output Y;
	input A, B, C;
endmodule
(* blackbox *)
module NAND3X8_9TSVT (
`ifdef WITH_POWER
  VDD, VSS, VNW, VPW,
`endif
  Y, A, B, C);
`ifdef WITH_POWER
  inout VDD, VSS, VNW, VPW;
`endif
	output Y;
	input A, B, C;
endmodule
(* blackbox *)
module NAND3X1_9TSVT (
`ifdef WITH_POWER
  VDD, VSS, VNW, VPW,
`endif
  Y, A, B, C);
`ifdef WITH_POWER
  inout VDD, VSS, VNW, VPW;
`endif
	output Y;
	input A, B, C;
endmodule
(* blackbox *)
module NAND2X1_9TSVT (
`ifdef WITH_POWER
  VDD, VSS, VNW, VPW,
`endif
  Y, A, B);
`ifdef WITH_POWER
  inout VDD, VSS, VNW, VPW;
`endif
	output Y;
	input A, B;
endmodule
(* blackbox *)
module NOR2X1_9TSVT (
`ifdef WITH_POWER
  VDD, VSS, VNW, VPW,
`endif
  Y, A, B);
`ifdef WITH_POWER
  inout VDD, VSS, VNW, VPW;
`endif
	output Y;
	input A, B;
endmodule
(* blackbox *)
module NAND2BX1_9TSVT (
`ifdef WITH_POWER
  VDD, VSS, VNW, VPW,
`endif
  Y, AN, B);
`ifdef WITH_POWER
  inout VDD, VSS, VNW, VPW;
`endif
	output Y;
	input AN, B;
endmodule
(* blackbox *)
module NOR2BX1_9TSVT (
`ifdef WITH_POWER
  VDD, VSS, VNW, VPW,
`endif
  Y, AN, B);
`ifdef WITH_POWER
  inout VDD, VSS, VNW, VPW;
`endif
	output Y;
	input AN, B;
endmodule
(* blackbox *)
module BUFX0P5_9TSVT (
`ifdef WITH_POWER
  VDD, VSS, VNW, VPW,
`endif
  Y, A);
`ifdef WITH_POWER
  inout VDD, VSS, VNW, VPW;
`endif
	output Y;
	input A;
endmodule
(* blackbox *)
module AND2X1_9TSVT (
`ifdef WITH_POWER
  VDD, VSS, VNW, VPW,
`endif
  Y, A, B);
`ifdef WITH_POWER
  inout VDD, VSS, VNW, VPW;
`endif
	output Y;
	input A, B;
endmodule
(* blackbox *)
module DFFNQX1_9TSVT (
`ifdef WITH_POWER
  VDD, VSS, VNW, VPW,
`endif
  Q, D, CKN);
`ifdef WITH_POWER
  inout VDD, VSS, VNW, VPW;
`endif
	output Q;
	input D, CKN;
endmodule
(* blackbox *)
module DFFQX1_9TSVT (
`ifdef WITH_POWER
  VDD, VSS, VNW, VPW,
`endif
  Q, D, CK);
`ifdef WITH_POWER
  inout VDD, VSS, VNW, VPW;
`endif
	output Q;
	input D, CK;
endmodule
`endif
