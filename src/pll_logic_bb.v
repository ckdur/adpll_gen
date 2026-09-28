(* blackbox *)
module pll_logic #(
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
    input VDD, VSS, // Ignored (for now)
    input REF, OUT, MID_OUT, INJ_EDGE, RST_N,
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
    output reg DCO_EN, LOCKED, ERR
);
    // Blackbox implementation is not provided
endmodule
