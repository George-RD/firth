#!/usr/bin/env python3
"""Adversarial tests for the runbook driver's token acceptance.

The driver under test is the FIRST fenced sh block of docs/loop-runbook.md,
extracted exactly as the launch contract extracts it. The harness and git
are stubbed on PATH, so every stop path runs hermetically and fast:
token-last, token-then-report, buried token, conflicting tokens, missing
token, halt, exhaustion strictness both ways, and a nonzero harness exit
(dec.driver-token-tail, dec.loop-driver-contract).
"""

from __future__ import annotations

import os
import stat
import subprocess
import tempfile
import unittest
from pathlib import Path

RUNBOOK = Path(__file__).resolve().parents[2] / "docs" / "loop-runbook.md"


def extract_driver() -> str:
    lines = RUNBOOK.read_text(encoding="utf-8").splitlines()
    block: list[str] = []
    inside = False
    for line in lines:
        if not inside and line == "```sh":
            inside = True
            continue
        if inside and line == "```":
            break
        if inside:
            block.append(line)
    if not block:
        raise AssertionError("no fenced sh block found in docs/loop-runbook.md")
    return "\n".join(block) + "\n"


GIT_STUB = """#!/bin/sh
# ls-remote advances one fake tip per call so ITERATION COMPLETE always
# counts as landed work and the wedge window never trips in these tests.
case "$1" in
  fetch) exit 0 ;;
  show) printf 'prompt\\n'; exit 0 ;;
  ls-remote)
    n=$(cat "$STUB_DIR/tip" 2>/dev/null || echo 0)
    n=$((n + 1))
    printf '%s' "$n" > "$STUB_DIR/tip"
    printf 'tip%s\\trefs/heads/main\\n' "$n"
    exit 0 ;;
  *) exit 0 ;;
esac
"""

AGENT_STUB = """#!/bin/sh
# Emits one canned output per iteration from $STUB_DIR/out.N, exiting with
# the paired rc.N (default 0). After the last canned iteration it emits a
# final-line LOOP HALTED so every scenario terminates.
n=$(cat "$STUB_DIR/iter" 2>/dev/null || echo 0)
n=$((n + 1))
printf '%s' "$n" > "$STUB_DIR/iter"
if [ -f "$STUB_DIR/out.$n" ]; then
  cat "$STUB_DIR/out.$n"
  exit "$(cat "$STUB_DIR/rc.$n" 2>/dev/null || echo 0)"
fi
printf 'wrap-up report\\nLOOP HALTED\\n'
exit 0
"""


class DriverTokenTests(unittest.TestCase):
    def setUp(self) -> None:
        self.tmp = tempfile.TemporaryDirectory()
        self.dir = Path(self.tmp.name)
        (self.dir / "driver.sh").write_text(extract_driver(), encoding="utf-8")
        bin_dir = self.dir / "bin"
        bin_dir.mkdir()
        for name, body in (("git", GIT_STUB), ("agent", AGENT_STUB)):
            path = bin_dir / name
            path.write_text(body, encoding="utf-8")
            path.chmod(path.stat().st_mode | stat.S_IEXEC)

    def tearDown(self) -> None:
        self.tmp.cleanup()

    def iteration(self, number: int, text: str, rc: int = 0) -> None:
        (self.dir / f"out.{number}").write_text(text, encoding="utf-8")
        if rc:
            (self.dir / f"rc.{number}").write_text(str(rc), encoding="utf-8")

    def run_driver(self) -> subprocess.CompletedProcess:
        env = dict(
            os.environ,
            PATH=f"{self.dir / 'bin'}:{os.environ['PATH']}",
            STUB_DIR=str(self.dir),
            AGENT="agent",
            TMPDIR=str(self.dir),
            W="10",
            MAXTIME="60",
        )
        return subprocess.run(
            ["sh", str(self.dir / "driver.sh")],
            cwd=self.dir,
            env=env,
            capture_output=True,
            text=True,
            timeout=60,
            check=False,
        )

    def test_token_as_last_line_continues_then_halt_stops_rc2(self) -> None:
        self.iteration(1, "did work\nITERATION COMPLETE\n")
        done = self.run_driver()
        self.assertEqual(done.returncode, 2)  # iteration 2 is the stub's halt
        self.assertIn("LOOP HALTED", done.stdout)

    def test_token_followed_by_report_is_accepted(self) -> None:
        report = "\n".join(f"- bullet {i}" for i in range(10))
        self.iteration(1, f"ITERATION COMPLETE\n{report}\n")
        done = self.run_driver()
        self.assertEqual(done.returncode, 2)
        self.assertEqual((self.dir / "iter").read_text(), "2")

    def test_token_buried_deeper_than_tail_fails_closed(self) -> None:
        filler = "\n".join(f"line {i}" for i in range(20))
        self.iteration(1, f"ITERATION COMPLETE\n{filler}\n")
        done = self.run_driver()
        self.assertEqual(done.returncode, 3)
        self.assertIn("missing or unknown terminal token", done.stderr)

    def test_conflicting_tokens_fail_closed(self) -> None:
        self.iteration(1, "ITERATION COMPLETE\nsome text\nLOOP HALTED\n")
        done = self.run_driver()
        self.assertEqual(done.returncode, 3)

    def test_missing_token_fails_closed(self) -> None:
        self.iteration(1, "worked on things\nno token here\n")
        done = self.run_driver()
        self.assertEqual(done.returncode, 3)

    def test_exhausted_as_final_line_exits_zero(self) -> None:
        self.iteration(1, "coverage says done\nLOOP EXHAUSTED\n")
        done = self.run_driver()
        self.assertEqual(done.returncode, 0)

    def test_exhausted_followed_by_report_fails_closed(self) -> None:
        self.iteration(1, "LOOP EXHAUSTED\ntrailing report\n")
        done = self.run_driver()
        self.assertEqual(done.returncode, 3)

    def test_token_on_nonzero_exit_is_ignored(self) -> None:
        self.iteration(1, "ITERATION COMPLETE\n", rc=5)
        done = self.run_driver()
        self.assertEqual(done.returncode, 3)
        self.assertIn("harness exited 5", done.stderr)

    def test_quoted_token_lines_stay_inert(self) -> None:
        self.iteration(
            1,
            'the report mentions "LOOP HALTED" and `LOOP EXHAUSTED` in prose\n'
            "ITERATION COMPLETE\n",
        )
        done = self.run_driver()
        self.assertEqual(done.returncode, 2)


if __name__ == "__main__":
    unittest.main()
