# Delay characterization tests
test_fine_delay: $(SIM_DIR)/outputs/test_fine_delay.raw

$(SIM_DIR)/outputs/test_fine_delay.raw: $(SIM_DIR)/outputs/FINE_DELAY.sp $(SRC_DIR)/test_fine_delay.sp $(SRC_DIR)/measure_delay.sp $(SIM_DIR)/outputs/models.inc $(SIM_DIR)/outputs/.spiceinit
	cp $(SRC_DIR)/test_fine_delay.sp $(SIM_DIR)/outputs/test_fine_delay.sp
	cp $(SRC_DIR)/measure_delay.sp $(SIM_DIR)/outputs/measure_delay.sp
	cd $(SIM_DIR)/outputs && $(NGSPICE) -o test_fine_delay.log test_fine_delay.sp < /dev/null

view_test_fine_delay: $(SIM_DIR)/outputs/test_fine_delay.raw
	$(WAVEVIEW) $(SIM_DIR)/outputs/test_fine_delay.raw

test_mid_delay: $(SIM_DIR)/outputs/test_mid_delay.raw

$(SIM_DIR)/outputs/test_mid_delay.raw: $(SIM_DIR)/outputs/MID_DELAY.sp $(SRC_DIR)/test_mid_delay.sp $(SRC_DIR)/measure_delay.sp $(SIM_DIR)/outputs/models.inc $(SIM_DIR)/outputs/.spiceinit
	cp $(SRC_DIR)/test_mid_delay.sp $(SIM_DIR)/outputs/test_mid_delay.sp
	cp $(SRC_DIR)/measure_delay.sp $(SIM_DIR)/outputs/measure_delay.sp
	cd $(SIM_DIR)/outputs && $(NGSPICE) -o test_mid_delay.log test_mid_delay.sp < /dev/null

view_test_mid_delay: $(SIM_DIR)/outputs/test_mid_delay.raw
	$(WAVEVIEW) $(SIM_DIR)/outputs/test_mid_delay.raw

test_coarse_delay: $(SIM_DIR)/outputs/test_coarse_delay.raw

$(SIM_DIR)/outputs/test_coarse_delay.raw: $(SIM_DIR)/outputs/COARSE_DELAY.sp $(SRC_DIR)/test_coarse_delay.sp $(SRC_DIR)/measure_delay.sp $(SIM_DIR)/outputs/models.inc $(SIM_DIR)/outputs/.spiceinit
	cp $(SRC_DIR)/test_coarse_delay.sp $(SIM_DIR)/outputs/test_coarse_delay.sp
	cp $(SRC_DIR)/measure_delay.sp $(SIM_DIR)/outputs/measure_delay.sp
	cd $(SIM_DIR)/outputs && $(NGSPICE) -o test_coarse_delay.log test_coarse_delay.sp < /dev/null

view_test_coarse_delay: $(SIM_DIR)/outputs/test_coarse_delay.raw
	$(WAVEVIEW) $(SIM_DIR)/outputs/test_coarse_delay.raw

# Delay characterization tests... but in digital (using sdf files)
test_fine_delay_digital: $(SIM_DIR)/outputs/test_fine_delay.vcd

$(SIM_DIR)/outputs/test_fine_delay.vcd: $(SYN_DIR)/outputs/FINE_DELAY_net.v $(SRC_DIR)/test_fine_delay.v $(SRC_DIR)/measure_delay.v $(SRC_DIR)/sim_mux.v $(CELLS_SRC)
	mkdir -p $(SIM_DIR)/outputs
	cp $(SYN_DIR)/outputs/FINE_DELAY.sdf $(SIM_DIR)/outputs/FINE_DELAY.sdf
	cp $(SYN_DIR)/outputs/FINE_DELAY_net.v $(SIM_DIR)/outputs/FINE_DELAY_net.v
	cp $(SRC_DIR)/measure_delay.v $(SIM_DIR)/outputs/measure_delay.v
	cd $(SIM_DIR)/outputs && $(IVERILOG) -ginterconnect -gspecify -T max -o a.out -D SIMULATION=1 $(CELLS_ADD_DEF) $(SRC_DIR)/test_fine_delay.v $(SRC_DIR)/sim_mux.v $(CELLS_SRC) && $(VVP) a.out

