#!python

# Generates the ngspice runs for the ISF (impulse sensitivity function) phase-noise
# analysis of the DCO (Hajimiri & Lee). See isf_phase_noise.py for the analysis.
#
# Two steps (run inside sim/outputs/<PDK>):
#
# 1. python3 ../../src/create_isf.py wave --twarm 15n --len 5n
#    Writes test_dco_isf_wave.sp: the DCO in steady state, saving every node,
#    from twarm to twarm+len. Run it with ngspice.
#
# 2. python3 ../../src/create_isf.py runs --twarm 15n --nphase 128 --nper 3 --dq 50e-18
#    Using test_dco_isf_wave.raw, writes:
#    - isf_ref.sp: the same DCO with a zero injection, saving only OUT
#    - isf_node<i>.sp: one per oscillating net of the DCO, injecting a small charge
#      dq at nphase different phases of the period, one injection every nper periods
#    - isf_lut<i>.sp: the drain current noise of each kind of transistor, over a Vgs/Vds grid
#    - isf_runs.txt: the list of the runs (without the .sp)
#    - isf_setup.json: everything the analysis needs

import argparse, json, re, sys
from spice_io import read_raw
from spice_netlist import Netlist

TB = "test_dco.sp"          # The DCO testbench (fixed codes)
DUT = "PLL_ILDCO.sp"        # The netlist of the DCO
DUT_INST = "xdco"           # Instance of the DCO in the testbench
OUT = "out"                 # Oscillator output used as phase reference
NMOS = r'^(nm\w*_lp|sg13_\w+_nmos)$'   # Transistor wrappers (d g s b) of the PDKs
PMOS = r'^(pm\w*_lp|sg13_\w+_pmos)$'
LUT_POINTS = 13             # Vgs and Vds points of the noise tables

def spice_num(s):
    m = re.fullmatch(r'([-+]?[\d.]+(?:e[-+]?\d+)?)(meg|[fpnumkgt]?)\w*', s.strip("'{} ").lower())
    if not m:
        raise ValueError(s)
    scale = {"": 1, "f": 1e-15, "p": 1e-12, "n": 1e-9, "u": 1e-6, "m": 1e-3,
             "k": 1e3, "meg": 1e6, "g": 1e9, "t": 1e12}[m.group(2)]
    return float(m.group(1)) * scale

def device_kind(master):
    if re.match(NMOS, master, re.I):
        return "n"
    if re.match(PMOS, master, re.I):
        return "p"
    return None

def device_key(d):
    """Devices with the same model and parameters (except the multiplier) share a noise table"""
    params = []
    for k, v in sorted(d["params"].items()):
        if k == "m":
            continue
        try:
            v = "%.6g" % spice_num(v)
        except ValueError:
            pass
        params.append(f"{k}={v}")
    return d["master"] + " " + " ".join(params)

def crossings(t, v, th):
    import numpy as np
    i = np.where((v[:-1] < th) & (v[1:] >= th))[0]
    return t[i] + (th - v[i]) * (t[i + 1] - t[i]) / (v[i + 1] - v[i])

def tb_text():
    with open(TB) as f:
        return f.read()

def temperature(text):
    m = re.search(r'^\.TEMP\s+(\S+)', text, re.M | re.I)
    return m.group(1) if m else "27"

def control(raw, saves):
    return f"""
.SAVE {saves}
.control
run
write {raw}
quit
.endc
.end
"""

def cmd_wave(args):
    text = f"""* DCO steady-state waveforms for the ISF phase-noise analysis
.inc {TB}
.TRAN 1p {args.twarm + args.len:g} {args.twarm:g} uic
.control
run
write test_dco_isf_wave.raw
quit
.endc
.end
"""
    with open("test_dco_isf_wave.sp", "w") as f:
        f.write(text)
    print("Written test_dco_isf_wave.sp")

