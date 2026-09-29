#!/bin/bash
# round.sh ARM SAMPLE N : ARM is A (4c379e0) or B (8ea4a1d)
set -e
case $1 in A) W=/home/user/firth-r8; H=4c379e0;; B) W=/home/user/firth-v9; H=8ea4a1d;; esac
cd $W; export PATH=$HOME/.elan/bin:$HOME/.cargo/bin:$PATH
D=eval/s7/runs/2026-09-29-control/$H/$2; N=$3; T=/tmp/claude-0/ctl/new-$1-$2-$N.json
python3 eval/s7/harness.py extract $D/answer-$N.md > $T
if [ "$N" -gt 1 ]; then
  python3 -c "import json,sys;p=json.load(open(sys.argv[1]));n=json.load(open(sys.argv[2]));json.dump({**p,**n},open(sys.argv[3],'w'),indent=2)" $D/solutions-$((N-1)).json $T $D/solutions-$N.json
else cp $T $D/solutions-$N.json; fi
python3 eval/s7/harness.py score --lang firth --tier mvp $D/solutions-$N.json --label "control $H firth $2 round $N" --prompt-docs "prompt --tier mvp --rounds 2 at $H" --jobs 4 > $D/results-$N.json
if grep -qE 'toolchain:|lake: exit|cargo: exit|is not available' $D/results-$N.json; then echo "TOOLCHAIN TEXT in $D/results-$N.json"; exit 3; fi
python3 eval/s7/harness.py report $D/results-$N.json | tail -1
if [ "$N" -lt 3 ]; then python3 eval/s7/harness.py repair $D/solutions-$N.json $D/results-$N.json --lang firth --tier mvp > $D/repair-$N.md; fi
