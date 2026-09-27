#!/usr/bin/env python3
"""Keep implementation work and acceptance evidence attached to the live matrix."""
from __future__ import annotations

import json
import re
import shutil
import subprocess
import sys
import tempfile
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

    def test_completion_flips_loop_exhaustion_only_when_every_language_task_is_done(self) -> None:
        """Both directions of the exhaustion decision, against a copy of the live matrix.

        The copy holds the real matrix, blueprint and todos plus a stub for every
        pinned gate path, so the positive direction is checked against the real
        bindings rather than a synthetic fixture, without editing the tracker.
        """
        with tempfile.TemporaryDirectory(prefix="firth-roadmap-") as temporary:
            root = Path(temporary)
            (root / "tools" / "loop").mkdir(parents=True)
            (root / "meta" / "todos").mkdir(parents=True)
            for name in ("coverage.py", "select_unit.py", "obligations.toml"):
                shutil.copy2(ROOT / "tools" / "loop" / name, root / "tools" / "loop" / name)
            shutil.copy2(ROOT / "cairn.blueprint", root / "cairn.blueprint")
            todos = sorted((ROOT / "meta" / "todos").glob("todo.*.md"))
            for path in todos:
                shutil.copy2(path, root / "meta" / "todos" / path.name)
            for row in self.rows.values():
                gate = row.get("gate")
                if isinstance(gate, str):
                    (root / gate).parent.mkdir(parents=True, exist_ok=True)
                    (root / gate).write_text("#!/usr/bin/env python3\nraise SystemExit(0)\n", encoding="utf-8")

            def coverage() -> dict:
                process = subprocess.run([sys.executable, str(root / "tools" / "loop" / "coverage.py")],
                                         cwd=root, capture_output=True, text=True, timeout=30, check=True)
                return json.loads(process.stdout)

            def set_status(path: Path, status: str) -> None:
                text = (root / "meta" / "todos" / path.name).read_text(encoding="utf-8")
                self.assertRegex(text, r"(?m)^status:", path.name)
                updated = re.sub(r"^status:.*$", f"status: {status}", text, count=1, flags=re.MULTILINE)
                (root / "meta" / "todos" / path.name).write_text(updated, encoding="utf-8")

            language = [path for path in todos if path.name.startswith("todo.language-")]
            self.assertTrue(language)
            open_language = [path for path in language if frontmatter_and_requires(path)[0]["status"] != "done"]
            self.assertTrue(open_language, "the live matrix has no open language task to exercise")
            self.assertFalse(coverage()["loop_exhausted_valid"])

            for path in todos:
                set_status(path, "done")
            result = coverage()
            self.assertEqual(result["ungenerated"], [])
            self.assertEqual(result["missing_gates"], [])
            self.assertEqual(result["in_flight"], [])
            self.assertTrue(result["loop_exhausted_valid"])

            set_status(open_language[0], "open")
            result = coverage()
            self.assertTrue(result["in_flight"])
            self.assertFalse(result["loop_exhausted_valid"])

    def test_consumer_spec_and_examples_exist(self) -> None:
        for path in ("docs/roadmap.md", "specs/inventory-allocation.md", "specs/inventory-allocation-cases.json",
                     "meta/decisions/usable-language-milestones.md"):
            self.assertTrue((ROOT / path).is_file(), path)


if __name__ == "__main__":
    unittest.main()
