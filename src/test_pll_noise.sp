* Spice stub test_pll for transient simulations (to extract noise using test_pll_plot_phase_noise.py)


.inc test_pll.sp

.TRAN 10n 'stopsim' uic
*.TRAN 10n 100n uic
.SAVE
+    V(LOCKED)
+    V(ERR)
+    V(OUT)
+    V(REF)

* Run and save the waveforms (.meas results are printed in the log)
.control
run
write test_pll_noise.raw
quit
.endc
