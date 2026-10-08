"""
Summarizes a KLayout LVS database (.lvsdb): status of every circuit pair and, for the circuits
that do not match, the nets / devices / pins / subcircuits without a match.
Exits with 1 when any circuit does not match.
Usage: lvs_summary.py <report.lvsdb> [max items per circuit]
"""

import sys
from collections import Counter

import klayout.db as db

XREF = db.NetlistCrossReference
STATUS = {getattr(XREF, k): k.lower() for k in ("Match", "MatchWithWarning", "Mismatch", "NoMatch", "Skipped")}
OK = ("match", "matchwithwarning")

path = sys.argv[1]
max_items = int(sys.argv[2]) if len(sys.argv) > 2 else 20

lvs = db.LayoutVsSchematic()
lvs.read(path)
xref = lvs.xref()


def name(obj):
    if obj is None:
        return "-"
    if isinstance(obj, db.Net):
        return obj.expanded_name()
    if isinstance(obj, (db.Device, db.SubCircuit)):
        return obj.expanded_name()
    return obj.name()


bad = 0
counts = Counter()
for cp in xref.each_circuit_pair():
    a, b = cp.first(), cp.second()
    st = STATUS.get(cp.status(), "none")
    counts[st] += 1
    if st in OK:
        continue
    bad += 1
    print(f"Circuit {(a or b).name}: {st}" + ("" if a and b else (" (schematic only)" if not a else " (layout only)")))
    for kind, it in (("pin", xref.each_pin_pair), ("net", xref.each_net_pair),
                     ("device", xref.each_device_pair), ("subcircuit", xref.each_subcircuit_pair)):
        shown = 0
        for p in it(cp):
            pst = STATUS.get(p.status(), "none")
            if pst in OK:
                continue
            if shown < max_items:
                print(f"  {kind:<10} {pst:<16} layout={name(p.first())}  schematic={name(p.second())}")
            shown += 1
        if shown > max_items:
            print(f"  ... {shown - max_items} more {kind} mismatches")

print("LVS circuits: " + ", ".join(f"{n} {st}" for st, n in counts.most_common()))
print("LVS: " + ("MISMATCH" if bad else "MATCH"))
sys.exit(1 if bad else 0)
