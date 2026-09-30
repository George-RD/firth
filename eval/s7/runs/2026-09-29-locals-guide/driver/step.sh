#!/bin/bash
# step.sh ARM N ROUND : score round ROUND, then audit and scan the log so far
W=/home/user/firth-r11; RD=$W/eval/s7/runs/2026-09-29-locals-guide
case $1 in A) AD=arm-a;; B) AD=arm-b;; esac
D=$RD/$AD/haiku-firth-$2
ID=$(awk -v a=$1 -v s=$2 '$1==a && $2==s {print $3}' /tmp/claude-0/r11/ids.txt)
LOG=$(ls /tmp/claude-0/-home-user*/*/tasks/$ID.output 2>/dev/null | head -1)
[ -f "$LOG" ] || { echo "NO LOG for $ID"; exit 1; }
/tmp/claude-0/r11/round.sh $1 $2 $3 || { echo "ROUND FAILED $?"; exit 1; }
cd $W/eval/s7
python3 audit_subagent.py $LOG --prompt $RD/$AD/prompt-firth.md --dir $D --rounds 2 --lang firth > $D/transcript.json 2>/tmp/claude-0/r11/audit-$1-$2.err; echo "audit exit $?"; head -c 600 /tmp/claude-0/r11/audit-$1-$2.err
python3 runs/2026-09-29-control/seen_agents.py $LOG $W $(cat /tmp/claude-0/r11/blobs.txt) > $D/agents-seen.json; echo "agents exit $? $(tr -d ' \n' < $D/agents-seen.json)"
python3 context_seen.py $LOG --arm-set run11 --arm $AD --sample haiku-firth-$2 --label $1$2 > $D/context-seen.json 2>/tmp/claude-0/r11/ctx-$1-$2.err; echo "context exit $?"; head -c 400 /tmp/claude-0/r11/ctx-$1-$2.err
true
