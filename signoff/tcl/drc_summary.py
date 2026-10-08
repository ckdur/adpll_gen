"""
Prints the number of violations per rule of KLayout DRC report(s) (.lyrdb).
Exits with 1 when there is any violation.
Usage: drc_summary.py <report.lyrdb> [<report.lyrdb> ...]
"""

import sys
import xml.etree.ElementTree as ET
from collections import Counter

total = 0
for path in sys.argv[1:]:
    counts = Counter()
    for item in ET.parse(path).getroot().iter("item"):
        counts[item.findtext("category", "").strip("'")] += 1
    print(f"{path}: {sum(counts.values())} violations")
    for rule, n in sorted(counts.items()):
        print(f"  {rule:<30} {n}")
    total += sum(counts.values())

print(f"DRC total: {total} violations")
sys.exit(1 if total else 0)
