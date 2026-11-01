// PLL test
`timescale 1fs/1fs

// Loop gains: override with -D TB_KP=<n> -D TB_KI=<n>. With -D TB_KP_LOCKED=<n> -D TB_KI_LOCKED=<n> the
// gains change to those after LOCKED (gear shifting: fast acquisition, then low jitter)
`ifndef TB_KP
`define TB_KP 'd3967
`endif
`ifndef TB_KI
`define TB_KI 'd257
`endif
// Reference period (fs) and FCW (= N - 2): sim/tests.mk compiles $(SIM_OUT)/pll_target.vh first, which
// defines them (and the gains) for the PDK (src/pll_target.py). These are the defaults without it
`ifndef TB_REF_T
`define TB_REF_T 10000000
`endif
`ifndef TB_FCW
`define TB_FCW 'd8
`endif

module pll_test();
    localparam REF_T = `TB_REF_T; // fs (10 ns: 100 MHz)
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
`ifdef WITH_POWER
        .VDD(VDD), .VSS(VSS),
`endif
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

    // Edge log for the post-processing (src/pll_design.ipynb): "<kind> <time fs> <value>"
    //   O: OUT, R: REF, L: LOCKED, A: injection active (INJ_ACT), C: loop filter output,
    //   F: FINE_OUT (the natural edge of the DCO, before the mux), K/M: coarse/mid thermometer codes
    integer flog;
    initial begin
`ifdef POSTSYN
        flog = $fopen(`ifdef INJ_TEST "test_pll_inj_postsyn_edges.txt" `else "test_pll_postsyn_edges.txt" `endif, "w");
`else
        flog = $fopen(`ifdef INJ_TEST "test_pll_inj_edges.txt" `else "test_pll_edges.txt" `endif, "w");
`endif
    end
    always @(OUT) $fwrite(flog, "O %0d %0d\n", $time, OUT);
    always @(CLK_REF) $fwrite(flog, "R %0d %0d\n", $time, CLK_REF);
    always @(LOCKED) $fwrite(flog, "L %0d %0d\n", $time, LOCKED);
`ifndef POSTSYN
    always @(dut.INJ_ACT) $fwrite(flog, "A %0d %0d\n", $time, dut.INJ_ACT);
    always @(dut.pll_dig.FILTER_OUT) $fwrite(flog, "C %0d %0d\n", $time, dut.pll_dig.FILTER_OUT);
    always @(dut.pll_ana.dco.FINE_OUT) $fwrite(flog, "F %0d %0d\n", $time, dut.pll_ana.dco.FINE_OUT);
    always @(dut.pll_dig.COARSE_MUX) $fwrite(flog, "K %0d %0d\n", $time, dut.pll_dig.COARSE_MUX);
    always @(dut.pll_dig.MID_MUX) $fwrite(flog, "M %0d %0d\n", $time, dut.pll_dig.MID_MUX);
`endif

`ifdef TB_KP_LOCKED
    always @(posedge LOCKED) begin
        KP <= `TB_KP_LOCKED;
        KI <= `TB_KI_LOCKED;
        $display("Gear shift at %0t: KP = %0d, KI = %0d", $time, `TB_KP_LOCKED, `TB_KI_LOCKED);
    end
`endif

    // Glitch checker: after the lock, every half period of OUT must be close to the nominal one
    // (a glitch of the injection is a pulse much shorter than half a period)
    time t_last = 0;
    integer n_glitch = 0, n_half = 0;
    real t_half;
    always @(OUT) begin
        if(LOCKED && t_last > 0) begin
            t_half = $time - t_last;
            n_half = n_half + 1;
            if(t_half < 0.6 * REF_T / (2 * (FCW + 2))) begin
                n_glitch = n_glitch + 1;
                if(n_glitch <= 10) $display("GLITCH: OUT pulse of %0.1f ps at %0t", t_half / 1000.0, $time);
            end
        end
        t_last = $time;
    end

    integer iter;
    initial begin
`ifdef POSTSYN
        $dumpfile(`ifdef INJ_TEST "test_pll_inj_postsyn.vcd" `else "test_pll_postsyn.vcd" `endif);
`else
        $dumpfile(`ifdef INJ_TEST "test_pll_inj.vcd" `else "test_pll.vcd" `endif);
`endif
        // Only the top level and the loop variables (the full hierarchy is several GB)
        $dumpvars(1, pll_test);
`ifndef POSTSYN
        $dumpvars(0, dut.pll_dig.FILTER_OUT, dut.pll_dig.COARSE_MUX, dut.pll_dig.MID_MUX, dut.pll_dig.FINE_MUX,
                     dut.pll_dig.state, dut.SS_BBPD, dut.INJ_ACT, dut.pll_ana.INJ_WIN, dut.INJ_EDGE);
`endif
        RST_N = 1'b0;
        KI = `TB_KI;  // See src/pll_design.ipynb (section 7) for the choice of KP/KI
        KP = `TB_KP;
        FCW = `TB_FCW; // f_OUT = (FCW + 2) f_REF
`ifdef INJ_TEST
        INJ_EN = 1'b1;  // Injection requested from the start (it becomes active after LOCKED)
`else
        INJ_EN = 1'b0;
`endif
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
        
        $display("Half periods of OUT after LOCKED: %0d, glitches: %0d", n_half, n_glitch);
        if(!LOCKED) $display("FAIL: not locked");
        else if(n_glitch > 0) $display("FAIL: glitches on OUT");
        else $display("PASS");
        $fflush(flog);
        $finish;
    end


endmodule
