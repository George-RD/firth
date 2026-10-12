#!/usr/bin/env python3
"""Lists every task a kept Sonnet Firth author failed in round 1 of this run,
with what failed it: the checker's first code on the visible example, or the
trap on the first failing hidden case when the visible example passed. Reads
the pin rescore (`rescore-pin/`, the reported results) and `voids.txt`.

    python3 sonnet_firth_r1.py > sonnet-firth-r1.txt
"""
import json
import re
from collections import Counter
from pathlib import Path

RUN = Path(__file__).resolve().parent
void = {l.split()[0] for l in (RUN / "voids.txt").read_text().splitlines() if l and not l.startswith("#")}
rows = []
for d in sorted((RUN / "rescore-pin").glob("sonnet-firth-*")):
    if d.name in void:
        continue
    for task, v in json.loads((d / "results-1.json").read_text())["tasks"].items():
        if v.get("pass"):
            continue
        cases = v.get("cases", [])
        vis = next((c for c in cases if c.get("visible")), {})
        if vis.get("pass"):
            bad = next(c for c in cases if not c.get("pass"))
            trap = re.search(r"trap (\S+)", bad.get("error") or "")
            cause = f"ran: trap {trap[1]}" if trap else f"ran: wrong result"
        else:
            code = re.search(r"code: (\S+)", vis.get("error") or "")
            cause = f"refused: {code[1]}" if code else f"failed: {(vis.get('error') or 'no answer')[:60]}"
        rows.append((d.name, task, cause))
for r in rows:
    print("\t".join(r))
print(f"\n{len(rows)} tasks failed in round 1")
for cause, n in Counter(c for _, _, c in rows).most_common():
    print(f"{n}\t{cause}")
