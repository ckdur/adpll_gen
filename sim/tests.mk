# Delay characterization tests
test_fine_delay: $(SIM_OUT)/test_fine_delay.raw

$(SIM_OUT)/test_fine_delay.raw: $(SIM_OUT)/FINE_DELAY.sp $(SRC_DIR)/test_fine_delay.sp $(SRC_DIR)/measure_delay.sp $(SIM_OUT)/models.inc $(SIM_OUT)/.spiceinit
	cp $(SRC_DIR)/test_fine_delay.sp $(SIM_OUT)/test_fine_delay.sp
	cp $(SRC_DIR)/measure_delay.sp $(SIM_OUT)/measure_delay.sp
	cd $(SIM_OUT) && $(NGSPICE) -o test_fine_delay.log test_fine_delay.sp < /dev/null

view_test_fine_delay: $(SIM_OUT)/test_fine_delay.raw
	$(WAVEVIEW) $(SIM_OUT)/test_fine_delay.raw

test_mid_delay: $(SIM_OUT)/test_mid_delay.raw

$(SIM_OUT)/test_mid_delay.raw: $(SIM_OUT)/MID_DELAY.sp $(SRC_DIR)/test_mid_delay.sp $(SRC_DIR)/measure_delay.sp $(SIM_OUT)/models.inc $(SIM_OUT)/.spiceinit
	cp $(SRC_DIR)/test_mid_delay.sp $(SIM_OUT)/test_mid_delay.sp
	cp $(SRC_DIR)/measure_delay.sp $(SIM_OUT)/measure_delay.sp
	cd $(SIM_OUT) && $(NGSPICE) -o test_mid_delay.log test_mid_delay.sp < /dev/null

view_test_mid_delay: $(SIM_OUT)/test_mid_delay.raw
	$(WAVEVIEW) $(SIM_OUT)/test_mid_delay.raw

test_coarse_delay: $(SIM_OUT)/test_coarse_delay.raw

$(SIM_OUT)/test_coarse_delay.raw: $(SIM_OUT)/COARSE_DELAY.sp $(SRC_DIR)/test_coarse_delay.sp $(SRC_DIR)/measure_delay.sp $(SIM_OUT)/models.inc $(SIM_OUT)/.spiceinit
	cp $(SRC_DIR)/test_coarse_delay.sp $(SIM_OUT)/test_coarse_delay.sp
	cp $(SRC_DIR)/measure_delay.sp $(SIM_OUT)/measure_delay.sp
	cd $(SIM_OUT) && $(NGSPICE) -o test_coarse_delay.log test_coarse_delay.sp < /dev/null

view_test_coarse_delay: $(SIM_OUT)/test_coarse_delay.raw
	$(WAVEVIEW) $(SIM_OUT)/test_coarse_delay.raw

# Delay characterization tests... but in digital (using sdf files)
test_fine_delay_digital: $(SIM_OUT)/test_fine_delay.vcd

$(SIM_OUT)/test_fine_delay.vcd: $(SYN_OUT)/FINE_DELAY_net.v $(SRC_DIR)/test_fine_delay.v $(SRC_DIR)/measure_delay.v $(SRC_DIR)/sim_mux.v $(CELLS_SRC)
	mkdir -p $(SIM_OUT)
	cp $(SYN_OUT)/FINE_DELAY.sdf $(SIM_OUT)/FINE_DELAY.sdf
	cp $(SYN_OUT)/FINE_DELAY_net.v $(SIM_OUT)/FINE_DELAY_net.v
	cp $(SRC_DIR)/measure_delay.v $(SIM_OUT)/measure_delay.v
	cd $(SIM_OUT) && $(IVERILOG) -ginterconnect -gspecify -T max -o a.out -D SIMULATION=1 $(CELLS_ADD_DEF) $(SRC_DIR)/test_fine_delay.v $(SRC_DIR)/sim_mux.v $(CELLS_SRC) && $(VVP) a.out

view_test_fine_delay_digital: $(SIM_OUT)/test_fine_delay.vcd
	gtkwave $(SIM_OUT)/test_fine_delay.vcd

