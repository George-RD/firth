#!/bin/bash
# multi.sh "A 2 1" "B 1 1" ... : step each, compact output
for s in "$@"; do set -- $s; echo "== $1$2 round $3"; /tmp/claude-0/r13/step.sh $1 $2 $3 2>&1 | grep -E "total|exit|FAIL|TOOLCHAIN|NO LOG|flag|CROSS" | sed -E 's/agents exit ([0-9]+).*/agents exit \1/' | cut -c1-300; done
