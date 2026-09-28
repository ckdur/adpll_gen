// PLL test
`timescale 1fs/1fs

module pll_test();
    localparam REF_T = 10000000; // 10ns, 100MHz
    reg CLK_REF = 1'b0;
    always begin
        #(REF_T/2) CLK_REF <= !CLK_REF;
    end

    localparam COARSE_NDELS = 15;   // DO NOT CHANGE
    localparam MID_NDELS = 15;      // DO NOT CHANGE
    localparam FINE_NDELS = 31;     // DO NOT CHANGE
    localparam FILTER_BITS = 16;    // DO NOT CHANGE
    localparam IS_DSM = 1;          // DO NOT CHANGE
    localparam LOCKED_WAIT = 64;    // DO NOT CHANGE
    localparam FILTER_ILL = 16;     // DO NOT CHANGE
`ifndef PLL_WITHOUT_DIVIDER
    localparam DIV_BITS = 8;
`endif
    localparam FCW_BITS = 8;

    wire VDD = 1'b1;
    wire VSS = 1'b0;
    wire OUT, LOCKED, ERR;
    reg RST_N;
    reg [FILTER_BITS-1:0] KP, KI;
    reg [FCW_BITS-1:0] FCW;
    reg INJ_EN;
    reg DSM_EN_DT;
    reg DSM_EN_SHDT;
    reg [1:0] DSM_ORDER;
`ifndef PLL_WITHOUT_DIVIDER
    reg [DIV_BITS-1:0] SET_DIV;
    reg LOAD_DIV;
    wire OUT_DIV;
`endif

    pll 
`ifndef POSTSYN
    #(
        .COARSE_NDELS(COARSE_NDELS),
        .MID_NDELS(MID_NDELS),
        .FINE_NDELS(FINE_NDELS),
        .FILTER_BITS(FILTER_BITS),
        .IS_DSM(IS_DSM),
        .LOCKED_WAIT(LOCKED_WAIT),
        .FILTER_ILL(FILTER_ILL),
`ifndef PLL_WITHOUT_DIVIDER
        .DIV_BITS(DIV_BITS),
`endif
        .FCW_BITS(FCW_BITS)
    ) 
`endif
    dut (
        .VDD(VDD), .VSS(VSS),
        .REF(CLK_REF), .RST_N(RST_N), .INJ_EN(INJ_EN),
        .KP(KP), .KI(KI),
        .FCW(FCW),
        .DSM_EN_DT(DSM_EN_DT),
        .DSM_EN_SHDT(DSM_EN_SHDT),
        .DSM_ORDER(DSM_ORDER),
`ifndef PLL_WITHOUT_DIVIDER
        .SET_DIV(SET_DIV),
        .LOAD_DIV(LOAD_DIV),
        .OUT_DIV(OUT_DIV),
`endif
        .LOCKED(LOCKED), .ERR(ERR), .OUT(OUT)
    );

    integer iter;
    initial begin
`ifdef POSTSYN
        $dumpfile("test_pll_postsyn.vcd");
`else
        $dumpfile("test_pll.vcd");
`endif
        $dumpvars;
        RST_N = 1'b0;
        KI = 'd257;  // Use the noise_shape.ipynb for this (dlf_design.py is deprecated)
        KP = 'd3967;
        FCW = 'd8; // x10 times
        INJ_EN = 1'b0;
        DSM_EN_DT = 1'b0;
        DSM_EN_SHDT = 1'b1;
        DSM_ORDER = 2'b00;
`ifndef PLL_WITHOUT_DIVIDER
        SET_DIV = 'd14;
        LOAD_DIV = 1'b1;
`endif

        for(iter = 0; iter < 2; iter = iter + 1)
            #(REF_T);
        RST_N = 1'b1;

        for(iter = 0; iter < 1024; iter = iter + 1)
            #(REF_T);

        for(iter = 0; iter < 1024; iter = iter + 1)
            #(REF_T);

        for(iter = 0; iter < 1024; iter = iter + 1)
            #(REF_T);

        for(iter = 0; iter < 1024; iter = iter + 1)
            #(REF_T);

        for(iter = 0; iter < 1024; iter = iter + 1)
            #(REF_T);

        for(iter = 0; iter < 1024; iter = iter + 1)
            #(REF_T);

        for(iter = 0; iter < 1024; iter = iter + 1)
            #(REF_T);

        for(iter = 0; iter < 1024; iter = iter + 1)
            #(REF_T);
        
        $finish;
    end


endmodule