test_mid_delay_digital: $(SIM_OUT)/test_mid_delay.vcd

$(SIM_OUT)/test_mid_delay.vcd: $(SYN_OUT)/MID_DELAY_net.v $(SRC_DIR)/test_mid_delay.v $(SRC_DIR)/measure_delay.v $(SRC_DIR)/sim_mux.v $(CELLS_SRC)
	mkdir -p $(SIM_OUT)
	cp $(SYN_OUT)/MID_DELAY.sdf $(SIM_OUT)/MID_DELAY.sdf
	cp $(SYN_OUT)/MID_DELAY_net.v $(SIM_OUT)/MID_DELAY_net.v
	cp $(SRC_DIR)/measure_delay.v $(SIM_OUT)/measure_delay.v
	cd $(SIM_OUT) && $(IVERILOG) -ginterconnect -gspecify -T max -o a.out -D SIMULATION=1 $(CELLS_ADD_DEF) $(SRC_DIR)/test_mid_delay.v $(SRC_DIR)/sim_mux.v $(CELLS_SRC) && $(VVP) a.out

view_test_mid_delay_digital: $(SIM_OUT)/test_mid_delay.vcd
	gtkwave $(SIM_OUT)/test_mid_delay.vcd

test_coarse_delay_digital: $(SIM_OUT)/test_coarse_delay.vcd

$(SIM_OUT)/test_coarse_delay.vcd: $(SYN_OUT)/COARSE_DELAY_net.v $(SRC_DIR)/test_coarse_delay.v $(SRC_DIR)/measure_delay.v $(CELLS_SRC)
	mkdir -p $(SIM_OUT)
	cp $(SYN_OUT)/COARSE_DELAY.sdf $(SIM_OUT)/COARSE_DELAY.sdf
	cp $(SYN_OUT)/COARSE_DELAY_net.v $(SIM_OUT)/COARSE_DELAY_net.v
	cp $(SRC_DIR)/measure_delay.v $(SIM_OUT)/measure_delay.v
	cd $(SIM_OUT) && $(IVERILOG) -ginterconnect -gspecify -T max -o a.out -D SIMULATION=1 $(CELLS_ADD_DEF) $(SRC_DIR)/test_coarse_delay.v $(CELLS_SRC) && $(VVP) a.out

view_test_coarse_delay_digital: $(SIM_OUT)/test_coarse_delay.vcd
	gtkwave $(SIM_OUT)/test_coarse_delay.vcd

# PLL injection test
test_pll_injection: $(SIM_OUT)/test_pll_injection.raw

$(SIM_OUT)/test_pll_injection.raw: $(SIM_OUT)/PLL_INJECTION.sp $(SRC_DIR)/test_pll_injection.sp $(SIM_OUT)/models.inc $(SIM_OUT)/.spiceinit
	cp $(SRC_DIR)/test_pll_injection.sp $(SIM_OUT)/test_pll_injection.sp
	cd $(SIM_OUT) && $(NGSPICE) -o test_pll_injection.log test_pll_injection.sp < /dev/null

view_test_pll_injection: $(SIM_OUT)/test_pll_injection.raw
	$(WAVEVIEW) $(SIM_OUT)/test_pll_injection.raw

# Symmetrical circuit delay test
test_sym_delay: $(SIM_OUT)/test_sym_delay.raw

$(SIM_OUT)/test_sym_delay.raw: $(SIM_OUT)/PLL_SYM.sp $(SRC_DIR)/test_sym_delay.sp $(SIM_OUT)/models.inc $(SIM_OUT)/.spiceinit
	cp $(SRC_DIR)/test_sym_delay.sp $(SIM_OUT)/test_sym_delay.sp
	cd $(SIM_OUT) && $(NGSPICE) -o test_sym_delay.log test_sym_delay.sp < /dev/null

view_test_sym_delay: $(SIM_OUT)/test_sym_delay.raw
	$(WAVEVIEW) $(SIM_OUT)/test_sym_delay.raw

