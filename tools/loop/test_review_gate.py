#!/usr/bin/env python3
"""Hermetic tests for the dec.review-mandatory Cleanup review gate.

Extracts the gate lines verbatim from the landing skill's Cleanup
script and runs them against a stub gh, so any drift in the published
procedure is tested, not a copy. The stub plays gh's role after jq:
it returns the head SHA and the per-comment first lines the fixed
--jq expressions would produce; the shell matching under test is the
gate's own.
Run: python3 tools/loop/test_review_gate.py
"""
import os
import stat
import subprocess
import sys
import tempfile
from pathlib import Path

ROOT = Path(__file__).resolve().parents[2]
SKILL = ROOT / ".claude" / "skills" / "firth-loop-landing" / "SKILL.md"

GH_STUB = """#!/bin/sh
case "$*" in
  *headRefOid*) [ -n "$GH_HEAD" ] && printf '%s\n' "$GH_HEAD" ;;
  *comments*) cat "$GH_FIRSTS" ;;
  *) exit 1 ;;
esac
exit 0
"""


def extract_gate() -> str:
    lines = SKILL.read_text(encoding="utf-8").splitlines()
    start = next(i for i, l in enumerate(lines)
                 if l.startswith("# dec.review-mandatory:"))
    end = next(i for i, l in enumerate(lines[start:], start)
               if "review: simplicity" in l and "exit 1" in l)
    return "\n".join(lines[start:end + 1])


def run_gate(head: str, firsts: list[str], gh_head: str | None = None) -> int:
    gate = extract_gate()
    with tempfile.TemporaryDirectory() as tmp:
        tmpp = Path(tmp)
        (tmpp / "gh").write_text(GH_STUB, encoding="utf-8")
        (tmpp / "gh").chmod((tmpp / "gh").stat().st_mode | stat.S_IEXEC)
        (tmpp / "firsts").write_text(
            "".join(f + "\n" for f in firsts), encoding="utf-8")
        script = "pr=1\n" + gate + "\nexit 0\n"
        (tmpp / "gate.sh").write_text(script, encoding="utf-8")
        env = dict(
            os.environ,
            PATH=f"{tmpp}:{os.environ['PATH']}",
            GH_HEAD=gh_head if gh_head is not None else head,
            GH_FIRSTS=str(tmpp / "firsts"),
        )
        return subprocess.run(
            ["sh", str(tmpp / "gate.sh")], env=env,
            capture_output=True, timeout=30).returncode


HEAD = "0123abc0123abc0123abc0123abc0123abc01234"
ok = True


def check(name: str, cond: bool) -> None:
    global ok
    print(f"  {name}: {'PASS' if cond else 'FAIL'}")
    if not cond:
        ok = False


check("both lenses on first lines pass", run_gate(HEAD, [
    f"review: correctness {HEAD}", f"review: simplicity {HEAD}"]) == 0)
check("missing simplicity fails", run_gate(HEAD, [
    f"review: correctness {HEAD}"]) != 0)
check("missing correctness fails", run_gate(HEAD, [
    f"review: simplicity {HEAD}"]) != 0)
check("no comments fail", run_gate(HEAD, []) != 0)
check("wrong sha fails", run_gate(HEAD, [
    f"review: correctness {HEAD}",
    "review: simplicity 9999999999999999999999999999999999999999"]) != 0)
check("one comment cannot carry both lenses", run_gate(HEAD, [
    f"review: correctness {HEAD}"]) != 0
    and run_gate(HEAD, [f"review: correctness {HEAD} review: simplicity {HEAD}"]) != 0)
check("trailing text on the marker line fails", run_gate(HEAD, [
    f"review: correctness {HEAD} looks good",
    f"review: simplicity {HEAD}"]) != 0)
check("marker as substring fails", run_gate(HEAD, [
    f"re: review: correctness {HEAD}", f"review: simplicity {HEAD}"]) != 0)
check("unreadable head fails", run_gate(HEAD, [
    f"review: correctness {HEAD}", f"review: simplicity {HEAD}"],
    gh_head="") != 0)

print("RESULT:", "PASS" if ok else "FAIL")
sys.exit(0 if ok else 1)
