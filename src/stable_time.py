import sys, os
import numpy as np
import pandas as pd
import matplotlib.pyplot as plt

def detect_edges(t, x, threshold=None, rising=True):
    """
    Detect threshold crossings and return edge times.
    """
    x = np.asarray(x)
    t = np.asarray(t)

    if threshold is None:
        threshold = (np.max(x) + np.min(x))/2

    if rising:
        crossings = (x[:-1] < threshold) & (x[1:] >= threshold)
    else:
        crossings = (x[:-1] > threshold) & (x[1:] <= threshold)

    # Linear interpolation for sub-sample precision
    t_edges = t[:-1][crossings] + (
        (threshold - x[:-1][crossings]) *
        (t[1:] - t[:-1])[crossings] /
        (x[1:] - x[:-1])[crossings]
    )

    return t_edges

def times_from_crossings(sig, time, val=None, rising=True):
    """
    Estimate frequency by counting zero crossings
    """
    if val is None:
        val = (np.max(sig) + np.min(sig))/2

    # Find all indices right before a rising-edge zero crossing
    if rising:
        indices = np.where((sig[1:] >= val) & (sig[:-1] < val))
    else:
        indices = np.where((sig[1:] <= val) & (sig[:-1] > val))

    # Naive (Measures 1000.185 Hz for 1000 Hz, for instance)
    crossings = time[indices]

    # More accurate, using linear interpolation to find intersample
    # zero-crossings (Measures 1000.000129 Hz for 1000 Hz, for instance)
    # crossings = [time[i] - sig[i] / (sig[i+1] - sig[i]) for i in indices]

    # Some other interpolation based on neighboring points might be better.
    # Spline, cubic, whatever

    return np.diff(crossings).ravel(), time[indices][:-1].ravel()

def window_rms(a, window_size):
    a_squared = np.square(a)
    window = np.ones(window_size) / float(window_size)
    return np.sqrt(np.convolve(a_squared, window, 'valid'))

def detect(x, window=200, tol = 0.8, eps = 1e-15, first_window=5, plot=False):
    n = len(x)
    x_med = pd.Series(x).rolling(window=first_window, center=True, min_periods=1).median().to_numpy()
    resid = x - x_med

    roll_mad = pd.Series(resid).abs().rolling(window=window, min_periods=1, center=True).median()
    baseline = np.median(roll_mad)

    if n <= window:
        raise Exception(f"n <= window, {n} <= {window}")

    var = np.zeros(n-window)
    for i in range(0, n-window):
        var[i] = (np.abs(roll_mad[i:i+window] - baseline) <= eps).astype(float).sum() / window

    candidates = np.where(var >= tol)[0]
    if len(candidates) <= 0:
        print("WARN: No candidates")
    stabil_index = np.clip(int(candidates[0]) + window//2 if len(candidates) else 0, 0, n-1)
    
    if plot:
        plt.subplot(3,1,1)
        plt.plot(x, "k")
        plt.plot(x_med, "r")
        
        plt.subplot(3,1,2)
        plt.plot(resid, "b")
        plt.plot(roll_mad, "r")
        
        plt.subplot(3,1,3)
        plt.plot(var, "b")
        plt.plot([0, n-1], [tol, tol], "g")
        plt.plot([stabil_index, stabil_index], [0.0, 1.0], "g")

        plt.show()

    return stabil_index