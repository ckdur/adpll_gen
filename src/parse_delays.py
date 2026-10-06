#!python

# Invoke me with:
# python3 ../src/parse_delays.py outputs/test_fine_delay.log FINE
# python3 ../src/parse_delays.py outputs/test_mid_delay.log MID
# python3 ../src/parse_delays.py outputs/test_coarse_delay.log COARSE

import sys
from spice_io import meas_until_failed
import numpy as np
import matplotlib.pyplot as plt

# The delays measured by measure_delay.sp, up to the first failed one
values = meas_until_failed(sys.argv[1], "tdel")
nvalues = len(values)

# Convert all values to the nearest integer, in fento-seconds
for i in range(nvalues):
    v = values[i]
    iv = int(v * 1e15)
    if i == 0:
        print(f"        if({sys.argv[2]}_MUX[{i}] == 1'b0) #({iv}); // delay = {v}")
    elif i != (nvalues-1):
        print(f"        else if({sys.argv[2]}_MUX[{i}] == 1'b0) #({iv}); // delay = {v}")
    else:
        print(f"        else #({iv}); // delay = {v}")

plt.figure()
xvalues = np.arange(nvalues)
yvalues = np.array(values)
plt.plot(xvalues, yvalues*1e12, "o-b")
plt.title(f"Delay characterization for {sys.argv[2]}")
plt.xlabel("Code")
plt.ylabel("Delay (ps)")
plt.show()
