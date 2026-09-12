#!/usr/bin/env python3
"""Regenerate the SMT translation-rule and soundness-proof hashes.

`spec/smt/refinement-discharge-architecture.md` §3 requires the
translation-rule and soundness-proof hashes to be part of every SMT request
and every discharge record, so that a record cannot outlive the translation it
was produced under. `Firth.Smt.defaultSmtProofBindings` holds those hashes,
and this tool is what computes them: before it existed they were two literals
with no producing tool, which is a pinned constant rather than a binding.

Each hash covers a marked region of one of the sources listed in `SOURCES`:

* `-- firth:translation-rules-begin <name>` ... `-- firth:translation-rules-end <name>`
  encloses one translation rule set. Today: the typed-IR normaliser, the VC
  generator, the QF_LIA encoder and the SMT-LIB serialiser.
* `-- firth:translation-soundness-begin <name>` ... `-- firth:translation-soundness-end <name>`
  encloses the Lean-checked theorems for one of them, plus the adapter bridge
  that says what an `unsat` verdict establishes.

The spec's §3 sentence names five stages: the typed-IR normaliser, the VC
generator, the sort and theory encoder, each registered predicate translation,
and the final SMT-LIB serialiser. The first two live in the elaborator and the
rest in the SMT boundary, so the tool reads both files. Order is by file and
then by position, so an existing hash keeps its place in the list when a
region is added after it.

Every region hash also binds a conservative source envelope: every Lean file
under src/, the declared Lake configuration and dependency lock, and the Lean
toolchain pin. This includes unmarked helpers and their transitive local
sources without pretending a regex is a Lean dependency analyser. Comments
and unrelated Lean tests deliberately invalidate records too. The supported
layout has all source roots under src/ and no third-party Lake packages;
unsupported layouts, dependencies, missing files and symlinks fail closed.

Only the two literal pin lists are masked to avoid self-reference. The
initializer is parsed strictly; arbitrary code between declarations can never
be excluded. Source integrity remains distinct from semantic proof checking,
compiled-artifact authentication and actual solver invocation provenance.

Usage: python3 tools/loop/update_smt_proof_bindings.py [--check]

`--check` recomputes without writing and exits non-zero on drift. Unknown
arguments are errors, never an instruction to enter write mode.

Every translation rule needs a same-name soundness region. The established
four rule regions and the two proof-only bridge regions remain mandatory;
new stages must be introduced as matched rule/proof pairs. This checks the
coverage of declared regions and their source envelope, not the semantic
applicability of Lean proofs. The envelope assumes the declared Lake build,
not a hostile host or undeclared search-path overrides.
"""

from __future__ import annotations

import argparse
import hashlib
import json
import os
import re
import sys
import tomllib
from pathlib import Path

ROOT = Path(__file__).resolve().parents[2]
BINDINGS_SOURCE = ROOT / "src" / "smt" / "Firth" / "SmtBoundary.lean"
SOURCES = [
    BINDINGS_SOURCE,
    ROOT / "src" / "elaborator" / "Firth" / "Refinement.lean",
]

RULE_FIELD = "translationRuleHashes"
PROOF_FIELD = "translationSoundnessProofHashes"

BEGIN = re.compile(r"^-- firth:(translation-rules|translation-soundness)-begin (\S+)$")
END = re.compile(r"^-- firth:(translation-rules|translation-soundness)-end (\S+)$")
# This line-comment namespace is reserved for exact delimiters. Recognise
# near-misses before ignoring ordinary text, including outside any region.
MARKER_LIKE = re.compile(r"^\s*--\s*firth\s*:", re.IGNORECASE)

REQUIRED_RULE_REGIONS = frozenset({"encoder", "serialiser", "normaliser", "vc-generator"})
# These theorems bridge stages rather than defining another translation rule.
REQUIRED_PROOF_ONLY_REGIONS = frozenset({"adapter", "normaliser-validity"})

# Only literal lists may be exempted from the envelope. In particular, do not
# match arbitrary text through the next definition: that hides helper code.
STRING_LITERAL = r'"[^"\\\r\n]*"'
LITERAL_LIST = rf"\[\s*(?:{STRING_LITERAL}(?:\s*,\s*{STRING_LITERAL})*\s*)?\]"
BINDINGS = re.compile(
    r"^def defaultSmtProofBindings : SmtProofBindings :=\n"
    r"  \{\s*translationRuleHashes :=\s*" + LITERAL_LIST +
    r"\s+translationSoundnessProofHashes :=\s*" + LITERAL_LIST +
    r"\s*\}[ \t]*\n",
    flags=re.MULTILINE,
)
MASKED_BINDINGS = (
    "def defaultSmtProofBindings : SmtProofBindings :=\n"
    "  { translationRuleHashes := []\n"
    "    translationSoundnessProofHashes := [] }\n"
)
BUILD_INPUTS = ("lean-toolchain", "lakefile.toml", "lake-manifest.json")
ENVELOPE_DOMAIN = b"firth.smt.source-envelope.v1"
REGION_DOMAIN = b"firth.smt.region-with-source-envelope.v1"


