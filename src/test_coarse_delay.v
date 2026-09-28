// A replica of the test_coarse_delay.sp
// It uses the sdf annotation to just get the delay
// ... maybe is better to find the delay chain... but
// this is probably safer for us

`timescale 1ps/1fs

`include "COARSE_DELAY_net.v"

`include "measure_delay.v"

module test_coarse_delay();

    reg IN = 1'b0;
    reg [14:0] MUX = 15'd0;
    wire OUT;
    wire VDD = 1'b1;
    wire VSS = 1'b1;
    integer f = 0;

    localparam tsw = 1000000; // 100n (see the timescale)
    localparam tclk1 = tsw/8;

    // Clock generation
    always begin
        #(tclk1) IN = ~IN;
    end
    
    // Multiplexer selection
    integer i;
    initial begin
        for(i = 0; i < 15; i=i+1) begin
            #(tsw);
            MUX[i] <= 1'b1;
        end
    end

    // DUT
    COARSE_DELAY dut(
`ifdef WITH_POWER 
        .VDD(VDD), .VSS(VSS), 
`endif
        .MUX(MUX), .IN(IN), .OUT(OUT));

    // SDF annotation, VCD dump, and simulation time. MAKE SURE this is okay
    initial begin
        $sdf_annotate("COARSE_DELAY.sdf", test_coarse_delay.dut, "", "COARSE_DELAY.sdf.log", "maximum");
        $dumpfile("test_coarse_delay.vcd");
        $dumpvars(0);
        f = $fopen("test_coarse_delay.vcd.mt0", "w");

        #(16*tsw);
        $fclose(f);
        $finish;
    end

    // Measurement
    measure_delay #(
        .tsw(tsw),
        .tclk1(tclk1)
    ) meas (
        .f(f),
        .IN(IN), .OUT(OUT)
    );


endmodule
