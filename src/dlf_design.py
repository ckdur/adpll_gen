#!python

# An attempt to do a digital loop filter
# ... yes, you can do this in MATLAB... but screw MATLAB

import numpy as np
from scipy import signal
import matplotlib.pyplot as plt

#------------------------------------------------
# Create a signal for demonstration.
#------------------------------------------------

FCW = 15
alpha = 0.0875
F_REF = 100000000  # 100 MHz
F_VCO = (FCW + 1 + alpha) * F_REF
FILTER_BITS = 16
F_CUT = 1000000 # 1 MHz cutoff

sample_rate = F_VCO  # Sample rate is the VCO
nsamples = 10000

t = np.arange(nsamples) / sample_rate
x = signal.square(2 * np.pi * F_REF * t)

#------------------------------------------------
# Filter design
#------------------------------------------------
omega_c = 2 * np.pi * F_CUT / sample_rate
Kp = np.sin(omega_c)
Ki = (1 - np.cos(omega_c)) * sample_rate / (2 * np.pi * F_CUT)  # scaled for realism

# Transfer function: H(z) = (Kp + Ki - Kp*z^-1) / (1 - z^-1)
b = [Kp + Ki, -Kp]   # numerator
a = [1, -1]          # denominator

# Create the digital filter system
system = signal.dlti(b, a, dt=1/sample_rate)

# Frequency response
w, h = signal.dfreqresp(system, n=512)
f = w / (2 * np.pi)

# Use lfilter to filter x with the filter.
# NOTE: It has no meaning, but is just for checking into
y, _ = signal.lfilter(b, a, x, zi=[10.0])
print(y.shape)

#------------------------------------------------
# Plot the original and filtered signals.
#------------------------------------------------
plt.figure(figsize=(10, 10))

plt.subplot(3, 1, 1)
#plt.plot(t, ref+2, label='REF')
#plt.plot(t, vco+1, label='VCO')
plt.plot(t, x, label='SSBBPD')
plt.title(f"Clock Signals")
plt.xlabel("Time [s]")
plt.ylabel("Amplitude")
plt.legend()
plt.grid(True)

# The phase delay of the filtered signal.
plt.subplot(3, 1, 2)
plt.plot(t, y, label='Filtered signal', linewidth=2)
plt.title(f"Filtered Signal")
plt.xlabel("Time [s]")
plt.ylabel("Amplitude")
plt.grid(True)

#------------------------------------------------
# Plot the magnitude response of the filter.
#------------------------------------------------

w, h = signal.dfreqresp(system, n=512)
f = w / (2 * np.pi)
plt.subplot(3, 1, 3)
plt.plot(f * sample_rate, np.abs(h))
plt.title("Magnitude Response")
plt.yscale('log')
plt.xscale('log')
plt.xlabel("Frequency [Hz]")
plt.ylabel("Magnitude [dB]")
plt.grid(True)
plt.tight_layout()

# Print the results
print(f"Kp = {Kp}, Ki = {Ki}")
Kpb = int((1 << FILTER_BITS) * Kp)
Kib = int((1 << FILTER_BITS) * Ki)
print(f"Kpb = {Kpb}, Kib = {Kib}")

plt.show()
