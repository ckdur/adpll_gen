// Microdefinition of the cells
// Map the technology standard cells here
// Mapped using the SkyWater sky130_fd_sc_hd cells (1.8 V). Generated, see CLAUDE.md (porting)

//`define YOSYS
//`define WITH_POWER

module PLL_CELL_INVX1(
`ifdef WITH_POWER
  VDD, VSS,
`endif
  input I,
  output ZN
);
  // INVX1 -> inv_1
  (* keep *) (* dont_touch = "true" *)
  sky130_fd_sc_hd__inv_1 impl(
`ifdef WITH_POWER
    .VPWR(VDD), .VGND(VSS), .VPB(VDD), .VNB(VSS),
`endif
    .A(I), .Y(ZN)
  );
endmodule

module PLL_CELL_INVX2(
`ifdef WITH_POWER
  VDD, VSS,
`endif
  input I,
  output ZN
);
  // INVX2 -> inv_2
  (* keep *) (* dont_touch = "true" *)
  sky130_fd_sc_hd__inv_2 impl(
`ifdef WITH_POWER
    .VPWR(VDD), .VGND(VSS), .VPB(VDD), .VNB(VSS),
`endif
    .A(I), .Y(ZN)
  );
endmodule

module PLL_CELL_INVX5(
`ifdef WITH_POWER
  VDD, VSS,
`endif
  input I,
  output ZN
);
  // INVX5 -> inv_4
  (* keep *) (* dont_touch = "true" *)
  sky130_fd_sc_hd__inv_4 impl(
`ifdef WITH_POWER
    .VPWR(VDD), .VGND(VSS), .VPB(VDD), .VNB(VSS),
`endif
    .A(I), .Y(ZN)
  );
endmodule

module PLL_CELL_INVX9(
`ifdef WITH_POWER
  VDD, VSS,
`endif
  input I,
  output ZN
);
  // INVX9 -> inv_8
  (* keep *) (* dont_touch = "true" *)
  sky130_fd_sc_hd__inv_8 impl(
`ifdef WITH_POWER
    .VPWR(VDD), .VGND(VSS), .VPB(VDD), .VNB(VSS),
`endif
    .A(I), .Y(ZN)
  );
endmodule

module PLL_CELL_NAND3X8(
`ifdef WITH_POWER
  VDD, VSS,
`endif
  input A0, A1, A2, // NOTE: A1 should be ALWAYS the middle one. Check it on the spice.
  output ZN
);
  // NAND3X8 -> nand3_1 x8 (C is the transistor next to ground: A0)
  (* keep *) (* dont_touch = "true" *)
  sky130_fd_sc_hd__nand3_1 impl_0(
`ifdef WITH_POWER
    .VPWR(VDD), .VGND(VSS), .VPB(VDD), .VNB(VSS),
`endif
    .A(A2), .B(A1), .C(A0), .Y(ZN)
  );
  (* keep *) (* dont_touch = "true" *)
  sky130_fd_sc_hd__nand3_1 impl_1(
`ifdef WITH_POWER
    .VPWR(VDD), .VGND(VSS), .VPB(VDD), .VNB(VSS),
`endif
    .A(A2), .B(A1), .C(A0), .Y(ZN)
  );
  (* keep *) (* dont_touch = "true" *)
  sky130_fd_sc_hd__nand3_1 impl_2(
`ifdef WITH_POWER
    .VPWR(VDD), .VGND(VSS), .VPB(VDD), .VNB(VSS),
`endif
    .A(A2), .B(A1), .C(A0), .Y(ZN)
  );
  (* keep *) (* dont_touch = "true" *)
  sky130_fd_sc_hd__nand3_1 impl_3(
`ifdef WITH_POWER
    .VPWR(VDD), .VGND(VSS), .VPB(VDD), .VNB(VSS),
`endif
    .A(A2), .B(A1), .C(A0), .Y(ZN)
  );
  (* keep *) (* dont_touch = "true" *)
  sky130_fd_sc_hd__nand3_1 impl_4(
`ifdef WITH_POWER
    .VPWR(VDD), .VGND(VSS), .VPB(VDD), .VNB(VSS),
`endif
    .A(A2), .B(A1), .C(A0), .Y(ZN)
  );
  (* keep *) (* dont_touch = "true" *)
  sky130_fd_sc_hd__nand3_1 impl_5(
`ifdef WITH_POWER
    .VPWR(VDD), .VGND(VSS), .VPB(VDD), .VNB(VSS),
`endif
    .A(A2), .B(A1), .C(A0), .Y(ZN)
  );
  (* keep *) (* dont_touch = "true" *)
  sky130_fd_sc_hd__nand3_1 impl_6(
`ifdef WITH_POWER
    .VPWR(VDD), .VGND(VSS), .VPB(VDD), .VNB(VSS),
`endif
    .A(A2), .B(A1), .C(A0), .Y(ZN)
  );
  (* keep *) (* dont_touch = "true" *)
  sky130_fd_sc_hd__nand3_1 impl_7(
`ifdef WITH_POWER
    .VPWR(VDD), .VGND(VSS), .VPB(VDD), .VNB(VSS),
`endif
    .A(A2), .B(A1), .C(A0), .Y(ZN)
  );
