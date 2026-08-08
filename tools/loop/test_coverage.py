#!/usr/bin/env python3
"""Behaviour tests for the obligations coverage report."""

from __future__ import annotations

import json
import os
import shutil
import subprocess
import tempfile
import unittest
from pathlib import Path


LOOP = Path(__file__).parent


class CoverageTests(unittest.TestCase):
    def setUp(self) -> None:
        self.tmp = tempfile.TemporaryDirectory()
        self.root = Path(self.tmp.name)
        (self.root / "tools" / "loop").mkdir(parents=True)
        (self.root / "meta" / "todos").mkdir(parents=True)
        shutil.copy2(LOOP / "select_unit.py", self.root / "tools" / "loop" / "select_unit.py")
        shutil.copy2(LOOP / "coverage.py", self.root / "tools" / "loop" / "coverage.py")
        (self.root / "cairn.blueprint").write_text(
            'System Firth id "firth" {\n'
            '  Module Kernel id "firth.language.kernel" { path "files" }\n'
            '  Module Surface id "firth.language.surface" { path "spec/surface" }\n'
            '}\n'
            'firth.language.surface -> firth.language.kernel "depends"\n',
            encoding="utf-8",
        )

    def tearDown(self) -> None:
        self.tmp.cleanup()

    def todo(self, slug: str, status: str = "open", node: str = "firth.language.kernel") -> None:
        (self.root / "meta" / "todos" / f"todo.{slug}.md").write_text(
            f"---\nnode: {node}\nstatus: {status}\n---\n\nRequires:\n",
            encoding="utf-8",
        )

    def obligations(self, text: str) -> None:
        (self.root / "tools" / "loop" / "obligations.toml").write_text(text, encoding="utf-8")

    def run_coverage(
        self, *args: str, env: dict[str, str] | None = None
    ) -> tuple[int, dict[str, object]]:
        result = subprocess.run(
            ["python3", str(self.root / "tools" / "loop" / "coverage.py"), *args],
            text=True,
            capture_output=True,
            check=False,
            env=dict(os.environ, **env) if env else None,
        )
        return result.returncode, json.loads(result.stdout)

    def test_unknown_node_and_slug_are_validation_errors(self) -> None:
        self.todo("known")
        self.obligations(
            '[obligation.a]\nnode = "firth.unknown"\nsource = "test"\nsatisfied_by = ["missing"]\n'
        )
        code, report = self.run_coverage("--validate")
        self.assertEqual(code, 2)
        self.assertTrue(any("unknown node" in error for error in report["errors"]))
        self.assertTrue(any("unknown satisfied_by slug" in error for error in report["errors"]))

    def test_classifies_complete_inflight_ungenerated_and_blocked(self) -> None:
        self.todo("done", "done")
        self.todo("open", "open")
        self.todo("blocked", "blocked")
        self.obligations(
            '[obligation.a]\nnode = "firth.language.kernel"\nsource = "a"\nsatisfied_by = ["done"]\n\n'
            '[obligation.b]\nnode = "firth.language.kernel"\nsource = "b"\nsatisfied_by = ["open"]\n\n'
            '[obligation.c]\nnode = "firth.language.kernel"\nsource = "c"\nsatisfied_by = []\n\n'
            '[obligation.d]\nnode = "firth.language.kernel"\nsource = "d"\nsatisfied_by = ["blocked"]\n'
        )
        code, report = self.run_coverage()
        self.assertEqual(code, 0)
        self.assertEqual(report["complete"], ["a"])
        self.assertEqual(report["in_flight"], ["b"])
        self.assertEqual(report["ungenerated"], ["c"])
        self.assertEqual(report["blocked"], ["d"])
        self.assertEqual(report["first_incomplete"], "b")
        self.assertEqual(report["next_obligation"], "c")
        self.assertFalse(report["loop_exhausted_valid"])

    def test_dependency_gates_next_obligation_and_stable_order(self) -> None:
        self.obligations(
            '[obligation.a-surface]\nnode = "firth.language.surface"\nsource = "a"\nsatisfied_by = []\n\n'
            '[obligation.z-kernel]\nnode = "firth.language.kernel"\nsource = "z"\nsatisfied_by = []\n'
        )
        code, report = self.run_coverage()
        self.assertEqual(code, 0)
        self.assertEqual(report["next_obligation"], "z-kernel")

        self.todo("kernel-work", "in_progress")
        self.obligations(
            '[obligation.a-surface]\nnode = "firth.language.surface"\nsource = "a"\nsatisfied_by = []\n\n'
            '[obligation.z-kernel]\nnode = "firth.language.kernel"\nsource = "z"\nsatisfied_by = ["kernel-work"]\n'
        )
        code, report = self.run_coverage()
        self.assertEqual(code, 0)
        self.assertEqual(report["next_obligation"], "a-surface")

    def test_validate_success(self) -> None:
        self.todo("done", "done")
        self.obligations(
            '[obligation.a]\nnode = "firth.language.kernel"\nsource = "test"\nsatisfied_by = ["done"]\n'
        )
        code, report = self.run_coverage("--validate")
        self.assertEqual(code, 0)
        self.assertEqual(report, {"schema": 1, "valid": True})

    def test_mvp_profile_scopes_termination_and_generation(self) -> None:
        self.todo("done", "done")
        self.obligations(
            '[completion]\nprofile = "mvp"\n'
            '[obligation.core]\nnode = "firth.language.kernel"\nsource = "PRD R1"\n'
            'satisfied_by = ["done"]\n'
            '[obligation.later]\nnode = "firth.language.kernel"\nsource = "PRD S6"\n'
            'milestone = "post-mvp"\nsatisfied_by = []\n'
        )
        code, report = self.run_coverage()
        self.assertEqual(code, 0)
        self.assertEqual(report["profile"], "mvp")
        self.assertEqual(report["outside_profile"], ["later"])
        self.assertTrue(report["loop_exhausted_valid"])
        self.assertIsNone(report["next_obligation"])

    def test_missing_pinned_gate_holds_exhaustion_false(self) -> None:
        self.todo("done", "done")
        self.obligations(
            '[completion]\nprofile = "mvp"\n'
            '[obligation.core]\nnode = "firth.language.kernel"\nsource = "PRD R1"\n'
            'gate = "tools/loop/mvp_agent_gate.py"\nsatisfied_by = ["done"]\n'
        )
        code, report = self.run_coverage()
        self.assertEqual(code, 0)
        self.assertFalse(report["loop_exhausted_valid"])
        self.assertEqual(report["missing_gates"], ["tools/loop/mvp_agent_gate.py"])

    def test_present_pinned_gate_permits_exhaustion(self) -> None:
        self.todo("done", "done")
        (self.root / "tools" / "loop" / "mvp_agent_gate.py").write_text(
            "raise SystemExit(0)\n", encoding="utf-8"
        )
        self.obligations(
            '[completion]\nprofile = "mvp"\n'
            '[obligation.core]\nnode = "firth.language.kernel"\nsource = "PRD R1"\n'
            'gate = "tools/loop/mvp_agent_gate.py"\nsatisfied_by = ["done"]\n'
        )
        code, report = self.run_coverage()
        self.assertEqual(code, 0)
        self.assertTrue(report["loop_exhausted_valid"])
        self.assertEqual(report["missing_gates"], [])

    def test_failing_gate_holds_exhaustion_false_under_run_gates(self) -> None:
        self.todo("done", "done")
        (self.root / "tools" / "loop" / "mvp_agent_gate.py").write_text(
            "raise SystemExit(1)\n", encoding="utf-8"
        )
        self.obligations(
            '[completion]\nprofile = "mvp"\n'
            '[obligation.core]\nnode = "firth.language.kernel"\nsource = "PRD R1"\n'
            'gate = "tools/loop/mvp_agent_gate.py"\nsatisfied_by = ["done"]\n'
        )
        code, report = self.run_coverage("--run-gates")
        self.assertEqual(code, 0)
        self.assertFalse(report["loop_exhausted_valid"])
        self.assertEqual(report["failing_gates"], ["tools/loop/mvp_agent_gate.py"])

    def test_passing_gate_permits_exhaustion_under_run_gates(self) -> None:
        self.todo("done", "done")
        (self.root / "tools" / "loop" / "mvp_agent_gate.py").write_text(
            "raise SystemExit(0)\n", encoding="utf-8"
        )
        self.obligations(
            '[completion]\nprofile = "mvp"\n'
            '[obligation.core]\nnode = "firth.language.kernel"\nsource = "PRD R1"\n'
            'gate = "tools/loop/mvp_agent_gate.py"\nsatisfied_by = ["done"]\n'
        )
        code, report = self.run_coverage("--run-gates")
        self.assertEqual(code, 0)
        self.assertTrue(report["loop_exhausted_valid"])
        self.assertEqual(report["failing_gates"], [])

    def test_hung_gate_fails_closed_under_run_gates(self) -> None:
        self.todo("done", "done")
        (self.root / "tools" / "loop" / "mvp_agent_gate.py").write_text(
            "import time\ntime.sleep(30)\n", encoding="utf-8"
        )
        self.obligations(
            '[completion]\nprofile = "mvp"\n'
            '[obligation.core]\nnode = "firth.language.kernel"\nsource = "PRD R1"\n'
            'gate = "tools/loop/mvp_agent_gate.py"\nsatisfied_by = ["done"]\n'
        )
        code, report = self.run_coverage(
            "--run-gates", env={"COVERAGE_GATE_TIMEOUT": "1"}
        )
        self.assertEqual(code, 0)
        self.assertFalse(report["loop_exhausted_valid"])
        self.assertEqual(report["failing_gates"], ["tools/loop/mvp_agent_gate.py"])

    def test_full_profile_restores_whole_matrix_completion(self) -> None:
        self.todo("done", "done")
        self.obligations(
            '[completion]\nprofile = "full"\n'
            '[obligation.core]\nnode = "firth.language.kernel"\nsource = "PRD R1"\n'
            'satisfied_by = ["done"]\n'
            '[obligation.later]\nnode = "firth.language.kernel"\nsource = "PRD S6"\n'
            'milestone = "post-mvp"\nsatisfied_by = []\n'
        )
        code, report = self.run_coverage()
        self.assertEqual(code, 0)
        self.assertFalse(report["loop_exhausted_valid"])
        self.assertEqual(report["next_obligation"], "later")
        self.assertEqual(report["outside_profile"], [])

    def test_todo_mapped_only_to_inactive_rows_does_not_gate(self) -> None:
        self.todo("done", "done")
        self.todo("roadmap", "open")
        self.obligations(
            '[completion]\nprofile = "mvp"\n'
            '[obligation.core]\nnode = "firth.language.kernel"\nsource = "PRD R1"\n'
            'satisfied_by = ["done"]\n'
            '[obligation.later]\nnode = "firth.language.kernel"\nsource = "PRD S3"\n'
            'milestone = "post-mvp"\nsatisfied_by = ["roadmap"]\n'
        )
        code, report = self.run_coverage()
        self.assertEqual(code, 0)
        self.assertTrue(report["loop_exhausted_valid"])

    def test_unmapped_open_todo_still_gates_exhaustion(self) -> None:
        self.todo("done", "done")
        self.todo("stray", "open")
        self.obligations(
            '[completion]\nprofile = "mvp"\n'
            '[obligation.core]\nnode = "firth.language.kernel"\nsource = "PRD R1"\n'
            'satisfied_by = ["done"]\n'
        )
        code, report = self.run_coverage()
        self.assertEqual(code, 0)
        self.assertFalse(report["loop_exhausted_valid"])

    def test_inactive_only_dependency_node_does_not_deadlock(self) -> None:
        self.obligations(
            '[completion]\nprofile = "mvp"\n'
            '[obligation.gated]\nnode = "firth.language.surface"\nsource = "PRD R2"\n'
            'satisfied_by = []\n'
            '[obligation.later]\nnode = "firth.language.kernel"\nsource = "PRD S3"\n'
            'milestone = "post-mvp"\nsatisfied_by = []\n'
        )
        code, report = self.run_coverage()
        self.assertEqual(code, 0)
        self.assertEqual(report["next_obligation"], "gated")

    def test_invalid_profile_and_milestone_fail_validation(self) -> None:
        self.todo("done", "done")
        self.obligations(
            '[completion]\nprofile = "beta"\n'
            '[obligation.core]\nnode = "firth.language.kernel"\nsource = "PRD R1"\n'
            'milestone = "later"\nsatisfied_by = ["done"]\n'
        )
        code, report = self.run_coverage("--validate")
        self.assertEqual(code, 2)
        joined = " ".join(report["errors"])
        self.assertIn("completion.profile", joined)
        self.assertIn("milestone", joined)


if __name__ == "__main__":
    unittest.main()
