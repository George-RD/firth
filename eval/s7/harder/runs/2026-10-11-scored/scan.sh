#!/bin/bash
# The context scan of one scored author's raw log ("Context" in
# preregistration.md): context_seen.py --sample, the kinds of item injected,
# and a search for every other sample's name and agent id, task_status, task
# notifications, compaction, queued_command and project messages (outside the
# prompt_snapshot item, the session's tool list, whose descriptions name them).
#   scan.sh NAME AGENT_ID
R=/home/user/firth-ds/eval/s7/harder/runs/2026-10-11-scored
L=/root/.claude/projects/-home-user/14f4bbfb-4430-5764-b3e8-0fbaaa663891/subagents/agent-$2.jsonl
NAME=$1
others=$(awk -v n="$NAME" '$1 != n {printf "%s|%s|", $1, $2}' "$R/agent-ids.txt")
# every planned sample name except this one, run or not
names=$(for s in sonnet deepseek haiku; do for l in python firth; do for i in $(seq 1 11); do
  [ "$s-$l-$i" != "$NAME" ] && printf '%s-%s-%s([^0-9]|$)|' $s $l $i; done; done; done)
pat="${others}${names%|}"
echo "$NAME ($2)"
echo "  others: $(grep -cE "$pat" "$L")  task_status: $(grep -c task_status "$L")  notification: $(grep -c task-notification "$L")  compact: $(grep -ciE '"compact|isCompactSummary' "$L")  queued_command: $(grep -c queued_command "$L")  project message: $(grep -v '"type":"prompt_snapshot"' "$L" | grep -cE 'mcp__hearthbot__reply|<wake |cmsg_[A-Za-z0-9]{20}')"
python3 - "$L" <<'PY'
import json, collections, sys
c = collections.Counter()
for line in open(sys.argv[1]):
    o = json.loads(line)
    if o.get("type") == "attachment":
        c[o.get("attachment", {}).get("type")] += 1
print("  attachments:", dict(c))
PY
