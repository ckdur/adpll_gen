#!python

# Invoke me with:
# python3 ../src/parse_delays.py outputs/test_fine_delay.mt0 FINE
# python3 ../src/parse_delays.py outputs/test_mid_delay.mt0 MID
# python3 ../src/parse_delays.py outputs/test_coarse_delay.mt0 COARSE

import re, sys
import numpy as np
import matplotlib.pyplot as plt

with open(sys.argv[1]) as f:
    data = f.read()

lines = data.splitlines()

# 1. Extract column names (between .TITLE and the numeric block)
header_lines = []
data_lines = []
in_data = False

for line in lines:
    if in_data:
        data_lines.append(line)
    elif line.strip() and not line.startswith(('$DATA', '.TITLE')):
        header_lines.append(line)
    if re.search(r'alter', line.strip()):  # line has numbers
        in_data = True

# 2. Join and split by whitespace
headers = re.split(r'\s+', " ".join(header_lines).strip())
values = re.split(r'\s+', " ".join(data_lines).strip())

# How many values actually exist?
nvalues = 32
for i, v in enumerate(values):
    if v == "failed":
        nvalues = i
        break

# Convert all values to the nearest integer, in fento-seconds
for i in range(nvalues):
    v = float(values[i])
    iv = int(v * 1e15)
    if i == 0:
        print(f"        if({sys.argv[2]}_MUX[{i}] == 1'b0) #({iv}); // delay = {v}")
    elif i != (nvalues-1):
        print(f"        else if({sys.argv[2]}_MUX[{i}] == 1'b0) #({iv}); // delay = {v}")
    else:
        print(f"        else #({iv}); // delay = {v}")

plt.figure()
xvalues = np.arange(nvalues)
yvalues = np.array([float(values[i]) for i in xvalues])
plt.plot(xvalues, yvalues*1e12, "o-b")
plt.title(f"Delay characterization for {sys.argv[2]}")
plt.xlabel("Code")
plt.ylabel("Delay (ps)")
plt.show()
