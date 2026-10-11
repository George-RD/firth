#!/usr/bin/env bash
# Reruns every fix check cited in the notes in readings.json.
# usage: checks.sh RUN PIN   (RUN = run dir, PIN = pin checkout); exits nonzero on any unexpected result
#        checks.sh --self-test RUN PIN   (planted results each runner must reject)
set -euo pipefail
H=$(cd "$(dirname "$0")" && pwd)
if [ "$1" = "--self-test" ]; then  # checks.sh --self-test RUN PIN: planted results each runner must reject
  RUN=$2; PIN=$3
  ! python3 "$H/run.py" "$RUN" "$PIN" sonnet-python-6 1 sokoban 3,8 || { echo "self-test FAILED: unpatched answer accepted"; exit 1; }
  ! python3 "$H/run.py" --expect-fail "$RUN" "$PIN" sonnet-python-6 1 sokoban 3,8 'boxes[k] = player + d' 'boxes[k] = player' || { echo "self-test FAILED: --expect-fail accepted a fix"; exit 1; }
  ! python3 "$H/run.py" "$RUN" "$PIN" deepseek-python-9 1 regex 9,12,14,16,20,21,25 'for r in m(s, q):' 'for r in m(q):' 'first = m(s, p)' 'first = m(p)' 'res |= m(s, p)' 'res |= m(p)' || { echo "self-test FAILED: a failing visible example accepted"; exit 1; }
  python3 -c 'import json,sys; print(json.load(open(sys.argv[1]))["swiss"])' "$RUN/rescore-pin/sonnet-firth-1/solutions-1.json" > "$H/.sf1-swiss.firth"
  ! python3 "$H/runfirth.py" "$RUN" "$PIN" "$H/.sf1-swiss.firth" sonnet-firth-1 1 swiss 16 || { rm -f "$H/.sf1-swiss.firth"; echo "self-test FAILED: unfixed Firth answer accepted"; exit 1; }
  rm -f "$H/.sf1-swiss.firth"
  echo "self-test ok"; exit 0
fi
RUN=$1; PIN=$2
py() { python3 "$H/run.py" "$RUN" "$PIN" "$@"; }
fr() { python3 "$H/runfirth.py" "$RUN" "$PIN" "$@"; }

# deepseek-python-5 r1 checkers: drop zero-jump captures
py deepseek-python-5 1 checkers 4,7,8,9,10,11,12,13,14,15,16,17,18 $'            if not moves:\n                final_b' $'            if not moves and captured_count == 0:\n                return\n            if not moves:\n                final_b'
# deepseek-python-5 r1 regex: no fix run; unpatched rerun shows the crash on every listed case
py --expect-fail deepseek-python-5 1 regex 8,9,10,11,12,13,14,15,16,17,18,19,20,21,22,23,25
# deepseek-python-6 r1 checkers: crown white on row 0 (< 4), not rows 0-1 (< 8)
py deepseek-python-6 1 checkers 13 'piece == 1 and l < 8' 'piece == 1 and l < 4' 'val == 1 and t < 8' 'val == 1 and t < 4'
# deepseek-python-9 r1 regex, operator trace: operator call fix alone fixes 9,12,14,16,20,21,25
py --visible-may-fail deepseek-python-9 1 regex 9,12,14,16,20,21,25 'for r in m(s, q):' 'for r in m(q):' 'first = m(s, p)' 'first = m(p)' 'res |= m(s, p)' 'res |= m(p)'
# deepseek-python-9 r1 regex: operator + group fixes together fix 13,15,17,18 and the group trace's case 23
py deepseek-python-9 1 regex 13,15,17,18,23 'for r in m(s, q):' 'for r in m(q):' 'first = m(s, p)' 'first = m(p)' 'res |= m(s, p)' 'res |= m(p)' "return ('alt', alt)" 'return alt'
# haiku-firth-4 r2 sokoban/checkers: placeholders, no fix (see answer-2.md NOTE lines)
n=$(grep -c '^NOTE: Placeholder' "$RUN/haiku-firth-4/answer-2.md"); echo "$n"; [ "$n" = 6 ]
# sonnet-firth-1 r1 regex case 25: one 12-letter string is correct but costs vm_cost ~366k
( cd "$PIN" && python3 -c 'import json,sys; print(json.load(open(sys.argv[1]))["regex"])' "$RUN/rescore-pin/sonnet-firth-1/solutions-1.json" > "$H/.sf1-regex.firth" && python3 tools/loop/firth_run.py run "$H/.sf1-regex.firth" --entry main --stack '[[0,27,0,27,0,27,0,27,0,27,0,27,0,27,0,27,0,27,0,27],[12],[0,0,0,0,0,0,0,0,0,0,0,0]]' --fuel 1000000 | python3 -c 'import json,sys; sys.path.insert(0, "eval/s7/harder"); import scored
o=json.load(sys.stdin); print("sonnet-firth-1 r1 regex one-string:", o["status"], o["stack"], "vm_cost", o["vm_cost"])
want=json.loads(json.dumps(list(scored._regex([0,27,0,27,0,27,0,27,0,27,0,27,0,27,0,27,0,27,0,27],[12],[0]*12))))
sys.exit(0 if o["status"] == "success" and o["stack"] == want and 8 * o["vm_cost"] > 1000000 else 1)' ); rm -f "$H/.sf1-regex.firth"
# sonnet-firth-1 r1 swiss: state sequence 240 -> 260
fr "$H/sf1-swiss-260.firth" sonnet-firth-1 1 swiss 16
# sonnet-firth-2 r1 swiss: state sequence 300 -> 320
fr "$H/sf2-swiss-320.firth" sonnet-firth-2 1 swiss 16
# sonnet-firth-6 r2 regex: string count moved from slot 25 to 99
fr "$H/sf6-regex-fix.firth" sonnet-firth-6 2 regex 0,9,10,12,13,14,15,16,17,18,19,20,21,22,23,24,25
# sonnet-python-6 r1 sokoban: undo moves the box back to the worker's cell
py sonnet-python-6 1 sokoban 3,8 'boxes[k] = player + d' 'boxes[k] = player'
# sonnet-python-7 r1 checkers: clear the square jumped from during a multi-jump
py sonnet-python-7 1 checkers 3,6,7,8,13,14 $'                bd[li] = newp\n                lands.append(li)' $'                bd[li] = newp\n                _ci = idx(r, c); _old = bd[_ci]; bd[_ci] = 0\n                lands.append(li)' $'                lands.pop()\n                bd[li] = 0' $'                lands.pop()\n                bd[_ci] = _old\n                bd[li] = 0'
