#!/bin/bash
# round.sh ARM N ROUND : ARM is A or B; scores answer-ROUND of haiku-firth-N, writes repair-ROUND
set -e
W=/home/user/firth-r12; RD=$W/eval/s7/runs/2026-09-30-check-tool
case $1 in A) AD=arm-a;; B) AD=arm-b;; esac
cd $W; export PATH=$HOME/.elan/bin:$HOME/.cargo/bin:$PATH
D=$RD/$AD/haiku-firth-$2; R=$3; T=/tmp/claude-0/r12/new-$1-$2-$R.json
python3 eval/s7/harness.py extract $D/answer-$R.md > $T
if [ "$R" -gt 1 ]; then
  python3 -c "import json,sys;p=json.load(open(sys.argv[1]));n=json.load(open(sys.argv[2]));json.dump({**p,**n},open(sys.argv[3],'w'),indent=2)" $D/solutions-$((R-1)).json $T $D/solutions-$R.json
else cp $T $D/solutions-$R.json; fi
python3 eval/s7/harness.py score --lang firth --tier mvp $D/solutions-$R.json --label "run 12 $AD firth $2 round $R" --prompt-docs "prompt --tier mvp --rounds 2 at $(git rev-parse --short HEAD), $AD" --jobs 4 > $D/results-$R.json
if grep -qE 'toolchain:|lake: exit|cargo: exit|is not available' $D/results-$R.json; then echo "TOOLCHAIN TEXT in $D/results-$R.json"; exit 3; fi
python3 eval/s7/harness.py report $D/results-$R.json | tail -1
if [ "$R" -lt 3 ]; then python3 eval/s7/harness.py repair $D/solutions-$R.json $D/results-$R.json --lang firth --tier mvp > $D/repair-$R.md; fi
