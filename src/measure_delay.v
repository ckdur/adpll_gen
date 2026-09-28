// A replica of measure_delay in verilog

module measure_delay #(
    parameter tsw = 8,
    parameter tclk1 = 1
) (
    input [31:0] f,
    input IN, OUT
);

    realtime t1, t2;
    genvar i;

    generate
        for(i = 0; i < 32; i=i+1) begin : meas
            initial begin
                #(i*tsw+2*tclk1);
                @(posedge IN) t1 = $realtime ;
                @(posedge OUT) t2 = $realtime ;
                
                $fwrite(f, "Time for %d is %f\n", i, t2-t1);
            end
        end
    endgenerate
endmodule