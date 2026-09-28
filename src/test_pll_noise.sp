* Spice stub test_pll for transient simulations (to extract noise using test_pll_plot_phase_noise.py)

.OPTION
+    ARTIST=2
+    INGOLD=2
+    PARHIER=LOCAL
+    PSF=2
+    PROBE
+    POST=2

* POST=2 enabled for text mode

.inc test_pll.sp

.TRAN 10n stopsim uic
*.TRAN 10n 100n uic
.PROBE
+    V(LOCKED)
+    V(ERR)
+    V(OUT)
+    V(REF)
