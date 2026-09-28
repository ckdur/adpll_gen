// Testbench of the pll frequency lock
`timescale 1fs/1fs

module pll_freq_lock_tb();
    localparam REF_T = 10000000; // 10ns, 100MHz
    localparam CNT_BITS = 8;
    reg [CNT_BITS-1:0] FCW = 'd15;

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

    reg RST_N;
    wire LOCKED, ERR;
    reg START;
    pll_freq_lock #(
        .COARSE_NDELS(COARSE_NDELS),
        .MID_NDELS(MID_NDELS),
        .CNT_BITS(CNT_BITS)
    ) dut (
        .REF(CLK_REF), .VCO(CLK_VCO), .RST_N(RST_N),
        .FCW(FCW), .START(START),
        .LOCKED(LOCKED), .ERR(ERR),
        .COARSE_MUX(COARSE_MUX),
        .MID_MUX(MID_MUX)
    );

    assign FINE_MUX = 0; // Fine is not used here

    integer iter;
    initial begin
        $dumpfile("freq_lock_tb.vcd");
        $dumpvars;
        RST_N = 1'b0;
        START = 1'b0;
        #1000000 RST_N = 1'b1;
        for(iter = 0; iter < 2; iter = iter + 1)
            #(REF_T);
        
        START = 1'b1;
        #(REF_T) START = 1'b0;

        for(iter = 0; iter < 256; iter = iter + 1)
            #(REF_T);
        
        FCW = 'd13;
        START = 1'b1;
        #(REF_T) START = 1'b0;

        for(iter = 0; iter < 256; iter = iter + 1)
            #(REF_T);
        $finish;
    end
endmodule