# DCO phase noise test
test_dco: $(SIM_OUT)/test_dco_tran.raw
	$(PYTHON) $(SRC_DIR)/test_dco_get_stable_time.py $(SIM_OUT)/test_dco_tran.raw

$(SIM_OUT)/test_dco_tran.raw: $(SIM_OUT)/PLL_ILDCO.sp $(SRC_DIR)/test_dco.sp $(SRC_DIR)/test_dco_tran.sp $(SIM_OUT)/models.inc $(SIM_OUT)/.spiceinit
	cp $(SRC_DIR)/test_dco.sp $(SIM_OUT)/test_dco.sp
	cp $(SRC_DIR)/test_dco_tran.sp $(SIM_OUT)/test_dco_tran.sp
	cd $(SIM_OUT) && $(NGSPICE) -o test_dco_tran.log test_dco_tran.sp < /dev/null

view_test_dco: $(SIM_OUT)/test_dco_tran.raw
	$(WAVEVIEW) $(SIM_OUT)/test_dco_tran.raw

# DCO phase noise with the ISF method (Hajimiri & Lee). See src/create_isf.py and src/isf_phase_noise.py
# 1. Steady-state waveforms of the DCO
# 2. One run per oscillating net injecting small charges at ISF_NPHASE phases of the period,
#    plus the drain current noise (.noise) of each kind of transistor. Runs ISF_JOBS in parallel
# 3. Phase noise from the ISFs and the cyclostationary noise of the transistors
ISF_TWARM?=15n
ISF_NPHASE?=128
ISF_NPER?=3
ISF_DQ?=50e-18
ISF_JOBS?=$(shell sysctl -n hw.ncpu 2>/dev/null || nproc)

test_dco_noise: $(SIM_OUT)/test_dco_noise.csv

view_test_dco_noise: $(SIM_OUT)/test_dco_noise.csv
	open $(SIM_OUT)/test_dco_noise.pdf 2>/dev/null || xdg-open $(SIM_OUT)/test_dco_noise.pdf

$(SIM_OUT)/test_dco_isf_wave.raw: $(SIM_OUT)/PLL_ILDCO.sp $(SRC_DIR)/test_dco.sp $(SRC_DIR)/create_isf.py $(SIM_OUT)/models.inc $(SIM_OUT)/.spiceinit
	cp $(SRC_DIR)/test_dco.sp $(SIM_OUT)/test_dco.sp
	cd $(SIM_OUT) && $(PYTHON) $(SRC_DIR)/create_isf.py wave --twarm $(ISF_TWARM)
	cd $(SIM_OUT) && $(NGSPICE) -o test_dco_isf_wave.log test_dco_isf_wave.sp < /dev/null

$(SIM_OUT)/isf_runs.txt: $(SIM_OUT)/test_dco_isf_wave.raw $(SRC_DIR)/spice_netlist.py
	cd $(SIM_OUT) && $(PYTHON) $(SRC_DIR)/create_isf.py runs --twarm $(ISF_TWARM) --nphase $(ISF_NPHASE) --nper $(ISF_NPER) --dq $(ISF_DQ)

$(SIM_OUT)/isf_done: $(SIM_OUT)/isf_runs.txt
	cd $(SIM_OUT) && xargs -P $(ISF_JOBS) -I{} sh -c '$(NGSPICE) -o {}.log {}.sp < /dev/null > /dev/null && echo "Done {}"' < isf_runs.txt
	touch $@

$(SIM_OUT)/test_dco_noise.csv: $(SIM_OUT)/isf_done $(SRC_DIR)/isf_phase_noise.py
	cd $(SIM_OUT) && $(PYTHON) $(SRC_DIR)/isf_phase_noise.py | tee test_dco_noise.txt

# Main PLL test
test_pll: $(SIM_OUT)/test_pll_tran.raw

