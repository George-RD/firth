#!/usr/bin/env python3
"""Live binding tests between the obligations matrix, the manifest and the gate.

`tools/loop/test_mvp_agent_gate.py` exercises the gate's behaviour over
synthetic trees. This suite checks the other half of the coverage slice: that
the real matrix names the real pinned gate, that the manifest stays the
authoritative inventory of acceptance inputs, and that those inputs are not
stale. It reads repository configuration, never the todo tracker, and it runs
no build, so a stale hash is caught in under a second and without a toolchain.
"""

from __future__ import annotations

import hashlib
import unittest
from pathlib import Path

import tomllib

ROOT = Path(__file__).resolve().parents[2]
OBLIGATIONS = ROOT / "tools" / "loop" / "obligations.toml"
MANIFEST = ROOT / "tools" / "loop" / "mvp_agent_manifest.toml"
GATE = "tools/loop/mvp_agent_gate.py"


def load(path: Path) -> dict:
    return tomllib.loads(path.read_text(encoding="utf-8"))


def digest(path: Path) -> str:
    return hashlib.sha256(path.read_bytes()).hexdigest()


class MvpAgentCoverageTests(unittest.TestCase):
    def setUp(self) -> None:
        self.obligations = load(OBLIGATIONS)
        self.manifest = load(MANIFEST)

    def test_the_matrix_names_the_pinned_gate_and_the_gate_exists(self) -> None:
        row = self.obligations["obligation"]["mvp-agent-authoring"]
        self.assertEqual(row["gate"], GATE)
        self.assertTrue((ROOT / GATE).is_file())

    def test_every_pinned_gate_exists_and_is_repository_relative(self) -> None:
        gates = {
            row["gate"]
            for row in self.obligations["obligation"].values()
            if isinstance(row.get("gate"), str)
        }
        self.assertIn(GATE, gates)
        for gate in gates:
            self.assertFalse(gate.startswith("/"), gate)
            self.assertTrue((ROOT / gate).is_file(), gate)

    def test_the_manifest_agrees_with_the_matrix_about_the_gate(self) -> None:
        self.assertEqual(self.manifest["gate_path"], GATE)

    def test_the_completion_profile_is_unchanged(self) -> None:
        """`completion.profile` is goal layer under dec.loop-autonomy clause 2a.

        Wiring a gate must not move it, so the binding suite pins it.
        """
        self.assertEqual(self.obligations["completion"]["profile"], "mvp")

    def test_the_authoring_row_is_inside_the_active_profile(self) -> None:
        row = self.obligations["obligation"]["mvp-agent-authoring"]
        self.assertEqual(row.get("milestone", "mvp"), "mvp")

    def test_the_manifest_is_the_authoritative_inventory(self) -> None:
        applications = self.manifest["applications"]
        self.assertGreaterEqual(applications["minimum"], 3)
        self.assertGreaterEqual(len(applications["entries"]), applications["minimum"])

    def test_no_acceptance_input_is_stale(self) -> None:
        inputs = self.manifest["inputs"]
        guide = ROOT / inputs["guide_path"]
        self.assertTrue(guide.is_file(), inputs["guide_path"])
        self.assertEqual(inputs["guide_sha256"], digest(guide), "the guide has drifted")
        for item in inputs["interface"]:
            path = ROOT / item["path"]
            self.assertTrue(path.is_file(), item["path"])
            self.assertEqual(item["sha256"], digest(path), f"{item['path']} has drifted")
        for entry in self.manifest["applications"]["entries"]:
            source = ROOT / entry["source_path"]
            transcript = ROOT / entry["transcript_path"]
            self.assertTrue(source.is_file(), entry["source_path"])
            self.assertTrue(transcript.is_file(), entry["transcript_path"])
            self.assertEqual(entry["transcript_sha256"], digest(transcript),
                             f"{entry['name']}: the transcript has drifted")
            actual = digest(source)
            self.assertEqual(entry["source_sha256"], actual, f"{entry['name']} has drifted")
            self.assertEqual(
                entry["transcript_output_sha256"],
                actual,
                f"{entry['name']}: the transcript records another output",
            )

    def test_every_pinned_adapter_stays_gate_required(self) -> None:
        """The adapters exist now, but the manifest records what the gate must
        exercise, not what happens to be installed. Relaxing this would let a
        future gate skip an entry point."""
        for name in ("elaborate", "compile", "reference_run", "vm_run"):
            entry = self.manifest["entry_point"][name]
            self.assertEqual(entry["availability"], "gate-required", name)
            self.assertEqual(entry["transport"], "structured-json", name)


if __name__ == "__main__":
    unittest.main()
