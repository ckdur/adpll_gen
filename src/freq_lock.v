// Frequency locking. A very basic (and probably wrong) RTL for
// locking the frequency of a DCO in an IL-PLL

// The RTL will have a counter which is constantly reset by the
// ref clock, and update coarse and mid configurations.
`timescale 1fs/1fs

module pll_freq_lock #(
    parameter integer COARSE_NDELS = 4,     // Assign to coarse delays
    parameter integer MID_NDELS = 5,        // Assign to mid delays
    parameter integer CNT_BITS = 8,         // Number of bits for the freq counter
    parameter integer CNT_TOL_BITS = 8,     // Number of bits for tolerances
    parameter integer LOCK_LIMIT = 64,      // If CNT is inside the locking tolerance for this many cycles, lock
    parameter integer ERR_LIMIT = 64,       // If COARSE and MID cannot increase/decrease for this many cycles, err
    parameter integer LOCK_TOL = 0,         // Tolerance for the FCW for locking. 0 for exact (CNT = FCW +/- LOCK_TOL)
    parameter integer TOL_COARSE_WAIT = 1   // Wait REF cycles for changing the COARSE once the MID is in the limit, 1 for always change
) (
    input REF, MID_OUT, OUT, RST_N, START,
    input [CNT_BITS-1:0] FCW,
    input LOCK,
    input FORCE_P, FORCE_N,                 // Force count up or down
    output reg LOCKED, ERR,
    output reg [COARSE_NDELS-1:0] COARSE_MUX,
    output reg [MID_NDELS-1:0] MID_MUX
);
    wire CLK_REF = REF; // NOTE: Negative injection
    wire CLK_OUT = MID_OUT;

    // The counter that resets every reference
    reg [CNT_BITS-1:0] cnt;
    reg [CNT_BITS-1:0] cnt_cap;
    wire rst_cnt_d;
    reg rst_cnt;

    // Counter logic
`ifndef PLL_NEGFLOP_COUNTER
    // Leave the synthesizer to do the counter
    always @(posedge CLK_OUT or negedge RST_N) begin
        if(!RST_N) begin
            cnt <= 'd0;
        end else begin
            if(rst_cnt) begin
                cnt <= 'd0;
            end else begin
                cnt <= cnt + 1;
            end
        end
    end
`else
    // Use negate flops (if the synthesizer allows it)
    // NOTE: It doesn't allow it. Is disabled for now
    wire rst_cnt_beg_async;
    assign rst_cnt_beg_async = (!rst_cnt) && RST_N;
    genvar i;
    generate
        // For zero
        always @(posedge CLK_OUT or negedge rst_cnt_beg_async) begin
            if(!rst_cnt_beg_async) begin
                cnt[0] <= 1'b0;
            end else begin
                cnt[0] <= !cnt[0];
            end
        end
        for(i = 1; i < CNT_BITS; i=i+1) begin : jk_counter
        always @(negedge cnt[i-1] or negedge rst_cnt_beg_async) begin
            if(!rst_cnt_beg_async) begin
                cnt[i] <= 1'b0;
            end else begin
                cnt[i] <= !cnt[i];
            end
        end
        end
    endgenerate
`endif

    // Capture logic
    always @(posedge CLK_OUT or negedge RST_N) begin
        if(!RST_N) begin
            cnt_cap <= 'd0;
        end else begin
            if(rst_cnt_d) begin
                cnt_cap <= cnt;
            end
        end
    end

    // The reset logic for the counter
    reg CLK_REF_Q;
    assign rst_cnt_d = !CLK_REF_Q && CLK_REF;
    always @(posedge CLK_OUT or negedge RST_N) begin
        if(!RST_N) begin
            CLK_REF_Q <= 1'b0;
            rst_cnt <= 1'b0;
        end else begin
            CLK_REF_Q <= CLK_REF;
            rst_cnt <= rst_cnt_d;
        end
    end

    // Register the tolerances... 
    reg [CNT_BITS-1:0] FCW_PA; // FCW + TOL
    reg [CNT_BITS-1:0] FCW_NA; // FCW - TOL
    always @(posedge CLK_REF) begin
        FCW_PA <= FCW + LOCK_TOL;
        FCW_NA <= FCW - LOCK_TOL;
    end