def binding_span(text: str) -> re.Match[str]:
    matches = list(BINDINGS.finditer(text))
    declarations = re.findall(r"^def defaultSmtProofBindings\b", text, flags=re.MULTILINE)
    if len(matches) != 1 or len(declarations) != 1:
        raise SystemExit(
            f"{BINDINGS_SOURCE}: expected exactly one literal defaultSmtProofBindings declaration"
        )
    return matches[0]


def frame(value: bytes) -> bytes:
    return str(len(value)).encode("ascii") + b":" + value


def read_input(path: Path) -> bytes:
    if path.is_symlink() or not path.is_file():
        raise SystemExit(f"{path}: source-envelope input must be a regular, non-symlink file")
    return path.read_bytes()


def reject_duplicate_members(pairs: list[tuple[str, object]]) -> dict[str, object]:
    result: dict[str, object] = {}
    for key, value in pairs:
        if key in result:
            raise ValueError(f"duplicate Lake manifest member {key!r}")
        result[key] = value
    return result


def walk_error(error: OSError) -> None:
    raise error


def source_snapshot() -> dict[Path, bytes]:
    """Capture the complete supported package, never an inferred import subset."""
    snapshot = {ROOT / name: read_input(ROOT / name) for name in BUILD_INPUTS}
    if (ROOT / "lakefile.lean").exists() or (ROOT / "lakefile.lean").is_symlink():
        raise SystemExit("source envelope does not support a competing lakefile.lean")
    config = tomllib.loads(snapshot[ROOT / "lakefile.toml"].decode("utf-8"))
    manifest = json.loads(snapshot[ROOT / "lake-manifest.json"], object_pairs_hook=reject_duplicate_members)
    if (not isinstance(manifest, dict) or manifest.get("packages") != [] or
            config.get("require")):
        raise SystemExit("source envelope does not support third-party Lake dependencies")
    targets = config.get("lean_lib", []) + config.get("lean_exe", [])
    if not targets or not all(isinstance(target, dict) for target in targets):
        raise SystemExit("source envelope requires declared Lean targets")
    roots = [target.get("srcDir", config.get("srcDir", ".")) for target in targets]
    if "srcDir" in config:
        roots.append(config["srcDir"])
    for root in roots:
        if (not isinstance(root, str) or not root or Path(root).is_absolute() or
                not Path(root).parts or Path(root).parts[0] != "src" or ".." in Path(root).parts):
            raise SystemExit(f"source envelope does not support source root {root!r}")
        path = ROOT
        for component in Path(root).parts:
            path = path / component
            if path.is_symlink() or not path.is_dir():
                raise SystemExit(f"{path}: source root must be a non-symlink directory")
    for directory, directories, files in os.walk(ROOT / "src", followlinks=False, onerror=walk_error):
        base = Path(directory)
        for name in directories:
            if (base / name).is_symlink():
                raise SystemExit(f"{base / name}: symlinked source directory is unsupported")
        for name in files:
            if name.endswith(".lean"):
                path = base / name
                snapshot[path] = read_input(path)
    for source in SOURCES:
        if source not in snapshot:
            raise SystemExit(f"{source}: required SMT source is missing from the envelope")
    return snapshot


def source_envelope(snapshot: dict[Path, bytes]) -> str:
    digest = hashlib.sha256(frame(ENVELOPE_DOMAIN))
    for path in sorted(snapshot, key=lambda path: path.relative_to(ROOT).as_posix()):
        content = snapshot[path]
        if path == BINDINGS_SOURCE:
            text = content.decode("utf-8")
            match = binding_span(text)
            content = (text[:match.start()] + MASKED_BINDINGS + text[match.end():]).encode("utf-8")
        digest.update(frame(path.relative_to(ROOT).as_posix().encode("utf-8")))
        digest.update(frame(content))
    return digest.hexdigest()


def region_hash(envelope: str, kind: str, name: str, body: str) -> str:
    values = [REGION_DOMAIN, envelope.encode("ascii"), kind.encode("ascii"),
              name.encode("utf-8"), body.encode("utf-8")]
    return "sha256:" + hashlib.sha256(b"".join(frame(value) for value in values)).hexdigest()