$(SIM_OUT)/test_pll_tran.raw: $(SIM_OUT)/pll.sp $(SRC_DIR)/test_pll_tran.sp $(SRC_DIR)/pll_inst_declr.sp $(SRC_DIR)/test_pll.sp $(SIM_OUT)/models.inc $(SIM_OUT)/.spiceinit
	cp $(SRC_DIR)/test_pll.sp $(SIM_OUT)/test_pll.sp
	cp $(SRC_DIR)/test_pll_tran.sp $(SIM_OUT)/test_pll_tran.sp
	cp $(SRC_DIR)/pll_inst_declr.sp $(SIM_OUT)/pll_inst_declr.sp
	cd $(SIM_OUT) && $(NGSPICE) -o test_pll_tran.log test_pll_tran.sp < /dev/null

view_test_pll: $(SIM_OUT)/test_pll_tran.raw
	$(WAVEVIEW) $(SIM_OUT)/test_pll_tran.raw

test_pll_noise: $(SIM_OUT)/test_pll_noise.raw $(SRC_DIR)/test_pll_plot_phase_noise.py
	$(PYTHON) $(SRC_DIR)/test_pll_plot_phase_noise.py $(SIM_OUT)/test_pll_noise.raw

view_test_pll_noise: $(SIM_OUT)/test_pll_noise.raw $(SRC_DIR)/test_pll_plot_phase_noise.py
	$(WAVEVIEW) $(SIM_OUT)/test_pll_noise.raw

$(SIM_OUT)/test_pll_noise.raw: $(SIM_OUT)/pll.sp $(SRC_DIR)/test_pll_noise.sp $(SRC_DIR)/pll_inst_declr.sp $(SRC_DIR)/test_pll.sp $(SIM_OUT)/models.inc $(SIM_OUT)/.spiceinit
	cp $(SRC_DIR)/test_pll.sp $(SIM_OUT)/test_pll.sp
	cp $(SRC_DIR)/test_pll_noise.sp $(SIM_OUT)/test_pll_noise.sp
	cp $(SRC_DIR)/pll_inst_declr.sp $(SIM_OUT)/pll_inst_declr.sp
	cd $(SIM_OUT) && $(NGSPICE) -o test_pll_noise.log test_pll_noise.sp < /dev/null

test_pll_rcx: $(PRJ_DIR)/ver/rcx/rundir/xrc_lay.dist.sp $(PRJ_DIR)/ver/rcx/rundir/xrc_lay.dist.sp.pll.pxi $(PRJ_DIR)/src/pll_inst_declr_xrc.sp $(SRC_DIR)/test_pll.sp $(SIM_OUT)/models.inc $(SIM_OUT)/.spiceinit
	cp $(PRJ_DIR)/ver/rcx/rundir/xrc_lay.dist.sp $(SIM_OUT)/pll.sp
	cp $(PRJ_DIR)/ver/rcx/rundir/xrc_lay.dist.sp.pll.pxi $(SIM_OUT)/xrc_lay.dist.sp.pll.pxi
	cp $(PRJ_DIR)/src/pll_inst_declr_xrc.sp $(SIM_OUT)/pll_inst_declr.sp
	cp $(SRC_DIR)/test_pll.sp $(SIM_OUT)/test_pll_rcx.sp
	cd $(SIM_OUT) && $(NGSPICE) -o test_pll_rcx.log test_pll_rcx.sp < /dev/null

view_test_pll_rcx:
	$(WAVEVIEW) $(SIM_OUT)/test_pll_rcx.raw

# Frequency locking RTL simulation
test_freq_lock: $(SIM_OUT)/freq_lock_tb.vcd

view_test_freq_lock: $(SIM_OUT)/freq_lock_tb.vcd
	gtkwave $(SIM_OUT)/freq_lock_tb.vcd

$(SIM_OUT)/freq_lock_tb.vcd: $(SRC_DIR)/freq_lock.v $(SRC_DIR)/freq_lock_tb.v $(SIM_OUT)/sim_dco.v
	mkdir -p $(SIM_OUT)
	cd $(SIM_OUT) && $(IVERILOG) -ginterconnect -gspecify -T max -o a.out -D SIMULATION=1 $^ && $(VVP) a.out

# Digital loop filter RTL simulation
test_dlf: $(SIM_OUT)/digital_loop_filter_tb.vcd

