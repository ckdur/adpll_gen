* INJECTION test

.TEMP 25
.PARAM Rdigload=1M
.PARAM Cdigload=2e-15
.PARAM fclk=100000000

* Declare the times in this manner. This is SPICE compatible
.PARAM tclk1=(1/(2*fclk))
.PARAM tclk2=(1/fclk)
.PARAM stopsim=(10*tclk2)

* Include the models
.inc models.inc

* Include the actual netlist
.inc PLL_INJECTION.sp

vvdd VDD GND DC=lvdd
Vin REF 0 PULSE lvdd 0 0 0.05n 0.05n 'tclk1' 'tclk2'
Ven INJ_EN 0 DC=lvdd

* The actual implementation

xtest VDD GND REF INJ_EN INJ_EDGE INJ_WIN BBPD_CK PLL_INJECTION
* Just for the load
xload1 VDD GND INJ_EDGE INJ_EDGEN PLL_CELL_BUFFX0
xload2 VDD GND INJ_WIN INJ_WINN PLL_CELL_BUFFX0
* BBPD_CK drives the two flops of the SS-BBPD
xload3 VDD GND BBPD_CK BBPD_CKN PLL_CELL_BUFFX0
xload4 VDD GND BBPD_CK BBPD_CKN2 PLL_CELL_BUFFX0
cload1load INJ_EDGEN GND 'Cdigload'
ckiad2load INJ_WINN GND 'Cdigload'
cload3load BBPD_CKN GND 'Cdigload'
cload4load BBPD_CKN2 GND 'Cdigload'

* Analysis and measurement
* Maximum step of 1ps: without it the steps around the edges are ~50ps and the .meas are interpolated
.TRAN 1p 'stopsim' 0 1p uic

.param meas_time=(1.2*tclk2)

*                              > 1.2*tclk2
* REF _________++++++++++_________++++++++++_________++++++++++_________++++++++++
* WIN _____________________++++_______________++++_______________++++_________________
* EDG ____________++++++++++_________++++++++++_________++++++++++_________+++++++++
*                                          >--<  twin_start
*                                            >----<  twin_len
*                                          >---<  tedge_start
* BBPD_CK: REF delayed by the 3 chains, falls after the window (SS-BBPD capture)  tbbpd_ck

.meas tran twin_start TRIG V(REF) VAL=0.5 TD='meas_time' FALL=1 TARG V(INJ_WIN) VAL=0.5 TD='meas_time' RISE=1
.meas tran twin_len TRIG V(INJ_WIN) VAL=0.5 TD='meas_time' RISE=1 TARG V(INJ_WIN) VAL=0.5 TD='meas_time' FALL=1
.meas tran tedge_start TRIG V(REF) VAL=0.5 TD='meas_time' FALL=1 TARG V(INJ_EDGE) VAL=0.5 TD='meas_time' FALL=1
.meas tran tbbpd_ck TRIG V(REF) VAL=0.5 TD='meas_time' FALL=1 TARG V(BBPD_CK) VAL=0.5 TD='meas_time' FALL=1

.SAVE
+    V(REF)
+    V(INJ_EDGE)
+    V(INJ_WIN)
+    V(BBPD_CK)

* Run and save the waveforms (.meas results are printed in the log)
.control
run
write test_pll_injection.raw
quit
.endc
