// Several termometer decoders
`timescale 1ns/1ns

module pll_term_decoder_with_zero #(
    parameter integer NDELS = 31
) (
    input [$clog2(NDELS+1)-1:0] IN,
    output reg [NDELS-1:0] OUT
);
    always @(IN) begin
        if(IN == 0)
            OUT = 0;
        else
            OUT = ((1 << (IN)) - 1);
    end
endmodule