view_test_dlf: $(SIM_OUT)/digital_loop_filter_tb.vcd
	gtkwave $(SIM_OUT)/digital_loop_filter_tb.vcd

$(SIM_OUT)/digital_loop_filter_tb.vcd: $(SRC_DIR)/digital_loop_filter.v $(SRC_DIR)/digital_loop_filter_tb.v $(SIM_OUT)/sim_dco.v $(SRC_DIR)/sim_SSBBPD.v
	mkdir -p $(SIM_OUT)
	cd $(SIM_OUT) && $(IVERILOG) -ginterconnect -gspecify -T max -o a.out -D SIMULATION=1 $^ && $(VVP) a.out

# Termometer decoder RTL simulation
test_term_decoder: $(SIM_OUT)/term_decoder_tb.vcd

view_test_term_decoder: $(SIM_OUT)/term_decoder_tb.vcd
	gtkwave $(SIM_OUT)/term_decoder_tb.vcd

$(SIM_OUT)/term_decoder_tb.vcd: $(SRC_DIR)/term_decoder_tb.v $(SRC_DIR)/term_decoder.v
	mkdir -p $(SIM_OUT)
	cd $(SIM_OUT) && $(IVERILOG) -ginterconnect -gspecify -T max -o a.out -D SIMULATION=1  $^ && $(VVP) a.out

# Delta-sigma modulator RTL simulation
test_delta_sigma: $(SIM_OUT)/delta_sigma_tb.vcd

view_test_delta_sigma: $(SIM_OUT)/delta_sigma_tb.vcd
	gtkwave $(SIM_OUT)/delta_sigma_tb.vcd

$(SIM_OUT)/delta_sigma_tb.vcd: $(SRC_DIR)/delta_sigma_tb.v $(SRC_DIR)/delta_sigma.v
	mkdir -p $(SIM_OUT)
	cd $(SIM_OUT) && $(IVERILOG) -ginterconnect -gspecify -T max -o a.out -D SIMULATION=1  $^ && $(VVP) a.out

# PLL fine test
test_pll_fine: $(SIM_OUT)/pll_fine_test.vcd

view_test_pll_fine: $(SIM_OUT)/pll_fine_test.vcd
	gtkwave $(SIM_OUT)/pll_fine_test.vcd

$(SIM_OUT)/pll_fine_test.vcd: $(SRC_DIR)/pll_fine_test.v $(SRC_DIR)/pll_analog.v $(SIM_OUT)/sim_injection.v $(SRC_DIR)/il_dco.v $(SIM_OUT)/sim_dco.v $(SIM_OUT)/sim_sym.v $(SRC_DIR)/sim_SSBBPD.v $(SRC_DIR)/digital_loop_filter.v $(SRC_DIR)/delta_sigma.v $(SRC_DIR)/term_decoder.v
	mkdir -p $(SIM_OUT)
	cd $(SIM_OUT) && $(IVERILOG) -ginterconnect -gspecify -T max -o a.out -D SIMULATION=1 $^ && $(VVP) a.out

# Main PLL RTL simulation (pre and post-synthesis)
test_pll_digital: $(SIM_OUT)/test_pll.vcd

view_test_pll_digital: $(SIM_OUT)/test_pll.vcd
	gtkwave $(SIM_OUT)/test_pll.vcd

$(SIM_OUT)/test_pll.vcd: $(SRC_DIR)/pll_test.v $(SRC_DIR)/pll.v $(SRC_DIR)/pll_logic.v $(SRC_DIR)/pll_analog.v $(SIM_OUT)/sim_injection.v $(SRC_DIR)/il_dco.v $(SIM_OUT)/sim_dco.v $(SIM_OUT)/sim_sym.v $(SRC_DIR)/sim_SSBBPD.v $(SRC_DIR)/digital_loop_filter.v $(SRC_DIR)/term_decoder.v $(SRC_DIR)/freq_lock.v $(SRC_DIR)/conf_div.v $(SRC_DIR)/fix_div.v
	mkdir -p $(SIM_OUT)
	cd $(SIM_OUT) && $(IVERILOG) -ginterconnect -gspecify -T max -o a.out -D SIMULATION=1 $^ && $(VVP) a.out

