// A simulated multiplexer
// This multiplexer is used for the "digital simulation version" to get delays without
// the additional delay of a multiplexer

(* keep_hierarchy = "yes" *)
module sim_mux #(
    parameter integer NDELS = 15
) (
    input [NDELS-1:0] MUX,
    input [NDELS:0] IN,
    output reg OUT
);

    integer i;
    always @(MUX or IN) begin
        OUT = IN[0];
        for(i = 0; i < NDELS; i=i+1) begin
            if(MUX[i]) begin
                OUT = IN[i+1];
            end
        end
    end
endmodule

module sim_mux_NDELS15 (
    input [15-1:0] MUX,
    input [15:0] IN,
    output OUT
);
    sim_mux #(.NDELS(15)) impl(.MUX(MUX), .IN(IN), .OUT(OUT));
endmodule

module sim_mux_NDELS31 (
    input [31-1:0] MUX,
    input [31:0] IN,
    output OUT
);
    sim_mux #(.NDELS(31)) impl(.MUX(MUX), .IN(IN), .OUT(OUT));
endmodule
