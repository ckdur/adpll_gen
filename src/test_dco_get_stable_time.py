#!python

# Get the stable time after a transient simulation of a dco

import sys, os
import numpy as np
import pandas as pd
import matplotlib.pyplot as plt
from decida.Data import Data
from scipy.signal import medfilt
from stable_time import *

d = Data()
d.read_hspice(sys.argv[1])
rows = d.nrows()
cols = d.ncols()

t = d.get(0)
out = d.get(1)

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

