#!/bin/bash
# step.sh ARM SAMPLE N : score round N, then audit the transcript so far
case $1 in A) W=/home/user/firth-r8; H=4c379e0;; B) W=/home/user/firth-v9; H=8ea4a1d;; esac
RD=$W/eval/s7/runs/2026-09-29-control/$H; D=$RD/haiku-firth-$2
ID=$(awk -v a=$1 -v s=$2 '$1==a && $2==s {print $3}' /tmp/claude-0/ctl/ids.txt)
LOG=/tmp/claude-0/-home-user/52ce2f0f-c938-5174-b4d9-61188f8fa29f/tasks/$ID.output
/tmp/claude-0/ctl/round.sh $1 haiku-firth-$2 $3 || { echo "ROUND FAILED $?"; exit 1; }
cd /home/user/firth-res/eval/s7
python3 audit_subagent.py $LOG --prompt $RD/prompt-firth.md --dir $D --rounds 2 --lang firth > $D/transcript.json 2>/tmp/claude-0/ctl/audit-$1-$2.err; echo "audit exit $?"; head -c 600 /tmp/claude-0/ctl/audit-$1-$2.err
python3 runs/2026-09-29-control/seen_agents.py $LOG /home/user/firth 7c89481 43c994c > $D/agents-seen.json; echo "agents exit $? $(tr -d ' \n' < $D/agents-seen.json)"
[ "$3" -lt 3 ] && echo "multi: $(grep -c 'The checker found [0-9]* errors' $D/repair-$3.md)"
true
