#!python

# Reference phase noise of the DCO with Spectre (autonomous PSS + pnoise), to validate the ngspice
# ISF method (create_isf.py / isf_phase_noise.py) on the same netlist, codes and models.
#
# Run inside sim/outputs/<PDK> (needs PLL_ILDCO.sp, models.inc and isf_setup.json for the frequency guess):
#   python3 ../../src/spectre_dco_pnoise.py [--spectre "spectre"] [--harms 40]
# Writes test_dco_spectre.scs, runs it into test_dco_spectre.raw (psfascii) and writes
#   test_dco_spectre.csv: freq, L_dBc_Hz
#   test_dco_spectre.txt: f0, L at the usual offsets, and the noise contributions grouped by cell at 1 MHz
#
# The testbench is test_dco.sp (fixed codes) in SPICE syntax, read by Spectre in "simulator lang=spice"
# mode (the PDK model libraries are HSPICE format). Differences with test_dco.sp: GND is node 0, and
# DCO_EN rises at 1 ns, so the PSS stabilization transient starts from the DC point with the ring off.
# L(f) = S_v(f0 + f) / (|V1|^2 / 2): single-sideband noise at the 1st harmonic of OUT over its power.

import argparse, collections, json, os, re, subprocess, sys
import numpy as np

TB = "test_dco.sp"
OUT_NODE = "OUT"
REPORT = [1e3, 1e4, 1e5, 1e6, 1e7, 1e8]

def netlist(fund, harms):
    body = []
    with open(TB) as f:
        for line in f:
            l = line.strip()
            low = l.lower()
            if not l or l.startswith("*") or low.startswith((".tran", ".control", ".endc", ".meas", ".save",
                                                              ".end", "run", "write", "quit", ".option")):
                continue
            if re.match(r'\.PARAM\s+(tclk|stopsim)\w*\s*=', l, re.I):    # (expr) params of the tran only
                continue
            if re.match(r'vdco_en\s', low):
                l = "Vdco_en dco_en GND PWL 0 0 1n 0 1.05n lvdd"
            body.append(re.sub(r'\bGND\b', '0', l))
    return ("simulator lang=spice\n" + "\n".join(body) + f"""
simulator lang=spectre
opts options reltol=1e-5 vabstol=1e-7 iabstol=1e-13
pss1 ({OUT_NODE} 0) pss fund={fund:.6g} harms={harms} tstab=30n errpreset=conservative maxstep=1p
pn1 ({OUT_NODE} 0) pnoise start=1k stop=500M dec=10 maxsideband={harms} noisetype=timeaverage
""")

def numbers(text):
    return [float(t) for t in text.split() if re.fullmatch(r'[-+\d.eE]+', t)]

def parse(raw):
    # 1st harmonic of OUT
    fd = open(f"{raw}/pss1.fd.pss").read().split("\nVALUE\n", 1)[1]
    f0 = float(re.findall(r'"freq" ([-+\d.eE]+)', fd)[1])
    h1 = re.findall(r'"OUT" \(([-+\d.eE]+) ([-+\d.eE]+)\)', fd)[1]
    a1 = abs(complex(float(h1[0]), float(h1[1])))
    # pnoise: per frequency, the device structs (in TRACE order), then "out" and "cornerFreq"
    txt = open(f"{raw}/pn1.pnoise").read()
    types = txt.split("\nTYPE\n", 1)[1].split("\nSWEEP\n", 1)[0]
    structs, cur, prev = {}, None, ""
    for line in types.splitlines():
        m = re.match(r'^"([^"]+)" STRUCT\(', line)
        if m:
            cur, prev = m.group(1), ""
            structs[cur] = []
            continue
        if cur:
            m = re.match(r'^"(\w+)" FLOAT', line)
            if m:
                structs[cur].append(m.group(1))
            if line == ")" and prev == ")":
                cur = None
        prev = line
    traces = re.findall(r'^"([^"]+)" "([^"]+)"', txt.split("\nTRACE\n", 1)[1].split("\nVALUE\n", 1)[0], re.M)
    recs = [numbers(r) for r in txt.split("\nVALUE\n", 1)[1].split('"relative frequency" ')[1:]]
    fm = np.array([r[0] for r in recs])
    out = np.array([r[-2] for r in recs])
    L = 10 * np.log10(out ** 2 / (a1 ** 2 / 2))
    # Contributions at 1 MHz, grouped by cell instance (stage numbers folded)
    r = recs[int(np.argmin(np.abs(fm - 1e6)))][1:]
    pos, groups, flick = 0, collections.Counter(), collections.Counter()
    for name, typ in traces:
        fields = structs.get(typ)
        n = len(fields) if fields else 1
        if fields and "total" in fields:
            v = dict(zip(fields, r[pos:pos + n]))
            key = re.sub(r'\.X[^./]*\.?XMM[NP]\d+\.m\d+$|\.XMM[NP]\d+\.m\d+$', '', name)
            key = re.sub(r'\.XXI\d+$', '', key)
            key = re.sub(r'stage_\d+', 'stage_*', key)
            groups[key] += v["total"]
            flick[key] += v.get("fn", 0.0)
        pos += n
    return f0, fm, L, groups, flick

def main():
    p = argparse.ArgumentParser()
    p.add_argument("--spectre", default=os.environ.get("SPECTRE", "spectre"), help="Spectre command")
    p.add_argument("--harms", type=int, default=40)
    p.add_argument("--parse-only", action="store_true")
    a = p.parse_args()
    fund = 1e9
    if os.path.exists("isf_setup.json"):
        fund = 1 / json.load(open("isf_setup.json"))["T"]
    raw = "test_dco_spectre.raw"
    if not a.parse_only:
        with open("test_dco_spectre.scs", "w") as f:
            f.write(netlist(fund, a.harms))
        cmd = f"{a.spectre} -format psfascii -raw {raw} test_dco_spectre.scs > test_dco_spectre.log 2>&1"
        if subprocess.run(cmd, shell=True, executable="/bin/bash").returncode != 0:
            sys.exit("Spectre failed, see test_dco_spectre.log")
    f0, fm, L, groups, flick = parse(raw)
    with open("test_dco_spectre.csv", "w") as f:
        f.write("freq,L_dBc_Hz\n")
        for x, y in zip(fm, L):
            f.write(f"{x:.6g},{y:.4f}\n")
    lines = [f"f0 = {f0/1e9:.6g} GHz (Spectre PSS)"]
    for fr in REPORT:
        i = int(np.argmin(np.abs(fm - fr)))
        lines.append(f"L({fm[i]:8.3g} Hz) = {L[i]:7.2f} dBc/Hz")
    tot = sum(groups.values())
    lines.append("\nTop contributors at 1 MHz (fraction of flicker):")
    for k, c in groups.most_common(8):
        lines.append(f"  {k:50s} {100*c/tot:5.1f} %  ({100*flick[k]/c:4.1f} % flicker)")
    print("\n".join(lines))
    with open("test_dco_spectre.txt", "w") as f:
        f.write("\n".join(lines) + "\n")

if __name__ == "__main__":
    main()
