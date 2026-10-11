#!/bin/bash
# Rescore every kept sample of this run from a checkout of the pin (coordinator's
# instruction: the reported results are the pin's scores, compared with the live
# ones). For each sample directory not listed in voids.txt, and each round it has
# an answer file for, runs `tier.py take` and `tier.py score` from the pin
# checkout, exactly as the run did (round 2 takes `--after` the rescored round 1),
# then compares the rescored results with the live ones.
#   rescore.sh PIN_CHECKOUT OUT_DIR [NAME ...]   (names: only those samples)
#   rescore.sh --self-test   (planted differences the comparison must report)
# PIN_CHECKOUT is a built checkout of 627a0eb. OUT_DIR receives
# NAME/{solutions,results}-N.json and compare.txt.
set -e
R=$(cd "$(dirname "$0")" && pwd)

compare() {  # compare RUN_DIR OUT_DIR
  python3 - "$1" "$2" <<'PY'
# Same solutions, and the same per-task and per-case results, live versus pin.
import json, sys
from pathlib import Path
R, OUT = Path(sys.argv[1]), Path(sys.argv[2])
same = diff = 0
for d in sorted(p for p in OUT.iterdir() if p.is_dir()):
    for f in sorted(d.glob("*-[12].json")):
        live, pin = json.loads((R / d.name / f.name).read_text()), json.loads(f.read_text())
        header = True
        if f.name.startswith("results"):
            for k in ("eval_sha256", "fuel", "lang"):
                if live.get(k) != pin.get(k):
                    print("HEADER DIFFERS", d.name, f.name, k)
                    header = False
            live, pin = live["tasks"], pin["tasks"]
        if header and live == pin:
            same += 1
        else:
            diff += 1
            print("DIFFERS", d.name, f.name)
print(f"files identical: {same}, differing: {diff}")
PY
}

if [ "$1" = "--self-test" ]; then
  T=$(mktemp -d)
  mkdir -p "$T/run/s-firth-1" "$T/out/s-firth-1"
  printf '%s' '{"lang": "firth", "fuel": 1000000, "eval_sha256": "e", "tasks": {"a": {"pass": true, "cases": [{"pass": true, "kernel_cost": 5}]}}}' > "$T/run/s-firth-1/results-1.json"
  printf '%s' '{"a": "code"}' > "$T/run/s-firth-1/solutions-1.json"
  cp "$T/run/s-firth-1/"* "$T/out/s-firth-1/"
  compare "$T/run" "$T/out" | grep -x "files identical: 2, differing: 0" >/dev/null || { echo "self-test FAILED on identical files"; exit 1; }
  # Planted: a flipped pass, a changed cost, a changed solution, a changed header.
  for plant in 's/"pass": true, "cases"/"pass": false, "cases"/' 's/"kernel_cost": 5/"kernel_cost": 6/' 's/1000000/999/'; do
    sed "$plant" "$T/run/s-firth-1/results-1.json" > "$T/out/s-firth-1/results-1.json"
    compare "$T/run" "$T/out" | grep -x "files identical: 1, differing: 1" >/dev/null || { echo "self-test FAILED: planted $plant not counted as differing"; exit 1; }
  done
  cp "$T/run/s-firth-1/results-1.json" "$T/out/s-firth-1/"
  printf '%s' '{"a": "other code"}' > "$T/out/s-firth-1/solutions-1.json"
  compare "$T/run" "$T/out" | grep "DIFFERS s-firth-1 solutions-1.json" >/dev/null || { echo "self-test FAILED: changed solution not reported"; exit 1; }
  rm -r "$T"
  echo "self-test ok"
  exit 0
fi

PIN=$1; OUT=$2; shift 2; ONLY="$*"
mkdir -p "$OUT"; OUT=$(cd "$OUT" && pwd)  # tier.py runs from the pin checkout
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
compare "$R" "$OUT" | tee "$OUT/compare.txt"
