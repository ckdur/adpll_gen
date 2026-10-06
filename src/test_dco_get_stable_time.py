#!python

# Get the stable time after a transient simulation of a dco

import sys, os
import numpy as np
import pandas as pd
import matplotlib.pyplot as plt
from scipy.signal import medfilt
from stable_time import *
from spice_io import read_raw

d = read_raw(sys.argv[1])
t = d["time"]
out = d["v(out)"]

del d

dt, dtt = times_from_crossings(out, t, val=0.5)
det = detect(dt)
t_est = dtt[det]
f_mid = 1/np.median(dt)
print(f"t_est = {t_est}, f_mid = {f_mid}")

#plt.figure()
#plt.plot(dtt, dt, "b")
#plt.plot(dtt[window//2:-(window//2-1)], adt, "r")
#plt.show()