def cmd_runs(args):
    import numpy as np
    wave = read_raw("test_dco_isf_wave.raw")
    t = wave["time"]
    vdd = float(np.max(wave["v(vdd)"]))
    th = vdd / 2
    edges = crossings(t, wave[f"v({OUT})"], th)
    T = float(np.median(np.diff(edges)))
    print(f"f0 = {1/T/1e9:.6g} GHz, vdd = {vdd:g}")

    # Nets of the DCO that oscillate (only the ones of the DCO netlist level, not inside the cells)
    tb = Netlist("test_dco.sp")
    devs = [d for d in tb.devices(device_kind) if d["name"].startswith(DUT_INST + ".")]
    dut = tb.subckts[DUT[:-3].lower()]
    inst = next(s for s in tb.top if s.split()[0].lower() == DUT_INST)
    conns = inst.split()[1:1 + len(dut[0])]
    port_of = {c.lower(): p for p, c in zip(dut[0], conns)}

    nodes = []
    for n in sorted({n for d in devs for n in (d["d"], d["s"])}):
        v = wave.get(f"v({n})")
        if v is None or np.ptp(v) < th:
            continue
        if n.startswith(DUT_INST + "."):
            local = n[len(DUT_INST) + 1:]
            if "." in local:
                continue    # Inside a cell
        elif n in port_of:
            local = port_of[n]
        else:
            continue
        nodes.append((n, local))
    print(f"{len(nodes)} oscillating nets: {' '.join(n for n, _ in nodes)}")

    # Injection times: nphase phases, one every nper periods, after twarm
    tw = 1e-12      # Width of the injected current pulse
    tr = 0.1e-12
    t0 = edges[0]
    k0 = int(np.ceil((args.twarm - t0) / T)) + 1
    tinj = [t0 + (k0 + k * args.nper + k / args.nphase) * T for k in range(args.nphase)]
    tstop = tinj[-1] + (args.nper + 1) * T

    text = tb_text()
    if not re.search(r'^\.inc\s+' + re.escape(DUT) + r'\s*$', text, re.M | re.I):
        sys.exit(f"{TB} does not include {DUT}")
    tran = f".TRAN 1p {tstop:.6g} uic\n"

    with open(DUT) as f:
        dut_text = f.read()
    end = re.search(r'^\.ENDS\b.*$', dut_text, re.M | re.I)

    def write_run(name, title, local, current):
        pwl = ["0 0"]
        for ti in tinj:
            pwl.append(f"{ti:.6e} 0 {ti + tr:.6e} {current:.6g} {ti + tw - tr:.6e} {current:.6g} {ti + tw:.6e} 0")
        pwl = "\n+ ".join(pwl)
        # The current source goes inside the DCO subcircuit, to reach its internal nets
        inj = f"* ISF injection of {current * tw:g} C into {local}\nIisf VSS {local} PWL(\n+ {pwl})\n"
        with open(f"{name}_dut.sp", "w") as f:
            f.write(dut_text[:end.start()] + inj + dut_text[end.start():])
        tbn = re.sub(r'^\.inc\s+' + re.escape(DUT) + r'\s*$', f".inc {name}_dut.sp", text, flags=re.M | re.I)
        with open(f"{name}.sp", "w") as f:
            f.write(f"* {title}\n{tbn}\n{tran}" + control(f"{name}.raw", f"V({OUT})"))
        runs.append(name)

    # The reference has the same source with zero current: the breakpoints of the pulses
    # alone shift the edges ~100fs (numerical), and this way they cancel out
    runs = []
    write_run("isf_ref", "ISF reference run (zero injection)", nodes[0][1], 0.0)
    for i, (n, local) in enumerate(nodes):
        write_run(f"isf_node{i}", f"ISF injection into {n}", local, args.dq / tw)

    # Noise tables of the drain current of each kind of transistor
    kinds = {}
    for d in devs:
        kinds.setdefault(device_key(d), d)
    luts = []
    grid = np.linspace(0, vdd, LUT_POINTS)
    for i, (key, d) in enumerate(sorted(kinds.items())):
        name = f"isf_lut{i}"
        sign = 1 if d["type"] == "n" else -1
        params = " ".join(f"{k}={v}" for k, v in d["params"].items() if k != "m")
        vals = " ".join(f"{sign * v:.6g}" for v in grid)
        with open(f"{name}.sp", "w") as f:
            f.write(f"""* Drain current noise of {key}
* Output: lut_vgs, lut_vds and the spectrum of the drain current noise (A/sqrt(Hz)) for each point
.TEMP {temperature(text)}
.inc models.inc
Vg g 0 DC 0 AC 1
Vd d 0 DC 0
Vsense d dd 0
X1 dd g 0 0 {d['master']} {params}
H1 out 0 Vsense 1
.control
foreach vg {vals}
  foreach vd {vals}
    alter vg dc = $vg
    alter vd dc = $vd
    let lut_vgs = $vg
    let lut_vds = $vd
    print lut_vgs lut_vds
    noise v(out) vg dec 1 1e3 1e10
    setplot previous
    print onoise_spectrum
    destroy all
  end
end
quit
.endc
.end
""")
        runs.append(name)
        luts.append(dict(name=name, key=key, type=d["type"]))

    with open("isf_runs.txt", "w") as f:
        f.write("\n".join(runs) + "\n")
    setup = dict(T=T, vdd=vdd, out=OUT, dq=args.dq, tinj=tinj, nper=args.nper,
                 nodes=[dict(name=f"isf_node{i}", net=n) for i, (n, _) in enumerate(nodes)],
                 luts=luts,
                 devices=[dict(name=d["name"], type=d["type"], key=device_key(d),
                               m=spice_num(d["params"].get("m", "1")),
                               d=d["d"], g=d["g"], s=d["s"]) for d in devs])
    with open("isf_setup.json", "w") as f:
        json.dump(setup, f, indent=1)
    print(f"Written {len(runs)} runs ({len(nodes)} injections, {len(luts)} noise tables), tstop = {tstop:.4g}")

parser = argparse.ArgumentParser()
parser.add_argument("step", choices=["wave", "runs"])
parser.add_argument("--twarm", type=spice_num, default=15e-9, help="Time to reach the steady state")
parser.add_argument("--len", type=spice_num, default=5e-9, help="Length of the steady-state waveforms")
parser.add_argument("--nphase", type=int, default=128, help="Points of the ISF per period")
parser.add_argument("--nper", type=int, default=3, help="Periods between injections")
parser.add_argument("--dq", type=spice_num, default=50e-18, help="Injected charge (C)")
args = parser.parse_args()
{"wave": cmd_wave, "runs": cmd_runs}[args.step](args)
