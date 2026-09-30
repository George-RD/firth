#!/bin/bash
# preflight.sh: run arm B's check in the authors' own shell environment (no PATH export) before starting authors
out=$(python3 /home/user/firth-r13/eval/s7/harness.py check --lang firth /tmp/claude-0/r13/scratch.md 2>&1)
if [ "$out" = "$(printf '## sum-list\nok')" ]; then echo "PREFLIGHT ok $(date -u +%T)"; else echo "PREFLIGHT FAILED: $out"; exit 1; fi
