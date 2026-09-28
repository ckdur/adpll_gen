// A simulation model in verilog for the SSBBPD
// Is just a behavioral of a NAND-based latch
`timescale 1fs/1fs

module sim_SSBBPD(
    input CLK_VCO, CLK_REF,
    output [1:0] SS_BBPD
);

    reg SS_BBPD_REF;
    reg SS_BBPD_VCO;

    always @(CLK_VCO or CLK_REF) begin
        if(!CLK_VCO && !CLK_REF) begin
            SS_BBPD_REF <= 1'b1;
            SS_BBPD_VCO <= 1'b1;
        end else if(CLK_VCO && !CLK_REF) begin
            SS_BBPD_REF <= 1'b1;
            SS_BBPD_VCO <= 1'b0;
        end else if(!CLK_VCO && CLK_REF) begin
            SS_BBPD_REF <= 1'b0;
            SS_BBPD_VCO <= 1'b1;
        end
    end

    assign SS_BBPD[0] = SS_BBPD_REF; // NANDY, or INJ_EDGE_BALANCED
    assign SS_BBPD[1] = SS_BBPD_VCO; // NANDX, or OSC_BALANCED

endmodule
