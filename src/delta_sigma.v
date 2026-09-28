/*****************************************************************
* MASH 1-1-1 or 1-1 DSM for fractional-N PLL 
* Original Author: Zule Xu
* Modifiers: Chou Koumei
* 20200805. Modified for a previous version. Only 2nd-order DSM is
* considered but the 3rd-stage is employed for self-dithering.
* The dithering is only at the 2nd-stage. To meet with the 10-bit
*
* NOTE: No LICENSE yet
****************************************************************/

module delta_sigma #(
    parameter BITS_INT = 5,
    parameter BITS_DSM = 11
) (
    input CK,
    input RST,
    input EN_DSM,
    input EN_DSM_DT,
    input EN_DSM_SHDT,
    input [1:0] DSM_ORDER,
    input [BITS_INT-1:0] FCWI,         // Integer division ratio (AKA N)
    input [BITS_DSM-1:0] FCWF,         // Fractional division ratio (AKA N + FCWF / 2^bits_dsm)
    output reg [BITS_INT-1:0] DSM_OUT  // Output of the dsm (Note: The output is combinational. Register outside)
);

// Internal signals and regs
    wire cin_stg1;
    wire cin_stg2;
    wire ca1;
    wire ca2;
    wire ca3;
    
    wire self_dither;

    wire SEL_DSM_2ND = DSM_ORDER == 2'b01;
    wire SEL_DSM_3RD = DSM_ORDER == 2'b10;
    
    wire [BITS_DSM-1:0] err1;
    wire [BITS_DSM-1:0] err2;
    wire [BITS_DSM-1:0] err3;
    reg [BITS_DSM-1:0] dff_err1;
    reg [BITS_DSM-1:0] dff_err2;
    reg [BITS_DSM-1:0] dff_err3;
    wire [BITS_DSM:0] sum1;
    wire [BITS_DSM:0] sum2;
    wire [BITS_DSM:0] sum3;
    
    reg dff_ca2;
    reg dff_ca3;
    
    wire signed [3:0] sum_sd23;        // signed range (-1 to 2)
    reg signed [3:0] dff_sum_sd23;
    
    wire signed [4:0] dout_3rd;
    wire signed [3:0] dout_2nd;
    wire signed [2:0] dout_1st;
    wire [4:0] dout;

// Architecture
// Stage 1
    assign sum1 = FCWF + dff_err1 + cin_stg1;
    assign err1 = sum1[BITS_DSM-1:0];
    assign ca1 = sum1[BITS_DSM];
    always @(posedge CK or posedge RST)
    begin
        if(RST)
            dff_err1 <= 0;
        else if (EN_DSM)
            dff_err1 <= err1;
    end

// Stage 2
    assign sum2 = err1 + dff_err2 + cin_stg2;       // bits_dsm + 1
    assign err2 = sum2[BITS_DSM-1:0];
    assign ca2 = sum2[BITS_DSM];
    always @(posedge CK or posedge RST)
    begin
        if(RST)
            dff_err2 <= 0;
        else if (EN_DSM)
            dff_err2 <= err2;
    end

// Stage 3, dithering signal extraction
    assign sum3 = err2 + dff_err3;                  // bits_dsm + 1
    assign err3 = sum3[BITS_DSM-1:0];
    assign ca3 = sum3[BITS_DSM];
    assign self_dither = dff_err3[BITS_DSM-1];
    always @(posedge CK or posedge RST)
    begin
        if(RST)
            dff_err3 <= 0;
        else if (EN_DSM)
            dff_err3 <= err3;
    end

// DFFs for feedback adders
    always @(posedge CK or posedge RST)
    begin
        if (RST)
            dff_ca2 <= 0;
        else if (EN_DSM)
            dff_ca2 <= ca2;
    end

    always @(posedge CK or posedge RST)
    begin
        if (RST)
            dff_sum_sd23 <= 0;
        else if (EN_DSM)
            dff_sum_sd23 <= sum_sd23;
    end

    always @(posedge CK or posedge RST)
    begin
        if (RST)
            dff_ca3 <= 0;
        else if (EN_DSM)
            dff_ca3 <= ca3;
    end

// Output process
    assign cin_stg1 = EN_DSM & (SEL_DSM_2ND || SEL_DSM_3RD) & EN_DSM_DT & (~EN_DSM_SHDT) & self_dither;
    assign cin_stg2 = EN_DSM & (SEL_DSM_2ND || SEL_DSM_3RD) & EN_DSM_DT & ( EN_DSM_SHDT) & self_dither;
    
    assign sum_sd23 = {3'b000, ca2} + {3'b000, ca3} - {3'b000, dff_ca3};                            // 4b
    
    assign dout_3rd = {4'b0000, ca1} + {sum_sd23[3], sum_sd23} - {dff_sum_sd23[3], dff_sum_sd23};   // 5b, -3 ~ 4
    assign dout_2nd = {3'b000, ca1} + {3'b000, ca2} - {3'b000, dff_ca2};                            // 4b, -1 ~ 2
    assign dout_1st = {2'b00, ca1};                                                                 // 3b,  0 ~ 1
    
    assign dout = SEL_DSM_2ND ? {dout_2nd[3], dout_2nd} : (SEL_DSM_3RD ? dout_3rd : {dout_1st[2], dout_1st[2], dout_1st});
    
    // To divider
    wire [BITS_INT:0] DSM_OUT_D;
    wire DSM_CAP_P, DSM_CAP_N;
    assign DSM_OUT_D = {{(BITS_INT+1-5){dout[4]}}, dout} + {1'b0, FCWI};  // Sign extend of dout + FCWI
    assign DSM_CAP_P = DSM_OUT_D[BITS_INT] != 1'b0 && dout[4] == 1'b0;    // If +dout and suddenly negative
    assign DSM_CAP_N = DSM_OUT_D[BITS_INT] != 1'b0 && dout[4] == 1'b1;    // If -dout and suddenly negative
    always @(*) begin
        if (DSM_CAP_P)
            DSM_OUT = {(BITS_INT-1){1'b1}};    // Cap to maximum
        else if (DSM_CAP_N)
            DSM_OUT = {(BITS_INT-1){1'b0}};    // Cap to minimum
        else
            DSM_OUT = DSM_OUT_D[BITS_INT-1:0]; // Just output
    end

// Architecture end
endmodule