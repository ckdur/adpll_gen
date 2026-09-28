* Symmetrical circuit delay test

.TEMP 25
.OPTION
+    ARTIST=2
+    INGOLD=2
+    PARHIER=LOCAL
+    PSF=2
+    PROBE
.PARAM Rdigload=1M
.PARAM Cdigload=2e-15
.PARAM fclk=100000000

* Declare the times in this manner. This is SPICE compatible
.PARAM tclk1=(1/(2*fclk))
.PARAM tclk2=(1/fclk)
.PARAM stopsim=(10*tclk2)

* Include the models
.inc lib.sp

* Include the actual netlist
.inc PLL_SYM.sp

vvdd VDD GND DC=lvdd
vgnd GND 0 DC=0
Vinj_win INJ_WIN 0 DC=0
Vinj_edge INJ_EDGE 0 DC=lvdd
Vdco_en DCO_EN 0 DC=lvdd
Vin FINE_OUT 0 PULSE lvdd 0 0 0.05n 0.05n (tclk1) (tclk2)

* The actual implementation

xtest VDD GND INJ_WIN DCO_EN INJ_EDGE FINE_OUT SS_BBPD<1> SS_BBPD<0> OUT PLL_SYM
* Just for the load
xload1 VDD GND SS_BBPD<0> SS_BBPDN<0> PLL_CELL_BUFFX0
xload2 VDD GND SS_BBPD<1> SS_BBPDN<1> PLL_CELL_BUFFX0
xload3 VDD GND OUT OUTN PLL_CELL_BUFFX0
cload1load SS_BBPDN<0> GND Cdigload
ckiad2load SS_BBPDN<1> GND Cdigload
ckiad3load OUTN GND Cdigload

* Analysis and measurement
.TRAN 10n stopsim uic

.param meas_time=(1.2*tclk2)

.meas tran tmux TRIG V(FINE_OUT) VAL=0.5 TD=(meas_time) RISE=1 TARG V(OUT) VAL=0.5 TD=(meas_time) FALL=1
.meas tran tssbbpd TRIG V(FINE_OUT) VAL=0.5 TD=(meas_time) RISE=1 TARG V(SS_BBPDN<1>) VAL=0.5 TD=(meas_time) RISE=1

.PROBE
+    V(FINE_OUT)
+    V(SS_BBPDN<0>)
+    V(SS_BBPDN<1>)
+    V(OUT)

