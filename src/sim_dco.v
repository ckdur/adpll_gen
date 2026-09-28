// A digital VCO useful for digital simulations
`timescale 1fs/1fs

module sim_delay_fine #(
    parameter integer FINE_NDELS = 31
) (
    input [FINE_NDELS-1:0] FINE_MUX,
    input IN,
    output reg OUT
);
    initial OUT = 1'b0;
    always @(IN) begin
        if(FINE_MUX[0] == 1'b0) #(23770); // delay = 2.377e-11
        else if(FINE_MUX[1] == 1'b0) #(23830); // delay = 2.383e-11
        else if(FINE_MUX[2] == 1'b0) #(23880); // delay = 2.388e-11
        else if(FINE_MUX[3] == 1'b0) #(23940); // delay = 2.394e-11
        else if(FINE_MUX[4] == 1'b0) #(23990); // delay = 2.399e-11
        else if(FINE_MUX[5] == 1'b0) #(24050); // delay = 2.405e-11
        else if(FINE_MUX[6] == 1'b0) #(24110); // delay = 2.411e-11
        else if(FINE_MUX[7] == 1'b0) #(24170); // delay = 2.417e-11
        else if(FINE_MUX[8] == 1'b0) #(24230); // delay = 2.423e-11
        else if(FINE_MUX[9] == 1'b0) #(24290); // delay = 2.429e-11
        else if(FINE_MUX[10] == 1'b0) #(24360); // delay = 2.436e-11
        else if(FINE_MUX[11] == 1'b0) #(24420); // delay = 2.442e-11
        else if(FINE_MUX[12] == 1'b0) #(24490); // delay = 2.449e-11
        else if(FINE_MUX[13] == 1'b0) #(24550); // delay = 2.455e-11
        else if(FINE_MUX[14] == 1'b0) #(24620); // delay = 2.462e-11
        else if(FINE_MUX[15] == 1'b0) #(24690); // delay = 2.469e-11
        else if(FINE_MUX[16] == 1'b0) #(24760); // delay = 2.476e-11
        else if(FINE_MUX[17] == 1'b0) #(24830); // delay = 2.483e-11
        else if(FINE_MUX[18] == 1'b0) #(24910); // delay = 2.491e-11
        else if(FINE_MUX[19] == 1'b0) #(24980); // delay = 2.498e-11
        else if(FINE_MUX[20] == 1'b0) #(25060); // delay = 2.506e-11
        else if(FINE_MUX[21] == 1'b0) #(25140); // delay = 2.514e-11
        else if(FINE_MUX[22] == 1'b0) #(25220); // delay = 2.522e-11
        else if(FINE_MUX[23] == 1'b0) #(25300); // delay = 2.53e-11
        else if(FINE_MUX[24] == 1'b0) #(25380); // delay = 2.538e-11
        else if(FINE_MUX[25] == 1'b0) #(25470); // delay = 2.547e-11
        else if(FINE_MUX[26] == 1'b0) #(25550); // delay = 2.555e-11
        else if(FINE_MUX[27] == 1'b0) #(25640); // delay = 2.564e-11
        else if(FINE_MUX[28] == 1'b0) #(25730); // delay = 2.573e-11
        else if(FINE_MUX[29] == 1'b0) #(25830); // delay = 2.583e-11
        else if(FINE_MUX[30] == 1'b0) #(25920); // delay = 2.592e-11
        else #(26010); // delay = 2.601e-11
        OUT = IN;
    end
endmodule

module sim_delay_mid #(
    parameter integer MID_NDELS = 15
) (
    input [MID_NDELS-1:0] MID_MUX,
    input IN,
    output reg OUT
);
    initial OUT = 1'b0;
    always @(IN) begin
        if(MID_MUX[0] == 1'b0) #(52460); // delay = 5.246e-11
        else if(MID_MUX[1] == 1'b0) #(53250); // delay = 5.325e-11
        else if(MID_MUX[2] == 1'b0) #(54060); // delay = 5.406e-11
        else if(MID_MUX[3] == 1'b0) #(54890); // delay = 5.489e-11
        else if(MID_MUX[4] == 1'b0) #(55780); // delay = 5.578e-11
        else if(MID_MUX[5] == 1'b0) #(56740); // delay = 5.674e-11
        else if(MID_MUX[6] == 1'b0) #(57720); // delay = 5.772e-11
        else if(MID_MUX[7] == 1'b0) #(58700); // delay = 5.87e-11
        else if(MID_MUX[8] == 1'b0) #(59700); // delay = 5.97e-11
        else if(MID_MUX[9] == 1'b0) #(60710); // delay = 6.071e-11
        else if(MID_MUX[10] == 1'b0) #(61790); // delay = 6.179e-11
        else if(MID_MUX[11] == 1'b0) #(62950); // delay = 6.295e-11
        else if(MID_MUX[12] == 1'b0) #(64190); // delay = 6.419e-11
        else if(MID_MUX[13] == 1'b0) #(65520); // delay = 6.552e-11
        else if(MID_MUX[14] == 1'b0) #(66750); // delay = 6.675e-11
        else #(67930); // delay = 6.793e-11
        OUT = IN;
    end
endmodule

module sim_delay_coarse #(
    parameter integer COARSE_NDELS = 15
) (
    input [COARSE_NDELS-1:0] COARSE_MUX,
    input IN,
    output reg OUT
);
    initial OUT = 1'b0;
    always @(IN) begin
        if(COARSE_MUX[0] == 1'b0) #(31320); // delay = 3.132e-11
        else if(COARSE_MUX[1] == 1'b0) #(65810); // delay = 6.581e-11
        else if(COARSE_MUX[2] == 1'b0) #(99300); // delay = 9.93e-11
        else if(COARSE_MUX[3] == 1'b0) #(133300); // delay = 1.333e-10
        else if(COARSE_MUX[4] == 1'b0) #(170000); // delay = 1.7e-10
        else if(COARSE_MUX[5] == 1'b0) #(205200); // delay = 2.052e-10
        else if(COARSE_MUX[6] == 1'b0) #(235899); // delay = 2.359e-10
        else if(COARSE_MUX[7] == 1'b0) #(273000); // delay = 2.73e-10
        else if(COARSE_MUX[8] == 1'b0) #(307300); // delay = 3.073e-10
        else if(COARSE_MUX[9] == 1'b0) #(341800); // delay = 3.418e-10
        else if(COARSE_MUX[10] == 1'b0) #(373000); // delay = 3.73e-10
        else if(COARSE_MUX[11] == 1'b0) #(399400); // delay = 3.994e-10
        else if(COARSE_MUX[12] == 1'b0) #(431300); // delay = 4.313e-10
        else if(COARSE_MUX[13] == 1'b0) #(465100); // delay = 4.651e-10
        else if(COARSE_MUX[14] == 1'b0) #(511400); // delay = 5.114e-10
        else #(535700); // delay = 5.357e-10
        OUT = IN;
    end
endmodule

module sim_dco #(
    parameter integer COARSE_NDELS = 15,
    parameter integer MID_NDELS = 15,
    parameter integer FINE_NDELS = 31
) (
    input [COARSE_NDELS-1:0] COARSE_MUX,
    input [MID_NDELS-1:0] MID_MUX,
    input [FINE_NDELS-1:0] FINE_MUX,
    output reg CLK_VCO
);
    // Simulation of the delay-based VCO
    // see parse_delays.py for getting those values
    initial CLK_VCO = 1'b0;
    always begin
        #(23770/2); // This is a bias delay caused by a single inverter

        if(FINE_MUX[0] == 1'b0) #(23770); // delay = 2.377e-11
        else if(FINE_MUX[1] == 1'b0) #(23830); // delay = 2.383e-11
        else if(FINE_MUX[2] == 1'b0) #(23880); // delay = 2.388e-11
        else if(FINE_MUX[3] == 1'b0) #(23940); // delay = 2.394e-11
        else if(FINE_MUX[4] == 1'b0) #(23990); // delay = 2.399e-11
        else if(FINE_MUX[5] == 1'b0) #(24050); // delay = 2.405e-11
        else if(FINE_MUX[6] == 1'b0) #(24110); // delay = 2.411e-11
        else if(FINE_MUX[7] == 1'b0) #(24170); // delay = 2.417e-11
        else if(FINE_MUX[8] == 1'b0) #(24230); // delay = 2.423e-11
        else if(FINE_MUX[9] == 1'b0) #(24290); // delay = 2.429e-11
        else if(FINE_MUX[10] == 1'b0) #(24360); // delay = 2.436e-11
        else if(FINE_MUX[11] == 1'b0) #(24420); // delay = 2.442e-11
        else if(FINE_MUX[12] == 1'b0) #(24490); // delay = 2.449e-11
        else if(FINE_MUX[13] == 1'b0) #(24550); // delay = 2.455e-11
        else if(FINE_MUX[14] == 1'b0) #(24620); // delay = 2.462e-11
        else if(FINE_MUX[15] == 1'b0) #(24690); // delay = 2.469e-11
        else if(FINE_MUX[16] == 1'b0) #(24760); // delay = 2.476e-11
        else if(FINE_MUX[17] == 1'b0) #(24830); // delay = 2.483e-11
        else if(FINE_MUX[18] == 1'b0) #(24910); // delay = 2.491e-11
        else if(FINE_MUX[19] == 1'b0) #(24980); // delay = 2.498e-11
        else if(FINE_MUX[20] == 1'b0) #(25060); // delay = 2.506e-11
        else if(FINE_MUX[21] == 1'b0) #(25140); // delay = 2.514e-11
        else if(FINE_MUX[22] == 1'b0) #(25220); // delay = 2.522e-11
        else if(FINE_MUX[23] == 1'b0) #(25300); // delay = 2.53e-11
        else if(FINE_MUX[24] == 1'b0) #(25380); // delay = 2.538e-11
        else if(FINE_MUX[25] == 1'b0) #(25470); // delay = 2.547e-11
        else if(FINE_MUX[26] == 1'b0) #(25550); // delay = 2.555e-11
        else if(FINE_MUX[27] == 1'b0) #(25640); // delay = 2.564e-11
        else if(FINE_MUX[28] == 1'b0) #(25730); // delay = 2.573e-11
        else if(FINE_MUX[29] == 1'b0) #(25830); // delay = 2.583e-11
        else if(FINE_MUX[30] == 1'b0) #(25920); // delay = 2.592e-11
        else #(26010); // delay = 2.601e-11
        
        if(MID_MUX[0] == 1'b0) #(52460); // delay = 5.246e-11
        else if(MID_MUX[1] == 1'b0) #(53250); // delay = 5.325e-11
        else if(MID_MUX[2] == 1'b0) #(54060); // delay = 5.406e-11
        else if(MID_MUX[3] == 1'b0) #(54890); // delay = 5.489e-11
        else if(MID_MUX[4] == 1'b0) #(55780); // delay = 5.578e-11
        else if(MID_MUX[5] == 1'b0) #(56740); // delay = 5.674e-11
        else if(MID_MUX[6] == 1'b0) #(57720); // delay = 5.772e-11
        else if(MID_MUX[7] == 1'b0) #(58700); // delay = 5.87e-11
        else if(MID_MUX[8] == 1'b0) #(59700); // delay = 5.97e-11
        else if(MID_MUX[9] == 1'b0) #(60710); // delay = 6.071e-11
        else if(MID_MUX[10] == 1'b0) #(61790); // delay = 6.179e-11
        else if(MID_MUX[11] == 1'b0) #(62950); // delay = 6.295e-11
        else if(MID_MUX[12] == 1'b0) #(64190); // delay = 6.419e-11
        else if(MID_MUX[13] == 1'b0) #(65520); // delay = 6.552e-11
        else if(MID_MUX[14] == 1'b0) #(66750); // delay = 6.675e-11
        else #(67930); // delay = 6.793e-11

        if(COARSE_MUX[0] == 1'b0) #(31320); // delay = 3.132e-11
        else if(COARSE_MUX[1] == 1'b0) #(65810); // delay = 6.581e-11
        else if(COARSE_MUX[2] == 1'b0) #(99300); // delay = 9.93e-11
        else if(COARSE_MUX[3] == 1'b0) #(133300); // delay = 1.333e-10
        else if(COARSE_MUX[4] == 1'b0) #(170000); // delay = 1.7e-10
        else if(COARSE_MUX[5] == 1'b0) #(205200); // delay = 2.052e-10
        else if(COARSE_MUX[6] == 1'b0) #(235899); // delay = 2.359e-10
        else if(COARSE_MUX[7] == 1'b0) #(273000); // delay = 2.73e-10
        else if(COARSE_MUX[8] == 1'b0) #(307300); // delay = 3.073e-10
        else if(COARSE_MUX[9] == 1'b0) #(341800); // delay = 3.418e-10
        else if(COARSE_MUX[10] == 1'b0) #(373000); // delay = 3.73e-10
        else if(COARSE_MUX[11] == 1'b0) #(399400); // delay = 3.994e-10
        else if(COARSE_MUX[12] == 1'b0) #(431300); // delay = 4.313e-10
        else if(COARSE_MUX[13] == 1'b0) #(465100); // delay = 4.651e-10
        else if(COARSE_MUX[14] == 1'b0) #(511400); // delay = 5.114e-10
        else #(535700); // delay = 5.357e-10
        CLK_VCO <= !CLK_VCO;
    end
endmodule