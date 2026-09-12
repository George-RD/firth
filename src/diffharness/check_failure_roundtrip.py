#!/usr/bin/env python3
"""Verify saved failure replay and shrinking with the actual Firth adapters.

The deliberately exhausted case must fail, not count as language agreement.
"""
from __future__ import annotations

import argparse
import json
from pathlib import Path
import tempfile

import harness as h


def require(condition: bool, message: str) -> None:
    if not condition:
        raise h.HarnessError(message)


def main() -> int:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--artifacts", type=Path,
                        default=h.ROOT / ".firth-differential" / "roundtrip")
    args = parser.parse_args()
    try:
        h.gate.build_toolchain()
        toolchain = h.identities()
        execute = h.Executor()
        case = h.generate(0, 0, fuel=0)
        result = execute(case)
        require(result.kind == "bounded-fuel-inconclusive",
                f"expected dual fuel exhaustion, got {result.kind}")
        require(len(result.records) == 4, "the failure did not run all four adapters")
        args.artifacts.mkdir(parents=True, exist_ok=True)
        directory = Path(tempfile.mkdtemp(prefix="real-roundtrip-", dir=args.artifacts))
        original = h.save_failure(directory, "original", h.failure_record(case, result, toolchain))

        reduced, reduced_result, report = h.shrink(case, result, execute, 32)
        require(reduced_result.signature == result.signature, "shrinking changed the failure")
        require(reduced.complexity < case.complexity and report["accepted"] > 0,
                "shrinking did not produce a smaller real failure")
        record = h.failure_record(reduced, reduced_result, toolchain)
        record["shrinking"] = report
        reduced_path = h.save_failure(directory, "reduced", record)

        for label, artifact in (("original", original), ("reduced", reduced_path)):
            output = directory / (label + "-replay")
            code = h.main(["replay", str(artifact), "--artifacts", str(output)])
            require(code == 1, f"{label} replay must preserve the non-passing exit, got {code}")
            summaries = list(output.glob("summary-*.json"))
            require(len(summaries) == 1, f"{label} replay did not retain exactly one summary")
            summary = h.strict_json(summaries[0].read_text(encoding="utf-8"))
            require(summary["replay_signature_matches"] is True and summary["toolchain_drift"] is False,
                    f"{label} replay did not reproduce the same identified failure")
            require(summary["outcomes"] == {"bounded-fuel-inconclusive": 1},
                    f"{label} replay treated exhaustion as another outcome")

        print(json.dumps({"status": "ok", "check": "real-failure-replay-and-shrink",
                          "failure_kind": result.kind, "shrinking": report,
                          "artifacts": str(directory),
                          "scope": "expected failure round-trip, not language agreement"}, sort_keys=True))
        return 0
    except (h.HarnessError, h.gate.GateError, OSError, ValueError) as error:
        print(json.dumps({"status": "error", "error": str(error)}, sort_keys=True))
        return 1


if __name__ == "__main__":
    raise SystemExit(main())
