#!/usr/bin/env python3
"""Change a partial-fulfilment client to all-or-nothing and check the change.

specs/inventory-allocation.md's maintenance task: change a client from partial
to all-or-nothing while preserving conservation, order, input validation and
later fulfilment. `policy-change/partial.firth` is the client before the change
and `policy-change/all-or-nothing.firth` the client after it. Each defines one
word, `reserve`, on top of `allocator.firth`. Firth has no imports, so each
program is the allocator's source followed by the client's.

Two checks, both against what the toolchain itself produces:

1. Changed words and their dependents. Both programs are elaborated and
   compiled. A word changed when the compiler's body digest or the erased word
   type differs; its dependents are every word that reaches it through
   `call-word` in the compiled target program. The check fails unless exactly
   `reserve` changed, nothing depends on it, and every allocator word keeps its
   digest and type. Both programs share `allocator.firth`, so the script also
   compiles a mutant with one allocator word edited and fails unless that
   word and its callers are reported: the check can see an allocator change.
2. Regression evidence. Every corpus case that reaches Firth runs through both
   clients on the VM and the reference interpreter, which must agree
   (`mvp_agent_gate.rebuild`). When a case's policy is the client's, the result
   must equal the corpus's fixed expected output. When it is not, the result
   must equal the independently tested model in
   tools/loop/test_inventory_contract.py for the client's policy, and must keep
   the spec's properties: conservation, IDs and order, no request over its
   quantity, and the policy's own rule. Every run must also stay within
   `run_cases.cost_bound` plus the client's measured entry cost.
"""
from __future__ import annotations

import argparse
import json
import sys
import tempfile
from concurrent.futures import ThreadPoolExecutor
from pathlib import Path
from typing import Any

import run_cases as host

gate = host.gate
sys.path.insert(0, str(host.ROOT / "tools" / "loop"))
from test_inventory_contract import model  # noqa: E402

CLIENTS = {
    "partial": host.HERE / "policy-change" / "partial.firth",
    "all-or-nothing": host.HERE / "policy-change" / "all-or-nothing.firth",
}
ENTRY = "reserve"
CHANGED = {ENTRY}
# `reserve` puts the policy under the IDs and quantities, then calls
# `allocate-batch`: the kernel steps it adds to every run.
CLIENT_COST = 6
MUTANT_EDIT = ("[ remaining requested prim - requested 0 ]",
               "[ remaining requested prim - requested 0 prim + 0 ]")
MUTANT_IMPACT = ({"allocate-one", "reserve"}, {"allocate-from", "allocate-batch"})


def program_text(policy: str) -> str:
    return host.SOURCE.read_text(encoding="utf-8") + "\n" + CLIENTS[policy].read_text(encoding="utf-8")


def compile_program(name: str, text: str, workspace: Path) -> dict[str, Any]:
    """The toolchain's own view of one program: digests, types and calls."""
    scratch = workspace / name
    scratch.mkdir()
    source_name = "inventory-client.firth"
    (scratch / source_name).write_text(text, encoding="utf-8")
    elaboration = gate.adapter(
        [str(gate.LEAN_BIN / "firthElaborate")],
        {"request_id": name, "source_path": source_name, "source_text": text,
         "language_version": gate.LANGUAGE_VERSION, "gamma_version": gate.GAMMA_VERSION},
        scratch, f"{name} elaborate")
    gate.expect_status(elaboration, "success", f"{name} elaborate")
    compiled = gate.adapter(
        [str(gate.LEAN_BIN / "firthCompile")],
        {"request_id": name, "entry": ENTRY,
         "checked_words": elaboration["checked_words"],
         "erased_word_types": elaboration["erased_word_types"],
         "gamma_version": gate.GAMMA_VERSION, "target_version": gate.TARGET_VERSION,
         "source": {"source_path": source_name, "source_text": text,
                    "language_version": gate.LANGUAGE_VERSION}},
        scratch, f"{name} compile")
    gate.expect_status(compiled, "success", f"{name} compile")
    words = [word["name"] for word in elaboration["checked_words"]]
    target = compiled["target_program"]["words"]
    if len(target) != len(words):
        raise SystemExit(f"{name}: {len(words)} checked words but {len(target)} compiled")
    # Target words appear in checked-word order under an encoded name.
    by_source = dict(zip((word["name"] for word in target), words, strict=True))
    calls = {by_source[word["name"]]: {by_source[callee] for callee in calls_in(word["code"])}
             for word in target}
    types = {by_source[word["name"]]: word["erased_word_type"] for word in target}
    return {"digests": compiled["word_digests"], "types": types, "calls": calls}


def mutant_text() -> str:
    """The after program with an allocator word edited as well.

    Both programs share `allocator.firth`, so on its own the comparison above
    cannot see an allocator edit: this change touches only the client, and
    any allocator change is reviewed and gated as its own change. The mutant
    shows the check is not vacuous: it adds a no-op to `allocate-one`'s
    fulfilled branch, and the check must report that word and its callers.
    """
    text = program_text("all-or-nothing")
    if MUTANT_EDIT[0] not in text:
        raise SystemExit(f"mutant: {MUTANT_EDIT[0]!r} is no longer in allocate-one; update MUTANT_EDIT")
    return text.replace(*MUTANT_EDIT, 1)


def calls_in(code: list[dict[str, Any]]) -> set[str]:
    found: set[str] = set()
    for instruction in code:
        if instruction["op"] == "call-word":
            found.add(instruction["name"])
        quotation = instruction.get("quotation")
        if quotation is not None:
            found |= calls_in(quotation["code"])
    return found


