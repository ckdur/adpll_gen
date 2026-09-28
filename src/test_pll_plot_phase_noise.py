#!python

# Get the Phase Noise from a simulation of pll_test.sp

import sys, os
import numpy as np
import pandas as pd
import matplotlib.pyplot as plt
from decida.Data import Data
from scipy.signal import welch, hilbert
from scipy.interpolate import interp1d
from stable_time import *

# Configuration

d = Data()  # verbose=True
d.read_hspice(sys.argv[1])
rows = d.nrows()
cols = d.ncols()

t = d.get(0)
v_locked = d.get(1)
v_err = d.get(2)
v_out = d.get(3)
v_ref = d.get(4)

dt = np.diff(t)
fs = 4/np.min(dt[dt > 0])  # Four times the minimal time detected in the simulation

del d

def resample_from_time(t, x, fs_new, kind="linear"):
    t = np.asarray(t)
    x = np.asarray(x)

    t_new = np.arange(t[0], t[-1], 1 / fs_new)

    interp = interp1d(
        t, x,
        kind=kind,
        bounds_error=False,
        fill_value="extrapolate"
    )

    x_new = interp(t_new)
    return t_new, x_new

def estimate_carrier_frequency(x, fs):
    """
    Estimate carrier frequency using FFT peak detection.
    """

    x = np.asarray(x)
    N = len(x)

    # Window to reduce leakage
    window = np.hanning(N)
    print("Calculating the fft")
    X = np.fft.fft(x * window)
    print("Done the fft")

    print("Calculating the fftfreq")
    freqs = np.fft.fftfreq(N, 1/fs)
    print("Done the fftfreq")

    # Use magnitude spectrum
    mag = np.abs(X)

    # Ignore DC
    mag[np.abs(freqs) < fs/N] = 0

    idx = np.argmax(mag)
    f_carrier = abs(freqs[idx])
    print(f"f_carrier = {f_carrier}")
    return f_carrier

def ideal_edge_times(t_edges):
    T = np.mean(np.diff(t_edges))
    k = np.arange(len(t_edges))
    t_ideal = t_edges[0] + k * T
    return t_ideal, T

def absolute_jitter(t_edges, t_ideal):
    return t_edges - t_ideal

def phase_noise_from_jitter(phi, fs_edges, nperseg=256):
    # ---- Phase PSD ----
    f, S_phi = welch(
        phi,
        fs=fs_edges,
        nperseg=nperseg,
        scaling="density"
    )

    # ---- SSB phase noise ----
    L_dBc_Hz = 10*np.log10(0.5 * S_phi)

    return f, L_dBc_Hz

# Calculate PN
def cadence_phase_noise(t, x, threshold):
    # Detect rising edges
    t_edges = detect_edges(t, x, threshold)

    # Ideal clock
    t_ideal, T_period = ideal_edge_times(t_edges)

    # Absolute jitter
    J_a = absolute_jitter(t_edges, t_ideal)

    # Phase error (cycles)
    phi = J_a / T_period

    # PSD
    fs_edges = 1 / T_period
    f, P_noise = phase_noise_from_jitter(phi, fs_edges)

    return f, P_noise, T_period

# Detect where either locked or error gets latched
# NOTE: Maybe you need to put half the vdd here (instead of 0.5)
# NOTE: We need to detect also the reset for the t > 0.5e-6
locked_ind = np.where((v_locked >= 0.5) & (t > 0.5e-6))[0]
if len(locked_ind) < 0:
    locked_ind = np.where((v_err >= 0.5) & (t > 0.5e-6))[0]
    if len(locked_ind) < 0:
        raise Exception("There is no locked nor error activation. Check simulation first")
#print(type(locked_ind[0]))
#print(locked_ind)

# Take only those times
t = t[locked_ind[0]+1:]
v_out = v_out[locked_ind[0]+1:]
v_ref = v_ref[locked_ind[0]+1:]
print(f"t_locked = {t[0]}")

# Detect the time that the stabilitization happens
dt, dtt = times_from_crossings(v_out, t, val=0.5)
det = detect(dt, window=200, plot=False)
t_est = dtt[det] + 0.1e-6  # NOTE: We are skipping 0.1us after the detection
f_mid = 1/np.median(dt)
f_avg = 1/np.average(dt)
print(f"t_est = {t_est}, f_mid = {f_mid}, f_avg = ${f_avg}")

# Take only those times
locked_ind = np.where(t >= t_est)[0]
t = t[locked_ind[0]:]
v_out = v_out[locked_ind[0]:]
v_ref = v_ref[locked_ind[0]:]

f, L_dBc_Hz, T_period = cadence_phase_noise(t, v_out, 0.5)
F_period = 1 / T_period
print(f"Average frequency is {F_period}")

# Plot the actual thing
plt.figure(figsize=(9, 6))
plt.semilogx(f, L_dBc_Hz, color="#FF0000", label="PN")
plt.title('PLL Noise')
plt.ylabel('Magnitude (dBc)')
plt.xlabel('Frequency (Hz)')
plt.grid(True, which="both", ls="-")
plt.legend(fontsize=8, loc='lower left')

plt.tight_layout()
plt.savefig("outputs/pll_pn_simulation.pdf")

plt.show()


