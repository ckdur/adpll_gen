#!python

# Readers for the ngspice outputs:
# - read_raw: the waveforms of a rawfile (binary or ascii), written by "write" in the .control
# - read_meas: the .meas results printed in the ngspice log (-o file)

import re

def read_raw(fil):
    """Returns a dict {vector name (lowercase): numpy array} of the first plot in the rawfile."""
    import numpy as np
    with open(fil, "rb") as f:
        data = f.read()

    names = []
    nvars = npoints = 0
    complex_data = False
    pos = 0
    while True:
        end = data.index(b"\n", pos)
        line = data[pos:end].decode("latin-1").strip()
        pos = end + 1
        key, _, value = line.partition(":")
        key = key.lower()
        if key == "flags":
            complex_data = "complex" in value.lower()
        elif key == "no. variables":
            nvars = int(value)
        elif key == "no. points":
            npoints = int(value)
        elif key == "variables":
            for _ in range(nvars):
                end = data.index(b"\n", pos)
                names.append(data[pos:end].decode("latin-1").split()[1].lower())
                pos = end + 1
        elif key == "binary":
            dtype = np.complex128 if complex_data else np.float64
            values = np.frombuffer(data, dtype=dtype, count=npoints * nvars, offset=pos)
            break
        elif key == "values":
            text = data[pos:].decode("latin-1").split()
            values = []
            for i in range(npoints):
                # Each point is: index value0 value1 ... value(nvars-1)
                row = text[i * (nvars + 1) + 1:(i + 1) * (nvars + 1)]
                values += [complex(*map(float, v.split(","))) if complex_data else float(v) for v in row]
            values = np.array(values)
            break

    values = values.reshape(npoints, nvars)
    if not complex_data:
        values = values.real
    return {n: values[:, i] for i, n in enumerate(names)}

def read_meas(fil):
    """Returns a dict {measurement name: value} from an ngspice log.
    Failed measurements have None as value.
    NOTE: ngspice prints the failed ones first, so the order is not the one of the .meas"""
    meas = {}
    with open(fil) as f:
        for line in f:
            m = re.match(r'^(\w+)\s+=\s+(\S+)', line)
            if m:
                meas[m.group(1).lower()] = float(m.group(2))
                continue
            # ngspice reports a failed one as: " .meas tran name ... failed!"
            m = re.match(r'^\s*\.meas\w*\s+\w+\s+(\w+)\s.*failed!', line, re.I)
            if m:
                meas[m.group(1).lower()] = None
    return meas

def meas_until_failed(fil, prefix):
    """The values of the measurements starting with prefix, up to the first failed one."""
    meas = read_meas(fil)
    # Sort by the number after the prefix (tdel00, tdel01, ...)
    names = sorted((k for k in meas if re.fullmatch(re.escape(prefix) + r'\d+', k)),
                   key=lambda k: int(k[len(prefix):]))
    values = []
    for k in names:
        if meas[k] is None:
            break
        values.append(meas[k])
    return values
