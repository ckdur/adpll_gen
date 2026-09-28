// Sigma delta modulator for
// quote: "Noise-shape" or "quantize the franctional bits"
// Point being that we take the LSB of the digital loop filter
// and pass them through here

module pll_sigma_delta_modulator #(
    parameter integer FILTER_BITS = 10,
    parameter integer Q_BITS = 3
) (
    input CLK, RST_N, ENABLE,
    input [FILTER_BITS-1:0] IN,
    output reg [BITS-1:0] OUT
);
    // NOTE: Implementing MASH 1-1
    // NOTE2: Not sure if this is a MASH 1-1
    // NOTE3: Just using this, because is popular
    /*  ____________________________________
        |             |                     |
        |  _________  x2 _________          |
        |  |       |  |  |       |          |
        v  |   z-1 |  v  |   z-1 |          |
    --->+--| ----- |--+--| ----- |-- QUANT------> OUT
           | 1-z-1 |     | 1-z-1 |
           |_______|     |_______|
    */

    // The first z^-1/(1-z^-1)
    wire [FILTER_BITS:0] f1i;
    reg [FILTER_BITS:0] f1; // 1-bit more for representing negative values
    wire [FILTER_BITS:0] f1d;
    assign f1d = ind + f1;
    always @(posedge CLK or negedge RST_N) begin
        if(!RST_N) begin
            f1 <= 'd0;
        end else begin
            if(f1[FILTER_BITS] == f1i[FILTER_BITS] && f1[FILTER_BITS] == f1d[FILTER_BITS]) begin
                f1 <= f1d[FILTER_BITS-1:0];
            end
        end
    end

    // The second z^-1/(1-z^-1)
    wire [FILTER_BITS:0] f2i;
    reg [FILTER_BITS:0] f2; // 1-bit more for representing negative values
    wire [FILTER_BITS:0] f2d;
    assign f2d = f2 + f2i;
    always @(posedge CLK or negedge RST_N) begin
        if(!RST_N) begin
            f2 <= 'd0;
        end else begin
            if(f2[FILTER_BITS] == f2i[FILTER_BITS] && f2[FILTER_BITS] == f2d[FILTER_BITS] && f2_invalid) begin
                f2 <= f2d[FILTER_BITS-1:0];
            end
        end
    end

    // Assignment of the filters
    wire [Q_BITS-1:0] quant = f2[FILTER_BITS:FILTER_BITS-Q_BITS+1]; // Yeah... no idea. Taking filter 2's output truncated, along with the carry
    assign f1i = {1'b0, IN} + {(FILTER_BITS-Q_BITS+1){1'b0}, quant};
    assign f2i =        f1i + {(FILTER_BITS-Q_BITS){1'b0}, quant, 1'b0}; // x2
    assign f2_invalid = !f1[FILTER_BITS] && f2i[FILTER_BITS];

    assign OUT = quant;
    
endmodule