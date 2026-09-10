#!/usr/bin/env python3
"""Black-box regressions for source guarantees and untrusted adapter inputs.

Runs real pinned binaries, reports every case, and fails on a crash, timeout,
missing diagnostic, or accidental acceptance. No injected checker/solver.
"""
from __future__ import annotations

import copy
import json
import subprocess
import sys
from typing import Any, Callable

import mvp_agent_gate as gate


def invoke(command: list[str], payload: dict[str, Any]) -> tuple[int, dict[str, Any]]:
    process = subprocess.run(
        command, input=json.dumps(payload), text=True, encoding="utf-8",
        capture_output=True, cwd=gate.ROOT, timeout=30, check=False,
    )
    if process.returncode not in (0, 1):
        raise AssertionError(f"adapter crashed/exited {process.returncode}: {process.stderr[:500]}")
    output = process.stdout if process.returncode == 0 else process.stderr
    result = json.loads(output)
    if not isinstance(result, dict):
        raise AssertionError("adapter did not return a JSON object")
    return process.returncode, result


def source_request(source: str) -> dict[str, Any]:
    return {"request_id": "trust-source", "source_path": "trust.firth", "source_text": source,
            "language_version": "0.1", "gamma_version": "0.1"}


def source_refusal(source: str, code: str) -> None:
    rc, result = invoke([str(gate.LEAN_BIN / "firthElaborate")], source_request(source))
    assert rc == 0 and result.get("status") == "failure", result
    assert "checked_words" not in result and "kernel_programs" not in result, result
    # Check the diagnostic's actual code, not a coincidental string in prose.
    diagnostics = result.get("diagnostics", [])
    assert any(d.get("body", {}).get("code") == code for d in diagnostics), result


def source_success() -> None:
    rc, result = invoke([str(gate.LEAN_BIN / "firthElaborate")],
                        source_request(": main ( -- n:Int^many ) 42 ;"))
    assert rc == 0 and result.get("status") == "success", result
    assert len(result.get("checked_words", [])) == 1, result


def compile_request(usage: str) -> dict[str, Any]:
    stack = {"row": None, "items": []}
    output = {"row": None, "items": [{"kind": "base", "name": "Int", "usage": "many"}]}
    literal = {"kind": "lit", "value": {"type": "nat", "value": 42}}
    return {"request_id": "trust-compile", "entry": "main", "gamma_version": "0.1",
            "target_version": "0.1", "checked_words": [{"name": "main",
            "checking_state": "checked", "proof_state": "available", "program": [
                {"kind": "push", "value": {"kind": "quotation", "body": [literal], "usage": usage}},
                {"kind": "call"}]}], "erased_word_types": [{"word": "main", "type": {
                    "row_variables": [], "input": stack, "output": output}}]}


def quotation_ownership(usage: str) -> None:
    rc, result = invoke([str(gate.LEAN_BIN / "firthCompile")], compile_request(usage))
    assert rc == 0, result
    if usage == "many":
        assert result.get("status") == "success", result
    else:
        assert result.get("status") == "failure", result
        assert result.get("compile_error", {}).get("code") == "firth.compile.unsupported-value", result
        assert "target_program" not in result, result


def row_binder_agreement() -> None:
    """The compiler's generated row names are accepted by the VM's parser.

    A scheme with 25 binders reaches past the fixed 24-name table, so its
    erased word type carries a generated name. Both hosts must admit it: the
    compiler renders and rechecks the word, and the VM parses the type when it
    loads and runs the image.
    """
    request = compile_request("many")
    request["checked_words"][0]["program"] = [{"kind": "lit", "value": {"type": "nat", "value": 42}}]
    rows = [f"r{index}" for index in range(25)]
    boundary = request["erased_word_types"][0]["type"]
    boundary["row_variables"] = rows
    boundary["input"]["row"] = rows[-1]
    boundary["output"]["row"] = rows[-1]
    rc, compiled = invoke([str(gate.LEAN_BIN / "firthCompile")], request)
    assert rc == 0 and compiled.get("status") == "success", compiled
    erased = compiled["target_program"]["words"][0]["erased_word_type"]
    binders = erased[len("(forall"):erased.index(";")].split(",")
    assert len(binders) == 25 and len(set(binders)) == 25, erased
    assert all(len(name) == 1 for name in binders), erased
    rc, target = invoke([str(gate.VM_BINARY), "vm-run"], {
        "request_id": "row-binders", "target_program": compiled["target_program"],
        "initial_stack": [], "image": {"image_version": 1, "gamma_version": 1},
        "gamma_version": "0.1", "fuel": 32,
    })
    assert rc == 0 and target.get("status") == "success", target
    assert target["stack"] == gate.initial_values([42]), target


