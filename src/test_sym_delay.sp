* Symmetrical circuit delay test

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
.inc PLL_SYM.sp

vvdd VDD GND DC=lvdd
Vinj_win INJ_WIN 0 DC=0
Vinj_edge INJ_EDGE 0 DC=lvdd
Vdco_en DCO_EN 0 DC=lvdd
Vin FINE_OUT 0 PULSE lvdd 0 0 0.05n 0.05n 'tclk1' 'tclk2'

* The actual implementation

xtest VDD GND INJ_WIN DCO_EN INJ_EDGE FINE_OUT SS_BBPD<1> SS_BBPD<0> OUT OSC_LVL INJ_LVL PLL_SYM
* Second instance for the delays of the window latch (sym_mux/WIN): the DCO is low (FINE_OUT high) when
* INJ_WIN rises at 30 ns (the window opens), then it goes high at 33 ns, and INJ_WIN falls at 36 ns (closes)
* (the window closes with INJ_WIN in any case, the DCO going high only checks that it stays open)
Vwin_win INJ_WIN2 0 PWL 0 0 30n 0 30.05n lvdd 36n lvdd 36.05n 0
Vwin_fine FINE_OUT2 0 PWL 0 lvdd 33n lvdd 33.05n 0
xwin VDD GND INJ_WIN2 DCO_EN INJ_EDGE FINE_OUT2 SS2<1> SS2<0> OUT2 OSC_LVL2 INJ_LVL2 PLL_SYM
xwload VDD GND OUT2 OUT2N PLL_CELL_BUFFX0
cwload OUT2N GND 'Cdigload'

* Just for the load
xload1 VDD GND SS_BBPD<0> SS_BBPDN<0> PLL_CELL_BUFFX0
xload2 VDD GND SS_BBPD<1> SS_BBPDN<1> PLL_CELL_BUFFX0
xload3 VDD GND OUT OUTN PLL_CELL_BUFFX0
* OSC_LVL and INJ_LVL drive the level flops of il_dco.v
xload4 VDD GND OSC_LVL OSC_LVLN PLL_CELL_BUFFX0
xload5 VDD GND INJ_LVL INJ_LVLN PLL_CELL_BUFFX0
cload1load SS_BBPDN<0> GND 'Cdigload'
ckiad2load SS_BBPDN<1> GND 'Cdigload'
ckiad3load OUTN GND 'Cdigload'
cload4load OSC_LVLN GND 'Cdigload'
cload5load INJ_LVLN GND 'Cdigload'

* Analysis and measurement
* Maximum step of 1ps: without it the steps around the edges are ~50ps and the .meas are interpolated
.TRAN 1p 'stopsim' 0 1p uic

.param meas_time=(1.2*tclk2)

.meas tran tmux TRIG V(FINE_OUT) VAL=0.5 TD='meas_time' RISE=1 TARG V(OUT) VAL=0.5 TD='meas_time' FALL=1
.meas tran tssbbpd TRIG V(FINE_OUT) VAL=0.5 TD='meas_time' RISE=1 TARG V(SS_BBPDN<1>) VAL=0.5 TD='meas_time' RISE=1
* Window latch: opening (DCO low) and closing (DCO high) delays from INJ_WIN
.meas tran twin_on TRIG V(INJ_WIN2) VAL=0.5 TD=29n RISE=1 TARG V(xwin.sym_mux/WIN) VAL=0.5 TD=29n RISE=1
.meas tran twin_off TRIG V(INJ_WIN2) VAL=0.5 TD=35n FALL=1 TARG V(xwin.sym_mux/WIN) VAL=0.5 TD=35n FALL=1
.meas tran tlvl TRIG V(FINE_OUT) VAL=0.5 TD='meas_time' RISE=1 TARG V(OSC_LVL) VAL=0.5 TD='meas_time' RISE=1

.SAVE
+    V(FINE_OUT)
+    V(SS_BBPDN<0>)
+    V(SS_BBPDN<1>)
+    V(OUT)
+    V(OSC_LVL)
+    V(INJ_WIN2)
+    V(xwin.sym_mux/WIN)

* Run and save the waveforms (.meas results are printed in the log)
.control
run
write test_sym_delay.raw
quit
.endc
