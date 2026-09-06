#!/usr/bin/env python3
"""Fail-closed behaviour tests for the pinned MVP acceptance gate.

Provenance cases run the copied gate against synthetic repository trees, never
the real tracker. Execution wiring cases inspect adapter requests using an
injected runner. The separate language-examples gate executes real binaries.
Every refusal here must occur for its stated reason, not a missing toolchain.
"""

from __future__ import annotations

import hashlib
import importlib.util
import io
from contextlib import redirect_stderr, redirect_stdout
from unittest.mock import patch
import json
import shutil
import tempfile
import unittest
from pathlib import Path

LOOP = Path(__file__).parent

GUIDE = "# guide\n"
INTERFACE = "-- interface\n"
APPLICATION = ": app\n  ( -- result:Int^many )\n  42;\n"

INTERFACE_PATHS = (
    "src/agent/Firth/Agent/DiagnosticEnvelope.lean",
    "src/agent/Firth/Agent/Validation.lean",
    "src/agent/Firth/Agent/ElaboratorDiagnostics.lean",
)


def sha256(text: str) -> str:
    return hashlib.sha256(text.encode("utf-8")).hexdigest()


def transcript(index: int) -> str:
    paths = ["docs/firth-agent-guide.md", *INTERFACE_PATHS]
    context = "\n".join(f"- `{path}`" for path in paths)
    return (
        "---\n"
        f"file: examples/mvp/app{index}.firth\n"
        "type: model-authorship-transcript\n"
        f"output_sha256: {sha256(APPLICATION)}\n"
        "---\n# Transcript\n\n## Context\n\n"
        f"{context}\n\n## Model output\n\n```firth\n{APPLICATION}```\n"
    )


