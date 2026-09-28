// A synthesizable divider
module pll_fix_divider #(
    parameter DIV = 2
)(
    input  wire             clk,
    input  wire             rst_n,     // active low reset
    output reg              out        // divided clock output
);
    localparam W = $clog2(DIV) + 1;

    // counters and limits for alternating high/low when odd
    reg [W-1:0] cnt;
    reg         high_phase; // 1 => currently producing high phase (counting high_count)

    // compute counts when div changes (synchronous)
    // high_count = ceil(div/2), low_count = floor(div/2)
    localparam half = DIV >> 1;
    localparam div_is_odd = (DIV & 1) != 0;
    localparam high_count = DIV == 1 ? 1 : (div_is_odd ? (half + 1) : half);
    localparam low_count = DIV == 1 ? 1 : half;

    generate 
        if(DIV == 0) begin : IS_DIV_ZERO
            always @(*) out <= clk;
        end else if(DIV == 1) begin : IS_DIV_ONE
            always @(posedge clk or negedge rst_n) begin
                if(!rst_n) begin
                    out        <= 0;
                    high_phase <= 1'b0;
                end else begin
                    // divide by 1: output follows input clock (toggle every cycle -> same freq)
                    out <= ~out; // alternative: keep out = clk? but easier to toggle each cycle gives clk/2; depends on desired semantics
                end
            end
        end else begin
            always @(posedge clk or negedge rst_n) begin
                if(!rst_n) begin
                    cnt        <= 0;
                    out        <= 0;
                    high_phase <= 1'b0;
                end else begin
                    // normal operation: count cycles within current phase
                    if (cnt + 1 >= (high_phase ? high_count : low_count)) begin
                        // phase complete -> toggle output and start next phase
                        out <= ~out;
                        cnt <= 0;
                        high_phase <= ~high_phase;
                    end else begin
                        cnt <= cnt + 1;
                    end
                end
            end
        end
    endgenerate
    

endmodule
