#!/usr/bin/env python3
"""Behaviour tests for the pure loop preflight classifier."""

from __future__ import annotations

import copy
import hashlib
import importlib.util
import json
import os
import shutil
import subprocess
import tempfile
import unittest
from pathlib import Path
from typing import Any


ROOT = Path(__file__).resolve().parents[2]
SOURCE = Path(__file__).with_name("preflight_state.py")
SELECTOR = Path(__file__).with_name("select_unit.py")

spec = importlib.util.spec_from_file_location("preflight_state", SOURCE)
assert spec and spec.loader
preflight = importlib.util.module_from_spec(spec)
spec.loader.exec_module(preflight)


class PreflightStateTests(unittest.TestCase):
    def setUp(self) -> None:
        self.todos: dict[str, dict[str, Any]] = {
            "alpha": {"status": "open", "text": ""},
            "beta": {"status": "in_progress", "text": ""},
        }

    def bound_branch(
        self,
        unit: str = "alpha",
        head: str | None = None,
        incident_id: str = "019126d3-4f7a-7cc0-9b5f-123456789abc",
    ) -> dict[str, Any]:
        return {
            "name": f"loop/resolver.{incident_id.replace('-', '')}",
            "head": head or "b" * 40,
            "unit": unit,
            "incident_id": incident_id,
        }

    def bound_pr(
        self,
        unit: str = "alpha",
        head: str | None = None,
        state: str = "OPEN",
        incident_id: str = "019126d3-4f7a-7cc0-9b5f-123456789abc",
    ) -> dict[str, Any]:
        branch = self.bound_branch(unit, head, incident_id)
        return {
            "number": 7,
            "head_ref": branch["name"],
            "head_sha": branch["head"],
            "state": state,
            "unit": unit,
            "incident_id": branch["incident_id"],
        }

    def observation(self, **changes: Any) -> dict[str, Any]:
        value: dict[str, Any] = {
            "schema": 1,
            "failures": [],
            "observation_generation": 10,
            "observation_signature": "e" * 64,
            "forge": {"complete": True, "items": [], "error": None},
            "main_head": "a" * 40,
            "head": "a" * 40,
            "current_branch": "main",
            "dirty": False,
            "loop_branches": [],
            "live_findings": [],
            "backlog_modules": [],
            "park": None,
            "status_hash": "status-clean",
        }
        value.update(changes)
        return value

    def classify(self, **changes: Any) -> dict[str, Any]:
        observation = self.observation(**changes)
        before = copy.deepcopy(observation)
        result = preflight.classify(observation, self.todos)
        self.assertEqual(observation, before, "classification mutated its observation")
        self.assertEqual(result["schema"], 1)
        self.assertIn(result["verdict"], preflight.VERDICTS)
        return result

    def test_fresh(self) -> None:
        result = self.classify()
        self.assertEqual(result["verdict"], "fresh")
        self.assertEqual(result["observation_generation"], 10)
        self.assertEqual(result["observation_signature"], "e" * 64)

    def test_dirty_known_unit(self) -> None:
        branch = self.bound_branch()
        result = self.classify(
            current_branch=branch["name"],
            head=branch["head"],
            dirty=True,
            loop_branches=[branch],
        )
        self.assertEqual(result["verdict"], "dirty-known-unit")
        self.assertEqual(result["slug"], "alpha")

    def test_dirty_unsafe_on_unknown_or_unbound_branch(self) -> None:
        result = self.classify(
            current_branch="loop/unknown",
            head="b" * 40,
            dirty=True,
            loop_branches=[{"name": "loop/unknown", "head": "b" * 40}],
        )
        self.assertEqual(result["verdict"], "dirty-unsafe")
        result = self.classify(
            current_branch="loop/alpha",
            head="b" * 40,
            dirty=True,
            loop_branches=[{"name": "loop/alpha", "head": "c" * 40}],
        )
        self.assertEqual(result["verdict"], "dirty-unsafe")

    def test_exactly_one_open_pr(self) -> None:
        branch = self.bound_branch()
        result = self.classify(
            current_branch=None,
            head="a" * 40,
            loop_branches=[branch],
            forge={
                "complete": True,
                "error": None,
                "items": [self.bound_pr()],
            },
        )
        self.assertEqual(result["verdict"], "open-pr")
        self.assertEqual(result["pr"], 7)

    def test_open_pr_requires_exact_local_tip(self) -> None:
        branch = self.bound_branch(head="c" * 40)
        result = self.classify(
            loop_branches=[branch],
            forge={
                "complete": True,
                "error": None,
                "items": [self.bound_pr(head="b" * 40)],
            },
        )
        self.assertEqual(result["verdict"], "observation-failed")

    def test_open_pr_rejects_an_extra_surviving_branch(self) -> None:
        result = self.classify(
            loop_branches=[
                self.bound_branch(),
                self.bound_branch(
                    "beta",
                    "c" * 40,
                    "019126d3-4f7a-7cc0-9b5f-123456789abd",
                ),
            ],
            forge={
                "complete": True,
                "error": None,
                "items": [self.bound_pr()],
            },
        )
        self.assertEqual(result["verdict"], "observation-failed")
        self.assertIn("not the only surviving", result["reason"])

    def test_multiple_open_prs_precede_dirty_state(self) -> None:
        alpha_branch = self.bound_branch()
        beta_branch = self.bound_branch(
            "beta",
            "c" * 40,
            "019126d3-4f7a-7cc0-9b5f-123456789abd",
        )
        branches = [alpha_branch, beta_branch]
        beta_pr = self.bound_pr(
            "beta",
            "c" * 40,
            incident_id="019126d3-4f7a-7cc0-9b5f-123456789abd",
        )
        beta_pr["number"] = 2
        result = self.classify(
            current_branch=alpha_branch["name"],
            head="b" * 40,
            dirty=True,
            loop_branches=branches,
            forge={
                "complete": True,
                "error": None,
                "items": [self.bound_pr(), beta_pr],
            },
        )
        self.assertEqual(result["verdict"], "multiple-open-prs")
        self.assertEqual(
            result["branches"],
            [
                "loop/resolver.019126d34f7a7cc09b5f123456789abc",
                "loop/resolver.019126d34f7a7cc09b5f123456789abd",
            ],
        )

    def test_merged_tip_cleanup_requires_exact_head(self) -> None:
        branch = self.bound_branch()
        merged_pr = self.bound_pr(state="MERGED")
        merged_pr["number"] = 3
        result = self.classify(
            loop_branches=[branch],
            forge={
                "complete": True,
                "error": None,
                "items": [merged_pr],
            },
        )
        self.assertEqual(result["verdict"], "merged-tip-cleanup")

    def test_recover_todo_precedes_open_pr(self) -> None:
        todos = dict(self.todos)
        todos["recover-alpha"] = {"status": "blocked", "text": "Failing-check: owner decision\n"}
        branch = self.bound_branch()
        pr = self.bound_pr()
        pr["number"] = 4
        observation = self.observation(
            loop_branches=[branch],
            forge={
                "complete": True,
                "error": None,
                "items": [pr],
            },
        )
        self.assertEqual(preflight.classify(observation, todos)["verdict"], "recover-todo")

    def test_done_recover_todo_needs_explicit_discard(self) -> None:
        branch = {"name": "loop/unknown", "head": "b" * 40}
        todos = dict(self.todos)
        todos["recover-unknown"] = {"status": "done", "text": "resolved\n"}
        self.assertEqual(
            preflight.classify(self.observation(loop_branches=[branch]), todos)["verdict"],
            "recover-todo",
        )
        todos["recover-unknown"] = {"status": "done", "text": "Maintainer-discard: authorised\n"}
        self.assertEqual(
            preflight.classify(self.observation(loop_branches=[branch]), todos)["verdict"],
            "surviving-orphan",
        )

    def test_surviving_adoptable_todo_finding_and_backlog(self) -> None:
        self.assertEqual(
            self.classify(loop_branches=[self.bound_branch("alpha")])["verdict"],
            "surviving-adoptable",
        )
        self.assertEqual(
            self.classify(
                loop_branches=[self.bound_branch("finding.one")],
                live_findings=["finding.one"],
            )["verdict"],
            "surviving-adoptable",
        )
        self.assertEqual(
            self.classify(
                loop_branches=[self.bound_branch("backlog.firth.runtime")],
                backlog_modules=["firth.runtime"],
            )["verdict"],
            "surviving-adoptable",
        )

    def test_surviving_orphan_is_lexicographic(self) -> None:
        result = self.classify(
            loop_branches=[
                {"name": "loop/zeta", "head": "b" * 40},
                {"name": "loop/gamma", "head": "c" * 40},
            ]
        )
        self.assertEqual(result["verdict"], "surviving-orphan")
        self.assertEqual(result["branch"], "loop/gamma")

    def test_stale_park_requires_bound_clean_state_and_no_writer(self) -> None:
        branch = self.bound_branch()
        park = {
            "branch": branch["name"],
            "head": branch["head"],
            "status_hash": "status-clean",
            "writer_present": False,
            "unit": branch["unit"],
            "incident_id": branch["incident_id"],
        }
        result = self.classify(loop_branches=[branch], park=park)
        self.assertEqual(result["verdict"], "stale-park")

    def test_unsafe_committed_park_on_writer_head_or_status_mismatch(self) -> None:
        branch = self.bound_branch()
        base = {
            "branch": branch["name"],
            "head": branch["head"],
            "status_hash": "status-clean",
            "writer_present": False,
            "unit": branch["unit"],
            "incident_id": branch["incident_id"],
        }
        for changes in (
            {"writer_present": True},
            {"head": "c" * 40},
            {"status_hash": "changed"},
        ):
            with self.subTest(changes=changes):
                park = {**base, **changes}
                self.assertEqual(
                    self.classify(loop_branches=[branch], park=park)["verdict"],
                    "unsafe-committed-park",
                )

    def test_uuid_branch_requires_consistent_incident_unit_bindings(self) -> None:
        incident = "019126d3-4f7a-7cc0-9b5f-123456789abc"
        branch_name = "loop/resolver.019126d34f7a7cc09b5f123456789abc"
        branch = {
            "name": branch_name,
            "head": "b" * 40,
            "unit": "alpha",
            "incident_id": incident,
        }
        result = self.classify(
            current_branch=branch_name,
            head="b" * 40,
            dirty=True,
            loop_branches=[branch],
        )
        self.assertEqual(result["verdict"], "dirty-known-unit")
        self.assertEqual(result["unit"], "alpha")
        self.assertEqual(result["incident_id"], incident)

        missing = dict(branch)
        missing.pop("unit")
        self.assertEqual(
            self.classify(loop_branches=[missing])["verdict"],
            "observation-failed",
        )

        conflicting_pr = {
            "complete": True,
            "error": None,
            "items": [
                {
                    "number": 7,
                    "head_ref": branch_name,
                    "head_sha": "b" * 40,
                    "state": "OPEN",
                    "unit": "beta",
                    "incident_id": incident,
                }
            ],
        }
        self.assertEqual(
            self.classify(loop_branches=[branch], forge=conflicting_pr)["verdict"],
            "observation-failed",
        )

        park = {
            "branch": branch_name,
            "head": "b" * 40,
            "status_hash": "status-clean",
            "writer_present": False,
            "unit": "beta",
            "incident_id": incident,
        }
        self.assertEqual(
            self.classify(loop_branches=[branch], park=park)["verdict"],
            "unsafe-committed-park",
        )

    def test_explicit_or_malformed_observation_failure_is_closed(self) -> None:
        self.assertEqual(self.classify(failures=["git status timed out"])["verdict"], "observation-failed")
        self.assertEqual(self.classify(main_head=None)["verdict"], "observation-failed")

    def test_observation_schema_must_be_exact_integer_one(self) -> None:
        for schema in (None, 0, 2, True, "1"):
            with self.subTest(schema=schema):
                observation = self.observation()
                if schema is None:
                    observation.pop("schema")
                else:
                    observation["schema"] = schema
                self.assertEqual(
                    preflight.classify(observation, self.todos)["verdict"],
                    "observation-failed",
                )

    def test_every_malformed_forge_item_fails_closed(self) -> None:
        malformed = (
            {"number": 1, "head_ref": "feature/not-loop", "head_sha": "b" * 40, "state": "OPEN"},
            {"number": 1, "head_ref": self.bound_branch()["name"], "head_sha": "b" * 40},
            {
                "number": 1,
                "head_ref": self.bound_branch()["name"],
                "head_sha": "b" * 40,
                "state": "OPEN",
                "unit": "beta",
                "incident_id": self.bound_branch()["incident_id"],
            },
            "not-an-object",
        )
        for item in malformed:
            with self.subTest(item=item):
                result = self.classify(
                    forge={"complete": True, "error": None, "items": [item]}
                )
                self.assertEqual(result["verdict"], "observation-failed")
    def test_non_object_and_optional_observations_fail_closed(self) -> None:
        self.assertEqual(preflight.classify([], self.todos)["verdict"], "observation-failed")
        self.assertEqual(
            preflight.classify(self.observation(), {"alpha": None})["verdict"],
            "observation-failed",
        )
        self.assertEqual(self.classify(live_findings=None)["verdict"], "observation-failed")
        self.assertEqual(self.classify(backlog_modules=None)["verdict"], "observation-failed")

    def test_unreadable_todo_bytes_are_reported_not_raised(self) -> None:
        with tempfile.TemporaryDirectory() as directory:
            root = Path(directory)
            todos = root / "meta" / "todos"
            todos.mkdir(parents=True)
            (todos / "todo.alpha.md").write_bytes(b"\xff\xfe")
            records, errors = preflight.load_todos(root)
            self.assertEqual(records, {})
            self.assertEqual(len(errors), 1)
            self.assertIn("unreadable todo", errors[0])

    def test_pagination_requires_explicit_next_cursor(self) -> None:
        result = preflight.collect_forge_pages(lambda _cursor: {"items": []})
        self.assertFalse(result["complete"])
        self.assertIn("omitted explicit next_cursor", result["error"])

    def test_incomplete_forge_is_failure_not_empty(self) -> None:
        result = self.classify(forge={"complete": False, "items": [], "error": "rate limited"})
        self.assertEqual(result["verdict"], "observation-failed")
        self.assertIn("rate limited", result["errors"])
        self.assertEqual(
            self.classify(forge={"complete": True, "items": [], "error": None})["verdict"],
            "fresh",
        )

    def test_complete_pagination(self) -> None:
        pages = {
            None: {"items": [{"number": 1}], "next_cursor": "next"},
            "next": {"items": [{"number": 2}], "next_cursor": None},
        }
        seen: list[str | None] = []

        def fetch(cursor: str | None) -> dict[str, Any]:
            seen.append(cursor)
            return pages[cursor]

        result = preflight.collect_forge_pages(fetch)
        self.assertTrue(result["complete"])
        self.assertEqual([item["number"] for item in result["items"]], [1, 2])
        self.assertEqual(seen, [None, "next"])

    def test_pagination_failure_and_cursor_loop_fail_closed(self) -> None:
        def rate_limited(_cursor: str | None) -> dict[str, Any]:
            raise RuntimeError("rate limited")

        self.assertEqual(preflight.collect_forge_pages(rate_limited)["complete"], False)
        self.assertIn("rate limited", preflight.collect_forge_pages(rate_limited)["error"])

        def repeated(_cursor: str | None) -> dict[str, Any]:
            return {"items": [], "next_cursor": "same"}

        result = preflight.collect_forge_pages(repeated)
        self.assertFalse(result["complete"])
        self.assertIn("repeated", result["error"])

    def test_cli_is_byte_for_byte_non_mutating_and_reuses_todo_parser(self) -> None:
        with tempfile.TemporaryDirectory() as directory:
            root = Path(directory)
            loop = root / "tools" / "loop"
            todos = root / "meta" / "todos"
            loop.mkdir(parents=True)
            todos.mkdir(parents=True)
            shutil.copy2(SOURCE, loop / SOURCE.name)
            shutil.copy2(SELECTOR, loop / SELECTOR.name)
            todo = todos / "todo.alpha.md"
            todo.write_text(
                "---\nnode: firth.governance.loop\nstatus: open\n---\n\nRequires:\n",
                encoding="utf-8",
            )
            observation = root / "observation.json"
            observation.write_text(json.dumps(self.observation()), encoding="utf-8")
            tracked = [loop / SOURCE.name, loop / SELECTOR.name, todo, observation]
            before = {path: hashlib.sha256(path.read_bytes()).hexdigest() for path in tracked}
            environment = dict(os.environ)
            environment["PYTHONDONTWRITEBYTECODE"] = "1"
            result = subprocess.run(
                ["python3", "-B", str(loop / SOURCE.name), "--root", str(root), str(observation)],
                text=True,
                capture_output=True,
                check=False,
                env=environment,
            )
            self.assertEqual(result.returncode, 0, result.stderr)
            self.assertEqual(json.loads(result.stdout)["verdict"], "fresh")
            after = {path: hashlib.sha256(path.read_bytes()).hexdigest() for path in tracked}
            self.assertEqual(after, before)
            self.assertFalse(any(path.name == "__pycache__" for path in root.rglob("__pycache__")))


if __name__ == "__main__":
    unittest.main()
