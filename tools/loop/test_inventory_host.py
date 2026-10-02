#!/usr/bin/env python3
"""The inventory host's own checks must be pinned by the corpus.

After `todo.inventory-host-proof`, the Python host (`examples/inventory/
run_cases.py`) keeps only what the spec's "Host and Firth split" gives it and
Lean does not model: the JSON shape and type checks and the ID syntax
(`invalid-input`) and the i64 range check (`invalid-range`), in `host_check`.
The ID encoding and the answer are Lean's (`src/proofs/Inventory/Host.lean`).

These tests plant one bug at a time in `host_check`'s source and require some
input to come out differently: a corpus case, or one of `EXTRA`, inputs the
corpus does not hold, with their expected results written by hand. So no host
check can be dropped or loosened unnoticed. `host_parse`, the path from JSON
text, is tested on the spec's two host tests (malformed JSON, repeated member
names) and on integers too long for Python's default conversion, with planted
parsers that keep the last member or use that default. They
need no Lean toolchain.
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
INVALID_INPUT = {"status": "error", "code": "invalid-input"}

# The spec's two host tests, which the corpus cannot hold because it stores
# decoded inputs: malformed JSON and repeated member names. With a valid
# document beside each, so a parser that refused everything would fail too.
TEXTS = {
    "malformed": ('{"available": 1, "policy": "partial", "requests": [}', INVALID_INPUT),
    "truncated": ('{"available": 1', INVALID_INPUT),
    "repeated-top-member": ('{"available": 1, "available": 2, "policy": "partial", "requests": []}',
                            INVALID_INPUT),
    "repeated-request-member": ('{"available": 1, "policy": "partial", "requests": '
                                '[{"id": "a", "id": "b", "quantity": 1}]}', INVALID_INPUT),
    "not-a-number": ('{"available": NaN, "policy": "partial", "requests": []}', INVALID_INPUT),
    # More digits than Python converts by default (4300): still an integer
    # outside i64, so invalid-range, but only after the invalid-input checks.
    "huge-stock": ('{"available": 1' + "0" * 4300 + ', "policy": "partial", "requests": []}',
                   {"status": "error", "code": "invalid-range"}),
    "huge-negative-quantity": ('{"available": 1, "policy": "partial", "requests": '
                               '[{"id": "a", "quantity": -1' + "0" * 4300 + '}]}',
                               {"status": "error", "code": "invalid-range"}),
    "huge-stock-bad-policy": ('{"available": 1' + "0" * 4300 + ', "policy": "none", "requests": []}',
                              INVALID_INPUT),
    "valid": ('{"available": 1, "policy": "partial", "requests": [{"id": "a", "quantity": 1}]}',
              (1, False, ["a"], [1])),
}

# Inputs the corpus does not hold, with the result the spec gives them.
EXTRA = {
    # A list naming the three members: only the object test rejects it.
    "list-of-member-names": (["available", "policy", "requests"], {"status": "error", "code": "invalid-input"}),
}

# (what the bug does, text in host_check, replacement)
MUTANTS = [
    ("accepts a non-object input", "not isinstance(value, dict) or ", ""),
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


def outcome(check, value) -> object:
    """The host's result: the error, "component" when it passes, or the crash."""
    try:
        result = check(value)
    except Exception as crash:  # noqa: BLE001  (a crash is an outcome too)
        return f"crash: {type(crash).__name__}"
    return result if isinstance(result, dict) else "component"


def outcomes(check) -> dict[str, object]:
    inputs = {case["name"]: case["input"] for case in CASES}
    inputs.update({name: value for name, (value, _) in EXTRA.items()})
    return {name: outcome(check, value) for name, value in inputs.items()}


def mutant(original: str, replacement: str):
    assert SOURCE.count(original) == 1, original
    namespace = dict(vars(host))
    exec(SOURCE.replace(original, replacement), namespace)  # noqa: S102
    return namespace["host_check"]


class HostParseTests(unittest.TestCase):
    def test_the_spec_host_tests(self) -> None:
        for name, (text, expected) in TEXTS.items():
            with self.subTest(case=name):
                self.assertEqual(host.host_parse(text), expected)

    def test_every_planted_parser_bug_changes_an_outcome(self) -> None:
        source = inspect.getsource(host.host_parse)
        # Compared as outcomes, so a passing document is "component" on both sides.
        expected = {name: outcome(host.host_parse, text) for name, (text, _) in TEXTS.items()}
        for bug, original in [("keeps the last repeated member", ", object_pairs_hook=unique_members"),
                              ("uses Python's digit limit", ", parse_int=json_integer")]:
            with self.subTest(bug=bug):
                self.assertEqual(source.count(original), 1)
                namespace = dict(vars(host))
                exec(source.replace(original, ""), namespace)  # noqa: S102
                planted = {name: outcome(namespace["host_parse"], text) for name, (text, _) in TEXTS.items()}
                self.assertNotEqual(planted, expected)


class HostCheckTests(unittest.TestCase):
    def test_the_host_rejects_what_the_corpus_expects(self) -> None:
        for case in CASES:
            result = host.host_check(case["input"])
            with self.subTest(case=case["name"]):
                if isinstance(result, dict):
                    self.assertEqual(result, case["expected"])
                else:
                    self.assertNotIn(case["expected"].get("code"), ("invalid-input",))

    def test_the_host_answers_the_extra_inputs_as_the_spec_says(self) -> None:
        for name, (value, expected) in EXTRA.items():
            with self.subTest(case=name):
                self.assertEqual(outcome(host.host_check, value), expected)

    def test_every_planted_host_bug_changes_an_outcome(self) -> None:
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