endmodule

module PLL_CELL_NAND3X1(
`ifdef WITH_POWER
  VDD, VSS,
`endif
  input A0, A1, A2,
  output ZN
);
  // NAND3X1 -> nand3_1
  (* keep *) (* dont_touch = "true" *)
  sky130_fd_sc_hd__nand3_1 impl(
`ifdef WITH_POWER
    .VPWR(VDD), .VGND(VSS), .VPB(VDD), .VNB(VSS),
`endif
    .A(A2), .B(A1), .C(A0), .Y(ZN)
  );
endmodule

module PLL_CELL_NAND2X1(
`ifdef WITH_POWER
  VDD, VSS,
`endif
  input A0, A1,
  output ZN
);
  // NAND2X1 -> nand2_1
  (* keep *) (* dont_touch = "true" *)
  sky130_fd_sc_hd__nand2_1 impl(
`ifdef WITH_POWER
    .VPWR(VDD), .VGND(VSS), .VPB(VDD), .VNB(VSS),
`endif
    .A(A0), .B(A1), .Y(ZN)
  );
endmodule

module PLL_CELL_NOR2X1(
`ifdef WITH_POWER
  VDD, VSS,
`endif
  input A0, A1,
  output ZN
);
  // NOR2X1 -> nor2_1
  (* keep *) (* dont_touch = "true" *)
  sky130_fd_sc_hd__nor2_1 impl(
`ifdef WITH_POWER
    .VPWR(VDD), .VGND(VSS), .VPB(VDD), .VNB(VSS),
`endif
    .A(A0), .B(A1), .Y(ZN)
  );
endmodule

module PLL_CELL_NAND2BX1(
`ifdef WITH_POWER
  VDD, VSS,
`endif
  input A0, B0, // A0 is the negated one
  output ZN
);
  // NAND2BX1 -> nand2b_1
  (* keep *) (* dont_touch = "true" *)
  sky130_fd_sc_hd__nand2b_1 impl(
`ifdef WITH_POWER
    .VPWR(VDD), .VGND(VSS), .VPB(VDD), .VNB(VSS),
`endif
    .A_N(A0), .B(B0), .Y(ZN)
  );
endmodule

module PLL_CELL_NOR2BX1(
`ifdef WITH_POWER
  VDD, VSS,
`endif
  input A0, B0, // A0 is the negated one
  output ZN
);
  // NOR2BX1 -> nor2b_1
  (* keep *) (* dont_touch = "true" *)
  sky130_fd_sc_hd__nor2b_1 impl(
`ifdef WITH_POWER
    .VPWR(VDD), .VGND(VSS), .VPB(VDD), .VNB(VSS),
`endif
    .B_N(A0), .A(B0), .Y(ZN)
  );
endmodule

module PLL_CELL_BUFFX0(
`ifdef WITH_POWER
  VDD, VSS,
`endif
  input I,
  output Z
);
  // BUFFX0 -> buf_1
  (* keep *) (* dont_touch = "true" *)
  sky130_fd_sc_hd__buf_1 impl(
`ifdef WITH_POWER
    .VPWR(VDD), .VGND(VSS), .VPB(VDD), .VNB(VSS),
`endif
    .A(I), .X(Z)
  );
endmodule

module PLL_CELL_AND2X1(
`ifdef WITH_POWER
  VDD, VSS,
`endif
  input A0, A1,
  output Z
);
  // AND2X1 -> and2_1
  (* keep *) (* dont_touch = "true" *)
  sky130_fd_sc_hd__and2_1 impl(
`ifdef WITH_POWER
    .VPWR(VDD), .VGND(VSS), .VPB(VDD), .VNB(VSS),
`endif
    .A(A0), .B(A1), .X(Z)
  );
endmodule

module PLL_CELL_CLKINVX1(
`ifdef WITH_POWER
  VDD, VSS,
`endif
  input I,
  output ZN
);
  // CLKINVX1 -> clkinv_1
  (* keep *) (* dont_touch = "true" *)
  sky130_fd_sc_hd__clkinv_1 impl(
`ifdef WITH_POWER
    .VPWR(VDD), .VGND(VSS), .VPB(VDD), .VNB(VSS),
`endif
    .A(I), .Y(ZN)
  );
endmodule

module PLL_CELL_DFFNQX1(
`ifdef WITH_POWER
  VDD, VSS,
`endif
  input D, CKN,
  output Q
);
  // DFFNQX1 -> inv_1 + dfxtp_1
  wire CLK;
  (* keep *) (* dont_touch = "true" *)
  sky130_fd_sc_hd__inv_1 impl_inv(
`ifdef WITH_POWER
    .VPWR(VDD), .VGND(VSS), .VPB(VDD), .VNB(VSS),
`endif
    .A(CKN), .Y(CLK)
  );
  (* keep *) (* dont_touch = "true" *)
  sky130_fd_sc_hd__dfxtp_1 impl(
`ifdef WITH_POWER
    .VPWR(VDD), .VGND(VSS), .VPB(VDD), .VNB(VSS),
`endif
    .CLK(CLK), .D(D), .Q(Q)
  );