view_test_fine_delay_digital: $(SIM_DIR)/outputs/test_fine_delay.vcd
	gtkwave $(SIM_DIR)/outputs/test_fine_delay.vcd

test_mid_delay_digital: $(SIM_DIR)/outputs/test_mid_delay.vcd

$(SIM_DIR)/outputs/test_mid_delay.vcd: $(SYN_DIR)/outputs/MID_DELAY_net.v $(SRC_DIR)/test_mid_delay.v $(SRC_DIR)/measure_delay.v $(SRC_DIR)/sim_mux.v $(CELLS_SRC)
	mkdir -p $(SIM_DIR)/outputs
	cp $(SYN_DIR)/outputs/MID_DELAY.sdf $(SIM_DIR)/outputs/MID_DELAY.sdf
	cp $(SYN_DIR)/outputs/MID_DELAY_net.v $(SIM_DIR)/outputs/MID_DELAY_net.v
	cp $(SRC_DIR)/measure_delay.v $(SIM_DIR)/outputs/measure_delay.v
	cd $(SIM_DIR)/outputs && $(IVERILOG) -ginterconnect -gspecify -T max -o a.out -D SIMULATION=1 $(CELLS_ADD_DEF) $(SRC_DIR)/test_mid_delay.v $(SRC_DIR)/sim_mux.v $(CELLS_SRC) && $(VVP) a.out

view_test_mid_delay_digital: $(SIM_DIR)/outputs/test_mid_delay.vcd
	gtkwave $(SIM_DIR)/outputs/test_mid_delay.vcd

test_coarse_delay_digital: $(SIM_DIR)/outputs/test_coarse_delay.vcd

$(SIM_DIR)/outputs/test_coarse_delay.vcd: $(SYN_DIR)/outputs/COARSE_DELAY_net.v $(SRC_DIR)/test_coarse_delay.v $(SRC_DIR)/measure_delay.v $(CELLS_SRC)
	mkdir -p $(SIM_DIR)/outputs
	cp $(SYN_DIR)/outputs/COARSE_DELAY.sdf $(SIM_DIR)/outputs/COARSE_DELAY.sdf
	cp $(SYN_DIR)/outputs/COARSE_DELAY_net.v $(SIM_DIR)/outputs/COARSE_DELAY_net.v
	cp $(SRC_DIR)/measure_delay.v $(SIM_DIR)/outputs/measure_delay.v
	cd $(SIM_DIR)/outputs && $(IVERILOG) -ginterconnect -gspecify -T max -o a.out -D SIMULATION=1 $(CELLS_ADD_DEF) $(SRC_DIR)/test_coarse_delay.v $(CELLS_SRC) && $(VVP) a.out

view_test_coarse_delay_digital: $(SIM_DIR)/outputs/test_coarse_delay.vcd
	gtkwave $(SIM_DIR)/outputs/test_coarse_delay.vcd

# PLL injection test
test_pll_injection: $(SIM_DIR)/outputs/test_pll_injection.raw

$(SIM_DIR)/outputs/test_pll_injection.raw: $(SIM_DIR)/outputs/PLL_INJECTION.sp $(SRC_DIR)/test_pll_injection.sp $(SIM_DIR)/outputs/models.inc $(SIM_DIR)/outputs/.spiceinit
	cp $(SRC_DIR)/test_pll_injection.sp $(SIM_DIR)/outputs/test_pll_injection.sp
	cd $(SIM_DIR)/outputs && $(NGSPICE) -o test_pll_injection.log test_pll_injection.sp < /dev/null

view_test_pll_injection: $(SIM_DIR)/outputs/test_pll_injection.raw
	$(WAVEVIEW) $(SIM_DIR)/outputs/test_pll_injection.raw

# Symmetrical circuit delay test
test_sym_delay: $(SIM_DIR)/outputs/test_sym_delay.raw

$(SIM_DIR)/outputs/test_sym_delay.raw: $(SIM_DIR)/outputs/PLL_SYM.sp $(SRC_DIR)/test_sym_delay.sp $(SIM_DIR)/outputs/models.inc $(SIM_DIR)/outputs/.spiceinit
	cp $(SRC_DIR)/test_sym_delay.sp $(SIM_DIR)/outputs/test_sym_delay.sp
	cd $(SIM_DIR)/outputs && $(NGSPICE) -o test_sym_delay.log test_sym_delay.sp < /dev/null