def quotation_observation(mode: str, called: bool) -> None:
    """Real host execution, not source authorship or proof-admission evidence.

    The source syntax cannot declare a quotation output boundary yet. Exercise
    the existing structured compiler transport with an explicitly typed fixture
    instead; its checking markers are not authenticated by this test.
    """
    request = compile_request("many")
    scalar = {"kind": "lit", "value": {"type": "nat", "value": 42}}
    if mode == "closed":
        program = [{"kind": "quotation", "body": [scalar]}]
    else:
        program = [scalar, {"kind": "quote"}]
    if called:
        program.append({"kind": "call"})
    request["checked_words"][0]["program"] = program
    if not called:
        boundary = request["erased_word_types"][0]["type"]
        quotation = {"kind": "quotation", "input": copy.deepcopy(boundary["input"]),
                     "output": copy.deepcopy(boundary["output"]), "usage": "many"}
        boundary["output"] = {"row": None, "items": [quotation]}
    rc, compiled = invoke([str(gate.LEAN_BIN / "firthCompile")], request)
    assert rc == 0 and compiled.get("status") == "success", compiled
    rc, target = invoke([str(gate.VM_BINARY), "vm-run"], {
        "request_id": "quote-result", "target_program": compiled["target_program"],
        "initial_stack": [], "image": {"image_version": 1, "gamma_version": 1},
        "gamma_version": "0.1", "fuel": 32,
    })
    assert rc == 0 and target.get("status") == "success", target
    kernel = {key: request["checked_words"][0][key]
              for key in ("checking_state", "proof_state", "program")}
    rc, reference = invoke([str(gate.LEAN_BIN / "firthReferenceRun")], {
        "request_id": "quote-result", "checked_kernel": {**kernel, "gamma_version": "0.1"},
        "initial_stack": [], "dictionary": {"main": kernel}, "gamma_version": "0.1", "fuel": 32,
    })
    assert rc == 0 and reference.get("status") == "success", reference
    if called:
        gate.compare(reference, target, f"{mode}-quotation-called", fuel=32)
        assert target["stack"] == gate.initial_values([42]), target
    else:
        assert reference["stack"][0]["kind"] == "quotation", reference
        assert target["stack"][0]["kind"] == "quotation", target
        try:
            gate.compare(reference, target, f"{mode}-quotation-result", fuel=32)
        except gate.GateError as error:
            assert "unsupported quotation result" in str(error), str(error)
        else:
            raise AssertionError("unsupported quotation result was accepted as agreement")


def malformed_capture_state(captures: list[Any], consumed: list[bool], placement: str) -> None:
    quotation = {"kind": "quotation", "code": [], "captures": captures, "consumed": consumed}
    if placement == "instruction":
        instruction = {"op": "push-quote", "quotation": quotation}
    elif placement == "literal":
        instruction = {"op": "push-literal", "literal": quotation}
    else:
        instruction = {"op": "push-quote", "quotation": {"kind": "quotation", "code": [],
                       "captures": [quotation], "consumed": [False]}}
    # Non-zero placeholder digests are intentional: malformed capture shape
    # must be rejected BEFORE canonical hashing or evidence/digest admission.
    word = {"name": "main", "erased_word_type": "(--)", "code": [instruction],
            "body_digest": "01" * 32, "kernel_evidence_digest": "01" * 32,
            "refinement_evidence_digest": "01" * 32, "generation": 0}
    request = {"request_id": "trust-vm", "target_program": {
        "format_version": 1, "entry": "main", "words": [word]}, "initial_stack": [],
        "image": {"image_version": 1, "gamma_version": 1}, "gamma_version": "0.1", "fuel": 32}
    rc, result = invoke([str(gate.VM_BINARY), "vm-run"], request)
    assert rc == 1 and result.get("status") == "error", result
    assert result.get("code") == "invalid-request", result
    assert "capture state length" in result.get("error", ""), result