endmodule

module PLL_CELL_DFFQX1(
`ifdef WITH_POWER
  VDD, VSS,
`endif
  input D, CK,
  output Q
);
  // DFFQX1 -> dfxtp_1
  (* keep *) (* dont_touch = "true" *)
  sky130_fd_sc_hd__dfxtp_1 impl(
`ifdef WITH_POWER
    .VPWR(VDD), .VGND(VSS), .VPB(VDD), .VNB(VSS),
`endif
    .CLK(CK), .D(D), .Q(Q)
  );
endmodule

// We also define the used cells as blackboxes for yosys synthesis
`ifdef YOSYS
(* blackbox *)
module sky130_fd_sc_hd__inv_1 (
`ifdef WITH_POWER
  VPWR, VGND, VPB, VNB,
`endif
  Y, A);
`ifdef WITH_POWER
  inout VPWR, VGND, VPB, VNB;
`endif
  output Y;
  input A;
endmodule
(* blackbox *)
module sky130_fd_sc_hd__inv_2 (
`ifdef WITH_POWER
  VPWR, VGND, VPB, VNB,
`endif
  Y, A);
`ifdef WITH_POWER
  inout VPWR, VGND, VPB, VNB;
`endif
  output Y;
  input A;
endmodule
(* blackbox *)
module sky130_fd_sc_hd__inv_4 (
`ifdef WITH_POWER
  VPWR, VGND, VPB, VNB,
`endif
  Y, A);
`ifdef WITH_POWER
  inout VPWR, VGND, VPB, VNB;
`endif
  output Y;
  input A;
endmodule
(* blackbox *)
module sky130_fd_sc_hd__inv_8 (
`ifdef WITH_POWER
  VPWR, VGND, VPB, VNB,
`endif
  Y, A);
`ifdef WITH_POWER
  inout VPWR, VGND, VPB, VNB;
`endif
  output Y;
  input A;
endmodule
(* blackbox *)
module sky130_fd_sc_hd__clkinv_1 (
`ifdef WITH_POWER
  VPWR, VGND, VPB, VNB,
`endif
  Y, A);
`ifdef WITH_POWER
  inout VPWR, VGND, VPB, VNB;
`endif
  output Y;
  input A;
endmodule
(* blackbox *)
module sky130_fd_sc_hd__nand3_1 (
`ifdef WITH_POWER
  VPWR, VGND, VPB, VNB,
`endif
  Y, A, B, C);
`ifdef WITH_POWER
  inout VPWR, VGND, VPB, VNB;
`endif
  output Y;
  input A, B, C;
endmodule
(* blackbox *)
module sky130_fd_sc_hd__nand2_1 (
`ifdef WITH_POWER
  VPWR, VGND, VPB, VNB,
`endif
  Y, A, B);
`ifdef WITH_POWER
  inout VPWR, VGND, VPB, VNB;
`endif
  output Y;
  input A, B;
endmodule
(* blackbox *)
module sky130_fd_sc_hd__nor2_1 (
`ifdef WITH_POWER
  VPWR, VGND, VPB, VNB,
`endif
  Y, A, B);
`ifdef WITH_POWER
  inout VPWR, VGND, VPB, VNB;
`endif
  output Y;
  input A, B;
endmodule
(* blackbox *)
module sky130_fd_sc_hd__nand2b_1 (
`ifdef WITH_POWER
  VPWR, VGND, VPB, VNB,
`endif
  Y, A_N, B);
`ifdef WITH_POWER
  inout VPWR, VGND, VPB, VNB;
`endif
  output Y;
  input A_N, B;
endmodule
(* blackbox *)
module sky130_fd_sc_hd__nor2b_1 (
`ifdef WITH_POWER
  VPWR, VGND, VPB, VNB,
`endif
  Y, A, B_N);
`ifdef WITH_POWER
  inout VPWR, VGND, VPB, VNB;
`endif
  output Y;
  input A, B_N;
endmodule
(* blackbox *)
module sky130_fd_sc_hd__buf_1 (
`ifdef WITH_POWER
  VPWR, VGND, VPB, VNB,
`endif
  X, A);
`ifdef WITH_POWER
  inout VPWR, VGND, VPB, VNB;
`endif
  output X;
  input A;
endmodule
(* blackbox *)
module sky130_fd_sc_hd__and2_1 (
`ifdef WITH_POWER
  VPWR, VGND, VPB, VNB,
`endif
  X, A, B);
`ifdef WITH_POWER
  inout VPWR, VGND, VPB, VNB;
`endif
  output X;
  input A, B;
endmodule
(* blackbox *)
module sky130_fd_sc_hd__dfxtp_1 (
`ifdef WITH_POWER
  VPWR, VGND, VPB, VNB,
`endif
  Q, CLK, D);
`ifdef WITH_POWER
  inout VPWR, VGND, VPB, VNB;
`endif
  output Q;
  input CLK, D;
endmodule
`endif
