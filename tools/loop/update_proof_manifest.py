#!/usr/bin/env python3
"""Regenerate the refinement proof-module manifest from built artefacts.

`lake test` authenticates six governed proof modules by comparing the
sha256 of each built `.olean` against
`src/elaborator/refinement-proof-module.sha256` (see
`governedProofModules` in `src/elaborator/Firth/Refinement.lean`).
Whenever any governed module's source changes, the manifest must be
regenerated from a fresh `lake build` or the gate fails with
"refinement proof-module hash is unavailable".

Usage: python3 tools/loop/update_proof_manifest.py [--check]

Run from the repository root after `lake build`. `--check` verifies the
manifest without writing and exits non-zero on drift.
"""
from __future__ import annotations

import hashlib
import sys
from pathlib import Path

# Order must match governedProofModules in Refinement.lean exactly:
# the manifest is positional.
GOVERNED_MODULES = [
    "elaborator/Firth/Refinement.olean",
    "elaborator/Firth/StackEffect.olean",
    "elaborator/Firth/Erasure.olean",
    "elaborator/Firth/Parser.olean",
    "smt/Firth/SmtBoundary.olean",
    "Firth/Interpreter.olean",
]


def main() -> int:
    root = Path(__file__).resolve().parents[2]
    check = "--check" in sys.argv[1:]
    lib = root / ".lake" / "build" / "lib" / "lean"
    manifest = root / "src" / "elaborator" / "refinement-proof-module.sha256"

    lines: list[str] = []
    for module in GOVERNED_MODULES:
        olean = lib / module
        if not olean.is_file():
            print(f"missing built artefact: {olean} (run `lake build` first)",
                  file=sys.stderr)
            return 2
        digest = hashlib.sha256(olean.read_bytes()).hexdigest()
        lines.append(f"sha256:{digest}")
    content = "\n".join(lines) + "\n"

    if check:
        current = manifest.read_text(encoding="utf-8") if manifest.is_file() else ""
        if current != content:
            print("manifest drift: run `python3 tools/loop/update_proof_manifest.py`",
                  file=sys.stderr)
            return 1
        print("manifest matches built artefacts")
        return 0

    manifest.write_text(content, encoding="utf-8")
    print(f"wrote {manifest.relative_to(root)} ({len(lines)} modules)")
    return 0


if __name__ == "__main__":
    sys.exit(main())