class MvpAgentGateTests(unittest.TestCase):
    def setUp(self) -> None:
        self.tmp = tempfile.TemporaryDirectory()
        self.root = Path(self.tmp.name)
        (self.root / "tools" / "loop").mkdir(parents=True)
        (self.root / "docs").mkdir(parents=True)
        (self.root / "examples" / "mvp").mkdir(parents=True)
        (self.root / "meta" / "sources").mkdir(parents=True)
        (self.root / "src" / "agent" / "Firth" / "Agent").mkdir(parents=True)
        shutil.copy2(LOOP / "mvp_agent_gate.py", self.root / "tools" / "loop" / "mvp_agent_gate.py")
        (self.root / "docs" / "firth-agent-guide.md").write_text(GUIDE, encoding="utf-8")
        for path in INTERFACE_PATHS:
            (self.root / path).write_text(INTERFACE, encoding="utf-8")
        for index in range(3):
            (self.root / "examples" / "mvp" / f"app{index}.firth").write_text(
                APPLICATION, encoding="utf-8"
            )
            (self.root / "meta" / "sources" / f"app{index}.md").write_text(
                transcript(index), encoding="utf-8"
            )

    def tearDown(self) -> None:
        self.tmp.cleanup()

    def entry(self, index: int, **overrides: object) -> dict[str, object]:
        entry: dict[str, object] = {
            "name": f"app{index}",
            "source_path": f"examples/mvp/app{index}.firth",
            "source_sha256": sha256(APPLICATION),
            "transcript_path": f"meta/sources/app{index}.md",
            "transcript_output_sha256": sha256(APPLICATION),
            "transcript_sha256": sha256(transcript(index)),
        }
        entry.update(overrides)
        return entry

    def manifest(self, entries: list[dict[str, object]] | None = None, **overrides: object) -> None:
        data: dict[str, object] = {
            "guide_path": "docs/firth-agent-guide.md",
            "inputs": {
                "model_only": True,
                "guide_path": "docs/firth-agent-guide.md",
                "guide_sha256": sha256(GUIDE),
                "interface_paths": list(INTERFACE_PATHS),
                "interface": [
                    {"path": path, "sha256": sha256(INTERFACE), "role": "r"}
                    for path in INTERFACE_PATHS
                ],
            },
            "applications": {
                "minimum": 3,
                "entries": entries if entries is not None else [self.entry(i) for i in range(3)],
            },
        }
        data.update(overrides)
        self.write_manifest(render_toml(data))

    def write_manifest(self, text: str) -> None:
        (self.root / "tools" / "loop" / "mvp_agent_manifest.toml").write_text(
            text, encoding="utf-8"
        )

    def run_gate(self) -> tuple[int, str]:
        # Import the copied entry point so ROOT still resolves to the synthetic
        # tree. A fresh module per call prevents state leaking between cases.
        spec = importlib.util.spec_from_file_location(
            "synthetic_gate", self.root / "tools/loop/mvp_agent_gate.py")
        gate = importlib.util.module_from_spec(spec)
        spec.loader.exec_module(gate)
        stderr, stdout = io.StringIO(), io.StringIO()
        with redirect_stderr(stderr), redirect_stdout(stdout), patch.object(
            gate, "build_toolchain", side_effect=gate.GateError("toolchain: unavailable in fixture")
        ):
            code = gate.main()
        return code, stderr.getvalue()

    def assert_refused(self, needle: str) -> None:
        code, stderr = self.run_gate()
        self.assertEqual(code, 1, stderr)
        payload = json.loads(stderr)
        self.assertEqual(payload["status"], "error")
        self.assertIn(needle, payload["error"])

    def test_a_missing_manifest_is_refused(self) -> None:
        self.assert_refused("missing tools/loop/mvp_agent_manifest.toml")

    def test_an_invalid_manifest_is_refused(self) -> None:
        self.write_manifest("this is not toml\n")
        self.assert_refused("invalid TOML")

    def test_a_drifted_guide_is_refused(self) -> None:
        self.manifest()
        (self.root / "docs" / "firth-agent-guide.md").write_text("# other\n", encoding="utf-8")
        self.assert_refused("the guide has drifted")

    def test_a_missing_guide_is_refused(self) -> None:
        self.manifest()
        (self.root / "docs" / "firth-agent-guide.md").unlink()
        self.assert_refused("missing file")

    def test_a_drifted_interface_file_is_refused(self) -> None:
        self.manifest()
        (self.root / INTERFACE_PATHS[1]).write_text("-- changed\n", encoding="utf-8")
        self.assert_refused("has drifted from its pinned hash")

    def test_an_unlisted_interface_path_is_refused(self) -> None:
        self.manifest()
        text = (self.root / "tools" / "loop" / "mvp_agent_manifest.toml").read_text(
            encoding="utf-8"
        )
        self.write_manifest(text.replace(INTERFACE_PATHS[0], "src/agent/Firth/Agent/Other.lean", 1))
        self.assert_refused("not listed in inputs.interface_paths")

    def test_a_missing_application_key_is_refused(self) -> None:
        entry = self.entry(0)
        del entry["transcript_output_sha256"]
        self.manifest([entry, self.entry(1), self.entry(2)])
        self.assert_refused("transcript_output_sha256: missing")

    def test_a_drifted_application_source_is_refused(self) -> None:
        self.manifest()
        (self.root / "examples" / "mvp" / "app1.firth").write_text(": other\n", encoding="utf-8")
        self.assert_refused("has drifted")

    def test_a_transcript_that_records_another_output_is_refused(self) -> None:
        self.manifest(
            [self.entry(0, transcript_output_sha256=sha256("something else")),
             self.entry(1), self.entry(2)]
        )
        self.assert_refused("records an output that is not the checked-in")

    def test_a_missing_transcript_is_refused(self) -> None:
        self.manifest()
        (self.root / "meta" / "sources" / "app2.md").unlink()
        self.assert_refused("missing file")

    def test_fewer_applications_than_the_minimum_is_refused(self) -> None:
        self.manifest([self.entry(0), self.entry(1)])
        self.assert_refused("expected at least 3 entries")

    def test_a_lowered_minimum_is_refused(self) -> None:
        self.manifest(applications={"minimum": 1, "entries": [self.entry(0)]})
        self.assert_refused("applications.minimum")

    def test_a_duplicate_application_name_is_refused(self) -> None:
        self.manifest([self.entry(0), self.entry(1, name="app0"), self.entry(2)])
        self.assert_refused("duplicate application")

    def test_a_path_that_escapes_the_repository_is_refused(self) -> None:
        self.manifest([self.entry(0, source_path="../outside.firth"), self.entry(1), self.entry(2)])
        self.assert_refused("source_path")

    def test_an_absolute_path_is_refused(self) -> None:
        self.manifest([self.entry(0, source_path="/etc/passwd"), self.entry(1), self.entry(2)])
        self.assert_refused("expected a non-empty relative path")

    def test_a_malformed_hash_is_refused(self) -> None:
        self.manifest([self.entry(0, source_sha256="NOTAHASH"), self.entry(1), self.entry(2)])
        self.assert_refused("expected a lowercase SHA-256")

    def test_provenance_is_verified_before_anything_is_executed(self) -> None:
        """A manifest whose provenance is sound reaches the toolchain stage.

        The synthetic tree has no Lake package, so the gate still refuses, but
        it refuses for a toolchain reason rather than a provenance one. That
        ordering is what makes every case above observable without a build.
        """
        self.manifest()
        code, stderr = self.run_gate()
        self.assertEqual(code, 1, stderr)
        error = json.loads(stderr)["error"]
        for provenance in ("drifted", "missing file", "invalid TOML", "SHA-256", "entries"):
            self.assertNotIn(provenance, error)
        self.assertTrue(
            error.startswith("toolchain:") or error.startswith("lake:") or error.startswith("cargo:"),
            error,
        )

    def test_transcript_byte_drift_is_refused(self) -> None:
        self.manifest()
        (self.root / "meta/sources/app0.md").write_text("fabricated\n", encoding="utf-8")
        self.assert_refused("transcript has drifted")

    def test_repinning_a_transcript_does_not_skip_its_content_checks(self) -> None:
        cases = [
            (transcript(0).replace(sha256(APPLICATION), "0" * 64), "records an output"),
            (transcript(0).replace("  42;", "  99;"), "model output bytes"),
            (transcript(0).replace("examples/mvp/app0.firth", "other.firth"), "another source path"),
            (transcript(0).replace("docs/firth-agent-guide.md", "docs/other.md"), "recorded inputs"),
            (transcript(0).replace("## Model output", "## Other"), "Model output section"),
            (transcript(0).replace("```firth", "```python"), "Firth output block"),
            (transcript(0).replace("type: model", "type: model\ntype: model"), "duplicate frontmatter"),
        ]
        for text, reason in cases:
            with self.subTest(reason=reason):
                (self.root / "meta/sources/app0.md").write_text(text, encoding="utf-8")
                self.manifest([self.entry(0, transcript_sha256=sha256(text)), self.entry(1), self.entry(2)])
                self.assert_refused(reason)

    def test_an_application_name_cannot_escape_the_scratch_workspace(self) -> None:
        for name in ("../outside", "/tmp/outside", ".", "..", "a/b", "a\\b"):
            with self.subTest(name=name):
                self.manifest([self.entry(0, name=name), self.entry(1), self.entry(2)])
                self.assert_refused("safe application name")


