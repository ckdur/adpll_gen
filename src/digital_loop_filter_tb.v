// Testbench of the pll frequency lock
`timescale 1fs/1fs

module digital_loop_filter_tb();
    localparam REF_T = 10000000; // 10ns, 100MHz
    reg CLK_REF = 1'b0;
    always begin
        #(REF_T/2) CLK_REF <= !CLK_REF;
    end
    
    // Simulation of the delay-based VCO
    localparam COARSE_NDELS = 15; // DO NOT CHANGE
    localparam MID_NDELS = 15; // DO NOT CHANGE
    localparam FINE_NDELS = 31; // DO NOT CHANGE
    wire [COARSE_NDELS-1:0] COARSE_MUX;
    wire [MID_NDELS-1:0] MID_MUX;
    wire [FINE_NDELS-1:0] FINE_MUX;
    wire CLK_VCO;

    sim_dco #(
        .COARSE_NDELS(COARSE_NDELS),
        .MID_NDELS(MID_NDELS),
        .FINE_NDELS(FINE_NDELS)
    ) dco (
        .CLK_VCO(CLK_VCO),
        .COARSE_MUX(COARSE_MUX),
        .MID_MUX(MID_MUX),
        .FINE_MUX(FINE_MUX)
    );

    assign COARSE_MUX = 'h1f; // Extracted from freq_lock_tb
    assign MID_MUX = 'h3f; // Extracted from freq_lock_tb
    assign FINE_MUX = 0; // Fine is not used here

    wire [1:0] SS_BBPD;
    sim_SSBBPD ss_bbpd_inst (
        .CLK_VCO(CLK_VCO), .CLK_REF(CLK_REF),
        .SS_BBPD(SS_BBPD)
    );

    localparam FILTER_BITS = 16;
    reg RST_N;
    reg ENABLE;
    reg [FILTER_BITS-1:0] KP, KI;
    wire [FILTER_BITS-1:0] OUT;
    wire FILTER_CLK = !CLK_VCO;

    pll_digital_loop_filter #(
        .BITS(FILTER_BITS)
    ) dut (
        .VCO(FILTER_CLK), .REF(CLK_REF), .RST_N(RST_N), .ENABLE(ENABLE),
        .SS_BBPD(SS_BBPD),
        .KP(KP), .KI(KI),
        .OUT(OUT)
    );

    integer iter;
    initial begin
        $dumpfile("digital_loop_filter_tb.vcd");
        $dumpvars;
        RST_N = 1'b0;
        ENABLE = 1'b0;
        #1000000 RST_N = 1'b1;
        for(iter = 0; iter < 2; iter = iter + 1)
            #(REF_T);
        
        ENABLE = 1'b1;
        KI = 'd255;  // Use the dlf_design.py for this
        KP = 'd127;

        for(iter = 0; iter < 512; iter = iter + 1)
            #(REF_T);
        
        $finish;
    end
endmodule
