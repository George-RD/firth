#!/bin/bash
# adv.sh ARM N : score the newest unscored answer of a sample, then print the next feedback text if any
case $1 in A) AD=arm-a;; B) AD=arm-b;; esac
D=/home/user/firth-r13/eval/s7/runs/2026-09-30-check-forms/$AD/haiku-firth-$2
for R in 1 2 3; do [ -f $D/answer-$R.md ] && [ ! -f $D/results-$R.json ] && break; R=; done
[ -n "$R" ] || { echo "$1$2: nothing to score"; exit 1; }
/tmp/claude-0/r13/multi.sh "$1 $2 $R"
[ "$R" -lt 3 ] && { echo "--- feedback:"; python3 /tmp/claude-0/r13/fb.py $1 $2 $R; }
true
