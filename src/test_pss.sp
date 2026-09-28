.title ringosc
.subckt inv in out vdd 
mn1 out in 0 0 nmos l=0.25u w=2u
mp1 out in vdd vdd pmos l=0.25u w=6u
.ends

vdd vdd 0 3
x1 1 2 vdd inv
x2 2 3 vdd inv
x3 3 4 vdd inv
x4 4 5 vdd inv
x5 5 6 vdd inv
x6 6 7 vdd inv
x7 7 1 vdd inv
c1 1 0 0.022p


.lib 'tsmc018.m' tt

.ic v(1)=3

.options post
.option measdgt=10

.snosc tones=1.7e9 nharms=10 oscnode=1 trinit=10n
.phasenoise v(7) dec 10 100 10meg listfreq=(all) listcount=5 listsources=on 
.probe phasenoise phnoise v(7)
.print phasenoise phnoise v(7)

.probe sn v(1) 
.probe snfd v(1) v(7)

* Measurement
.measure snfd freqsnfd1 find 'HERTZ[1]' at=0.01p

.end
