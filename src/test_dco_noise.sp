* Spice stub test_dco for phase noise analysis

* IMPORTANT NOTE
* Run "make test_dco" for getting the tone and the phase stabilization time

.inc test_dco.sp

.ic V(OUT)=1.2
.options post
.option measdgt=10

* According to the manual (primesim_hspice_aasa.pdf, PrimeSimTM HSPICE® User Guide: Advanced Analog Simulation and Analysis)
* For ring oscillators
* - Set up .HBOSC without FSPTS .
* - Choose one of the nodes in the ring as the PROBENODE .
* - Recommendation: Since ring oscillators tend to have square-wave-like output signals
*   which have significant high frequency content, use a relatively large value, perhaps 50,
*   for nharms . Ring oscillators with more stages tend to need more harmonics.
* - Set HBTRANINIT to a value that represents ~5-10 oscillator periods. Ensure that
*   you include an .ic command or other transient analysis setup to start the oscillator
*   in transient simulation. Longer HBTRANINIT times may result in faster HBOSC
*   convergence, at the expense of additional CPU time spent on HBTRANINIT .

* USING HB
.option HBTRANINIT=7.112n HBTRANSTEP=1p

* Phase noise analysis
*.HBOSC TONE=1124859392.5756907 NHARMS=50
*+ PROBENODE=OUT,GND,0.6

*.PHASENOISE V(OUT,GND) DEC 10 100 1000M
*+ METHOD=0 CARRIERINDEX=1 $use NLP algorithm
*+ listsources=on

*.PROBE PHASENOISE phnoise
*.PRINT PHASENOISE phnoise(X1)

* USING SB
.SNOSC TONES=1124859392.5756907 NHARMS=10
+ OSCNODE=OUT TRINIT=7.112n

.PHASENOISE V(OUT) DEC 10 100 1000e6
.PRINT PHASENOISE phnoise V(OUT)
.PROBE PHASENOISE phnoise V(OUT)

.PROBE SN V(OUT)
.PROBE SNFD V(OUT)

.measure snfd freqsnfd1 find 'HERTZ[1]' at=0.01p