view_test_sym_delay: $(SIM_DIR)/outputs/test_sym_delay.raw
	$(WAVEVIEW) $(SIM_DIR)/outputs/test_sym_delay.raw

# DCO phase noise test
test_dco: $(SIM_DIR)/outputs/test_dco_tran.raw
	$(PYTHON) $(SRC_DIR)/test_dco_get_stable_time.py $(SIM_DIR)/outputs/test_dco_tran.raw

$(SIM_DIR)/outputs/test_dco_tran.raw: $(SIM_DIR)/outputs/PLL_ILDCO.sp $(SRC_DIR)/test_dco.sp $(SRC_DIR)/test_dco_tran.sp $(SIM_DIR)/outputs/models.inc $(SIM_DIR)/outputs/.spiceinit
	cp $(SRC_DIR)/test_dco.sp $(SIM_DIR)/outputs/test_dco.sp
	cp $(SRC_DIR)/test_dco_tran.sp $(SIM_DIR)/outputs/test_dco_tran.sp
	cd $(SIM_DIR)/outputs && $(NGSPICE) -o test_dco_tran.log test_dco_tran.sp < /dev/null

view_test_dco: $(SIM_DIR)/outputs/test_dco_tran.raw
	$(WAVEVIEW) $(SIM_DIR)/outputs/test_dco_tran.raw

# NOTE: This one still needs HSPICE. ngspice has no oscillator phase-noise analysis (.SNOSC/.PHASENOISE)
test_dco_noise: $(SIM_DIR)/outputs/test_dco_noise.snpn0

view_test_dco_noise: $(SIM_DIR)/outputs/test_dco_noise.snpn0
	wv $(SIM_DIR)/outputs/test_dco_noise.snpn0

$(SIM_DIR)/outputs/test_dco_noise.snpn0: $(SIM_DIR)/outputs/PLL_ILDCO.sp $(SRC_DIR)/test_dco.sp $(SRC_DIR)/test_dco_noise.sp $(SIM_DIR)/outputs/models.inc $(SIM_DIR)/outputs/.spiceinit
	cp $(SRC_DIR)/test_dco.sp $(SIM_DIR)/outputs/test_dco.sp
	cp $(SRC_DIR)/test_dco_noise.sp $(SIM_DIR)/outputs/test_dco_noise.sp
	cd $(SIM_DIR)/outputs && $(HSPICE) test_dco_noise.sp

# A single test for ngspice .pss simulations
test_pss: $(SIM_DIR)/outputs/test_pss.snpn0

view_test_pss: $(SIM_DIR)/outputs/test_pss.snpn0
	$(WAVEVIEW) $(SIM_DIR)/outputs/test_pss.snpn0

$(SIM_DIR)/outputs/test_pss.snpn0: $(SRC_DIR)/test_pss.sp $(SRC_DIR)/tsmc018.m 
	cp $(SRC_DIR)/test_pss.sp $(SIM_DIR)/outputs/test_pss.sp
	cp $(SRC_DIR)/tsmc018.m $(SIM_DIR)/outputs/tsmc018.m
	cd $(SIM_DIR)/outputs && $(NGSPICE) -o test_pss.log test_pss.sp < /dev/null

# Main PLL test
test_pll: $(SIM_DIR)/outputs/test_pll_tran.raw

$(SIM_DIR)/outputs/test_pll_tran.raw: $(SIM_DIR)/outputs/pll.sp $(SRC_DIR)/test_pll_tran.sp $(SRC_DIR)/pll_inst_declr.sp $(SRC_DIR)/test_pll.sp $(SIM_DIR)/outputs/models.inc $(SIM_DIR)/outputs/.spiceinit
	cp $(SRC_DIR)/test_pll.sp $(SIM_DIR)/outputs/test_pll.sp
	cp $(SRC_DIR)/test_pll_tran.sp $(SIM_DIR)/outputs/test_pll_tran.sp
	cp $(SRC_DIR)/pll_inst_declr.sp $(SIM_DIR)/outputs/pll_inst_declr.sp
	cd $(SIM_DIR)/outputs && $(NGSPICE) -o test_pll_tran.log test_pll_tran.sp < /dev/null

