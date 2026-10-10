"""Show that context_seen.py's sample-name change leaves a Haiku run's results
as they were: run 14's session.py calls it as `LOG --arm-set ARMSET --arm ARM
--sample haiku-firth-N --label LABEL`. Usage: haiku_same.py REV, where REV is a
commit before the change (7d82348); its context_seen.py is written beside the
current one for the comparison, since both read their runs from there, and removed.
It builds logs whose injected items name Haiku samples, labels and arms the way
Haiku runs did, runs both versions with that call pattern, and checks their
output is byte-for-byte the same. A planted Sonnet-named item must differ."""
import json, subprocess, sys, tempfile
from pathlib import Path

S7 = Path(__file__).resolve().parents[2]
NEW = S7 / "context_seen.py"
OLD = S7 / "context_seen_before.py"
OLD.write_text(subprocess.run(["git", "show", f"{sys.argv[1]}:eval/s7/context_seen.py"], cwd=S7,
                              capture_output=True, text=True, check=True).stdout)
OURS = "You are the author in a programming evaluation."


def log(*bodies):
    evs = [{"type": "user", "timestamp": "t0", "message": {"role": "user", "content": OURS + " go"}}]
    for i, b in enumerate(bodies):
        evs.append({"type": "user", "timestamp": f"t{i + 1}",
                    "message": {"role": "user", "content": "<system-reminder>" + b + "</system-reminder>"}})
    f = tempfile.NamedTemporaryFile("w", suffix=".jsonl", delete=False)
    f.write("\n".join(json.dumps(e) for e in evs) + "\n"); f.close()
    return f.name


def run(script, path, argv):
    p = subprocess.run([sys.executable, str(script), path, *argv], capture_output=True, text=True)
    return p.returncode, p.stdout


HAIKU = [
    "nothing here",
    "author haiku-firth-3 wrote haiku-firth-3/answer-1.md",
    "haiku-firth-4/answer-1.md is yours",
    "haiku-python-4 and haiku-python-7 are running",
    "Run 11 author B3 is running; arm-b/haiku-firth-3",
    "Control author A10 in arm-a/haiku-firth-10",
    "/tasks/0123456789abcdef task notification for haiku-firth-12",
]
CALLS = [["--arm-set", "run11", "--arm", "arm-b", "--sample", "haiku-firth-4", "--label", "B4"],
         ["--arm-set", "run11", "--arm", "arm-a", "--sample", "haiku-firth-3", "--label", "A3"],
         ["--sample", "haiku-firth-4"], []]


def compare():
    same = 0
    for body in HAIKU:
        path = log(body)
        for argv in CALLS:
            a, b = run(OLD, path, argv), run(NEW, path, argv)
            assert a == b, (body, argv, a, b)
            same += 1
    path = log(*HAIKU)
    for argv in CALLS:
        assert run(OLD, path, argv) == run(NEW, path, argv), argv
        same += 1
    # Planted: an item naming another Sonnet author is caught only by the new version.
    planted = log("sonnet-python-4/answer-1.md")
    a, b = (run(OLD, planted, ["--sample", "sonnet-firth-4"]),
            run(NEW, planted, ["--sample", "sonnet-firth-4"]))
    assert json.loads(b[1])["cross_sample"] and a != b, (a, b)
    return same


try:
    print(f"{compare()} Haiku logs and calls give the same exit code and output; "
          "the planted Sonnet item differs")
finally:
    OLD.unlink()
