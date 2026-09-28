* FINE DELAY test

.TEMP 25
.OPTION
+    ARTIST=2
+    INGOLD=2
+    PARHIER=LOCAL
+    PSF=2
+    PROBE
.PARAM Rdigload=1M
.PARAM Cdigload=2e-15
.PARAM tsw=2000e-9
.PARAM stopsim=(32*tsw)

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
.PARAM tsw16=(16*tsw)
.PARAM tsw17=(17*tsw)
.PARAM tsw18=(18*tsw)
.PARAM tsw19=(19*tsw)
.PARAM tsw20=(20*tsw)
.PARAM tsw21=(21*tsw)
.PARAM tsw22=(22*tsw)
.PARAM tsw23=(23*tsw)
.PARAM tsw24=(24*tsw)
.PARAM tsw25=(25*tsw)
.PARAM tsw26=(26*tsw)
.PARAM tsw27=(27*tsw)
.PARAM tsw28=(28*tsw)
.PARAM tsw29=(29*tsw)
.PARAM tsw30=(30*tsw)
.PARAM tsw31=(31*tsw)
.PARAM tclk1=(0.05*tsw)
.PARAM tclk2=(0.10*tsw)

* Include the models
.inc lib.sp

* Include the actual netlist
.inc FINE_DELAY.sp

vvdd VDD GND DC=lvdd
vgnd GND 0 DC=0
Vm0 MUX<0> 0 PULSE lvdd 0 0 0.05n 0.05n (tsw1) (stopsim)
Vm1 MUX<1> 0 PULSE lvdd 0 0 0.05n 0.05n (tsw2) (stopsim)
Vm2 MUX<2> 0 PULSE lvdd 0 0 0.05n 0.05n (tsw3) (stopsim)
Vm3 MUX<3> 0 PULSE lvdd 0 0 0.05n 0.05n (tsw4) (stopsim)
Vm4 MUX<4> 0 PULSE lvdd 0 0 0.05n 0.05n (tsw5) (stopsim)
Vm5 MUX<5> 0 PULSE lvdd 0 0 0.05n 0.05n (tsw6) (stopsim)
Vm6 MUX<6> 0 PULSE lvdd 0 0 0.05n 0.05n (tsw7) (stopsim)
Vm7 MUX<7> 0 PULSE lvdd 0 0 0.05n 0.05n (tsw8) (stopsim)
Vm8 MUX<8> 0 PULSE lvdd 0 0 0.05n 0.05n (tsw9) (stopsim)
Vm9 MUX<9> 0 PULSE lvdd 0 0 0.05n 0.05n (tsw10) (stopsim)
Vm10 MUX<10> 0 PULSE lvdd 0 0 0.05n 0.05n (tsw11) (stopsim)
Vm11 MUX<11> 0 PULSE lvdd 0 0 0.05n 0.05n (tsw12) (stopsim)
Vm12 MUX<12> 0 PULSE lvdd 0 0 0.05n 0.05n (tsw13) (stopsim)
Vm13 MUX<13> 0 PULSE lvdd 0 0 0.05n 0.05n (tsw14) (stopsim)
Vm15 MUX<14> 0 PULSE lvdd 0 0 0.05n 0.05n (tsw15) (stopsim)
Vm16 MUX<15> 0 PULSE lvdd 0 0 0.05n 0.05n (tsw16) (stopsim)
Vm17 MUX<16> 0 PULSE lvdd 0 0 0.05n 0.05n (tsw17) (stopsim)
Vm18 MUX<17> 0 PULSE lvdd 0 0 0.05n 0.05n (tsw18) (stopsim)
Vm19 MUX<18> 0 PULSE lvdd 0 0 0.05n 0.05n (tsw19) (stopsim)
Vm20 MUX<19> 0 PULSE lvdd 0 0 0.05n 0.05n (tsw20) (stopsim)
Vm21 MUX<20> 0 PULSE lvdd 0 0 0.05n 0.05n (tsw21) (stopsim)
Vm22 MUX<21> 0 PULSE lvdd 0 0 0.05n 0.05n (tsw22) (stopsim)
Vm23 MUX<22> 0 PULSE lvdd 0 0 0.05n 0.05n (tsw23) (stopsim)
Vm24 MUX<23> 0 PULSE lvdd 0 0 0.05n 0.05n (tsw24) (stopsim)
Vm25 MUX<24> 0 PULSE lvdd 0 0 0.05n 0.05n (tsw25) (stopsim)
Vm26 MUX<25> 0 PULSE lvdd 0 0 0.05n 0.05n (tsw26) (stopsim)
Vm27 MUX<26> 0 PULSE lvdd 0 0 0.05n 0.05n (tsw27) (stopsim)
Vm28 MUX<27> 0 PULSE lvdd 0 0 0.05n 0.05n (tsw28) (stopsim)
Vm29 MUX<28> 0 PULSE lvdd 0 0 0.05n 0.05n (tsw29) (stopsim)
Vm30 MUX<29> 0 PULSE lvdd 0 0 0.05n 0.05n (tsw30) (stopsim)
Vm31 MUX<30> 0 PULSE lvdd 0 0 0.05n 0.05n (tsw31) (stopsim)
Vin IN 0 PULSE lvdd 0 0 0.05n 0.05n (tclk1) (tclk2)

* The actual implementation

xtest VDD GND
+ MUX<30>
+ MUX<29> MUX<28> MUX<27> MUX<26> MUX<25> MUX<24> MUX<23> MUX<22> MUX<21> MUX<20>
+ MUX<19> MUX<18> MUX<17> MUX<16> MUX<15> MUX<14> MUX<13> MUX<12> MUX<11> MUX<10>
+ MUX<9> MUX<8> MUX<7> MUX<6> MUX<5> MUX<4> MUX<3> MUX<2> MUX<1> MUX<0>
+ IN OUT FINE_DELAY
* Just for the load
xtestload VDD GND 
+ MUX<30>
+ MUX<29> MUX<28> MUX<27> MUX<26> MUX<25> MUX<24> MUX<23> MUX<22> MUX<21> MUX<20>
+ MUX<19> MUX<18> MUX<17> MUX<16> MUX<15> MUX<14> MUX<13> MUX<12> MUX<11> MUX<10>
+ MUX<9> MUX<8> MUX<7> MUX<6> MUX<5> MUX<4> MUX<3> MUX<2> MUX<1> MUX<0>
+ OUT OUT2 FINE_DELAY
cloadload OUT2 gnd Cdigload

* Analysis and measurement
.TRAN 1n stopsim uic

.inc measure_delay.sp

.PROBE
+    V(IN)
+    V(OUT)
+    V(FINE_DELAY)
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