view_test_pll: $(SIM_DIR)/outputs/test_pll_tran.raw
	$(WAVEVIEW) $(SIM_DIR)/outputs/test_pll_tran.raw

test_pll_noise: $(SIM_DIR)/outputs/test_pll_noise.raw $(SRC_DIR)/test_pll_plot_phase_noise.py
	$(PYTHON) $(SRC_DIR)/test_pll_plot_phase_noise.py $(SIM_DIR)/outputs/test_pll_noise.raw

view_test_pll_noise: $(SIM_DIR)/outputs/test_pll_noise.raw $(SRC_DIR)/test_pll_plot_phase_noise.py
	$(WAVEVIEW) $(SIM_DIR)/outputs/test_pll_noise.raw

$(SIM_DIR)/outputs/test_pll_noise.raw: $(SIM_DIR)/outputs/pll.sp $(SRC_DIR)/test_pll_noise.sp $(SRC_DIR)/pll_inst_declr.sp $(SRC_DIR)/test_pll.sp $(SIM_DIR)/outputs/models.inc $(SIM_DIR)/outputs/.spiceinit
	cp $(SRC_DIR)/test_pll.sp $(SIM_DIR)/outputs/test_pll.sp
	cp $(SRC_DIR)/test_pll_noise.sp $(SIM_DIR)/outputs/test_pll_noise.sp
	cp $(SRC_DIR)/pll_inst_declr.sp $(SIM_DIR)/outputs/pll_inst_declr.sp
	cd $(SIM_DIR)/outputs && $(NGSPICE) -o test_pll_noise.log test_pll_noise.sp < /dev/null

test_pll_rcx: $(PRJ_DIR)/ver/rcx/rundir/xrc_lay.dist.sp $(PRJ_DIR)/ver/rcx/rundir/xrc_lay.dist.sp.pll.pxi $(PRJ_DIR)/src/pll_inst_declr_xrc.sp $(SRC_DIR)/test_pll.sp $(SIM_DIR)/outputs/models.inc $(SIM_DIR)/outputs/.spiceinit
	cp $(PRJ_DIR)/ver/rcx/rundir/xrc_lay.dist.sp $(SIM_DIR)/outputs/pll.sp
	cp $(PRJ_DIR)/ver/rcx/rundir/xrc_lay.dist.sp.pll.pxi $(SIM_DIR)/outputs/xrc_lay.dist.sp.pll.pxi
	cp $(PRJ_DIR)/src/pll_inst_declr_xrc.sp $(SIM_DIR)/outputs/pll_inst_declr.sp
	cp $(SRC_DIR)/test_pll.sp $(SIM_DIR)/outputs/test_pll_rcx.sp
	cd $(SIM_DIR)/outputs && $(NGSPICE) -o test_pll_rcx.log test_pll_rcx.sp < /dev/null

view_test_pll_rcx:
	$(WAVEVIEW) $(SIM_DIR)/outputs/test_pll_rcx.raw

# Frequency locking RTL simulation
test_freq_lock: $(SIM_DIR)/outputs/freq_lock_tb.vcd

view_test_freq_lock: $(SIM_DIR)/outputs/freq_lock_tb.vcd
	gtkwave $(SIM_DIR)/outputs/freq_lock_tb.vcd

$(SIM_DIR)/outputs/freq_lock_tb.vcd: $(SRC_DIR)/freq_lock.v $(SRC_DIR)/freq_lock_tb.v $(SIM_DIR)/outputs/sim_dco.v
	mkdir -p $(SIM_DIR)/outputs
	cd $(SIM_DIR)/outputs && $(IVERILOG) -ginterconnect -gspecify -T max -o a.out -D SIMULATION=1 $^ && $(VVP) a.out

# Digital loop filter RTL simulation
test_dlf: $(SIM_DIR)/outputs/digital_loop_filter_tb.vcd

view_test_dlf: $(SIM_DIR)/outputs/digital_loop_filter_tb.vcd
	gtkwave $(SIM_DIR)/outputs/digital_loop_filter_tb.vcd

