#!/usr/bin/env python3
"""Lint the sealed SMT solver provenance boundary.

`Firth.Smt.Solver.Attested` is the type through which every solver result and
rerun verdict reaches the refinement-discharge result boundary. Its
constructor is private to `src/smt/Firth/SmtSolver.lean`, the one module that
spawns the solver, so outside that module the `provenance` field is a
statement about which path produced the value and not a field a caller filled
in. The boundary in `src/elaborator/Firth/Refinement.lean` publishes a
discharge record only behind a check of that field.

Lean's `private` is a naming discipline: the constructor still exists under a
mangled name, and metaprogramming could reach it. This lint refuses the
in-repository ways of doing so, and refuses a boundary that grew a third way
to publish a record. It checks, textually:

* `SmtSolver.lean` declares `structure Attested` exactly once and it contains
  the file's only `private mk ::` line;
* no other `.lean` file under `src/` declares a `structure Attested`, names
  `Attested.mk`, or names `_private`; and no line mentioning `Attested` names
  `Name.mkNum`, `.num 0` or `mkConst`, which are how a mangled constructor
  would be rebuilt; `SmtSolver.lean` itself names none of those either;
* `Refinement.lean` imports `smt.Firth.SmtSolver`, takes the attested result
  and verdict types at its two boundary functions, and builds a non-empty
  `dischargeRecords := [...]` at exactly two sites, each within a few lines
  after a `.provenance != .pinnedProcess` gate.

This is a lint, not a proof. It cannot see through macros, it checks the gate
by proximity rather than by control flow, and it says nothing about Lean code
outside this repository, which is outside the trusted computing base. What
authenticates the built module is the compiled proof-module manifest, and what
binds its source is the SMT source envelope; this lint is the cheap, early
check that the seal has not been worked around in the tree.

Usage: python3 tools/loop/check_smt_attestation.py [--root PATH]
"""

from __future__ import annotations

import argparse
import re
import sys
from pathlib import Path

SOLVER = Path("src/smt/Firth/SmtSolver.lean")
BOUNDARY = Path("src/elaborator/Firth/Refinement.lean")
SOLVER_IMPORT = "import smt.Firth.SmtSolver"
PRIVATE_CONSTRUCTOR = re.compile(r"^\s*private mk ::\s*$")
STRUCTURE = re.compile(r"^\s*(?:private\s+|protected\s+)?structure\s+(\S+)")
ATTESTED_STRUCTURE = re.compile(r"^structure Attested\b")
FORBIDDEN_ANYWHERE = ("Attested.mk", "_private")
FORBIDDEN_NEAR_ATTESTED = ("Name.mkNum", ".num 0", "mkConst")
RECORD_SITE = re.compile(r"dischargeRecords\s*:=\s*\[\s*[^\]\s]")
GATE = re.compile(r"\.provenance\s*!=\s*\.pinnedProcess")
GATE_WINDOW = 6
EXPECTED_SITES = 2
BOUNDARY_SIGNATURES = (
    "(attested : Firth.Smt.Solver.AttestedResult)",
    "(attested : Firth.Smt.Solver.AttestedVerdict)",
)


def lean_sources(root: Path) -> list[Path]:
    return sorted(path for path in (root / "src").rglob("*.lean") if path.is_file())


def check_solver(root: Path) -> list[str]:
    path = root / SOLVER
    if not path.is_file():
        return [f"{SOLVER}: missing"]
    errors: list[str] = []
    lines = path.read_text(encoding="utf-8").splitlines()
    header = ""
    structures = 0
    sealed_inside = 0
    sealed_total = 0
    for number, line in enumerate(lines, start=1):
        if line and not line[0].isspace():
            header = line
            if ATTESTED_STRUCTURE.match(line):
                structures += 1
        if PRIVATE_CONSTRUCTOR.match(line):
            sealed_total += 1
            if ATTESTED_STRUCTURE.match(header):
                sealed_inside += 1
            else:
                errors.append(f"{SOLVER}:{number}: private constructor outside structure Attested")
        for token in FORBIDDEN_NEAR_ATTESTED + ("_private",):
            if token in line:
                errors.append(f"{SOLVER}:{number}: names {token!r}")
    if structures != 1:
        errors.append(f"{SOLVER}: expected exactly one `structure Attested`, found {structures}")
    if sealed_inside != 1 or sealed_total != 1:
        errors.append(
            f"{SOLVER}: expected exactly one `private mk ::` inside structure Attested, "
            f"found {sealed_inside} inside and {sealed_total} in the file"
        )
    return errors


def check_other_sources(root: Path) -> list[str]:
    errors: list[str] = []
    solver = root / SOLVER
    for path in lean_sources(root):
        if path == solver:
            continue
        relative = path.relative_to(root).as_posix()
        for number, line in enumerate(path.read_text(encoding="utf-8").splitlines(), start=1):
            for token in FORBIDDEN_ANYWHERE:
                if token in line:
                    errors.append(f"{relative}:{number}: names {token!r}")
            if "Attested" in line:
                for token in FORBIDDEN_NEAR_ATTESTED:
                    if token in line:
                        errors.append(f"{relative}:{number}: names {token!r} next to Attested")
            declared = STRUCTURE.match(line)
            if declared and declared.group(1) == "Attested":
                errors.append(f"{relative}:{number}: declares another structure Attested")
    return errors


def check_boundary(root: Path) -> list[str]:
    path = root / BOUNDARY
    if not path.is_file():
        return [f"{BOUNDARY}: missing"]
    errors: list[str] = []
    text = path.read_text(encoding="utf-8")
    lines = text.splitlines()
    if SOLVER_IMPORT not in lines:
        errors.append(f"{BOUNDARY}: does not import smt.Firth.SmtSolver")
    for signature in BOUNDARY_SIGNATURES:
        if signature not in text:
            errors.append(f"{BOUNDARY}: boundary signature {signature!r} is absent")
    sites = [number for number, line in enumerate(lines, start=1) if RECORD_SITE.search(line)]
    if len(sites) != EXPECTED_SITES:
        errors.append(
            f"{BOUNDARY}: expected {EXPECTED_SITES} record-publishing sites, "
            f"found {len(sites)} at lines {sites}"
        )
    for number in sites:
        window = lines[max(0, number - 1 - GATE_WINDOW):number]
        if not any(GATE.search(line) for line in window):
            errors.append(
                f"{BOUNDARY}:{number}: dischargeRecords is built without a provenance gate "
                f"within the preceding {GATE_WINDOW} lines"
            )
    return errors


def check(root: Path) -> list[str]:
    return check_solver(root) + check_other_sources(root) + check_boundary(root)


def main(argv: list[str] | None = None) -> int:
    parser = argparse.ArgumentParser(description=__doc__, allow_abbrev=False)
    parser.add_argument("--root", type=Path, default=Path(__file__).resolve().parents[2])
    args = parser.parse_args(argv)
    errors = check(args.root)
    if errors:
        print("smt attestation lint failed", file=sys.stderr)
        for error in errors:
            print(f"- {error}", file=sys.stderr)
        return 1
    print("smt attestation lint passed: one sealed constructor, two gated record sites")
    return 0


if __name__ == "__main__":
    sys.exit(main())
