#!/usr/bin/env python3
"""Regenerate the proof records and the contract status of every exported word.

`lake env .lake/build/bin/firthProofRecords src/proofs/contracts.json` audits
each claimed contract (see `src/compiler/Firth/ProofRecords.lean`) and reports
every exported word as `contract_verified` or `type_checked`. This script
writes that report to `src/proofs/records.json`.

Before trusting the audit, it runs it on the fixtures in `src/prooftests/`:
every contract in `refused.json` must be refused for its expected reason, and
every contract in `accepted.json` must be accepted with exactly its expected
coverage and cost table. An audit that stopped refusing, or began to
overclaim coverage, fails here rather than admitting a proof.

It also plants two narrowed helpers, a definition and an inductive type, in
the preconditions of the `abs` fixtures in `src/prooftests/Helper.lean`. For
each it rebuilds that module and requires `--status` to stop counting that
record written before the edit, although the printed precondition is
unchanged. The file is restored and rebuilt afterwards.

It then reads the new report back with `firthProofRecords --status`, which
audits every record again and counts it only when the audit reproduces it
exactly. It plants one change at a time into the report: a stale cost table
digest, a stale registry digest, a stale body digest, a stale erased type, a
stale statement digest, a stale Lean version, an edited precondition, and a forged cover for a word
the record does not cover. Each must withdraw contract_verified from the words that record covers, and
the forged cover must not verify its word.

Usage: python3 tools/loop/update_proof_records.py [--check]

Run from the repository root after `lake build`. `--check` exits non-zero if
the checked-in report differs, which includes a covered word whose body digest
or erased type changed, or if any contract is refused.
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

FIXTURES = ROOT / "src" / "prooftests"
REFUSED = "Firth.ProofTests.Refused"
ACCEPTED = "Firth.ProofTests.Accepted"
NOT_THE_CONTRACT = "its statement is not"
# Each refused fixture and the start of its expected reason. The four
# NOT_THE_CONTRACT probes from falseHypothesis on were all accepted, as
# covering sum-to, by the audit this replaced.
EXPECTED_REFUSALS = {
    f"{REFUSED}.trustsCompiler": "rests on refused axioms [Lean.trustCompiler]",
    f"{REFUSED}.notATheorem": "not a theorem",
    f"{REFUSED}.unrelated": NOT_THE_CONTRACT,
    f"{REFUSED}.falseHypothesis": NOT_THE_CONTRACT,
    f"{REFUSED}.orTrue": NOT_THE_CONTRACT,
    f"{REFUSED}.registryOrTrue": NOT_THE_CONTRACT,
    f"{REFUSED}.vacuousPrecondition": NOT_THE_CONTRACT,
    f"{REFUSED}.otherRegistry": f"{REFUSED}.renamedGamma is not a reference registry",
    f"{REFUSED}.foreignDictionary": NOT_THE_CONTRACT,
    f"{ACCEPTED}.absOnly": NOT_THE_CONTRACT,
    "Firth.ProofTests.Gone.anything": "the source of prooftests.Gone",
}
# Each accepted fixture, the exact (module, word) pairs it must cover, and the
# cost table it must be bound to. sum-to calls sum-acc; abs calls nothing and
# its source's other words stay uncovered. The last two differ only in the
# cost table, so their digests must differ.
DEFAULT_COSTS = "Firth.Interpreter.defaultCosts"
HELPER = FIXTURES / "Helper.lean"
# Each planted helper edit: the theorem whose record it must withdraw, the
# text it replaces and what it puts there. Both narrow the precondition to
# x = 0 without changing the printed precondition or the contract's own
# definition. The second edits an inductive type, which has no value.
HELPER_EDITS = [
    ("Firth.ProofTests.Helper.absAllowed",
     "InInt64 (0 - x) ∧ True", "InInt64 (0 - x) ∧ x = 0"),
    ("Firth.ProofTests.Helper.absOk",
     "→ 0 = x * 0 → ProofTestHelpers.Ok x", "→ 0 = x → ProofTestHelpers.Ok x"),
]
EXPECTED_ACCEPTED = {
    f"{ACCEPTED}.sumTo": ([("Programs.SumTo", "sum-to"), ("Programs.SumTo", "sum-acc")],
                          DEFAULT_COSTS),
    f"{ACCEPTED}.absOnly": ([("Programs.Signed", "abs")], DEFAULT_COSTS),
    f"{ACCEPTED}.int64Diff": ([("Programs.Signed", "diff")], DEFAULT_COSTS),
    f"{ACCEPTED}.int64DiffDoubled": ([("Programs.Signed", "diff")],
                                     f"{ACCEPTED}.doubledPrimitives"),
    "Firth.ProofTests.Helper.absAllowed": ([("Programs.Signed", "abs")], DEFAULT_COSTS),
    "Firth.ProofTests.Helper.absOk": ([("Programs.Signed", "abs")], DEFAULT_COSTS),
}


def audit(*args: str) -> subprocess.CompletedProcess[str]:
    return subprocess.run(["lake", "env", str(AUDIT), *args], cwd=ROOT,
                          capture_output=True, text=True, check=False)


def fixture_status(report: str) -> subprocess.CompletedProcess[str]:
    with tempfile.TemporaryDirectory() as scratch:
        path = Path(scratch) / "accepted-records.json"
        path.write_text(report, encoding="utf-8")
        return audit("--fixtures", "--status", str(path))


def covering(words: list[dict], word: str) -> list[str]:
    return next((entry.get("theorems", []) for entry in words
                 if entry["module"] == "Programs.Signed" and entry["word"] == word), [])


def check_helper_edit(report: str, theorem: str, original_text: str,
                      planted_text: str) -> list[str]:
    """Plants one of the reviewer's probes on #138: narrows a helper behind a
    fixture's precondition, which leaves the proof, the printed precondition,
    the contract's definition and every body alone. `--status` on the report
    written before the edit must stop counting that record and keep the
    others. The file is restored and rebuilt whatever happens."""
    original = HELPER.read_text(encoding="utf-8")
    if original.count(original_text) != 1:
        return [f"{HELPER.relative_to(ROOT)} no longer contains {original_text!r} once"]
    before = fixture_status(report)
    if before.returncode != 0 or theorem not in covering(json.loads(before.stdout)["words"], "abs"):
        return [f"--status does not count {theorem} before the edit:\n{before.stderr}"]
    try:
        HELPER.write_text(original.replace(original_text, planted_text), encoding="utf-8")
        built = subprocess.run(["lake", "build", "prooftests.Helper"], cwd=ROOT,
                               capture_output=True, text=True, check=False)
        if built.returncode != 0:
            return [f"the planted edit for {theorem} did not build:\n{built.stdout}{built.stderr}"]
        after = fixture_status(report)
    finally:
        HELPER.write_text(original, encoding="utf-8")
        subprocess.run(["lake", "build", "prooftests.Helper"], cwd=ROOT,
                       capture_output=True, text=True, check=False)
    if after.returncode != 0:
        return [f"--status failed after the planted edit for {theorem}:\n{after.stderr}"]
    remaining = set(covering(json.loads(after.stdout)["words"], "abs"))
    expected = set(covering(json.loads(before.stdout)["words"], "abs")) - {theorem}
    if remaining != expected:
        return [f"a narrowed helper left {sorted(remaining - expected)} counted for abs"
                f" or withdrew {sorted(expected - remaining)}"]
    return []


def check_fixtures() -> list[str]:
    problems: list[str] = []
    result = audit("--fixtures", str(FIXTURES / "refused.json"))
    if result.returncode != 1:
        problems.append(f"refusal fixtures: audit exited {result.returncode}, expected 1")
    refusals = [line for line in result.stderr.splitlines() if line.startswith("refused: ")]
    for name, reason in EXPECTED_REFUSALS.items():
        if not any(line.startswith(f"refused: {name}: {reason}") for line in refusals):
            problems.append(f"the audit did not refuse {name} ({reason}): {refusals}")
    if len(refusals) != len(EXPECTED_REFUSALS):
        problems.append(f"expected {len(EXPECTED_REFUSALS)} refusals, got {refusals}")

    result = audit("--fixtures", str(FIXTURES / "accepted.json"))
    if result.returncode != 0:
        problems.append(f"accepted fixtures were refused:\n{result.stderr}")
        return problems
    records = {record["theorem"]: record for record in json.loads(result.stdout)["records"]}
    if set(records) != set(EXPECTED_ACCEPTED):
        problems.append(f"accepted {sorted(records)}, expected {sorted(EXPECTED_ACCEPTED)}")
        return problems
    digests: dict[str, str] = {}
    for name, (coverage, costs) in EXPECTED_ACCEPTED.items():
        covered = [(item["module"], item["word"]) for item in records[name]["covers"]]
        if covered != coverage:
            problems.append(f"{name} covers {covered}, expected exactly {coverage}")
        binding = records[name]["cost_binding"]
        if binding["name"] != costs:
            problems.append(f"{name} is bound to cost table {binding}, expected {costs}")
        digests[binding["name"]] = binding["digest"]
    if len(set(digests.values())) != len(digests):
        problems.append(f"different cost tables share a digest: {digests}")
    for theorem, original_text, planted_text in HELPER_EDITS:
        problems += check_helper_edit(result.stdout, theorem, original_text, planted_text)
    return problems


def status(report: str) -> subprocess.CompletedProcess[str]:
    with tempfile.TemporaryDirectory() as scratch:
        path = Path(scratch) / "records.json"
        path.write_text(report, encoding="utf-8")
        return audit("--status", str(path))


def verified_words(words: list[dict]) -> set[tuple[str, str]]:
    return {(word["module"], word["word"]) for word in words
            if word["status"] == "contract_verified"}


def plant(record: dict, change: str, words: list[dict]) -> str | None:
    """Applies one planted change to a record, returning the word a forged
    cover adds, if any."""
    if change == "cost table":
        record["cost_binding"]["digest"] = "0" * 64
    elif change == "registry":
        record["gamma_binding"]["digest"] = "0" * 64
    elif change == "body digest":
        record["covers"][0]["body_digest"] = "0" * 64
    elif change == "erased type":
        record["covers"][0]["erased_type"] += " "
    elif change == "toolchain":
        record["lean"] = "0.0.0"
    elif change == "statement digest":
        record["statement_digest"] = "0" * 64
    elif change == "precondition":
        record["statement"]["pre"] = "fun _ => True"
    elif change == "forged cover":
        covered = {(item["module"], item["word"]) for item in record["covers"]}
        other = next(word for word in words if (word["module"], word["word"]) not in covered)
        record["covers"].append({key: other[key] for key in
                                 ("module", "source", "word", "body_digest", "erased_type")})
        return other["word"]
    return None


def check_staleness(report: str) -> list[str]:
    """Reads the report back with `--status`, which must reproduce its words.
    Then plants one change at a time into one record. Each must turn every word
    only that record covers from contract_verified to type_checked, and verify
    nothing new."""
    problems: list[str] = []
    parsed = json.loads(report)
    result = status(report)
    if result.returncode != 0:
        return [f"--status failed on the report:\n{result.stderr}"]
    if json.loads(result.stdout)["words"] != parsed["words"]:
        problems.append("--status does not reproduce the report's words")
    if not parsed["records"]:
        return problems + ["no record, so staleness is untested"]
    record = parsed["records"][0]
    covered = {(item["module"], item["word"]) for item in record["covers"]}
    others = {(item["module"], item["word"]) for other in parsed["records"]
              if other is not record for item in other["covers"]}
    expected = verified_words(parsed["words"]) - (covered - others)
    for change in ("cost table", "registry", "body digest", "erased type", "statement digest",
                   "toolchain", "precondition", "forged cover"):
        planted = json.loads(report)
        plant(planted["records"][0], change, parsed["words"])
        result = status(json.dumps(planted))
        if result.returncode != 0:
            problems.append(f"--status failed on a planted {change}:\n{result.stderr}")
            continue
        still = verified_words(json.loads(result.stdout)["words"])
        if still != expected:
            problems.append(f"a planted {change} left {sorted(still - expected)} contract_verified"
                            f" or withdrew {sorted(expected - still)}")
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
    problems = check_staleness(report)
    if problems:
        for problem in problems:
            print(problem, file=sys.stderr)
        return 1
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
