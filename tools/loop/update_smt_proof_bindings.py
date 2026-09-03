#!/usr/bin/env python3
"""Regenerate the SMT translation-rule and soundness-proof hashes.

`spec/smt/refinement-discharge-architecture.md` §3 requires the
translation-rule and soundness-proof hashes to be part of every SMT request
and every discharge record, so that a record cannot outlive the translation it
was produced under. `Firth.Smt.defaultSmtProofBindings` holds those hashes,
and this tool is what computes them: before it existed they were two literals
with no producing tool, which is a pinned constant rather than a binding.

Each hash covers a marked region of `src/smt/Firth/SmtBoundary.lean`:

* `-- firth:translation-rules-begin <name>` ... `-- firth:translation-rules-end <name>`
  encloses one translation rule set. Today: the QF_LIA encoder and the SMT-LIB
  serialiser.
* `-- firth:translation-soundness-begin <name>` ... `-- firth:translation-soundness-end <name>`
  encloses the Lean-checked theorems for one of them, plus the adapter bridge
  that says what an `unsat` verdict establishes.

Hashing marked regions rather than the whole file avoids a fixed point: the
hashes themselves live in `defaultSmtProofBindings`, which sits outside every
marked region, so writing them cannot change what they cover. It is also more
honest than a whole-file hash, which would churn on a comment.

Usage: python3 tools/loop/update_smt_proof_bindings.py [--check]

`--check` recomputes without writing and exits non-zero on drift.
"""

from __future__ import annotations

import hashlib
import re
import sys
from pathlib import Path

ROOT = Path(__file__).resolve().parents[2]
SOURCE = ROOT / "src" / "smt" / "Firth" / "SmtBoundary.lean"

RULE_FIELD = "translationRuleHashes"
PROOF_FIELD = "translationSoundnessProofHashes"

BEGIN = re.compile(r"^-- firth:(translation-rules|translation-soundness)-begin (\S+)$")
END = re.compile(r"^-- firth:(translation-rules|translation-soundness)-end (\S+)$")

BINDINGS = re.compile(
    r"(def defaultSmtProofBindings : SmtProofBindings :=\n)"
    r"(?:.|\n)*?"
    r"(\ndef validSmtProofBindings)"
)


def regions(text: str) -> tuple[list[tuple[str, str]], list[tuple[str, str]]]:
    """Extracts the marked regions, in file order, refusing malformed markers."""
    rules: list[tuple[str, str]] = []
    proofs: list[tuple[str, str]] = []
    open_kind: str | None = None
    open_name: str | None = None
    collected: list[str] = []
    for number, line in enumerate(text.splitlines(), start=1):
        begin = BEGIN.match(line)
        end = END.match(line)
        if begin:
            if open_kind is not None:
                raise SystemExit(f"{SOURCE}:{number}: a region is already open")
            open_kind, open_name = begin.group(1), begin.group(2)
            collected = []
            continue
        if end:
            if open_kind is None:
                raise SystemExit(f"{SOURCE}:{number}: no region is open")
            if (end.group(1), end.group(2)) != (open_kind, open_name):
                raise SystemExit(f"{SOURCE}:{number}: region markers do not match")
            body = "\n".join(collected) + "\n"
            target = rules if open_kind == "translation-rules" else proofs
            target.append((open_name or "", body))
            open_kind, open_name = None, None
            continue
        if open_kind is not None:
            collected.append(line)
    if open_kind is not None:
        raise SystemExit(f"{SOURCE}: region {open_name!r} is never closed")
    if not rules:
        raise SystemExit(f"{SOURCE}: no translation-rule region is marked")
    if not proofs:
        raise SystemExit(f"{SOURCE}: no translation-soundness region is marked")
    return rules, proofs


def render(field: str, hashes: list[str]) -> str:
    entries = ",\n       ".join(f'"{value}"' for value in hashes)
    return f"    {field} :=\n      [{entries}]"


def main() -> int:
    check = "--check" in sys.argv[1:]
    text = SOURCE.read_text(encoding="utf-8")
    rules, proofs = regions(text)

    rule_hashes = [f"sha256:{hashlib.sha256(body.encode('utf-8')).hexdigest()}" for _, body in rules]
    proof_hashes = [
        f"sha256:{hashlib.sha256(body.encode('utf-8')).hexdigest()}" for _, body in proofs
    ]

    replacement = (
        "def defaultSmtProofBindings : SmtProofBindings :=\n"
        "  { "
        + render(RULE_FIELD, rule_hashes).lstrip()
        + "\n"
        + render(PROOF_FIELD, proof_hashes)
        + " }\n"
    )
    match = BINDINGS.search(text)
    if match is None:
        raise SystemExit(f"{SOURCE}: defaultSmtProofBindings was not found")
    updated = text[: match.start()] + replacement + text[match.start(2) :]

    if check:
        if updated != text:
            print(
                "smt proof bindings drift: run "
                "`python3 tools/loop/update_smt_proof_bindings.py`",
                file=sys.stderr,
            )
            return 1
        print(
            f"smt proof bindings match {len(rule_hashes)} rule and "
            f"{len(proof_hashes)} soundness regions"
        )
        return 0

    SOURCE.write_text(updated, encoding="utf-8")
    print(
        f"wrote {SOURCE.relative_to(ROOT)}: "
        f"{', '.join(name for name, _ in rules)} rules, "
        f"{', '.join(name for name, _ in proofs)} proofs"
    )
    return 0


if __name__ == "__main__":
    sys.exit(main())