def change_impact(before: dict[str, Any], after: dict[str, Any]) -> dict[str, Any]:
    names = set(before["digests"]) | set(after["digests"])
    changed = {name for name in names
               if before["digests"].get(name) != after["digests"].get(name)
               or before["types"].get(name) != after["types"].get(name)}
    dependents: set[str] = set()
    frontier = set(changed)
    while frontier:
        frontier = {caller for program in (before, after)
                    for caller, callees in program["calls"].items()
                    if callees & frontier} - changed - dependents
        dependents |= frontier
    return {"changed": sorted(changed), "dependents": sorted(dependents),
            "unchanged": sorted(names - changed - dependents)}


def properties(case_input: dict[str, Any], policy: str, result: dict[str, Any]) -> list[str]:
    """The spec's required properties, for a result the corpus does not fix."""
    if result["status"] != "ok":
        return []
    problems = []
    requests, allocations = case_input["requests"], result["allocations"]
    if result["remaining"] < 0 or result["remaining"] + sum(a["quantity"] for a in allocations) != case_input["available"]:
        problems.append("stock not conserved")
    if [a["id"] for a in allocations] != [r["id"] for r in requests]:
        problems.append("IDs or order not preserved")
    for allocation, request in zip(allocations, requests, strict=True):
        if not 0 <= allocation["quantity"] <= request["quantity"]:
            problems.append(f"{allocation['id']}: allocation outside 0..quantity")
        if policy == "all-or-nothing" and allocation["quantity"] not in (0, request["quantity"]):
            problems.append(f"{allocation['id']}: part of a request under all-or-nothing")
        if policy == "partial" and allocation["reason"] == "insufficient-stock":
            problems.append(f"{allocation['id']}: insufficient-stock under partial")
    return problems


def run_client(policy: str, program: Path, index: int, case: dict[str, Any]) -> dict[str, Any]:
    available, _, ids, quantities = host.host_decode(case["input"])
    with tempfile.TemporaryDirectory(prefix="firth-policy-change-") as directory:
        observation = gate.rebuild(
            {"name": f"{policy}-{index}", "entry": ENTRY, "source": str(program),
             "source_path": program.name},
            Path(directory), stack=[available, ids, quantities], fuel=host.FUEL)
    stack = [value["literal"]["value"] for value in observation["stack"]]
    actual = host.host_encode(case["input"]["requests"], stack)
    n = len(case["input"]["requests"])
    result = {"case": case["name"], "client": policy, "kernel_cost": observation["kernel_cost"]}
    if case["input"]["policy"] == policy:
        result["checked_against"], expected = "corpus", case["expected"]
        problems = []
    else:
        result["checked_against"] = "model"
        expected = model(case["input"] | {"policy": policy})
        problems = properties(case["input"], policy, actual)
    if actual != expected:
        problems.append(f"expected {expected}, got {actual}")
    if observation["kernel_cost"] > host.cost_bound(n) + CLIENT_COST:
        problems.append(f"cost {observation['kernel_cost']} over the bound")
    result["outcome"] = "fail" if problems else "pass"
    if problems:
        result["problems"] = problems
    return result


def main() -> int:
    parser = argparse.ArgumentParser(description=__doc__.splitlines()[0])
    parser.add_argument("--jobs", type=int, default=4)
    parser.add_argument("--json", type=Path, help="write the full report here")
    args = parser.parse_args()
    gate.build_toolchain()
    cases = json.loads((host.ROOT / "specs/inventory-allocation-cases.json").read_text(encoding="utf-8"))["cases"]
    failed = False
    with tempfile.TemporaryDirectory(prefix="firth-policy-change-") as directory:
        workspace = Path(directory)
        before, after = (compile_program(f"compile-{policy}", program_text(policy), workspace)
                         for policy in CLIENTS)
        impact = change_impact(before, after)
        print(f"changed words: {impact['changed']}; dependents: {impact['dependents']}; "
              f"unchanged: {len(impact['unchanged'])} words")
        if set(impact["changed"]) != CHANGED or impact["dependents"]:
            print("fail: the change reaches beyond the client word")
            failed = True
        detected = change_impact(before, compile_program(
            "compile-mutant", mutant_text(), workspace))
        print(f"mutant: changed {detected['changed']}; dependents {detected['dependents']}")
        if (set(detected["changed"]), set(detected["dependents"])) != MUTANT_IMPACT:
            print("fail: the impact check missed an allocator edit")
            failed = True
        programs = {}
        for policy in CLIENTS:
            programs[policy] = workspace / f"{policy}.firth"
            programs[policy].write_text(program_text(policy), encoding="utf-8")
        runs = [(policy, index, case) for index, case in enumerate(cases)
                if isinstance(host.host_decode(case["input"]), list) for policy in CLIENTS]
        with ThreadPoolExecutor(max_workers=args.jobs) as pool:
            results = list(pool.map(lambda run: run_client(run[0], programs[run[0]], run[1], run[2]), runs))
    for result in results:
        extra = f": {'; '.join(result['problems'])}" if result["outcome"] == "fail" else ""
        print(f"{result['outcome']:5} {result['client']:15} {result['case']} "
              f"[{result['checked_against']}] (kernel cost {result['kernel_cost']}){extra}")
    passed = sum(result["outcome"] == "pass" for result in results)
    print(f"{passed} pass, {len(results) - passed} fail of {len(results)} runs "
          f"({len(results) // len(CLIENTS)} cases through both clients)")
    failed = failed or passed != len(results)
    if args.json:
        args.json.write_text(json.dumps({"impact": impact, "runs": results}, indent=1) + "\n", encoding="utf-8")
    return 1 if failed else 0


if __name__ == "__main__":
    raise SystemExit(main())