$(SIM_DIR)/outputs/digital_loop_filter_tb.vcd: $(SRC_DIR)/digital_loop_filter.v $(SRC_DIR)/digital_loop_filter_tb.v $(SIM_DIR)/outputs/sim_dco.v $(SRC_DIR)/sim_SSBBPD.v
	mkdir -p $(SIM_DIR)/outputs
	cd $(SIM_DIR)/outputs && $(IVERILOG) -ginterconnect -gspecify -T max -o a.out -D SIMULATION=1 $^ && $(VVP) a.out

# Termometer decoder RTL simulation
test_term_decoder: $(SIM_DIR)/outputs/term_decoder_tb.vcd

view_test_term_decoder: $(SIM_DIR)/outputs/term_decoder_tb.vcd
	gtkwave $(SIM_DIR)/outputs/term_decoder_tb.vcd

$(SIM_DIR)/outputs/term_decoder_tb.vcd: $(SRC_DIR)/term_decoder.v
	mkdir -p $(SIM_DIR)/outputs
	cd $(SIM_DIR)/outputs && $(IVERILOG) -ginterconnect -gspecify -T max -o a.out -D SIMULATION=1  $^ && $(VVP) a.out

# Delta-sigma modulator RTL simulation
test_delta_sigma: $(SIM_DIR)/outputs/delta_sigma_tb.vcd

view_test_delta_sigma: $(SIM_DIR)/outputs/delta_sigma_tb.vcd
	gtkwave $(SIM_DIR)/outputs/delta_sigma_tb.vcd

$(SIM_DIR)/outputs/delta_sigma_tb.vcd: $(SRC_DIR)/delta_sigma_tb.v $(SRC_DIR)/delta_sigma.v
	mkdir -p $(SIM_DIR)/outputs
	cd $(SIM_DIR)/outputs && $(IVERILOG) -ginterconnect -gspecify -T max -o a.out -D SIMULATION=1  $^ && $(VVP) a.out

# PLL fine test
test_pll_fine: $(SIM_DIR)/outputs/pll_fine_test.vcd

view_test_pll_fine: $(SIM_DIR)/outputs/pll_fine_test.vcd
	gtkwave $(SIM_DIR)/outputs/pll_fine_test.vcd

$(SIM_DIR)/outputs/pll_fine_test.vcd: $(SRC_DIR)/pll_fine_test.v $(SRC_DIR)/pll_analog.v $(SIM_DIR)/outputs/sim_injection.v $(SRC_DIR)/il_dco.v $(SIM_DIR)/outputs/sim_dco.v $(SIM_DIR)/outputs/sim_sym.v $(SRC_DIR)/sim_SSBBPD.v $(SRC_DIR)/digital_loop_filter.v $(SRC_DIR)/delta_sigma.v $(SRC_DIR)/term_decoder.v
	mkdir -p $(SIM_DIR)/outputs
	cd $(SIM_DIR)/outputs && $(IVERILOG) -ginterconnect -gspecify -T max -o a.out -D SIMULATION=1 $^ && $(VVP) a.out

# Main PLL RTL simulation (pre and post-synthesis)
test_pll_digital: $(SIM_DIR)/outputs/test_pll.vcd

view_test_pll_digital: $(SIM_DIR)/outputs/test_pll.vcd
	gtkwave $(SIM_DIR)/outputs/test_pll.vcd

$(SIM_DIR)/outputs/test_pll.vcd: $(SRC_DIR)/pll_test.v $(SRC_DIR)/pll.v $(SRC_DIR)/pll_logic.v $(SRC_DIR)/pll_analog.v $(SIM_DIR)/outputs/sim_injection.v $(SRC_DIR)/il_dco.v $(SIM_DIR)/outputs/sim_dco.v $(SIM_DIR)/outputs/sim_sym.v $(SRC_DIR)/sim_SSBBPD.v $(SRC_DIR)/digital_loop_filter.v $(SRC_DIR)/term_decoder.v $(SRC_DIR)/freq_lock.v $(SRC_DIR)/conf_div.v $(SRC_DIR)/fix_div.v
	mkdir -p $(SIM_DIR)/outputs
	cd $(SIM_DIR)/outputs && $(IVERILOG) -ginterconnect -gspecify -T max -o a.out -D SIMULATION=1 $^ && $(VVP) a.out

