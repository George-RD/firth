#!/usr/bin/env python3
"""The inventory host's own checks must be pinned by the corpus.

After `todo.inventory-host-proof`, the Python host (`examples/inventory/
run_cases.py`) keeps only what the spec's "Host and Firth split" gives it and
Lean does not model: the JSON shape and type checks and the ID syntax
(`invalid-input`) and the i64 range check (`invalid-range`), in `host_check`.
The ID encoding and the answer are Lean's (`src/proofs/Inventory/Host.lean`).

These tests plant one bug at a time in `host_check`'s source and require some
corpus case to come out differently, so no host check can be dropped or
loosened without the corpus noticing. They need no Lean toolchain.
"""
from __future__ import annotations

import inspect
import json
import sys
import unittest
from pathlib import Path

ROOT = Path(__file__).resolve().parents[2]
sys.path.insert(0, str(ROOT / "examples" / "inventory"))
import run_cases as host  # noqa: E402

CASES = json.loads((ROOT / "specs" / "inventory-allocation-cases.json").read_text())["cases"]
SOURCE = inspect.getsource(host.host_check)

# (what the bug does, text in host_check, replacement)
MUTANTS = [
    ("accepts unknown top-level members", 'set(value) != {"available", "policy", "requests"}',
     'not {"available", "policy", "requests"} <= set(value)'),
    ("accepts a boolean stock", "type(available) is not int", "not isinstance(available, int)"),
    ("accepts any policy", 'policy not in ("partial", "all-or-nothing")', "False"),
    ("accepts unknown request members", 'set(request) != {"id", "quantity"}',
     'not {"id", "quantity"} <= set(request)'),
    ("accepts any ID text", "not ID_PATTERN.fullmatch(request[\"id\"])", "False"),
    ("accepts a boolean quantity", 'type(request["quantity"]) is not int',
     'not isinstance(request["quantity"], int)'),
    ("drops the i64 range check", "if any(number not in INT64 for number in integers):", "if False:"),
]


def outcomes(check) -> dict[str, object]:
    """Each corpus case's host result: the error, or "component" when it passes."""
    return {case["name"]: (result if isinstance(result := check(case["input"]), dict) else "component")
            for case in CASES}


def mutant(original: str, replacement: str):
    assert SOURCE.count(original) == 1, original
    namespace = dict(vars(host))
    exec(SOURCE.replace(original, replacement), namespace)  # noqa: S102
    return namespace["host_check"]


class HostCheckTests(unittest.TestCase):
    def test_the_host_rejects_what_the_corpus_expects(self) -> None:
        for case in CASES:
            result = host.host_check(case["input"])
            with self.subTest(case=case["name"]):
                if isinstance(result, dict):
                    self.assertEqual(result, case["expected"])
                else:
                    self.assertNotIn(case["expected"].get("code"), ("invalid-input",))

    def test_every_planted_host_bug_changes_a_corpus_case(self) -> None:
        baseline = outcomes(host.host_check)
        for name, original, replacement in MUTANTS:
            with self.subTest(bug=name):
                self.assertNotEqual(outcomes(mutant(original, replacement)), baseline)

    def test_ids_reach_lean_as_strings(self) -> None:
        checked = host.host_check({"available": 1, "policy": "partial",
                                   "requests": [{"id": "a", "quantity": 1}]})
        self.assertEqual(checked, (1, False, ["a"], [1]))


if __name__ == "__main__":
    unittest.main()
