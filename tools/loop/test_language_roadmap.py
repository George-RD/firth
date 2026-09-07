#!/usr/bin/env python3
"""Keep implementation work and acceptance evidence attached to the live matrix."""
from __future__ import annotations

import json
import subprocess
import sys
import tomllib
import unittest
from pathlib import Path

from select_unit import frontmatter_and_requires

ROOT = Path(__file__).resolve().parents[2]


class LanguageRoadmapTests(unittest.TestCase):
    def setUp(self) -> None:
        self.matrix = tomllib.loads((ROOT / "tools/loop/obligations.toml").read_text())
        self.rows = self.matrix["obligation"]
        self.tasks = {path.name[5:-3]: path for path in (ROOT / "meta/todos").glob("todo.language-*.md")}

    def test_every_roadmap_task_is_active_and_valid(self) -> None:
        active = {oid: row for oid, row in self.rows.items() if self.matrix["completion"]["profile"] == "full" or row.get("milestone", "mvp") == "mvp"}
        refs = {slug for row in active.values() for slug in row["satisfied_by"]}
        self.assertTrue(self.tasks)
        for slug, path in self.tasks.items():
            with self.subTest(task=slug):
                self.assertIn(slug, refs)
                fields, dependencies, errors = frontmatter_and_requires(path)
                self.assertEqual(errors, [])
                self.assertIn(fields["status"], {"open", "in_progress", "blocked", "done"})
                for dependency in dependencies:
                    self.assertTrue((ROOT / "meta/todos" / f"todo.{dependency}.md").is_file())

    def test_design_alone_cannot_discharge_differential_harness(self) -> None:
        self.assertIn("language-04-differential-execution", self.rows["scope-toolchain-diffharness"]["satisfied_by"])
        self.assertEqual(self.rows["usable-language-baseline"]["gate"], "tools/loop/check_trust_boundaries.py")
        self.assertTrue((ROOT / self.rows["usable-language-baseline"]["gate"]).is_file())

    def test_implementation_must_pin_its_gate_before_done(self) -> None:
        for slug, row in (("language-13-inventory-component", "usable-inventory-component"),
                          ("language-21-docs-only-change-trial", "agent-maintained-component")):
            fields, _, errors = frontmatter_and_requires(self.tasks[slug])
            self.assertEqual(errors, [])
            if fields["status"] == "done":
                self.assertIsInstance(self.rows[row].get("gate"), str)
                self.assertTrue((ROOT / self.rows[row]["gate"]).is_file())

    def test_open_work_prevents_completion(self) -> None:
        unfinished = any(frontmatter_and_requires(path)[0]["status"] != "done" for path in self.tasks.values())
        process = subprocess.run([sys.executable, "tools/loop/coverage.py"], cwd=ROOT, capture_output=True, text=True, timeout=30, check=True)
        result = json.loads(process.stdout)
        if unfinished:
            self.assertFalse(result["loop_exhausted_valid"])

    def test_consumer_spec_and_examples_exist(self) -> None:
        for path in ("docs/roadmap.md", "specs/inventory-allocation.md", "specs/inventory-allocation-cases.json",
                     "meta/decisions/usable-language-milestones.md"):
            self.assertTrue((ROOT / path).is_file(), path)


if __name__ == "__main__":
    unittest.main()
