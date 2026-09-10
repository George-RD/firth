#!/usr/bin/env python3
"""Public compiler admission regressions using real built Lean executables.

--baseline records the pre-fix kernel forgeries as expected reproductions.
The normal gate requires their rejection and runs source-binding checks too.
"""
from __future__ import annotations

import argparse
import copy
import hashlib
import json
from pathlib import Path
import subprocess
import sys
from typing import Any

import mvp_agent_gate as gate


def base(name: str = "Int", usage: str = "many") -> dict[str, Any]:
    return {"kind": "base", "name": name, "usage": usage}


def stack(*items: dict[str, Any], row: str | None = None) -> dict[str, Any]:
    return {"row": row, "items": list(items)}


def scheme(inputs: dict | None = None, outputs: dict | None = None, rows: list[str] | None = None) -> dict:
    return {"row_variables": rows or [], "input": stack() if inputs is None else inputs,
            "output": stack(base()) if outputs is None else outputs}


def literal(value: int | bool) -> dict:
    return {"kind": "lit", "value": {"type": "bool" if type(value) is bool else "nat", "value": value}}


def quotation(body: list[dict]) -> dict:
    return {"kind": "quotation", "body": body}


def word(name: str, program: list[dict]) -> dict:
    return {"name": name, "checking_state": "checked", "proof_state": "available", "program": program}


def request(program: list[dict], declared: dict | None = None) -> dict:
    return {"request_id": "compiler-admission", "entry": "main", "gamma_version": "0.1",
            "target_version": "0.1", "checked_words": [word("main", program)],
            "erased_word_types": [{"word": "main", "type": scheme() if declared is None else declared}]}


def source_request(source: str = ": main ( -- n:Int^many ) 42 ;") -> dict:
    value = request([literal(42)])
    value["source"] = {"source_path": "/does-not-exist/admission.firth", "source_text": source,
                       "language_version": "0.1"}
    return value


