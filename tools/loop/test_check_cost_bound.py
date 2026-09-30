#!/usr/bin/env python3
"""The cost-bound check must fail when either side changes alone.

`check_cost_bound.py` compares Lean's `batchCost` with the host's
`run_cases.cost_bound`. These tests replace Lean's answer with planted values,
so they need no Lean toolchain, and plant a change on each side in turn.
"""
from __future__ import annotations

import contextlib
import io
import sys
import unittest
from pathlib import Path
from unittest import mock

sys.path.insert(0, str(Path(__file__).resolve().parent))
import check_cost_bound as check  # noqa: E402

# batchCost as Allocate.lean defines it, written out independently of both
# sides: 165 + 202 n + 163 n (n - 1) / 2.
EXPECTED = {n: 165 + 202 * n + 163 * n * (n - 1) // 2 for n in range(65)}


def run(proved: dict[int, int] | Exception) -> int:
    evaluate = mock.Mock(side_effect=proved) if isinstance(proved, Exception) \
        else mock.Mock(return_value=proved)
    with mock.patch.object(check, "proved_costs", evaluate), \
            contextlib.redirect_stdout(io.StringIO()), contextlib.redirect_stderr(io.StringIO()):
        return check.main()


class CostBoundTests(unittest.TestCase):
    def test_matching_bounds_pass(self) -> None:
        self.assertEqual(run(dict(EXPECTED)), 0)

    def test_a_changed_proved_bound_fails(self) -> None:
        self.assertEqual(run({**EXPECTED, 64: EXPECTED[64] + 1}), 1)

    def test_a_changed_host_bound_fails(self) -> None:
        original = check.host.cost_bound
        with mock.patch.object(check.host, "cost_bound", lambda n: original(n) + (n == 2)):
            self.assertEqual(run(dict(EXPECTED)), 1)

    def test_a_missing_batch_size_fails(self) -> None:
        self.assertEqual(run({n: c for n, c in EXPECTED.items() if n != 64}), 1)

    def test_lean_failing_fails(self) -> None:
        self.assertEqual(run(RuntimeError("Lean could not evaluate batchCost")), 1)

    def test_the_program_asks_for_every_batch_size(self) -> None:
        self.assertIn("List.range 65", check.PROGRAM)
        self.assertIn("batchCost", check.PROGRAM)


if __name__ == "__main__":
    unittest.main()
