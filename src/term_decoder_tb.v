// PLL term decoder
`timescale 1ns/1ns

module pll_term_decoder_with_zero_tb;
    localparam NDELS = 31;
    reg [$clog2(NDELS+1)-1:0] IN;
    wire [NDELS-1:0] OUT;

    pll_term_decoder_with_zero dut(.IN(IN), .OUT(OUT));

    integer i;
    initial begin
        $dumpfile("term_decoder_tb.vcd");
        $dumpvars;
        for(i = 0; i < (NDELS+1); i= i + 1) begin
            IN = i;
            #(100);
        end
        $finish;
    end

endmodule
