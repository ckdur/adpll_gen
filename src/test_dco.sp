* PLL test

.TEMP 25
.OPTION
+    ARTIST=2
+    INGOLD=2
+    PARHIER=LOCAL
+    PSF=2
+    PROBE
+    POST=2
.PARAM Rdigload=1M
.PARAM Cdigload=2e-15
.PARAM fclk=100000000

* Declare the times in this manner. This is SPICE compatible
.PARAM tclk1=(1/(2*fclk))
.PARAM tclk2=(1/fclk)
.PARAM stopsim=(10000n)

* Include the models
.inc lib.sp

* Include the actual netlist
.inc PLL_ILDCO.sp

vvdd VDD GND DC=lvdd
vgnd GND 0 DC=0

* To avoid warnings when simulating
vpoc POC 0 DC=0
vtacvdd TACVDD 0 DC=0
vtavdd TAVDD 0 DC=0
vvddpst VDDPST 0 DC=0
vvss VSS 0 DC=0

Vfine<30> fine<30> GND DC=0.0
Vfine<29> fine<29> GND DC=0.0
Vfine<28> fine<28> GND DC=0.0
Vfine<27> fine<27> GND DC=0.0
Vfine<26> fine<26> GND DC=0.0
Vfine<25> fine<25> GND DC=0.0
Vfine<24> fine<24> GND DC=0.0
Vfine<23> fine<23> GND DC=0.0
Vfine<22> fine<22> GND DC=0.0
Vfine<21> fine<21> GND DC=0.0
Vfine<20> fine<20> GND DC=0.0
Vfine<19> fine<19> GND DC=0.0
Vfine<18> fine<18> GND DC=0.0
Vfine<17> fine<17> GND DC=0.0
Vfine<16> fine<16> GND DC=0.0
Vfine<15> fine<15> GND DC=0.0
Vfine<14> fine<14> GND DC=0.0
Vfine<13> fine<13> GND DC=0.0
Vfine<12> fine<12> GND DC=0.0
Vfine<11> fine<11> GND DC=0.0
Vfine<10> fine<10> GND DC=0.0
Vfine<9> fine<9> GND DC=0.0
Vfine<8> fine<8> GND DC=0.0
Vfine<7> fine<7> GND DC=lvdd
Vfine<6> fine<6> GND DC=lvdd
Vfine<5> fine<5> GND DC=lvdd
Vfine<4> fine<4> GND DC=lvdd
Vfine<3> fine<3> GND DC=lvdd
Vfine<2> fine<2> GND DC=lvdd
Vfine<1> fine<1> GND DC=lvdd
Vfine<0> fine<0> GND DC=lvdd

Vmid<14> mid<14> GND DC=0.0
Vmid<13> mid<13> GND DC=0.0
Vmid<12> mid<12> GND DC=0.0
Vmid<11> mid<11> GND DC=0.0
Vmid<10> mid<10> GND DC=0.0
Vmid<9> mid<9> GND DC=0.0
Vmid<8> mid<8> GND DC=0.0
Vmid<7> mid<7> GND DC=lvdd
Vmid<6> mid<6> GND DC=lvdd
Vmid<5> mid<5> GND DC=lvdd
Vmid<4> mid<4> GND DC=lvdd
Vmid<3> mid<3> GND DC=lvdd
Vmid<2> mid<2> GND DC=lvdd
Vmid<1> mid<1> GND DC=lvdd
Vmid<0> mid<0> GND DC=lvdd

Vcoarse<14> coarse<14> GND DC=0.0
Vcoarse<13> coarse<13> GND DC=0.0
Vcoarse<12> coarse<12> GND DC=0.0
Vcoarse<11> coarse<11> GND DC=0.0
Vcoarse<10> coarse<10> GND DC=0.0
Vcoarse<9> coarse<9> GND DC=0.0
Vcoarse<8> coarse<8> GND DC=0.0
Vcoarse<7> coarse<7> GND DC=lvdd
Vcoarse<6> coarse<6> GND DC=lvdd
Vcoarse<5> coarse<5> GND DC=lvdd
Vcoarse<4> coarse<4> GND DC=lvdd
Vcoarse<3> coarse<3> GND DC=lvdd
Vcoarse<2> coarse<2> GND DC=lvdd
Vcoarse<1> coarse<1> GND DC=lvdd
Vcoarse<0> coarse<0> GND DC=lvdd

Vinj_edge inj_edge GND DC=0.0
Vinj_win inj_win GND DC=0.0
Vdco_en dco_en GND DC=lvdd

* The DCO
xdco VDD GND
+ coarse<14> coarse<13> coarse<12> coarse<11> coarse<10> coarse<9> coarse<8> coarse<7> coarse<6> coarse<5> coarse<4> coarse<3> coarse<2> coarse<1> coarse<0>
+ mid<14> mid<13> mid<12> mid<11> mid<10> mid<9> mid<8> mid<7> mid<6> mid<5> mid<4> mid<3> mid<2> mid<1> mid<0>
+ fine<30> fine<29> fine<28> fine<27> fine<26> fine<25> fine<24> fine<23> fine<22> fine<21> fine<20> fine<19> fine<18> fine<17> fine<16> fine<15>
+ fine<14> fine<13> fine<12> fine<11> fine<10> fine<9> fine<8> fine<7> fine<6> fine<5> fine<4> fine<3> fine<2> fine<1> fine<0>
+ inj_edge inj_win dco_en
+ SS_BBPD<1> SS_BBPD<0> OUT MID_OUT PLL_ILDCO

* Just for the load
xloadssbbpd0 VDD GND SS_BBPD<0> SS_BBPD_L<0> PLL_CELL_BUFFX0
xloadssbbpd1 VDD GND SS_BBPD<1> SS_BBPD_L<1> PLL_CELL_BUFFX0
xloadmidout VDD GND MID_OUT MID_OUT_L PLL_CELL_BUFFX0
xloadout VDD GND OUT OUT_L PLL_CELL_BUFFX0
cloadssbbpd0 SS_BBPD_L<0> GND Cdigload
cloadssbbpd1 SS_BBPD_L<1> GND Cdigload
cloadmidout MID_OUT_L GND Cdigload
cloadout OUT_L GND Cdigload
