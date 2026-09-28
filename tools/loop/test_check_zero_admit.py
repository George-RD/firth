#!/usr/bin/env python3
"""The zero-admit check refuses each proof escape hatch, and passes clean source."""
import subprocess
import sys
import tempfile
import unittest
from pathlib import Path

CHECK = Path(__file__).resolve().parent / "check_zero_admit.py"


def run_on(source: str) -> subprocess.CompletedProcess:
    with tempfile.TemporaryDirectory() as root:
        (Path(root) / "src").mkdir()
        (Path(root) / "src" / "Planted.lean").write_text(source)
        return subprocess.run([sys.executable, str(CHECK)], cwd=root,
                              capture_output=True, text=True)


class ZeroAdmitTests(unittest.TestCase):
    def test_clean_source_passes(self):
        result = run_on("theorem ok : 1 + 1 = 2 := by decide\n")
        self.assertEqual(result.returncode, 0, result.stdout)

    def test_each_escape_hatch_fails(self):
        planted = {
            "sorry": "theorem t : 1 = 2 := by sorry\n",
            "admit": "theorem t : 1 = 2 := by admit\n",
            "axiom": "axiom bad : 1 = 2\n",
            "native_decide": "theorem t : 2 ^ 10 = 1024 := by native_decide\n",
        }
        for name, source in planted.items():
            with self.subTest(name=name):
                result = run_on(source)
                self.assertEqual(result.returncode, 1, result.stdout)
                self.assertIn("Planted.lean:1:", result.stdout)

    def test_identifiers_containing_a_hatch_pass(self):
        # `sorryAx` in prose names the constant; `decide` is not `native_decide`.
        result = run_on("-- refuses sorryAx\ntheorem t : 3 = 3 := by decide\n")
        self.assertEqual(result.returncode, 0, result.stdout)


if __name__ == "__main__":
    unittest.main()
