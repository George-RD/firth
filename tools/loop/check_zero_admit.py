#!/usr/bin/env python3
"""Fail if Lean source contains proof escape hatches.

`native_decide` is one: its proofs rest on `Lean.ofReduceBool`, which trusts
the compiled evaluator rather than the kernel (AGENTS.md rule 11).
"""

from pathlib import Path
import re
import sys

pattern = re.compile(r"\b(?:sorry|admit|axiom|native_decide)\b")
matches = []
for path in sorted(Path("src").rglob("*.lean")):
    for line_number, line in enumerate(path.read_text().splitlines(), 1):
        if pattern.search(line):
            matches.append(f"{path}:{line_number}:{line.strip()}")

if matches:
    print("zero-admit check failed")
    print("\n".join(matches))
    sys.exit(1)

print("zero-admit check passed")
