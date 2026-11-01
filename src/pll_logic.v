// The digital synthesizable part of the PLL

module pll_logic#(
    parameter integer COARSE_NDELS = 15, // 4-bit coarse
    parameter integer MID_NDELS = 15, // 4-bit mid
    parameter integer FINE_NDELS = 31, // 5-bit fine
    parameter integer FILTER_BITS = 16,
    parameter integer IS_DSM = 1,
    parameter integer DSM_DIV = 2,
    parameter integer LOCKED_WAIT = 64,
    parameter integer FILTER_ILL = 16,
`ifndef PLL_WITHOUT_DIVIDER
    parameter integer DIV_BITS = 8,
`endif
    parameter integer FCW_BITS = 8
) (
`ifdef WITH_POWER
    input VDD, VSS, // Ignored (for now)
`endif
    input REF, OUT, MID_OUT, INJ_EDGE, RST_N,
    input INJ_EN,
    input [1:0] SS_BBPD,
    input [FILTER_BITS-1:0] KP, KI,
    input [FCW_BITS-1:0] FCW,
    input DSM_EN_DT,
    input DSM_EN_SHDT,
    input [1:0] DSM_ORDER,
`ifndef PLL_WITHOUT_DIVIDER
    input [DIV_BITS-1:0] SET_DIV,
    input LOAD_DIV,
    output OUT_DIV,
`endif
    output reg [COARSE_NDELS-1:0] COARSE_MUX,
    output reg [MID_NDELS-1:0] MID_MUX,
    output reg [FINE_NDELS-1:0] FINE_MUX,
    output reg DCO_EN, LOCKED, ERR,
    output reg INJ_ACT
);
    wire [COARSE_NDELS-1:0] COARSE_MUX_D;
    wire [MID_NDELS-1:0] MID_MUX_D;
    wire [FINE_NDELS-1:0] FINE_MUX_D;

    // Update logic according to the paper
    reg CKR;
    always @(negedge MID_OUT or negedge RST_N) if(!RST_N) CKR <= 1'b0; else CKR <= REF;
    //always @(posedge CKR or negedge RST_N) if(!RST_N) FINE_MUX <= 'd0; else FINE_MUX <= FINE_MUX_D; // Done afterwards
    always @(posedge CKR or negedge RST_N) if(!RST_N) MID_MUX <= 'd0; else MID_MUX <= MID_MUX_D;
    always @(posedge CKR or negedge RST_N) if(!RST_N) COARSE_MUX <= 'd0; else COARSE_MUX <= COARSE_MUX_D;

    // Filter stage
    wire [FILTER_BITS-1:0] FILTER_OUT;
    wire ILL_P, ILL_N;
    reg ENABLE;
    pll_digital_loop_filter #(
        .BITS(FILTER_BITS)
    ) dlf (
        .CLK(!INJ_EDGE),
        .RST_N(RST_N), .ENABLE(ENABLE),
        .SS_BBPD(SS_BBPD),
        .KP(KP), .KI(KI),
        .OUT(FILTER_OUT),
        .ILL_P(ILL_P),
        .ILL_N(ILL_N)
    );

    wire [$clog2(FINE_NDELS)-1:0] FILTER_DEC;
    generate
        if(IS_DSM) begin : dsm_impl
            wire DSM_CK;
            pll_fix_divider #(.DIV(DSM_DIV)) dsm_div (.clk(MID_OUT), .rst_n(RST_N), .out(DSM_CK));
            // Fine code = FILTER_OUT / 2^(FILTER_BITS - $clog2(FINE_NDELS)): the MSBs are the integer
            // part (FCWI) and the rest is the fraction that the DSM modulates (FCWF).
            // NOTE: It was FCWI = {FILTER_OUT[15:12], 1'b0}, FCWF = FILTER_OUT[11:0]: the integer part
            // weighted 2 codes per 2^12 LSB and the fraction 1 code per 2^12 LSB, so the DCO had a gap
            // of one fine code every 2^12 LSB, where the loop hunted (deterministic jitter of ~2ps).
            localparam integer FRAC_BITS = FILTER_BITS - $clog2(FINE_NDELS);
            reg [$clog2(FINE_NDELS)-1:0] FCWI;
            reg [FRAC_BITS-1:0] FCWF;
            always @(posedge DSM_CK or negedge RST_N) begin
                if(!RST_N) begin
                    FCWI <= 0;
                    FCWF <= 0;
                end else begin
                    FCWI <= FILTER_OUT[FILTER_BITS-1:FRAC_BITS];
                    FCWF <= FILTER_OUT[FRAC_BITS-1:0];
                end     
            end
            delta_sigma #(
                .BITS_INT($clog2(FINE_NDELS)),
                .BITS_DSM(FRAC_BITS)
            ) dsm (
                .CK(DSM_CK),
                .RST(!RST_N),
                .EN_DSM(DCO_EN),
                .EN_DSM_DT(DSM_EN_DT),
                .EN_DSM_SHDT(DSM_EN_SHDT),
                .DSM_ORDER(DSM_ORDER),
                .FCWI(FCWI),
                .FCWF(FCWF),
                .DSM_OUT(FILTER_DEC)
            );
            always @(posedge DSM_CK or negedge RST_N) if(!RST_N) FINE_MUX <= 'd0; else FINE_MUX <= FINE_MUX_D; // For better in-time resolution
        end else begin
            assign FILTER_DEC = FILTER_OUT[FILTER_BITS-1:FILTER_BITS-$clog2(FINE_NDELS)];
            always @(posedge CKR or negedge RST_N) if(!RST_N) FINE_MUX <= 'd0; else FINE_MUX <= FINE_MUX_D; // Just save energy
        end
    endgenerate

    pll_term_decoder_with_zero #(
        .NDELS(FINE_NDELS)
    ) dec (
        .IN(FILTER_DEC),
        .OUT(FINE_MUX_D)
    );

    // Freq locking stage
    wire FREQ_LOCKED, FREQ_ERR;
    reg START;
    // Once the phase loop runs (after FREQ_LOCKED), the counter of the frequency lock does not move the
    // mid/coarse codes anymore (only FORCE_P/FORCE_N do, when the loop filter saturates). Otherwise every
    // cycle slip while the integrator settles changes the count, and the mid code toggles back and forth.
    wire LOCK;
    reg FORCE_P, FORCE_N;
    pll_freq_lock #(
        .COARSE_NDELS(COARSE_NDELS),
        .MID_NDELS(MID_NDELS),
        .CNT_BITS(FCW_BITS)
    ) flock (
        .REF(REF), .MID_OUT(MID_OUT), .OUT(OUT),
        .RST_N(RST_N),
        .FCW(FCW), .START(START),
        .LOCK(LOCK),
        .FORCE_P(FORCE_P), .FORCE_N(FORCE_N),
        .LOCKED(FREQ_LOCKED), .ERR(FREQ_ERR),
        .COARSE_MUX(COARSE_MUX_D),
        .MID_MUX(MID_MUX_D)
    );

    // State machine.
    reg [2:0] state;
    assign LOCK = (state == 3'b010) || (state == 3'b011);
    reg [7:0] cnt;
    reg [7:0] cntf;
    always @(negedge INJ_EDGE or negedge RST_N) begin
        if(!RST_N) begin
            state <= 2'b00;
            START <= 1'b0;
            cnt <= 'd0;
            cntf <= 'd0;
            LOCKED <= 1'b0;
            ERR <= 1'b0;
            DCO_EN <= 1'b0;
            ENABLE <= 1'b0;
            FORCE_P <= 1'b0;
            FORCE_N <= 1'b0;
        end else begin
            case(state)
                3'b000: begin  // Init. Do nothing
                    cnt <= cnt + 1;
                    DCO_EN <= 1'b1;
                    if(cnt[3]) begin 
                        state <= 3'b001;
                        START <= 1'b1;
                        cnt <= 'd0;
                        ENABLE <= 1'b1; // Enable the filter here
                    end
                end
                3'b001: begin  // Waiting for the freq locking
                    START <= 1'b0;
                    if(!START) begin
                        if(FREQ_LOCKED) begin 
                            state <= 3'b010;
                        end
                        else if(FREQ_ERR) state <= 3'b100;
                    end
                end
                3'b010: begin  // Wait for phase locking
                    if(cnt == LOCKED_WAIT) begin
                        state <= 3'b011;
                        cnt <= 'd0;
                    end else begin  // Logic for force count up/down whenever the illegal positive/negative is triggered
                        FORCE_P <= 1'b0;
                        FORCE_N <= 1'b0;
                        if(ILL_P || ILL_N) begin
                            cntf <= cntf + 1;
                            cnt <= 'd0;
                            if(cntf == FILTER_ILL) begin
                                // Activate one of the FORCE_P/FORCE_N
                                if(ILL_P) FORCE_P <= 1'b1;
                                else if(ILL_N) FORCE_N <= 1'b1;
                                cntf <= 'd0;
                            end
                        end else begin
                            cntf <= 'd0;
                            cnt <= cnt + 1;
                        end
                    end
                end
                3'b011: begin  // Locked state
                    state <= 3'b011;
                    LOCKED <= 1'b1;
                end
                3'b100: begin  // Error state
                    state <= 3'b100;
                    ERR <= 1'b1;
                end
                default:
                    state <= 3'b100; // Go to the error state
            endcase
        end
    end
    
    // Injection enable. The window (injection.v) opens after the falling edge of REF, so INJ_EN is
    // retimed with the rising edge: it never changes during a window (an asynchronous INJ_EN could
    // open or close a window halfway, and cut an edge of OUT).
    // The injection replaces the edge of the DCO by the injected one, which is only glitch-free if
    // the natural edge is inside the window. So it is allowed only after the phase lock (LOCKED).
    // LOCKED only means that the filter did not saturate for LOCKED_WAIT cycles, which also happens while
    // the integrator is still ramping (the phase slips with the same BBPD symbol every cycle). So the
    // injection also needs the BBPD to toggle: PHASE_OK falls after a run of 2^PHASE_RUN_BITS equal symbols
    // (and the injection stops at the next REF, without cutting a window).
    localparam integer PHASE_RUN_BITS = 5;
    reg [PHASE_RUN_BITS-1:0] run_cnt;
    reg last_p, PHASE_OK;
    always @(negedge INJ_EDGE or negedge RST_N) begin
        if(!RST_N) begin
            run_cnt <= 'd0;
            last_p <= 1'b0;
            PHASE_OK <= 1'b0;
        end else begin
            last_p <= SS_BBPD[0] && !SS_BBPD[1];  // SYMBOL_P of the loop filter
            if((SS_BBPD[0] && !SS_BBPD[1]) != last_p) begin
                run_cnt <= 'd0;
                PHASE_OK <= 1'b1;
            end else if(&run_cnt) begin
                PHASE_OK <= 1'b0;
            end else begin
                run_cnt <= run_cnt + 1;
            end
        end
    end

    always @(posedge REF or negedge RST_N) begin
        if(!RST_N) INJ_ACT <= 1'b0;
        else       INJ_ACT <= INJ_EN && LOCKED && PHASE_OK;
    end

`ifndef PLL_WITHOUT_DIVIDER
    pll_mod_divider #(.W(DIV_BITS)) div(
        .clk(OUT),
        .rst_n(RST_N),
        .set_div(SET_DIV),
        .load_div(LOAD_DIV),
        .out(OUT_DIV)
    );
`endif

endmodule