* PLL test

.TEMP 25
.PARAM Rdigload=1M
.PARAM Cdigload=2e-15
.PARAM fclk=100000000

* Declare the times in this manner. This is SPICE compatible
.PARAM tclk1=(1/(2*fclk))
.PARAM tclk2=(1/fclk)
.PARAM stopsim=(10000n)

* Include the models
.inc models.inc

* Include the actual netlist
.inc pll.sp

vvdd VDD GND DC=lvdd
Vin REF 0 PULSE lvdd 0 0 0.05n 0.05n 'tclk1' 'tclk2'
VRST_N RST_N 0 PULSE lvdd 0 0 0.05n 0.05n 'tclk1' 'stopsim'

* Injection state
Vinj_en INJ_EN 0 DC=0

* DSM options
Vdsm_en_dt DSM_EN_DT 0 DC=0
Vdsm_en_shdt DSM_EN_SHDT 0 DC=lvdd
Vdsm_order_1 DSM_ORDER<1> 0 DC=0
Vdsm_order_0 DSM_ORDER<0> 0 DC=0

* KI = 'd257
VKI<15> KI<15> GND DC=0.0
VKI<14> KI<14> GND DC=0.0
VKI<13> KI<13> GND DC=0.0
VKI<12> KI<12> GND DC=0.0
VKI<11> KI<11> GND DC=0.0
VKI<10> KI<10> GND DC=0.0
VKI<9> KI<9> GND DC=0.0
VKI<8> KI<8> GND DC=lvdd
VKI<7> KI<7> GND DC=0.0
VKI<6> KI<6> GND DC=0.0
VKI<5> KI<5> GND DC=0.0
VKI<4> KI<4> GND DC=0.0
VKI<3> KI<3> GND DC=0.0
VKI<2> KI<2> GND DC=0.0
VKI<1> KI<1> GND DC=0.0
VKI<0> KI<0> GND DC=lvdd
* KP = 'd3967
VKP<15> KP<15> GND DC=0.0
VKP<14> KP<14> GND DC=0.0
VKP<13> KP<13> GND DC=0.0
VKP<12> KP<12> GND DC=0.0
VKP<11> KP<11> GND DC=lvdd
VKP<10> KP<10> GND DC=lvdd
VKP<9> KP<9> GND DC=lvdd
VKP<8> KP<8> GND DC=lvdd
VKP<7> KP<7> GND DC=0.0
VKP<6> KP<6> GND DC=lvdd
VKP<5> KP<5> GND DC=lvdd
VKP<4> KP<4> GND DC=lvdd
VKP<3> KP<3> GND DC=lvdd
VKP<2> KP<2> GND DC=lvdd
VKP<1> KP<1> GND DC=lvdd
VKP<0> KP<0> GND DC=lvdd
* FCW = 'd8
VFCW<7> FCW<7> GND DC=0.0
VFCW<6> FCW<6> GND DC=0.0
VFCW<5> FCW<5> GND DC=0.0
VFCW<4> FCW<4> GND DC=0.0
VFCW<3> FCW<3> GND DC=lvdd
VFCW<2> FCW<2> GND DC=0.0
VFCW<1> FCW<1> GND DC=0.0
VFCW<0> FCW<0> GND DC=0.0
* DIV = 'd14
VSET_DIV<7> SET_DIV<7> GND DC=0.0
VSET_DIV<6> SET_DIV<6> GND DC=0.0
VSET_DIV<5> SET_DIV<5> GND DC=0.0
VSET_DIV<4> SET_DIV<4> GND DC=0.0
VSET_DIV<3> SET_DIV<3> GND DC=lvdd
VSET_DIV<2> SET_DIV<2> GND DC=lvdd
VSET_DIV<1> SET_DIV<1> GND DC=lvdd
VSET_DIV<0> SET_DIV<0> GND DC=0.0
VLOAD_DIV LOAD_DIV GND DC=lvdd

* BEHOLD! THE INSTANCE
.inc pll_inst_declr.sp

* Just for the load
xloadlocked VDD GND LOCKED LOCKED_L PLL_CELL_BUFFX0
xloaderr VDD GND ERR ERR_L PLL_CELL_BUFFX0
xloadout VDD GND OUT OUT_L PLL_CELL_BUFFX0
xloadoutdiv VDD GND OUT_DIV OUT_DIV_L PLL_CELL_BUFFX0
cloadlocked LOCKED_L GND 'Cdigload'
cloaderr ERR_L GND 'Cdigload'
cloadout OUT_L GND 'Cdigload'
cloadoutdiv OUT_DIV_L GND 'Cdigload'