class ExecutionWiringTests(unittest.TestCase):
    def setUp(self) -> None:
        spec = importlib.util.spec_from_file_location("tested_gate", LOOP / "mvp_agent_gate.py")
        self.gate = importlib.util.module_from_spec(spec)
        spec.loader.exec_module(self.gate)

    def observations(self):
        shared = {"status": "success", "trap": None, "stack": [], "trace": []}
        reference = {**shared, "cost": {"total": 2, "steps": 0}, "world_observation": {"ids": []}}
        target = {**shared, "cost": {"total": 3, "kernel": 2, "steps": 0}, "world_observation": {"bytes": [0]}}
        return reference, target

    def test_word_entry_overhead_is_not_a_kernel_mismatch(self) -> None:
        self.gate.compare(*self.observations(), "calls-helper")

    def test_changed_kernel_cost_is_refused(self) -> None:
        reference, target = self.observations()
        target["cost"]["kernel"] = 1
        with self.assertRaisesRegex(self.gate.GateError, "kernel cost"):
            self.gate.compare(reference, target, "bad")

    def test_incomplete_or_malformed_costs_never_agree(self) -> None:
        for cost in ({}, {"total": 2, "kernel": 2}, {"total": 3, "kernel": True, "steps": 0}):
            reference, target = self.observations()
            target["cost"] = cost
            with self.subTest(cost=cost), self.assertRaises(self.gate.GateError):
                self.gate.compare(reference, target, "bad")

    def test_two_missing_stacks_do_not_count_as_agreement(self) -> None:
        reference, target = self.observations()
        del reference["stack"]
        del target["stack"]
        with self.assertRaisesRegex(self.gate.GateError, "incomplete"):
            self.gate.compare(reference, target, "bad")

    def test_effectful_observations_are_not_reduced_to_one_bit(self) -> None:
        reference, target = self.observations()
        reference["world_observation"] = {"ids": [1]}
        target["world_observation"] = {"bytes": [0, 99]}
        with self.assertRaisesRegex(self.gate.GateError, "effectful"):
            self.gate.compare(reference, target, "bad")

    def test_dual_fuel_exhaustion_is_not_success(self) -> None:
        reference, target = self.observations()
        for observation in (reference, target):
            observation.update(status="trap", trap="fuel-exhausted")
        with self.assertRaisesRegex(self.gate.GateError, "inconclusive"):
            self.gate.compare(reference, target, "bounded")

    def test_input_values_distinguish_booleans_from_integers(self) -> None:
        encoded = self.gate.initial_values([True, 1])
        self.assertEqual([value["literal"]["type"] for value in encoded], ["bool", "nat"])
        for values in (["1"], [-1], [2**63], [None], [1.0], {}):
            with self.subTest(values=values), self.assertRaises(self.gate.GateError):
                self.gate.initial_values(values)

    def test_multiword_rebuild_preserves_entry_dictionary_and_markers(self) -> None:
        main = {"name": "main", "checking_state": "checked", "proof_state": "available",
                "program": [{"kind": "word", "name": "helper"}]}
        helper = {"name": "helper", "checking_state": "checked", "proof_state": "available",
                  "program": [{"kind": "lit", "value": {"type": "nat", "value": 42}}]}
        elaboration = {
            "status": "success", "checked_words": [main, helper],
            "kernel_programs": [{"word": word["name"], "program": word["program"]} for word in (main, helper)],
            "erased_word_types": [{"word": "main", "type": {"input": {"row": None, "items": []}}}],
        }
        calls = {}
        reference, target = self.observations()
        def adapter(command, request, workspace, label):
            calls[label] = request
            if label.endswith("elaborate"):
                return elaboration
            if label.endswith("compile"):
                return {"status": "success", "target_program": {"entry": "main", "words": [main, helper]}}
            return reference if label.endswith("reference-run") else target
        with tempfile.TemporaryDirectory() as directory:
            root = Path(directory)
            source = root / "source.firth"
            source.write_text(": main ( -- n:Int ) helper; : helper ( -- n:Int ) 42;", encoding="utf-8")
            with patch.object(self.gate, "adapter", adapter):
                result = self.gate.rebuild({"name": "test", "entry": "main", "source": str(source),
                                           "source_path": "source.firth"}, root)
        self.assertEqual(calls["test compile"]["entry"], "main")
        request = calls["test reference-run"]
        self.assertEqual(set(request["dictionary"]), {"main", "helper"})
        self.assertEqual(request["checked_kernel"]["program"], main["program"])
        self.assertEqual(request["dictionary"]["helper"]["proof_state"], helper["proof_state"])
        self.assertEqual(result["kernel_cost"], 2)
        self.assertEqual(result["cost"], 3)

    def test_unchecked_dictionary_values_are_refused(self) -> None:
        for state in ({"checking_state": "unchecked", "proof_state": "available"},
                      {"checking_state": "checked", "proof_state": "deferred"}):
            word = {"name": "main", "program": [], **state}
            with self.subTest(state=state), self.assertRaises(self.gate.GateError):
                self.gate.checked_dictionary({"checked_words": [word]})


