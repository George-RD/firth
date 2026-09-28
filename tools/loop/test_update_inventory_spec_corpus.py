#!/usr/bin/env python3
"""The inventory spec corpus check must fail on stale or edited output.

`update_inventory_spec_corpus.py --check` is what keeps
`src/proofs/Inventory/SpecCorpus.lean` in step with the frozen corpus, so
these tests plant a stale file and an edited corpus and require the check to
reject both.
"""
from __future__ import annotations

import contextlib
import io
import json
import sys
import tempfile
import unittest
from pathlib import Path
from unittest import mock

sys.path.insert(0, str(Path(__file__).resolve().parent))
import update_inventory_spec_corpus as corpus  # noqa: E402


def check(output: Path, cases: Path = corpus.CASES) -> int:
    with mock.patch.object(corpus, "OUTPUT", output), mock.patch.object(corpus, "CASES", cases), \
            mock.patch.object(sys, "argv", ["update_inventory_spec_corpus.py", "--check"]), \
            mock.patch.object(corpus, "ROOT", output.parent), \
            contextlib.redirect_stdout(io.StringIO()), contextlib.redirect_stderr(io.StringIO()):
        return corpus.main()


class InventorySpecCorpusTests(unittest.TestCase):
    def setUp(self) -> None:
        self.directory = tempfile.TemporaryDirectory()
        self.root = Path(self.directory.name)
        self.output = self.root / "SpecCorpus.lean"

    def tearDown(self) -> None:
        self.directory.cleanup()

    def test_the_checked_in_file_is_current(self) -> None:
        self.assertEqual(corpus.OUTPUT.read_text(encoding="utf-8"), corpus.render())

    def test_a_fresh_file_passes(self) -> None:
        self.output.write_text(corpus.render(), encoding="utf-8")
        self.assertEqual(check(self.output), 0)

    def test_an_edited_expected_value_fails(self) -> None:
        text = corpus.render()
        planted = text.replace("(5, [2, 3], [0, 0])", "(5, [2, 3], [0, 1])", 1)
        self.assertNotEqual(planted, text)
        self.output.write_text(planted, encoding="utf-8")
        self.assertEqual(check(self.output), 1)

    def test_a_missing_file_fails(self) -> None:
        self.assertEqual(check(self.output), 1)

    def test_a_corpus_change_makes_the_file_stale(self) -> None:
        self.output.write_text(corpus.render(), encoding="utf-8")
        data = json.loads(corpus.CASES.read_text(encoding="utf-8"))
        case = next(case for case in data["cases"] if case["expected"]["status"] == "ok")
        case["expected"]["remaining"] += 1
        cases = self.root / "cases.json"
        cases.write_text(json.dumps(data), encoding="utf-8")
        self.assertEqual(check(self.output, cases), 1)

    def test_every_successful_case_becomes_a_guard(self) -> None:
        data = json.loads(corpus.CASES.read_text(encoding="utf-8"))
        ok = [case for case in data["cases"] if case["expected"]["status"] == "ok"]
        self.assertEqual(corpus.render().count("#guard allocateAll"), len(ok))

    def test_every_case_the_host_passes_on_becomes_a_batch_guard(self) -> None:
        data = json.loads(corpus.CASES.read_text(encoding="utf-8"))
        passed = [case for case in data["cases"]
                  if not isinstance(corpus.host.host_decode(case["input"]), dict)]
        errors = [case for case in passed if case["expected"]["status"] != "ok"]
        self.assertTrue(errors)
        self.assertEqual(corpus.render().count("#guard batchSpec"), len(passed))


if __name__ == "__main__":
    unittest.main()
