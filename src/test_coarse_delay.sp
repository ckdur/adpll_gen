* COARSE DELAY test

.TEMP 25
.PARAM Rdigload=1M
.PARAM Cdigload=2e-15
.PARAM tsw=100n
.PARAM stopsim=(16*tsw)

* Declare the times in this manner. This is SPICE compatible
.PARAM tsw1=(1*tsw)
.PARAM tsw2=(2*tsw)
.PARAM tsw3=(3*tsw)
.PARAM tsw4=(4*tsw)
.PARAM tsw5=(5*tsw)
.PARAM tsw6=(6*tsw)
.PARAM tsw7=(7*tsw)
.PARAM tsw8=(8*tsw)
.PARAM tsw9=(9*tsw)
.PARAM tsw10=(10*tsw)
.PARAM tsw11=(11*tsw)
.PARAM tsw12=(12*tsw)
.PARAM tsw13=(13*tsw)
.PARAM tsw14=(14*tsw)
.PARAM tsw15=(15*tsw)
.PARAM tclk1=(0.125*tsw)
.PARAM tclk2=(0.25*tsw)

* Include the models
.inc models.inc

* Include the actual netlist
.inc COARSE_DELAY.sp

vvdd VDD GND DC=lvdd
Vm0 MUX<0> 0 PULSE lvdd 0 0 0.05n 0.05n 'tsw1' 'stopsim'
Vm1 MUX<1> 0 PULSE lvdd 0 0 0.05n 0.05n 'tsw2' 'stopsim'
Vm2 MUX<2> 0 PULSE lvdd 0 0 0.05n 0.05n 'tsw3' 'stopsim'
Vm3 MUX<3> 0 PULSE lvdd 0 0 0.05n 0.05n 'tsw4' 'stopsim'
Vm4 MUX<4> 0 PULSE lvdd 0 0 0.05n 0.05n 'tsw5' 'stopsim'
Vm5 MUX<5> 0 PULSE lvdd 0 0 0.05n 0.05n 'tsw6' 'stopsim'
Vm6 MUX<6> 0 PULSE lvdd 0 0 0.05n 0.05n 'tsw7' 'stopsim'
Vm7 MUX<7> 0 PULSE lvdd 0 0 0.05n 0.05n 'tsw8' 'stopsim'
Vm8 MUX<8> 0 PULSE lvdd 0 0 0.05n 0.05n 'tsw9' 'stopsim'
Vm9 MUX<9> 0 PULSE lvdd 0 0 0.05n 0.05n 'tsw10' 'stopsim'
Vm10 MUX<10> 0 PULSE lvdd 0 0 0.05n 0.05n 'tsw11' 'stopsim'
Vm11 MUX<11> 0 PULSE lvdd 0 0 0.05n 0.05n 'tsw12' 'stopsim'
Vm12 MUX<12> 0 PULSE lvdd 0 0 0.05n 0.05n 'tsw13' 'stopsim'
Vm13 MUX<13> 0 PULSE lvdd 0 0 0.05n 0.05n 'tsw14' 'stopsim'
Vm14 MUX<14> 0 PULSE lvdd 0 0 0.05n 0.05n 'tsw15' 'stopsim'
Vin IN 0 PULSE lvdd 0 0 0.05n 0.05n 'tclk1' 'tclk2'

* The actual implementation

xtest VDD GND
+ MUX<14> MUX<13> MUX<12> MUX<11> MUX<10>
+ MUX<9> MUX<8> MUX<7> MUX<6> MUX<5> MUX<4> MUX<3> MUX<2> MUX<1> MUX<0>
+ IN OUT COARSE_DELAY
* Just for the load
xtestload VDD GND
+ MUX<14> MUX<13> MUX<12> MUX<11> MUX<10>
+ MUX<9> MUX<8> MUX<7> MUX<6> MUX<5> MUX<4> MUX<3> MUX<2> MUX<1> MUX<0>
+ OUT OUT2 COARSE_DELAY
cloadload OUT2 gnd 'Cdigload'

* Analysis and measurement
* The MUX switching and the IN edges coincide. Merge breakpoints closer than 1fs
* (from rounding), otherwise ngspice aborts with "Timestep too small"
.OPTION minbreak=1e-15
.TRAN 1p 'stopsim' uic

.inc measure_delay.sp

.SAVE
+    V(IN)
+    V(OUT)
+    V(MUX<14>)
+    V(MUX<13>)
+    V(MUX<12>)
+    V(MUX<11>)
+    V(MUX<10>)
+    V(MUX<9>)
+    V(MUX<8>)
+    V(MUX<7>)
+    V(MUX<6>)
+    V(MUX<5>)
+    V(MUX<4>)
+    V(MUX<3>)
+    V(MUX<2>)
+    V(MUX<1>)
+    V(MUX<0>)

* Run and save the waveforms (.meas results are printed in the log)
.control
run
write test_coarse_delay.raw
quit
.endc
