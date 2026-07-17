#!/usr/bin/env python3
"""Behaviour tests for the deterministic todo selector."""

from __future__ import annotations

import json
import shutil
import subprocess
import tempfile
import unittest
from pathlib import Path


SOURCE = Path(__file__).with_name("select_unit.py")


class SelectorTests(unittest.TestCase):
    def setUp(self) -> None:
        self.tmp = tempfile.TemporaryDirectory()
        self.root = Path(self.tmp.name)
        (self.root / "tools" / "loop").mkdir(parents=True)
        (self.root / "meta" / "todos").mkdir(parents=True)
        shutil.copy2(SOURCE, self.root / "tools" / "loop" / "select_unit.py")

    def tearDown(self) -> None:
        self.tmp.cleanup()

    def todo(self, filename: str, *, status: str = "open", requires: str = "", extra: str = "") -> None:
        body = f"---\nnode: firth.governance.loop\nstatus: {status}\n{extra}---\n\n"
        body += f"Requires: {requires}\n"
        (self.root / "meta" / "todos" / filename).write_text(body, encoding="utf-8")

    def run_selector(self, *args: str) -> tuple[int, dict[str, object]]:
        result = subprocess.run(
            ["python3", str(self.root / "tools" / "loop" / "select_unit.py"), *args],
            text=True,
            capture_output=True,
            check=False,
        )
        return result.returncode, json.loads(result.stdout)

    def test_unknown_requires_returns_two(self) -> None:
        self.todo("todo.alpha.md", requires="missing")
        code, report = self.run_selector("--validate")
        self.assertEqual(code, 2)
        self.assertIn("unknown Requires slug missing", " ".join(report["errors"]))

    def test_dependency_cycle_returns_two(self) -> None:
        self.todo("todo.alpha.md", requires="beta")
        self.todo("todo.beta.md", requires="alpha")
        code, report = self.run_selector("--validate")
        self.assertEqual(code, 2)
        self.assertTrue(any("Requires cycle" in error for error in report["errors"]))

    def test_duplicate_declared_slug_returns_two(self) -> None:
        self.todo("todo.alpha.md", extra="slug: shared\n")
        self.todo("todo.beta.md", extra="slug: shared\n")
        code, report = self.run_selector("--validate")
        self.assertEqual(code, 2)
        self.assertIn("duplicate slug: shared", report["errors"])

    def test_filename_slug_mismatch_returns_two(self) -> None:
        self.todo("todo.alpha.md", extra="slug: other\n")
        code, report = self.run_selector("--validate")
        self.assertEqual(code, 2)
        self.assertTrue(any("does not match filename" in error for error in report["errors"]))

    def test_invalid_status_returns_two(self) -> None:
        self.todo("todo.alpha.md", status="pending")
        code, report = self.run_selector("--validate")
        self.assertEqual(code, 2)
        self.assertTrue(any("missing or invalid status" in error for error in report["errors"]))

    def test_requires_inside_code_fence_is_ignored(self) -> None:
        (self.root / "meta" / "todos" / "todo.alpha.md").write_text(
            "---\nnode: firth.governance.loop\nstatus: open\n---\n\n```\nRequires: missing\n```\n",
            encoding="utf-8",
        )
        code, report = self.run_selector("--validate")
        self.assertEqual(code, 0)
        self.assertEqual(report, {"schema": 1, "valid": True})

    def test_requires_heading_and_bullets_fail_closed(self) -> None:
        (self.root / "meta" / "todos" / "todo.alpha.md").write_text(
            "---\nnode: firth.governance.loop\nstatus: open\n---\n\n"
            "## Requires\n- `missing`\n",
            encoding="utf-8",
        )
        code, report = self.run_selector("--validate")
        self.assertEqual(code, 2)
        self.assertTrue(any("todo.alpha.md" in error for error in report["errors"]))
        self.assertTrue(any("inline `Requires: slug1 slug2`" in error for error in report["errors"]))

        (self.root / "meta" / "todos" / "todo.beta.md").write_text(
            "---\nnode: firth.governance.loop\nstatus: open\n---\n\n"
            "Requires: alpha\n\n## Requires:\n- `later`\n",
            encoding="utf-8",
        )
        code, report = self.run_selector()
        self.assertEqual(code, 2)
        self.assertTrue(any("todo.beta.md" in error for error in report["errors"]))

    def test_malformed_requires_lines_fail_closed(self) -> None:
        (self.root / "meta" / "todos" / "todo.alpha.md").write_text(
            "---\nnode: firth.governance.loop\nstatus: open\n---\n\n"
            "## Requires: missing\n",
            encoding="utf-8",
        )
        (self.root / "meta" / "todos" / "todo.beta.md").write_text(
            "---\nnode: firth.governance.loop\nstatus: open\n---\n\n"
            "Requires missing\n",
            encoding="utf-8",
        )
        (self.root / "meta" / "todos" / "todo.gamma.md").write_text(
            "---\nnode: firth.governance.loop\nstatus: open\n---\n\n"
            "Requires: alpha\nRequires: beta\n",
            encoding="utf-8",
        )
        code, report = self.run_selector()
        self.assertEqual(code, 2)
        self.assertEqual(len(report["errors"]), 3)

    def test_requires_list_continuations_fail_closed(self) -> None:
        cases = {
            "todo.alpha.md": "Requires:\n- `alpha`\n",
            "todo.beta.md": "Requires: alpha\n- `beta`\n",
            "todo.gamma.md": "- Requires: alpha\n",
        }
        for filename, requires_body in cases.items():
            (self.root / "meta" / "todos" / filename).write_text(
                "---\nnode: firth.governance.loop\nstatus: open\n---\n\n"
                + requires_body,
                encoding="utf-8",
            )
        code, report = self.run_selector()
        self.assertEqual(code, 2)
        self.assertEqual(len(report["errors"]), 3)

    def test_inline_requires_reports_open_dependency_as_ineligible(self) -> None:
        self.todo("todo.alpha.md")
        self.todo("todo.beta.md", requires="alpha")
        code, report = self.run_selector()
        self.assertEqual(code, 0)
        self.assertEqual(report["ineligible_open"], [{"missing": ["alpha"], "slug": "beta"}])

    def test_requires_accepts_commas_and_whitespace(self) -> None:
        self.todo("todo.alpha.md", status="done")
        self.todo("todo.beta.md", status="done")
        self.todo("todo.comma.md", requires="alpha,beta")
        self.todo("todo.space.md", requires="alpha beta")
        code, report = self.run_selector()
        self.assertEqual(code, 0)
        self.assertEqual(report["eligible"], ["comma", "space"])

    def test_open_requires_not_done_is_ineligible(self) -> None:
        self.todo("todo.alpha.md")
        self.todo("todo.beta.md", requires="alpha")
        code, report = self.run_selector()
        self.assertEqual(code, 0)
        self.assertEqual(report["next"], "alpha")
        self.assertEqual(report["ineligible_open"], [{"missing": ["alpha"], "slug": "beta"}])

    def test_in_progress_surfaces_before_eligible(self) -> None:
        self.todo("todo.alpha.md", status="in_progress")
        self.todo("todo.beta.md")
        code, report = self.run_selector()
        self.assertEqual(code, 0)
        self.assertEqual(report["next"], "alpha")

    def test_blocked_is_not_eligible(self) -> None:
        self.todo("todo.alpha.md", status="blocked")
        self.todo("todo.beta.md")
        code, report = self.run_selector()
        self.assertEqual(code, 0)
        self.assertEqual(report["next"], "beta")
        self.assertEqual(report["blocked"], ["alpha"])

    def test_open_requires_done_is_eligible(self) -> None:
        self.todo("todo.alpha.md", status="done")
        self.todo("todo.beta.md", requires="alpha")
        code, report = self.run_selector()
        self.assertEqual(code, 0)
        self.assertEqual(report["next"], "beta")
        self.assertEqual(report["eligible"], ["beta"])

    def test_eligible_tie_breaks_by_slug(self) -> None:
        self.todo("todo.zeta.md")
        self.todo("todo.alpha.md")
        code, report = self.run_selector()
        self.assertEqual(code, 0)
        self.assertEqual(report["next"], "alpha")
        self.assertEqual(report["eligible"], ["alpha", "zeta"])

    def test_node_filter_limits_selection_and_reports_nodes(self) -> None:
        self.todo("todo.alpha.md", extra="node: firth.language.kernel\n")
        self.todo("todo.beta.md", extra="node: firth.language.surface\n")
        code, report = self.run_selector("--node", "firth.language.surface")
        self.assertEqual(code, 0)
        self.assertEqual(report["next"], "beta")
        self.assertEqual(report["eligible"], ["beta"])
        self.assertEqual(report["node"]["alpha"], "firth.language.kernel")
        self.assertEqual(report["node"]["beta"], "firth.language.surface")

    def test_non_todo_markdown_filename_returns_two(self) -> None:
        self.todo("todo.alpha.md")
        (self.root / "meta" / "todos" / "notes.md").write_text("notes", encoding="utf-8")
        code, report = self.run_selector("--validate")
        self.assertEqual(code, 2)
        self.assertTrue(any("filename must match" in error for error in report["errors"]))


if __name__ == "__main__":
    unittest.main()
