* This is a declaration about how to instantiate the pll
* The instantiation can change if you are doing rcx or normal simulations
* supply the correct order of nets and name them as this file

xpll VDD GND REF RST_N INJ_EN KP<15> KP<14> KP<13> KP<12> KP<11> KP<10> KP<9> 
+ KP<8> KP<7> KP<6> KP<5> KP<4> KP<3> KP<2> KP<1> KP<0> KI<15> KI<14> KI<13> 
+ KI<12> KI<11> KI<10> KI<9> KI<8> KI<7> KI<6> KI<5> KI<4> KI<3> KI<2> KI<1> 
+ KI<0> FCW<7> FCW<6> FCW<5> FCW<4> FCW<3> FCW<2> FCW<1> FCW<0>
+ DSM_EN_DT DSM_EN_SHDT DSM_ORDER<1> DSM_ORDER<0>
+ SET_DIV<7> SET_DIV<6> SET_DIV<5> SET_DIV<4> SET_DIV<3> SET_DIV<2> SET_DIV<1> SET_DIV<0> LOAD_DIV OUT_DIV
+ LOCKED ERR OUT pll
