#!/bin/bash
# The context scan of every pool-3 author raw log, as run for this record.
# context_seen.py runs without --sample: on this commit it fails on a
# Sonnet sample name (todo.s7-harder-task-tier). The grep for the
# other five authors names and agent ids is the cross-sample check.
cd /home/user/firth
R=${R:?set R to a scratch directory}
L=/root/.claude/projects/-home-user/14f4bbfb-4430-5764-b3e8-0fbaaa663891/subagents
declare -A IDS=([python-1]=aa2de9a5c94f4d9a2 [firth-1]=a4e88a145507cb10c [python-2]=aca5bf88e596fa35f [firth-2]=acac0e40ea7d0803f [python-3]=ac80da00711a58d00 [firth-3]=a3e049c55ef1465a8)
for k in "${!IDS[@]}"; do
  f=$L/agent-${IDS[$k]}.jsonl
  python3 eval/s7/context_seen.py $f > $R/sonnet-$k/context-seen.json; echo "$k context_seen exit $?"
  others=""
  for o in "${!IDS[@]}"; do [ $o != $k ] && others="$others|sonnet-$o|${IDS[$o]}"; done
  echo "  others: $(grep -cE "${others:1}" $f)  task_status: $(grep -c task_status $f)  notification: $(grep -c task-notification $f)  compact: $(grep -ciE '"compact|isCompactSummary' $f)  queued_command: $(grep -c queued_command $f)  George: $(grep -c 'George' $f)"
  python3 -c "
import json,collections
c=collections.Counter(json.loads(l).get('attachment',{}).get('type') for l in open('$f') if json.loads(l).get('type')=='attachment')
print('  attachments:',dict(c))"
done
