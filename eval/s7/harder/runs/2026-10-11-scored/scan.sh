#!/bin/bash
# The raw-log part of the context scan of one scored author ("Context" in
# preregistration.md). context_seen.py --sample runs separately, in the same
# step, and writes context-seen.json; this adds the kinds of item injected,
# and a search for every other sample's name and agent id, task_status, task
# notifications, compaction, queued_command and project messages (outside the
# prompt_snapshot item, the session's tool list, whose descriptions name them).
# Its output for every author is kept in scan-output.txt.
#   scan.sh NAME AGENT_ID
#   scan.sh --self-test    (a planted log each clause must flag, and a clean one)
R=/home/user/firth-ds/eval/s7/harder/runs/2026-10-11-scored

scan() {  # scan NAME LABEL LOG IDS
  local NAME=$1 L=$3 IDS=$4
  local others names pat
  others=$(awk -v n="$NAME" '$1 != n {printf "%s|%s|", $1, $2}' "$IDS")
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
}

if [ "$1" = "--self-test" ]; then
  T=$(mktemp -d)
  printf 'haiku-firth-1 a240cd24227534291\nsonnet-python-1 ae558afd413328220\n' > "$T/ids"
  # Clean: own name, a tool list naming project messages, nothing else.
  cat > "$T/clean.jsonl" <<'EOF'
{"type":"user","message":{"content":"write haiku-firth-1/answer-1.md"}}
{"type":"attachment","attachment":{"type":"prompt_snapshot","text":"mcp__hearthbot__reply <wake cmsg_ABCDEFGHIJKLMNOPQRSTUV"}}
EOF
  got=$(scan haiku-firth-1 x "$T/clean.jsonl" "$T/ids" | sed -n 2p)
  want="  others: 0  task_status: 0  notification: 0  compact: 0  queued_command: 0  project message: 0"
  [ "$got" = "$want" ] || { echo "self-test FAILED on the clean log: $got"; exit 1; }
  # Planted: each line must raise its own count.
  for planted in 'sonnet-python-1 answer' 'agent ae558afd413328220' 'haiku-python-1/answer-1.md' \
                 'deepseek-firth-10 void' '"type":"task_status"' '<task-notification>' \
                 '"isCompactSummary":true' '"type":"queued_command"' 'cmsg_ABCDEFGHIJKLMNOPQRSTUV' \
                 '<wake reason=' 'mcp__hearthbot__reply'; do
    { cat "$T/clean.jsonl"; printf '{"type":"user","message":{"content":"%s"}}\n' "${planted//\"/\\\"}"; } > "$T/bad.jsonl"
    got=$(scan haiku-firth-1 x "$T/bad.jsonl" "$T/ids" | sed -n 2p)
    [ "$got" != "$want" ] || { echo "self-test FAILED: planted $planted not flagged"; exit 1; }
  done
  rm -r "$T"
  echo "self-test ok"
  exit 0
fi

scan "$1" "$2" "/root/.claude/projects/-home-user/14f4bbfb-4430-5764-b3e8-0fbaaa663891/subagents/agent-$2.jsonl" "$R/agent-ids.txt"
