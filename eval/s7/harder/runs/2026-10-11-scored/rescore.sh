#!/bin/bash
# Rescore every kept sample of this run from a checkout of the pin (coordinator's
# instruction: the reported results are the pin's scores, compared with the live
# ones). For each sample directory not listed in voids.txt, and each round it has
# an answer file for, runs `tier.py take` and `tier.py score` from the pin
# checkout, exactly as the run did (round 2 takes `--after` the rescored round 1),
# then compares the rescored results with the live ones.
#   rescore.sh PIN_CHECKOUT OUT_DIR [NAME ...]   (names: only those samples)
# PIN_CHECKOUT is a built checkout of 627a0eb. OUT_DIR receives
# NAME/{solutions,results}-N.json and compare.txt.
set -e
PIN=$1; OUT=$2; shift 2; ONLY="$*"
R=$(cd "$(dirname "$0")" && pwd)
[ "$(git -C "$PIN" rev-parse HEAD)" = 627a0ebf59eb18839e54b9bb20f25353108a1a09 ] || { echo "not a checkout of the pin"; exit 1; }
T=$PIN/eval/s7/harder/tier.py
mkdir -p "$OUT"
for D in "$R"/*/; do
  NAME=$(basename "$D")
  [ -f "$D/answer-1.md" ] || continue
  grep -q "^$NAME " "$R/voids.txt" && continue
  [ -z "$ONLY" ] || [[ " $ONLY " == *" $NAME "* ]] || continue
  case $NAME in *-python-*) LANG=python;; *) LANG=firth;; esac
  mkdir -p "$OUT/$NAME"
  for N in 1 2; do
    [ -f "$D/answer-$N.md" ] || continue
    if [ "$N" = 1 ]; then
      ( cd "$PIN" && python3 "$T" take --set scored "$D/answer-1.md" ) > "$OUT/$NAME/solutions-1.json"
    else
      ( cd "$PIN" && python3 "$T" take --set scored "$D/answer-2.md" --after "$OUT/$NAME/solutions-1.json" "$OUT/$NAME/results-1.json" ) > "$OUT/$NAME/solutions-2.json"
    fi
    ( cd "$PIN" && python3 "$T" score --set scored --lang $LANG "$OUT/$NAME/solutions-$N.json" --label "$NAME-r$N" ) > "$OUT/$NAME/results-$N.json"
  done
done
python3 - "$R" "$OUT" <<'PY' | tee "$OUT/compare.txt"
# Same solutions, and the same per-task and per-case results, live versus pin.
import json, sys
from pathlib import Path
R, OUT = Path(sys.argv[1]), Path(sys.argv[2])
same = diff = 0
for d in sorted(p for p in OUT.iterdir() if p.is_dir()):
    for f in sorted(d.glob("*-[12].json")):
        live, pin = json.loads((R / d.name / f.name).read_text()), json.loads(f.read_text())
        if f.name.startswith("results"):
            for k in ("eval_sha256", "fuel", "lang"):
                if live.get(k) != pin.get(k):
                    print("HEADER DIFFERS", d.name, f.name, k)
            live, pin = live["tasks"], pin["tasks"]
        if live == pin:
            same += 1
        else:
            diff += 1
            print("DIFFERS", d.name, f.name)
print(f"files identical: {same}, differing: {diff}")
PY
