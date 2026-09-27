#!/usr/bin/env python3
"""Regenerate the proof records and the contract status of every exported word.

`lake env .lake/build/bin/firthProofRecords src/proofs/contracts.json` audits
each claimed theorem (see `src/compiler/Firth/ProofRecords.lean`) and reports
every exported word as `contract_verified` or `type_checked`. This script
writes that report to `src/proofs/records.json`.

Before trusting the audit, it runs it on the fixtures in `src/prooftests/`:
every theorem in `Refused.lean` must be refused for its expected reason, and
every theorem in `Accepted.lean` must be accepted with exactly its expected
coverage. An audit that stopped refusing, or began to overclaim coverage,
fails here rather than admitting a proof.

Usage: python3 tools/loop/update_proof_records.py [--check]

Run from the repository root after `lake build`. `--check` exits non-zero if
the checked-in report differs, which includes a covered word whose body digest
changed, or if any contract is refused.
"""
from __future__ import annotations

import json
import subprocess
import sys
import tempfile
from pathlib import Path

ROOT = Path(__file__).resolve().parents[2]
AUDIT = ROOT / ".lake" / "build" / "bin" / "firthProofRecords"
CONTRACTS = ROOT / "src" / "proofs" / "contracts.json"
REPORT = ROOT / "src" / "proofs" / "records.json"

REFUSED = "Firth.ProofTests.Refused"
EXPECTED_REFUSALS = {
    f"{REFUSED}.native": "rests on refused axioms",
    f"{REFUSED}.unrelated": "statement runs under no reference registry",
    f"{REFUSED}.notATheorem": "not a theorem",
    f"{REFUSED}.namesNoWord": "statement runs under no reference registry",
    f"{REFUSED}.foreignDictionary": "statement names Programs.Allocate bodies but not",
}
# Each accepted fixture and the exact (module, word) pairs it must cover. The
# first guards against coverage overclaim: it uses the whole sum-to dictionary
# but states a fact about sum-acc only.
EXPECTED_COVERAGE = {
    "Firth.ProofTests.Accepted.narrow": [("Programs.SumTo", "sum-acc")],
}


def audit(*args: str) -> subprocess.CompletedProcess[str]:
    return subprocess.run(["lake", "env", str(AUDIT), *args], cwd=ROOT,
                          capture_output=True, text=True, check=False)


def audit_fixtures(module: str, names: list[str]) -> subprocess.CompletedProcess[str]:
    contracts = [{"theorem": name, "module": module, "claim": "fixture"} for name in names]
    with tempfile.TemporaryDirectory() as scratch:
        path = Path(scratch) / "fixtures.json"
        path.write_text(json.dumps(contracts), encoding="utf-8")
        return audit("--fixtures", str(path))


def check_fixtures() -> list[str]:
    problems: list[str] = []
    result = audit_fixtures("prooftests.Refused", list(EXPECTED_REFUSALS))
    if result.returncode != 1:
        problems.append(f"refusal fixtures: audit exited {result.returncode}, expected 1")
    refusals = [line for line in result.stderr.splitlines() if line.startswith("refused: ")]
    for name, reason in EXPECTED_REFUSALS.items():
        if not any(line.startswith(f"refused: {name}: {reason}") for line in refusals):
            problems.append(f"the audit did not refuse {name} ({reason}): {refusals}")
    if len(refusals) != len(EXPECTED_REFUSALS):
        problems.append(f"expected {len(EXPECTED_REFUSALS)} refusals, got {refusals}")

    result = audit_fixtures("prooftests.Accepted", list(EXPECTED_COVERAGE))
    if result.returncode != 0:
        problems.append(f"accepted fixtures were refused:\n{result.stderr}")
        return problems
    records = {record["theorem"]: record for record in json.loads(result.stdout)["records"]}
    for name, expected in EXPECTED_COVERAGE.items():
        covered = [(item["module"], item["word"]) for item in records[name]["covers"]]
        if covered != expected:
            problems.append(f"{name} covers {covered}, expected exactly {expected}")
    return problems


def main() -> int:
    check = "--check" in sys.argv[1:]
    if not AUDIT.is_file():
        print(f"missing {AUDIT} (run `lake build` first)", file=sys.stderr)
        return 2
    problems = check_fixtures()
    if problems:
        for problem in problems:
            print(problem, file=sys.stderr)
        return 1
    result = audit(str(CONTRACTS))
    if result.returncode != 0:
        print(result.stderr, file=sys.stderr, end="")
        print("proof audit refused a contract; nothing is recorded", file=sys.stderr)
        return 1
    report = result.stdout
    json.loads(report)
    if check:
        current = REPORT.read_text(encoding="utf-8") if REPORT.is_file() else ""
        if current != report:
            print("stale proof records: run `python3 tools/loop/update_proof_records.py`",
                  file=sys.stderr)
            return 1
        verified = report.count('"status": "contract_verified"')
        print(f"proof records match; {verified} exported words are contract_verified")
        return 0
    REPORT.write_text(report, encoding="utf-8")
    print(f"wrote {REPORT.relative_to(ROOT)}")
    return 0


if __name__ == "__main__":
    sys.exit(main())
