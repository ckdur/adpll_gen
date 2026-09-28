// The PLL fine test
// This test will attempt to do the PLL logic with the filtering and the ssbbpd.
`timescale 1fs/1fs

module pll_fine_test();

    localparam REF_T = 10000000; // 10ns, 100MHz
    reg CLK_REF = 1'b0;
    always begin
        #(REF_T/2) CLK_REF <= !CLK_REF;
    end

    localparam COARSE_NDELS = 15; // DO NOT CHANGE
    localparam MID_NDELS = 15; // DO NOT CHANGE
    localparam FINE_NDELS = 31; // DO NOT CHANGE
    wire [COARSE_NDELS-1:0] COARSE_MUX;
    wire [MID_NDELS-1:0] MID_MUX;
    wire [FINE_NDELS-1:0] FINE_MUX;

    wire VDD = 1'b1;
    wire VSS = 1'b0;
    wire DCO_EN = 1'b1;
    wire [1:0] SS_BBPD;
    wire OUT, MID_OUT;
    PLL_ANALOG #(
        .COARSE_NDELS(COARSE_NDELS),
        .MID_NDELS(MID_NDELS),
        .FINE_NDELS(FINE_NDELS)
    ) pll_ana (
        .VDD(VDD), .VSS(VSS),
        .COARSE_MUX(COARSE_MUX),
        .MID_MUX(MID_MUX),
        .FINE_MUX(FINE_MUX),
        .DCO_EN(DCO_EN), .REF(CLK_REF),
        .SS_BBPD(SS_BBPD),
        .OUT(OUT), .MID_OUT(MID_OUT)
    );

    assign COARSE_MUX = 'h1f; // Extracted from freq_lock_tb
    assign MID_MUX = 'h3f; // Extracted from freq_lock_tb

    localparam FILTER_BITS = 16;
    reg RST_N;
    reg ENABLE;
    reg [FILTER_BITS-1:0] KP, KI;
    wire [FILTER_BITS-1:0] FILTER_OUT;

    pll_digital_loop_filter #(
        .BITS(FILTER_BITS)
    ) dlf (
        .CLK(MID_OUT), .RST_N(RST_N), .ENABLE(ENABLE),
        .SS_BBPD(SS_BBPD),
        .KP(KP), .KI(KI),
        .OUT(FILTER_OUT)
    );

    wire [$clog2(FINE_NDELS)-1:0] FILTER_DEC = FILTER_OUT[FILTER_BITS-1:FILTER_BITS-$clog2(FINE_NDELS)]; // According to the paper, is the MSB
    pll_term_decoder_with_zero #(
        .DELS(FINE_NDELS)
    ) dec (
        .IN(FILTER_DEC),
        .OUT(FINE_MUX)
    );

    integer iter;
    initial begin
        $dumpfile("pll_fine_test.vcd");
        $dumpvars;
        RST_N = 1'b0;
        ENABLE = 1'b0;
        KI = 'd255;  // Use the dlf_design.py for this
        KP = 'd127;


        #1000000 RST_N = 1'b1;
        for(iter = 0; iter < 2; iter = iter + 1)
            #(REF_T);
        
        ENABLE = 1'b1;

        for(iter = 0; iter < 1024; iter = iter + 1)
            #(REF_T);
        
        $finish;
    end
    
endmodule