#!python

# Invoke me with:
# python3 ../src/delay_char.py outputs/test_fine_delay.log outputs/test_mid_delay.log outputs/test_coarse_delay.log
# or, with the digital (iverilog) results:
# python3 ../src/delay_char.py outputs/test_fine_delay.vcd.mt0 outputs/test_mid_delay.vcd.mt0 outputs/test_coarse_delay.vcd.mt0

import re, sys
import numpy as np
import matplotlib.pyplot as plt
from spice_io import meas_until_failed

def get_simulation_digital(text):
    pattern = r"Time for\s+(\d+)\s+is\s+([0-9.]+)"

    # The time is displayed in ps
    result = {int(i): float(v)*1e-12 for i, v in re.findall(pattern, text)}

    times = [v for _, v in sorted(result.items())]
    return times

def get_simulation_analog(fil):
    # The delays measured by measure_delay.sp (ngspice log), up to the first failed one
    return meas_until_failed(fil, "tdel")

def get_simulation(fil):
    with open(fil) as f:
        data = f.read()

    lines = data.splitlines()

    if lines[0].startswith("Time"):
        return get_simulation_digital(data)
    else:
        return get_simulation_analog(fil)

fine_dels = get_simulation(sys.argv[1])
mid_dels = get_simulation(sys.argv[2])
coarse_dels = get_simulation(sys.argv[3])

min_fine = np.min(fine_dels)
max_fine = np.max(fine_dels)
codes = np.arange(0, len(mid_dels)*len(coarse_dels))
min_dels = np.zeros((len(mid_dels)*len(coarse_dels),))
max_dels = np.zeros((len(mid_dels)*len(coarse_dels),))
midfine_codes = np.arange(0, len(fine_dels)*len(mid_dels))
midfine_dels = np.zeros((len(fine_dels)*len(mid_dels),))

for coarsei in range(len(coarse_dels)):
    for midi in range(len(mid_dels)):
        index = midi + coarsei * len(mid_dels)
        min_dels[index] = min_fine + mid_dels[midi] + coarse_dels[coarsei]
        max_dels[index] = max_fine + mid_dels[midi] + coarse_dels[coarsei]

for midi in range(len(mid_dels)):
    for fini in range(len(fine_dels)):
        index = fini + midi * len(fine_dels)
        midfine_dels[index] = fine_dels[fini] + mid_dels[midi]

plt.figure(figsize=(6,7))
plt.subplot(2, 1, 1)
plt.plot(codes, min_dels*1e12, "-b")
plt.plot(codes, max_dels*1e12, "-r")
plt.title(f"Delay codification for MID-COARSE")
plt.xlabel("Code")
plt.ylabel("Delay (ps)")

plt.subplot(2, 1, 2)
plt.plot(midfine_codes, midfine_dels*1e12, "-b")
plt.title(f"Delay codification for FINE-MID")
plt.xlabel("Code")
plt.ylabel("Delay (ps)")

plt.tight_layout()
plt.savefig("outputs/delay_overlap.pdf")
plt.show()
