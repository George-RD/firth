"""Rerun a Python answer, with optional text patches, against the reference.

usage: run.py [--expect-fail] [--visible-may-fail] RUN PIN SAMPLE ROUND TASK CASES [OLD NEW]...
RUN is the run dir (solutions/results read from RUN/rescore-pin/SAMPLE),
PIN the pin checkout (reference from PIN/eval/s7/harder/scored.py),
CASES a comma-separated list of case indices to report.
Prints one line: which of CASES now match the expected output, and the
visible example's status. Exits 1 unless every case in CASES matches and the
visible example passes; with --expect-fail, unless every case in CASES fails;
--visible-may-fail drops the visible example from the verdict.
"""
import json, sys
args = sys.argv[1:]
expect_fail = "--expect-fail" in args
visible_may_fail = "--visible-may-fail" in args
args = [a for a in args if a not in ("--expect-fail", "--visible-may-fail")]
run, pin, sample, rnd, task, cases = args[:6]
patch = args[6:]
assert len(patch) % 2 == 0, "patches come in OLD NEW pairs"
sys.path.insert(0, f"{pin}/eval/s7/harder")
import scored
src = json.load(open(f"{run}/rescore-pin/{sample}/solutions-{rnd}.json"))[task]
for i in range(0, len(patch), 2):
    assert patch[i] in src, f"patch text not found: {patch[i]!r}"  # every occurrence is replaced
    src = src.replace(patch[i], patch[i + 1])
g = {}
exec(src, g)
ref = getattr(scored, "_" + task.replace("-", "_"))
cs = json.load(open(f"{run}/rescore-pin/{sample}/results-{rnd}.json"))["tasks"][task]["cases"]
want = [int(x) for x in cases.split(",")]
def norm(x):
    return json.loads(json.dumps(x))
ok, bad, vis, vis_ok = [], [], [], True
for i, c in enumerate(cs):
    if i not in want and not c["visible"]:
        continue
    exp = norm(list(ref(*norm(c["input"]))))
    assert exp == c["expected"], f"reference disagrees with recorded expected on case {i}"
    try:
        got = norm(list(g["main"](*norm(c["input"]))))
    except Exception as e:
        got = repr(e)
    if c["visible"]:
        vis.append(f"visible {i} {'OK' if got == exp else 'FAIL'}")
        vis_ok = vis_ok and got == exp
    if i in want:
        (ok if got == exp else bad).append(i)
print(f"{sample} r{rnd} {task} patches={len(patch)//2}: OK {ok} FAIL {bad}; {'; '.join(vis)}")
good = not ok if expect_fail else (not bad and (vis_ok or visible_may_fail))
sys.exit(0 if good else 1)