`ifdef INVALID
    reg cnt_less;
    reg cnt_more;
    always @(negedge CLK_REF) cnt_less <= cnt_cap < FCW;
    always @(negedge CLK_REF) cnt_more <= cnt_cap > FCW;
`else
    wire cnt_less;
    wire cnt_more;
    assign cnt_less = cnt_cap < FCW;
    assign cnt_more = cnt_cap > FCW;
`endif

    reg [CNT_TOL_BITS-1:0] cnt_done;
    reg [CNT_TOL_BITS-1:0] cnt_err;
    reg [CNT_TOL_BITS-1:0] cnt_coarse_wait;
    reg started;
    always @(posedge CLK_REF or negedge RST_N) begin
        if(!RST_N) begin
            ERR <= 1'b0;
            LOCKED <= 1'b0;
            COARSE_MUX <= 'd0;
            MID_MUX <= 'd0;
            cnt_done <= 'd0;
            cnt_err <= 'd0;
            cnt_coarse_wait <= 'd0;
            started <= 1'b0;
        end else begin
            // Start status
            if(!started && START) started <= 1'b1;

            // Start again if it was already locked or in error status
            if((LOCKED || ERR) && START) begin
                LOCKED <= 1'b0;
                ERR <= 1'b0;
                cnt_done <= 'd0;
                cnt_err <= 'd0;
            end

            if(!LOCKED && !ERR && started) begin
                // Locking done when the frequency doesn't 
                // change anymore during a certain time
                if(cnt_done >= LOCK_LIMIT) LOCKED <= 1'b1;

                // Increase the locking counter when the frequency counter is
                // within the range. Reset the counter when counters are different
                if(FCW_NA <= cnt_cap && cnt_cap <= FCW_PA) cnt_done <= cnt_done + 1;
                else cnt_done <= 'd0;
            end

            // Coarse and mid delay tuning
            if(started && ((!LOCK && cnt_less) || FORCE_N)) begin
                // if the captured counter is lower than the desired
                // means that the frequency is lower
                // need to make it faster, and by extension, disable delays
                if(MID_MUX[0] == 1'b0) begin // Mid cannot decrease anymore
                    cnt_coarse_wait <= cnt_coarse_wait - 1;
                    if(cnt_coarse_wait == 'd0) begin
                        if(COARSE_MUX[0] == 1'b0) begin 
                            cnt_err <= cnt_err + 1;
                            if(cnt_err == ERR_LIMIT) ERR <= 1'b1; // Cannot decrease anything
                        end else begin
                            MID_MUX <= {{2{1'b0}}, {(MID_NDELS-2){1'b1}}}; // Put the mid on highest
                            COARSE_MUX <= {1'b0, COARSE_MUX[COARSE_NDELS-1:1]}; // Decrease by one
                            cnt_err <= 'd0;
                            cnt_coarse_wait <= TOL_COARSE_WAIT-1;
                        end
                    end
                end else begin
                    MID_MUX <= {1'b0, MID_MUX[MID_NDELS-1:1]}; // Decrease by one
                    cnt_err <= 'd0;
                    cnt_coarse_wait <= TOL_COARSE_WAIT-1;
                end
            end else if(started && ((!LOCK && cnt_more) || FORCE_P)) begin
                // if the captured counter is higher than the desired
                // means that the frequency is higher
                // need to make it slower, and by extension, enable delays
                if(MID_MUX[MID_NDELS-1] == 1'b1) begin // Mid cannot increase anymore
                    cnt_coarse_wait <= cnt_coarse_wait - 1;
                    if(cnt_coarse_wait == 'd0) begin
                        if(COARSE_MUX[COARSE_NDELS-1] == 1'b1) begin
                            cnt_err <= cnt_err + 1;
                            if(cnt_err == ERR_LIMIT) ERR <= 1'b1; // Cannot increase anything
                        end else begin
                            MID_MUX <= {{(MID_NDELS-2){1'b0}}, {2{1'b1}}}; // Put the mid on lowest
                            COARSE_MUX <= {COARSE_MUX[COARSE_NDELS-2:0], 1'b1}; // Increase by one
                            cnt_err <= 'd0;
                            cnt_coarse_wait <= TOL_COARSE_WAIT-1;
                        end
                    end
                end else begin
                    MID_MUX <= {MID_MUX[MID_NDELS-2:0], 1'b1}; // Increase by one
                    cnt_err <= 'd0;
                    cnt_coarse_wait <= TOL_COARSE_WAIT-1;
                end
            end else begin
                cnt_coarse_wait <= TOL_COARSE_WAIT-1;
            end
        end
    end

endmodule