def main() -> int:
    if not __debug__:
        print(json.dumps({"status": "error", "error": "assertions must be enabled"}), file=sys.stderr)
        return 1
    try:
        gate.build_toolchain()
    except (gate.GateError, OSError) as error:
        print(json.dumps({"status": "error", "error": str(error)}), file=sys.stderr)
        return 1
    checks: list[tuple[str, Callable[[], None]]] = [("plain typed source", source_success)]
    for name, source in (
        ("false postcondition", ": main ( -- n:Int^many{n > 0} ) 0 ;"),
        ("true but unsupported postcondition", ": main ( -- n:Int^many{n > 0} ) 1 ;"),
        ("precondition", ": main ( n:Int^many{n > 0} -- n:Int^many ) ;"),
        ("helper contract", ": helper ( -- n:Int^many{n > 0} ) 0 ; : main ( -- n:Int^many ) helper ;"),
        ("vocabulary contract", "vocab policy { : main ( -- n:Int^many{n > 0} ) 0 ; }"),
    ):
        checks.append((name, lambda s=source: source_refusal(s, "firth.refinement.unsupported-source")))
    for name, source in (("empty source", ""), ("whitespace source", " \n "),
                         ("empty vocabulary", "vocab empty { }")):
        checks.append((name, lambda s=source: source_refusal(s, "firth.elaboration.empty-program")))
    # Unknown word references carry the normative resolver code from
    # spec/surface/syntax.md; only an undeclared primitive is an unresolved
    # effect, because nothing but the environment can say it exists.
    for name, source in (("unknown unqualified word", ": main ( -- ) missing ;"),
                         ("unknown qualified word", "vocab a { : id ( -- ) ; } : main ( -- ) a.missing ;"),
                         ("unknown vocabulary prefix", ": main ( -- ) zzz.foo ;")):
        checks.append((name, lambda s=source: source_refusal(s, "firth.name.unresolved")))
    checks.append(("unknown primitive", lambda: source_refusal(": main ( -- ) prim nope ;",
                                                               "firth.name.unresolved-effect")))
    checks.append(("25 row binders agree with the VM", row_binder_agreement))
    for usage in ("many", "linear"):
        checks.append((f"{usage} quotation ownership", lambda u=usage: quotation_ownership(u)))
    for mode in ("closed", "captured"):
        for called in (False, True):
            checks.append((f"{mode} quotation: {'called' if called else 'returned'}",
                           lambda m=mode, c=called: quotation_observation(m, c)))
    for placement in ("instruction", "literal", "nested"):
        for name, captures, consumed in (
            ("extra state", [], [True]),
            ("missing state", [{"kind": "int", "value": 1}], []),
            ("bitmap overflow", [{"kind": "int", "value": 1}], [False] * 8 + [True]),
        ):
            checks.append((f"{placement}: {name}", lambda c=copy.deepcopy(captures),
                           s=list(consumed), p=placement: malformed_capture_state(c, s, p)))
    results = []
    for name, check in checks:
        try:
            check()
            results.append({"case": name, "status": "passed"})
        except (AssertionError, gate.GateError, OSError, ValueError, subprocess.TimeoutExpired) as error:
            results.append({"case": name, "status": "failed", "error": str(error)})
    failed = sum(result["status"] == "failed" for result in results)
    print(json.dumps({"status": "error" if failed else "ok", "passed": len(results) - failed,
                      "failed": failed, "cases": results}, sort_keys=True))
    return 1 if failed else 0


if __name__ == "__main__":
    raise SystemExit(main())
