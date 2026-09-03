#!/usr/bin/env python3
"""Fail-closed behaviour tests for the pinned MVP acceptance gate.

Every case here runs the gate against a synthetic repository tree, never the
real tracker, and every case asserts a refusal. The gate verifies provenance
before it executes anything, so a provenance violation is observable without a
toolchain: the assertions below check both that the gate refuses and that it
refuses for the stated reason.
"""

from __future__ import annotations

import hashlib
import json
import shutil
import subprocess
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
                "transcript\n", encoding="utf-8"
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
        result = subprocess.run(
            ["python3", str(self.root / "tools" / "loop" / "mvp_agent_gate.py")],
            text=True,
            capture_output=True,
            check=False,
        )
        return result.returncode, result.stderr

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
