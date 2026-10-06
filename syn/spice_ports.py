#!/usr/bin/env python3
# Reorder the ports of the top .SUBCKT written by openroad (alphabetical)
# so they follow the verilog module: VDD VSS, then the declared ports,
# buses MSB first. The testbenches instantiate the subcircuits positionally.
#
# Invoke me with:
# python3 spice_ports.py outputs/FINE_DELAY.sp FINE_DELAY outputs/FINE_DELAY_net.v [more_net.v ...]

import re, sys

SUPPLIES = ["VDD", "VSS"]

def verilog_ports(files, top):
    for fil in files:
        with open(fil) as f:
            text = f.read()
        m = re.search(r'\bmodule\s+' + re.escape(top) + r'\s*\((.*?)\)\s*;(.*?)\bendmodule', text, re.S)
        if not m:
            continue
        names = [p.strip() for p in m.group(1).split(",") if p.strip()]
        ranges = {}
        for d in re.finditer(r'\b(?:input|output|inout)\s+(?:\[(\d+):(\d+)\]\s*)?([^;]+);', m.group(2)):
            for n in d.group(3).split(","):
                ranges[n.strip()] = (d.group(1), d.group(2))
        ports = []
        for n in names:
            msb, lsb = ranges.get(n, (None, None))
            if msb is None:
                ports.append(n)
            else:
                step = 1 if int(lsb) >= int(msb) else -1
                ports += [f"{n}[{i}]" for i in range(int(msb), int(lsb) + step, step)]
        return ports
    raise SystemExit(f"Module {top} not found in {files}")

def reorder(spfile, top, ports):
    with open(spfile) as f:
        lines = f.read().splitlines()
    start = next(i for i, l in enumerate(lines) if re.match(r'\.SUBCKT\s+' + re.escape(top) + r'\b', l, re.I))
    end = start + 1
    while end < len(lines) and lines[end].startswith("+"):
        end += 1
    current = " ".join(l.lstrip("+") for l in lines[start:end]).split()[2:]

    order = [p for p in SUPPLIES if p in current] + [p for p in ports if p not in SUPPLIES]
    if sorted(order) != sorted(current):
        raise SystemExit(f"Port mismatch for {top}:\n  spice:   {sorted(current)}\n  verilog: {sorted(order)}")

    header = [f".SUBCKT {top}"]
    for p in order:
        if len(header[-1]) + len(p) + 1 > 78:
            header.append("+")
        header[-1] += " " + p
    lines[start:end] = header
    with open(spfile, "w") as f:
        f.write("\n".join(lines) + "\n")
    print(f"Reordered ports of {top} in {spfile}")

reorder(sys.argv[1], sys.argv[2], verilog_ports(sys.argv[3:], sys.argv[2]))