def corpus() -> list[tuple[str, dict, str]]:
    """Independent fixed expectations, not derived from the checker output."""
    cases: list[tuple[str, dict, str]] = []
    def add(name: str, payload: dict, expected: str = "reject") -> None:
        cases.append((name, copy.deepcopy(payload), expected))
    add("kernel: false output type", request([literal(True)]))
    add("kernel: missing output", request([]))
    add("kernel: stack underflow", request([{"kind": "dup"}]))
    add("kernel: primitive operand types", request([literal(True), literal(1), {"kind": "prim", "name": "+"}]))
    add("kernel: non-Boolean branch", request([literal(1), quotation([literal(2)]), quotation([literal(3)]), {"kind": "if"}]))
    add("kernel: unequal branch types", request([literal(True), quotation([literal(2)]), quotation([literal(False)]), {"kind": "if"}]))
    add("kernel: called quotation type", request([quotation([literal(False)]), {"kind": "call"}]))
    add("kernel: duplicate linear input", request([{"kind": "dup"}],
        scheme(stack(base("Handle", "linear")), stack(base("Handle", "linear"), base("Handle", "linear")))))
    add("kernel: discard linear input", request([{"kind": "drop"}],
        scheme(stack(base("Handle", "linear")), stack())))
    add("kernel: manufacture linear output", request([literal(42)], scheme(outputs=stack(base("Int", "linear")))))
    add("kernel: linear quote duplication", request([{"kind": "quote"}, {"kind": "dup"}, {"kind": "call"}, {"kind": "drop"}],
        scheme(stack(base("Handle", "linear")), stack())))
    bad_helper = request([{"kind": "word", "name": "helper"}])
    bad_helper["checked_words"].append(word("helper", [literal(True)]))
    bad_helper["erased_word_types"].append({"word": "helper", "type": scheme()})
    add("kernel: forged callee type", bad_helper)
    bad_helper["checked_words"][0]["program"] = [literal(42)]
    add("kernel: invalid unused helper", bad_helper)
    add("kernel: declared row loss", request([], scheme(stack(row="r"), stack(), ["r"])))
    add("kernel: altered nested quotation type", request([quotation([literal(42)])],
        scheme(outputs=stack({"kind": "quotation", "input": stack(), "output": stack(base("Bool")), "usage": "many"}))))
    add("kernel: literal", request([literal(42)]), "kernel-success")
    add("kernel: addition", request([literal(1), literal(2), {"kind": "prim", "name": "+"}]), "kernel-success")
    add("kernel: quotation call", request([quotation([literal(42)]), {"kind": "call"}]), "kernel-success")
    add("kernel: captured quote call", request([literal(42), {"kind": "quote"}, {"kind": "call"}]), "kernel-success")
    good = source_request()
    add("source: literal with unopened path", good, "source-success")
    changed = copy.deepcopy(good)
    changed["checked_words"][0]["program"] = [literal(43)]
    add("source: same-type body substitution", changed)
    changed["source"]["source_text"] = ": main ( -- n:Int^many ) 43 ;"
    add("source: consistent new input", changed, "source-success")
    changed = copy.deepcopy(good)
    changed["erased_word_types"][0]["type"] = scheme(outputs=stack(base("Bool")))
    add("source: type substitution", changed)
    changed["checked_words"][0]["program"] = [literal(True)]
    add("source: consistent kernel but different source", changed)
    multi = source_request(": main ( -- n:Int^many ) helper ; : helper ( -- n:Int^many ) 42 ;")
    multi["checked_words"][0]["program"] = [{"kind": "word", "name": "helper"}]
    multi["checked_words"].append(word("helper", [literal(42)]))
    multi["erased_word_types"].append({"word": "helper", "type": scheme()})
    add("source: forward dictionary", multi, "source-success")
    multi["checked_words"].reverse()
    multi["erased_word_types"].reverse()
    add("source: reordered dictionary", multi, "source-success")
    multi["checked_words"][0]["program"] = [literal(43)]
    add("source: helper body substitution", multi)
    extra = copy.deepcopy(good)
    extra["checked_words"].append(word("unused", [literal(1)]))
    extra["erased_word_types"].append({"word": "unused", "type": scheme()})
    add("source: extra kernel word", extra)
    missing = source_request(": main ( -- n:Int^many ) 42 ; : unused ( -- n:Int^many ) 1 ;")
    add("source: omitted unused word", missing)
    for label, source in (("false refinement", ": main ( -- n:Int^many{n > 0} ) 0 ;"),
                          ("true unsupported refinement", ": main ( -- n:Int^many{n > 0} ) 42 ;"),
                          ("empty", ""), ("type failure", ": main ( -- n:Int^many ) true ;")):
        add("source: " + label, source_request(source))
    for field, value in (("language_version", "0.2"), ("source_text", None), ("source_path", "")):
        changed = copy.deepcopy(good)
        changed["source"][field] = value
        add("schema: source " + field, changed)
    changed = copy.deepcopy(good)
    changed["source"]["proof"] = "available"
    add("schema: invented source evidence", changed)
    for field in ("gamma_version", "target_version"):
        changed = request([literal(42)])
        changed[field] = "0.2"
        add("schema: stale " + field, changed)
    changed = request([literal(42)])
    changed["checked_words"][0]["proof_state"] = "deferred"
    add("schema: unavailable marker", changed)
    changed = request([literal(42)])
    changed["checked_words"][0]["proof_hash"] = "01" * 32
    add("schema: invented proof hash", changed)
    changed = request([literal(42)])
    changed["erased_word_types"].append(copy.deepcopy(changed["erased_word_types"][0]))
    add("schema: duplicate erased type", changed)
    add("schema: unbound row", request([], scheme(stack(row="r"), stack(row="r"))))
    add("schema: duplicate row binders", request([], scheme(stack(row="r"), stack(row="r"), ["r", "r"])))
    forged = request([{"kind": "push", "value": {"kind": "quotation", "body": [literal(42)], "usage": "linear"}}, {"kind": "call"}])
    add("ownership: forged stored quotation usage", forged)
    # The VM refuses more than 4096 instructions per code vector and quotation
    # nesting deeper than 32 (src/runtime/vm/src/lib.rs); the compiler must
    # refuse the same programs instead of emitting an unloadable image, and
    # must still admit the programs exactly at the bound.
    pair = [{"kind": "dup"}, {"kind": "drop"}]
    add("bounds: instruction count at 4096",
        request([literal(1), literal(2), {"kind": "swap"}, {"kind": "drop"}] + pair * 2046), "kernel-success")
    add("bounds: instruction count above 4096", request([literal(1)] + pair * 2048))
    def nested(depth: int) -> list[dict]:
        body = literal(1)
        for _ in range(depth):
            body = quotation([body])
        return [body] + [{"kind": "call"}] * depth
    add("bounds: quotation nesting at 32", request(nested(32)), "kernel-success")
    add("bounds: quotation nesting above 32", request(nested(33)))
    # Canonical row names continue past the 24 fixed Greek names, so a valid
    # scheme with more binders compiles rather than failing as a bad type.
    rows = [f"r{index}" for index in range(25)]
    add("rows: 25 row binders", request([literal(42)], scheme(stack(row="r24"), stack(base(), row="r24"), rows)),
        "kernel-success")
    return cases


def execute(payload: dict) -> tuple[int, dict, str, str]:
    process = subprocess.run([str(gate.LEAN_BIN / "firthCompile")], input=json.dumps(payload),
        capture_output=True, text=True, encoding="utf-8", cwd=gate.ROOT, timeout=30, check=False)
    if process.returncode not in (0, 1):
        raise ValueError(f"compiler crashed: exit {process.returncode}: {process.stderr[:500]}")
    output = process.stdout if process.returncode == 0 else process.stderr
    # The Lean executable reports its JSON error, then may print its uncaught
    # exception. A nonzero exit must still carry an actual structured refusal.
    lines = [line for line in output.splitlines() if line.strip()]
    if not lines:
        raise ValueError("compiler returned no structured response")
    result = json.loads(lines[0], object_pairs_hook=gate._json_object,
                        parse_constant=gate._json_constant, parse_float=gate._json_float)
    if not isinstance(result, dict):
        raise ValueError("compiler response is not an object")
    if process.returncode == 0 and result.get("request_id") != payload["request_id"]:
        raise ValueError("compiler response request_id mismatch")
    return process.returncode, result, process.stdout, process.stderr


def evaluate(expected: str, rc: int, result: dict, payload: dict) -> bool:
    if expected == "reject":
        return "target_program" not in result and (
            rc == 0 and result.get("status") == "failure" and isinstance(result.get("compile_error"), dict)
            or rc == 1 and result.get("status") == "error" and isinstance(result.get("error"), str))
    if rc != 0 or result.get("status") != "success" or not isinstance(result.get("target_program"), dict):
        return False
    if expected == "baseline-acceptance":
        return True
    verification = result.get("verification", {})
    source_bound = expected == "source-success"
    digest = hashlib.sha256(payload["source"]["source_text"].encode()).hexdigest() if source_bound else None
    return verification == {
        "schema": "firth.compiler-verification.v1", "method": "kernel-type-and-linearity-recheck",
        "source_bound": source_bound, "source_sha256": digest, "gamma_version": "0.1",
        "target_version": "0.1", "refinements": "not-checked",
        "image_evidence": "legacy-content-identifiers-not-authenticated-proofs"}


def main() -> int:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--baseline", action="store_true")
    parser.add_argument("--no-build", action="store_true")
    args = parser.parse_args()
    try:
        if not args.no_build:
            gate.build_toolchain()
        cases = corpus()
        if args.baseline:
            cases = [(name, payload, "baseline-acceptance") for name, payload, expected in cases
                     if name.startswith("kernel:") and expected == "reject"]
        records = []
        for name, payload, expected in cases:
            try:
                rc, response, stdout, stderr = execute(payload)
                passed = evaluate(expected, rc, response, payload)
                records.append({"case": name, "expected": expected, "passed": passed,
                                "request": payload, "response": response, "exit_code": rc,
                                "stdout": stdout, "stderr": stderr})
            except (OSError, ValueError, subprocess.TimeoutExpired) as error:
                records.append({"case": name, "passed": False, "error": str(error), "request": payload})
        failed = sum(not record["passed"] for record in records)
        print(json.dumps({"status": "ok" if not failed else "failed", "baseline": args.baseline,
            "passed": len(records) - failed, "failed": failed, "cases": records,
            "binary_sha256": hashlib.sha256((gate.LEAN_BIN / "firthCompile").read_bytes()).hexdigest()}, sort_keys=True))
        return int(bool(failed))
    except (gate.GateError, OSError, ValueError) as error:
        print(json.dumps({"status": "error", "error": str(error)}, sort_keys=True))
        return 2


if __name__ == "__main__":
    raise SystemExit(main())
