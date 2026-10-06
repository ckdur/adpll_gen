* Spice stub test_dco for transient simulations

.inc test_dco.sp

.TRAN 10n 'stopsim' uic
.SAVE
+    V(OUT)
+    V(MID_OUT)

* Run and save the waveforms (.meas results are printed in the log)
.control
run
write test_dco_tran.raw
quit
.endc
