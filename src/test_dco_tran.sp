* Spice stub test_dco for transient simulations

.inc test_dco.sp

.TRAN 10n stopsim uic
.PROBE
+    V(OUT)
+    V(MID_OUT)
