// delta sigma testbench
// By Ckristian Duran
`timescale 1ps/1ps

module delta_sigma_tb();
    localparam REF_T = 10000; // 10ns, 100MHz
    reg CK = 1'b0;
    always begin
        #(REF_T/2) CK <= !CK;
    end

    localparam BITS_INT = 5;
    localparam BITS_DSM = 16-BITS_INT;

    reg RST;
    reg EN_DSM;
    reg EN_DSM_DT;
    reg EN_DSM_SHDT;
    reg [1:0] DSM_ORDER;
    reg [BITS_INT-1:0] FCWI;         // Integer division ratio (AKA N)
    reg [BITS_DSM-1:0] FCWF;         // Fractional division ratio (AKA N + FCWF / 2^bits_dsm)
    wire [BITS_INT-1:0] DSM_OUT;     // Output of the dsm 

    delta_sigma #(
        .BITS_INT(BITS_INT),
        .BITS_DSM(BITS_DSM)
    ) dut (
        .CK(CK),
        .RST(RST),
        .EN_DSM(EN_DSM),
        .EN_DSM_DT(EN_DSM_DT),
        .EN_DSM_SHDT(EN_DSM_SHDT),
        .DSM_ORDER(DSM_ORDER),
        .FCWI(FCWI),
        .FCWF(FCWF),
        .DSM_OUT(DSM_OUT)
    );

    real avg; // Moving average
    real int_avg; // Intended average
    real diff;
    integer i;
    integer order;

    initial begin
        $dumpfile("delta_sigma_tb.vcd");
        $dumpvars;
        EN_DSM = 1'b1;
        EN_DSM_DT = 1'b0;
        EN_DSM_SHDT = 1'b1;
        FCWI = 24;
        FCWF = 128;

        for(order = 0; order < 3; order = order + 1) begin
            DSM_ORDER = order; // 0 is first order, 1 second order, 2 third order
            avg = 0.0;
            int_avg = $itor(FCWI) + $itor(FCWF) / (2**BITS_DSM);

            RST = 1'b1;
            #(REF_T*10);
            RST = 1'b0;

            for(i = 0; i < 1024; i=i+1) begin
                #(REF_T);
                avg = avg + (($itor(DSM_OUT)-avg) / (i+1)); // Moving average
            end

            // abs() is SystemVerilog only. Plain Verilog-2005 equivalent:
            diff = (avg > int_avg) ? (avg - int_avg) : (int_avg - avg);
            $display("Order: %d, Average = %g, Intended average = %g, Diff = %g", order+1, avg, int_avg, diff);
        end

        $finish;
    end
    
endmodule