def regions(source: Path, text: str) -> tuple[list[tuple[str, str]], list[tuple[str, str]]]:
    """Extracts one file's marked regions, in order, refusing malformed markers."""
    rules: list[tuple[str, str]] = []
    proofs: list[tuple[str, str]] = []
    open_kind: str | None = None
    open_name: str | None = None
    collected: list[str] = []
    for number, line in enumerate(text.splitlines(), start=1):
        begin = BEGIN.match(line)
        end = END.match(line)
        if MARKER_LIKE.match(line) and not (begin or end):
            raise SystemExit(f"{source}:{number}: malformed SMT region marker")
        if begin:
            if open_kind is not None:
                raise SystemExit(f"{source}:{number}: a region is already open")
            open_kind, open_name = begin.group(1), begin.group(2)
            collected = []
            continue
        if end:
            if open_kind is None:
                raise SystemExit(f"{source}:{number}: no region is open")
            if (end.group(1), end.group(2)) != (open_kind, open_name):
                raise SystemExit(f"{source}:{number}: region markers do not match")
            body = "\n".join(collected) + "\n"
            if not body.strip():
                raise SystemExit(f"{source}:{number}: region {open_name!r} is empty")
            target = rules if open_kind == "translation-rules" else proofs
            target.append((open_name or "", body))
            open_kind, open_name = None, None
            continue
        if open_kind is not None:
            collected.append(line)
    if open_kind is not None:
        raise SystemExit(f"{source}: region {open_name!r} is never closed")
    return rules, proofs


def allRegions(snapshot: dict[Path, bytes] | None = None) -> tuple[list[tuple[str, str]], list[tuple[str, str]]]:
    """Collects every marked region across `SOURCES`, by file then position."""
    rules: list[tuple[str, str]] = []
    proofs: list[tuple[str, str]] = []
    ruleNames: set[str] = set()
    proofNames: set[str] = set()
    for source in SOURCES:
        text = source.read_text(encoding="utf-8") if snapshot is None else snapshot[source].decode("utf-8")
        fileRules, fileProofs = regions(source, text)
        # A rule set and its soundness proofs share a name on purpose. Two rule
        # sets, or two proof sets, sharing one would make a hash ambiguous
        # about what it covers.
        for name, _ in fileRules:
            if name in ruleNames:
                raise SystemExit(f"{source}: rule region {name!r} is declared twice")
            ruleNames.add(name)
        for name, _ in fileProofs:
            if name in proofNames:
                raise SystemExit(f"{source}: soundness region {name!r} is declared twice")
            proofNames.add(name)
        rules.extend(fileRules)
        proofs.extend(fileProofs)
    if not rules:
        raise SystemExit("no translation-rule region is marked")
    if not proofs:
        raise SystemExit("no translation-soundness region is marked")
    missing_rules = REQUIRED_RULE_REGIONS - ruleNames
    if missing_rules:
        raise SystemExit(f"missing required translation-rule regions: {', '.join(sorted(missing_rules))}")
    reserved_rules = ruleNames & REQUIRED_PROOF_ONLY_REGIONS
    if reserved_rules:
        raise SystemExit(f"proof-only regions cannot be translation rules: {', '.join(sorted(reserved_rules))}")
    missing_bridges = REQUIRED_PROOF_ONLY_REGIONS - proofNames
    if missing_bridges:
        raise SystemExit(f"missing required soundness regions: {', '.join(sorted(missing_bridges))}")
    unproved_rules = ruleNames - proofNames
    if unproved_rules:
        raise SystemExit(f"translation-rule regions without soundness regions: {', '.join(sorted(unproved_rules))}")
    unexpected_proofs = proofNames - ruleNames - REQUIRED_PROOF_ONLY_REGIONS
    if unexpected_proofs:
        raise SystemExit(f"soundness regions without translation rules: {', '.join(sorted(unexpected_proofs))}")
    return rules, proofs


def render(field: str, hashes: list[str]) -> str:
    entries = ",\n       ".join(f'"{value}"' for value in hashes)
    return f"    {field} :=\n      [{entries}]"


def main(argv: list[str] | None = None) -> int:
    parser = argparse.ArgumentParser(description=__doc__, allow_abbrev=False)
    parser.add_argument("--check", action="store_true", help="verify bindings without writing")
    check = parser.parse_args(argv).check
    snapshot = source_snapshot()
    text = snapshot[BINDINGS_SOURCE].decode("utf-8")
    match = binding_span(text)
    rules, proofs = allRegions(snapshot)
    envelope = source_envelope(snapshot)

    rule_hashes = [region_hash(envelope, "rule", name, body) for name, body in rules]
    proof_hashes = [region_hash(envelope, "soundness", name, body) for name, body in proofs]

    replacement = (
        "def defaultSmtProofBindings : SmtProofBindings :=\n"
        "  { "
        + render(RULE_FIELD, rule_hashes).lstrip()
        + "\n"
        + render(PROOF_FIELD, proof_hashes)
        + " }\n"
    )
    updated = text[: match.start()] + replacement + text[match.end():]

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
            f"{len(proof_hashes)} soundness regions; source envelope {envelope} "
            f"({len(snapshot)} inputs)"
        )
        return 0

    BINDINGS_SOURCE.write_text(updated, encoding="utf-8")
    print(
        f"wrote {BINDINGS_SOURCE.relative_to(ROOT)}: "
        f"{', '.join(name for name, _ in rules)} rules, "
        f"{', '.join(name for name, _ in proofs)} proofs"
    )
    return 0


if __name__ == "__main__":
    try:
        sys.exit(main())
    except (OSError, UnicodeError, ValueError, TypeError) as error:
        raise SystemExit(f"cannot bind SMT source envelope: {error}") from error