test_pll_digital_postsyn: $(SIM_DIR)/outputs/test_pll_postsyn.vcd

view_test_pll_digital_postsyn: $(SIM_DIR)/outputs/test_pll_postsyn.vcd
	gtkwave $(SIM_DIR)/outputs/test_pll_postsyn.vcd

$(SIM_DIR)/outputs/test_pll_postsyn.vcd: $(CELLS_SRC) $(SRC_DIR)/pll_test.v $(SRC_DIR)/pll.v $(SYN_DIR)/outputs/pll_logic_net.v $(SRC_DIR)/pll_analog.v $(SIM_DIR)/outputs/sim_injection.v $(SRC_DIR)/il_dco.v $(SIM_DIR)/outputs/sim_dco.v $(SIM_DIR)/outputs/sim_sym.v $(SRC_DIR)/sim_SSBBPD.v $(SRC_DIR)/conf_div.v
	mkdir -p $(SIM_DIR)/outputs
	cd $(SIM_DIR)/outputs && $(IVERILOG) -ginterconnect -gspecify -T max -o a.out -D SIMULATION=1 $(CELLS_ADD_DEF) $^ && $(VVP) a.out

$(SIM_DIR)/outputs/%.sp: $(SYN_DIR)/outputs/%.sp
	mkdir -p $(SIM_DIR)/outputs
	cp $^ $@

$(SYN_DIR)/outputs/%.sp: $(SYN_DIR)/outputs/%_net.v
	make -C $(SYN_DIR) TOP=$* gen

$(SYN_DIR)/outputs/%_net.v: $(SYN_DIR)/Makefile
	make -C $(SYN_DIR) TOP=$* all
	make -C $(SYN_DIR) TOP=$* sdf

$(SIM_DIR)/outputs/sim_dco.v: $(SIM_DIR)/outputs/test_fine_delay.raw $(SIM_DIR)/outputs/test_mid_delay.raw $(SIM_DIR)/outputs/test_coarse_delay.raw $(SRC_DIR)/create_sim_dco.py
	$(PYTHON) $(SRC_DIR)/create_sim_dco.py $(SIM_DIR)/outputs/test_fine_delay.log $(SIM_DIR)/outputs/test_mid_delay.log $(SIM_DIR)/outputs/test_coarse_delay.log > $(SIM_DIR)/outputs/sim_dco.v

$(SIM_DIR)/outputs/sim_injection.v: $(SIM_DIR)/outputs/test_pll_injection.raw $(SRC_DIR)/create_sim_inj.py
	$(PYTHON) $(SRC_DIR)/create_sim_inj.py $(SIM_DIR)/outputs/test_pll_injection.log > $(SIM_DIR)/outputs/sim_injection.v

$(SIM_DIR)/outputs/sim_sym.v: $(SIM_DIR)/outputs/test_sym_delay.raw $(SRC_DIR)/create_sim_sym.py
	$(PYTHON) $(SRC_DIR)/create_sim_sym.py $(SIM_DIR)/outputs/test_sym_delay.log > $(SIM_DIR)/outputs/sim_sym.v

# Some metric tests
show_delay_overlap: $(SIM_DIR)/outputs/test_mid_delay.raw $(SIM_DIR)/outputs/test_fine_delay.raw $(SIM_DIR)/outputs/test_coarse_delay.raw $(SRC_DIR)/delay_char.py
	$(PYTHON) $(SRC_DIR)/delay_char.py $(SIM_DIR)/outputs/test_fine_delay.log $(SIM_DIR)/outputs/test_mid_delay.log $(SIM_DIR)/outputs/test_coarse_delay.log

show_delay_overlap_digital: $(SIM_DIR)/outputs/test_mid_delay.vcd $(SIM_DIR)/outputs/test_fine_delay.vcd $(SIM_DIR)/outputs/test_coarse_delay.vcd $(SRC_DIR)/delay_char.py
	$(PYTHON) $(SRC_DIR)/delay_char.py $(SIM_DIR)/outputs/test_fine_delay.vcd.mt0 $(SIM_DIR)/outputs/test_mid_delay.vcd.mt0 $(SIM_DIR)/outputs/test_coarse_delay.vcd.mt0

.SECONDARY:
