"""Show that context_seen.py's sample-name change (#230, then whole Haiku names)
leaves a Haiku run's results as they were, apart from one new field. Since #230
each flagged item also carries `sample_names`, so output is no longer
byte-identical; this script drops only that field from the new output and
requires everything else, the exit code included, to match. Run 14's session.py
calls it as `LOG --arm-set ARMSET --arm ARM --sample haiku-firth-N --label
LABEL`. `context_seen.py` offers no run14 arm set when run from here, so the
comparison uses run13's, whose arms and labels have the same shape.
Usage: haiku_same.py REV, where REV is a commit before the change (7d82348); its
context_seen.py is written beside the current one, since both read their runs
from there, and removed. It builds logs whose injected items name Haiku samples,
labels and arms the way Haiku runs did and runs both versions with that call
pattern. Planted: a Sonnet-named item must differ, and so must an extra field
other than `sample_names` and a changed `names`; the script fails if not."""
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


def strip(result, field="sample_names"):
    """Result with `field` dropped from every flagged item: the exit code, the
    JSON report and the text after it."""
    code, out = result
    if not out.startswith("{"):
        return code, None, out
    report, end = json.JSONDecoder().raw_decode(out)
    for key in ("injected", "cross_sample"):
        for item in report.get(key, []):
            item.pop(field, None)
    return code, report, out[end:]


def same(old, new):
    return strip(old) == strip(new)


HAIKU = [
    "nothing here",
    "author haiku-firth-3 wrote haiku-firth-3/answer-1.md",
    "haiku-firth-4/answer-1.md is yours",
    "haiku-python-4 and haiku-python-7 are running",
    "Run 11 author B3 is running; arm-b/haiku-firth-3",
    "Control author A10 in arm-a/haiku-firth-10",
    "/tasks/0123456789abcdef task notification for haiku-firth-12",
]
CALLS = [["--arm-set", "run13", "--arm", "arm-b", "--sample", "haiku-firth-4", "--label", "B4"],
         ["--arm-set", "run13", "--arm", "arm-a", "--sample", "haiku-firth-3", "--label", "A3"],
         ["--sample", "haiku-firth-4"], []]


def compare():
    same_n = 0
    for body in HAIKU:
        path = log(body)
        for argv in CALLS:
            a, b = run(OLD, path, argv), run(NEW, path, argv)
            assert same(a, b), (body, argv, a, b)
            same_n += 1
    path = log(*HAIKU)
    for argv in CALLS:
        assert same(run(OLD, path, argv), run(NEW, path, argv)), argv
        same_n += 1
    # Planted: an item naming another Sonnet author is caught only by the new version.
    planted = log("sonnet-python-4/answer-1.md")
    a, b = (run(OLD, planted, ["--sample", "sonnet-firth-4"]),
            run(NEW, planted, ["--sample", "sonnet-firth-4"]))
    assert strip(b)[1]["cross_sample"] and not same(a, b), (a, b)
    # Planted: an extra field other than `sample_names`, or a changed `names`,
    # is not forgiven.
    path = log(HAIKU[1])
    a, b = run(OLD, path, CALLS[0]), run(NEW, path, CALLS[0])
    assert same(a, b)
    for edit in (lambda r: r["injected"][0].update(extra=1),
                 lambda r: r["injected"][0].update(names=["9"])):
        r = json.loads(b[1][:json.JSONDecoder().raw_decode(b[1])[1]])
        edit(r)
        assert not same(a, (b[0], json.dumps(r) + b[1][json.JSONDecoder().raw_decode(b[1])[1]:]))
    return same_n


try:
    print(f"{compare()} Haiku logs and calls give the same exit code, report and text apart from `sample_names`; "
          "the planted Sonnet item, extra field and changed names differ")
finally:
    OLD.unlink()
