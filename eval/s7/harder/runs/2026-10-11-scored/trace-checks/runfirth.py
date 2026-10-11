"""Run a Firth source on recorded cases with the pin checkout's runner.

usage: runfirth.py RUN PIN FIRTH_FILE SAMPLE ROUND TASK CASES
Runs PIN/tools/loop/firth_run.py (cwd PIN, fuel 1,000,000) on each case in
CASES (comma-separated) from RUN/rescore-pin/SAMPLE/results-ROUND.json and
prints one line: which cases match the recorded expected output.
"""
import json, os, subprocess, sys
run, pin, src, sample, rnd, task, cases = sys.argv[1:8]
src = os.path.abspath(src)
cs = json.load(open(f"{run}/rescore-pin/{sample}/results-{rnd}.json"))["tasks"][task]["cases"]
ok, bad = [], []
for i in [int(x) for x in cases.split(",")]:
    c = cs[i]
    p = subprocess.run([sys.executable, "tools/loop/firth_run.py", "run", src, "--entry", "main",
                        "--stack", json.dumps(c["input"]), "--fuel", "1000000"],
                       capture_output=True, text=True, cwd=pin)
    try:
        out = json.loads(p.stdout)
    except ValueError:
        out = {}
    if out.get("status") == "success" and out.get("stack") == c["expected"]:
        ok.append(i)
    else:
        bad.append((i, out.get("status")))
print(f"{sample} r{rnd} {task} {os.path.basename(src)}: OK {ok} FAIL {bad}")
