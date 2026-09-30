#!/bin/bash
# final.sh ARM N [toolchain]: after the audit and scans ran on the complete log (post answer 3), mark validity final
case $1 in A) AD=arm-a;; B) AD=arm-b;; esac
W=/home/user/firth-r13/eval/s7; D=$W/runs/2026-09-30-check-forms/$AD/haiku-firth-$2
if [ "$3" = toolchain ]; then echo "toolchain: stopped $(date -u +%FT%TZ)" > $D/final.md
else [ -f $D/results-3.json ] || { echo "no results-3.json"; exit 1; }; echo "final $(date -u +%FT%TZ): audit and scans run on the complete log after answer 3 was scored" > $D/final.md; fi
if [ $1 = B ]; then cd $W && python3 runs/2026-09-30-check-forms/driver/bash_calls.py extract /tmp/claude-0/-home-user/8303955b-b8e6-5ad0-99b0-7583acb11fc5/tasks 2>&1 | tail -2; fi
echo "$1$2 final: $(cat $D/final.md)$( [ -f $D/void.md ] && echo "; VOID $(head -1 $D/void.md)")"