test_pll_digital_postsyn: $(SIM_OUT)/test_pll_postsyn.vcd

view_test_pll_digital_postsyn: $(SIM_OUT)/test_pll_postsyn.vcd
	gtkwave $(SIM_OUT)/test_pll_postsyn.vcd

$(SIM_OUT)/test_pll_postsyn.vcd: $(CELLS_SRC) $(SRC_DIR)/pll_test.v $(SRC_DIR)/pll.v $(SYN_OUT)/pll_logic_net.v $(SRC_DIR)/pll_analog.v $(SIM_OUT)/sim_injection.v $(SRC_DIR)/il_dco.v $(SIM_OUT)/sim_dco.v $(SIM_OUT)/sim_sym.v $(SRC_DIR)/sim_SSBBPD.v $(SRC_DIR)/conf_div.v
	mkdir -p $(SIM_OUT)
	cd $(SIM_OUT) && $(IVERILOG) -ginterconnect -gspecify -T max -o a.out -D SIMULATION=1 $(CELLS_ADD_DEF) $^ && $(VVP) a.out

$(SIM_OUT)/%.sp: $(SYN_OUT)/%.sp
	mkdir -p $(SIM_OUT)
	cp $^ $@

$(SYN_OUT)/%.sp: $(SYN_OUT)/%_net.v
	make -C $(SYN_DIR) TOP=$* gen

# Also on the sources (RTL and the PLL_CELL_* map of the PDK), as the netlists of syn/Makefile
$(SYN_OUT)/%_net.v: $(SYN_DIR)/Makefile $(SYN_SRC)
	make -C $(SYN_DIR) TOP=$* all
	make -C $(SYN_DIR) TOP=$* sdf

$(SIM_OUT)/sim_dco.v: $(SIM_OUT)/test_fine_delay.raw $(SIM_OUT)/test_mid_delay.raw $(SIM_OUT)/test_coarse_delay.raw $(SRC_DIR)/create_sim_dco.py
	$(PYTHON) $(SRC_DIR)/create_sim_dco.py $(SIM_OUT)/test_fine_delay.log $(SIM_OUT)/test_mid_delay.log $(SIM_OUT)/test_coarse_delay.log > $(SIM_OUT)/sim_dco.v

$(SIM_OUT)/sim_injection.v: $(SIM_OUT)/test_pll_injection.raw $(SRC_DIR)/create_sim_inj.py
	$(PYTHON) $(SRC_DIR)/create_sim_inj.py $(SIM_OUT)/test_pll_injection.log > $(SIM_OUT)/sim_injection.v

$(SIM_OUT)/sim_sym.v: $(SIM_OUT)/test_sym_delay.raw $(SRC_DIR)/create_sim_sym.py
	$(PYTHON) $(SRC_DIR)/create_sim_sym.py $(SIM_OUT)/test_sym_delay.log > $(SIM_OUT)/sim_sym.v

# Some metric tests
show_delay_overlap: $(SIM_OUT)/test_mid_delay.raw $(SIM_OUT)/test_fine_delay.raw $(SIM_OUT)/test_coarse_delay.raw $(SRC_DIR)/delay_char.py
	$(PYTHON) $(SRC_DIR)/delay_char.py $(SIM_OUT)/test_fine_delay.log $(SIM_OUT)/test_mid_delay.log $(SIM_OUT)/test_coarse_delay.log

show_delay_overlap_digital: $(SIM_OUT)/test_mid_delay.vcd $(SIM_OUT)/test_fine_delay.vcd $(SIM_OUT)/test_coarse_delay.vcd $(SRC_DIR)/delay_char.py
	$(PYTHON) $(SRC_DIR)/delay_char.py $(SIM_OUT)/test_fine_delay.vcd.mt0 $(SIM_OUT)/test_mid_delay.vcd.mt0 $(SIM_OUT)/test_coarse_delay.vcd.mt0

.SECONDARY:
