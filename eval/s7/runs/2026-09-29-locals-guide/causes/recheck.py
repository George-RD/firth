#!/usr/bin/env python3
"""Recheck every answer run 11's counted authors submitted, reporting all errors.

The feedback shows the first error in each refused word, and a scored result
keeps only the first failing case's text. This runs the pinned checker over every distinct task source in every counted
sample's solutions-N.json, both arms, and keeps each diagnostic's code, word
and position. The checker is the pinned `5d09e25`'s (`firth_run.py check`), the one both arms were scored with, which reports
the first error in each word (#174), so an answer's errors are counted per
word. Scoring is not redone: pass/fail stays the kept results-N.json.

    recheck.py --firth /path/to/checkout-at-5d09e25 [--jobs 4] > rechecked.json
    recheck.py --self-test

The checkout must be built (lake and cargo on PATH). A toolchain failure
stops the run rather than being recorded as the answer's error.
"""
import argparse
import ast
import hashlib
import json
import subprocess
import sys
import tempfile
from concurrent.futures import ThreadPoolExecutor
from pathlib import Path

RUN = Path(__file__).resolve().parents[1]
CHECKER_COMMIT = "5d09e25"
sys.path.insert(0, str(RUN))
from analyse import ARMS, counted as counted_in  # noqa: E402


def counted():
    """The counted samples of both arms (analyse.py's rule: first 20 non-void)."""
    for path in ARMS.values():
        yield from counted_in(path)


def sources():
    out = {}
    for d in counted():
        for n in (1, 2, 3):
            for task, src in json.loads((d / f"solutions-{n}.json").read_text()).items():
                out[hashlib.sha256(src.encode()).hexdigest()] = src
    return out


def diagnostics(raw: str) -> list:
    """The diagnostics in `firth_run.py check`'s error text, or raise."""
    doc = json.loads(raw)
    if "error" not in doc:
        return []
    err = doc["error"]
    if err.startswith("toolchain:") or "lake: exit" in err or "cargo: exit" in err:
        raise RuntimeError(err)
    head = "check: status 'failure', expected 'success': "
    if not err.startswith(head):
        return [{"code": None, "raw": err[:400]}]
    out = []
    for p in ast.literal_eval(err[len(head):]):
        b = p["body"]
        rng = ((b.get("location") or {}).get("range") or {}).get("start") or {}
        mp = b.get("message_params") or {}
        out.append({"code": b.get("code"), "word": mp.get("word"),
                    "line": rng.get("line"), "column": rng.get("column"),
                    "message": mp.get("message"), "hint": mp.get("hint"),
                    "assumes": mp.get("assumes") or []})
    return out


def check(firth: Path, src: str) -> list:
    with tempfile.NamedTemporaryFile("w", suffix=".firth", delete=False) as f:
        f.write(src)
    try:
        r = subprocess.run([sys.executable, "tools/loop/firth_run.py", "check", f.name],
                           cwd=firth, capture_output=True, text=True, timeout=300)
    finally:
        Path(f.name).unlink()
    # firth_run.py prints success on stdout and a failure on stderr.
    return diagnostics(r.stdout if r.returncode == 0 else r.stderr)


def self_test():
    assert diagnostics(json.dumps({"status": "success"})) == []
    diag = {"body": {"code": "firth.type.branch-mismatch",
                     "location": {"range": {"start": {"line": 3, "column": 5}}},
                     "message_params": {"word": "w", "message": "m", "hint": "h",
                                        "assumes": ["v"]}}}
    raw = json.dumps({"error": "check: status 'failure', expected 'success': " + repr([diag])})
    assert diagnostics(raw) == [{"code": "firth.type.branch-mismatch", "word": "w", "line": 3,
                                 "column": 5, "message": "m", "hint": "h", "assumes": ["v"]}]
    # Planted: a failed build must stop the run, not become the answer's error.
    for err in ("toolchain: firthElaborate did not answer", "build: lake: exit 1"):
        try:
            diagnostics(json.dumps({"error": err}))
        except RuntimeError:
            continue
        raise AssertionError(f"{err!r} was recorded as an answer's error")
    assert diagnostics(json.dumps({"error": "something else"}))[0]["code"] is None
    print("self-test ok")


def main():
    if "--self-test" in sys.argv:
        return self_test()
    cli = argparse.ArgumentParser(description=__doc__,
                                  formatter_class=argparse.RawDescriptionHelpFormatter)
    cli.add_argument("--firth", type=Path, required=True)
    cli.add_argument("--jobs", type=int, default=4)
    a = cli.parse_args()
    head = subprocess.run(["git", "rev-parse", "--short=7", "HEAD"], cwd=a.firth,
                          capture_output=True, text=True).stdout.strip()
    if head != CHECKER_COMMIT:
        sys.exit(f"checker checkout is at {head}, expected {CHECKER_COMMIT}")
    srcs = sources()
    # One serial check first, so a cold build is not raced by the workers.
    first = next(iter(srcs))
    done = {first: check(a.firth, srcs[first])}
    with ThreadPoolExecutor(a.jobs) as pool:
        rest = [k for k in srcs if k != first]
        for k, diags in zip(rest, pool.map(lambda k: check(a.firth, srcs[k]), rest)):
            done[k] = diags
    json.dump({"checker": CHECKER_COMMIT, "answers": dict(sorted(done.items()))},
              sys.stdout, indent=1, ensure_ascii=False)
    print()


if __name__ == "__main__":
    main()