def render_toml(data: dict[str, object]) -> str:
    """A minimal TOML writer for the shapes these fixtures use.

    The standard library reads TOML but does not write it, and a fixture that
    hand-formatted every manifest would be harder to read than this.
    """

    def scalar(value: object) -> str:
        if isinstance(value, bool):
            return "true" if value else "false"
        if isinstance(value, int):
            return str(value)
        if isinstance(value, str):
            return json.dumps(value)
        if isinstance(value, list):
            return "[" + ", ".join(scalar(item) for item in value) + "]"
        raise TypeError(f"unsupported TOML scalar: {value!r}")

    lines: list[str] = []

    def table(prefix: str, values: dict[str, object]) -> None:
        simple = {
            key: value
            for key, value in values.items()
            if not isinstance(value, dict) and not is_table_array(value)
        }
        if prefix:
            lines.append(f"[{prefix}]")
        for key, value in simple.items():
            lines.append(f"{key} = {scalar(value)}")
        lines.append("")
        for key, value in values.items():
            name = f"{prefix}.{key}" if prefix else key
            if isinstance(value, dict):
                table(name, value)
            elif is_table_array(value):
                for item in value:
                    lines.append(f"[[{name}]]")
                    for inner_key, inner in item.items():
                        lines.append(f"{inner_key} = {scalar(inner)}")
                    lines.append("")

    def is_table_array(value: object) -> bool:
        return isinstance(value, list) and bool(value) and all(isinstance(i, dict) for i in value)

    table("", data)
    return "\n".join(lines) + "\n"


if __name__ == "__main__":
    unittest.main()
