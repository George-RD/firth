#!/usr/bin/env python3
"""Run the fixed inventory corpus through the host and the Firth allocator.

The host part of specs/inventory-allocation.md lives here: JSON shape, types
and ID syntax (`invalid-input`) and integers a 64-bit host cannot hold
(`invalid-range`). The per-ID encoding and turning the component's codes back
into an answer are Lean definitions with proofs (src/proofs/Inventory/Host.lean),
run through `lake exe inventoryHost`; this file only moves JSON to and from it.
Everything else (bounds, repeated IDs and the allocation) runs in
`allocator.firth` on the VM and the reference interpreter, which must agree
(`mvp_agent_gate.rebuild`). The result must equal the corpus's fixed expected
output; the corpus is never rewritten from what the program produces.
Negative integers reach the component as they are: the lower bounds are
Firth's checks, not the host's.
"""
from __future__ import annotations

import argparse
import json
import re
import shutil
import subprocess
import sys
import tempfile
from concurrent.futures import ThreadPoolExecutor
from pathlib import Path
from typing import Any

HERE = Path(__file__).resolve().parent
ROOT = HERE.parents[1]
sys.path.insert(0, str(ROOT / "tools" / "loop"))

import mvp_agent_gate as gate  # noqa: E402

SOURCE = HERE / "allocator.firth"
HOST = ROOT / ".lake" / "build" / "bin" / "inventoryHost"
ENTRY = "allocate-batch"
FUEL = gate.MAX_FUEL
ALPHABET = "ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789_-"
ID_PATTERN = re.compile(r"[A-Za-z0-9_-]{1,32}")
INT64 = range(-(2**63), 2**63)
# Worst-case kernel cost for a batch of n requests: 165 to enter and validate
# an empty batch, 202 per request, and 163 per pair of requests for the
# repeated-ID scan (its costliest pair shape). 202 was the costliest request
# (the partial branch) when the bound was proved; since #213 the partial
# branch costs 192 and insufficient-stock 191, so it holds with that slack. At n = 64 that is 341,701, inside the VM's
# 1,000,000-step fuel cap. It is proved for the reference interpreter
# (`batchCost` and `allocate_batch_reference` in
# src/proofs/Inventory/Allocate.lean) and measured by measure_cost.py. Every
# corpus run is checked against it. tools/loop/check_cost_bound.py checks this
# function equals Lean's `batchCost` for 0 to 64 requests and every corpus size.
def cost_bound(n: int) -> int:
    return 165 + 202 * n + 163 * n * (n - 1) // 2


def error(code: str) -> dict[str, str]:
    return {"status": "error", "code": code}


def build_toolchain() -> None:
    """The gate's adapters and VM, then `inventoryHost`, rebuilt so none is stale."""
    gate.build_toolchain()
    lake = shutil.which("lake")
    if lake is None:
        raise RuntimeError("lake is not on PATH")
    gate.run([lake, "build", "inventoryHost"], cwd=ROOT, stdin=None,
             timeout=gate.BUILD_TIMEOUT_SECONDS)
    if not HOST.is_file():
        raise RuntimeError(f"{HOST} was not built")


def lean_host(mode: str, payload: Any) -> Any:
    """Run `inventoryHost <mode>` (src/proofs/Inventory/HostMain.lean) on `payload`.

    The ID encoding and the answer are computed by the Lean definitions that
    src/proofs/Inventory/Host.lean proves injective and order-preserving, not by
    a Python copy of them.
    """
    if not HOST.is_file():
        raise RuntimeError(f"{HOST} is missing; call build_toolchain() first")
    result = subprocess.run([str(HOST), mode], input=json.dumps(payload), capture_output=True,
                            text=True, check=False)
    if result.returncode != 0:
        raise RuntimeError(f"inventoryHost {mode} failed: {result.stderr.strip()}")
    return json.loads(result.stdout)


def unique_members(pairs: list[tuple[str, Any]]) -> dict[str, Any]:
    """A JSON object, refusing a repeated member name rather than keeping the last."""
    result: dict[str, Any] = {}
    for key, value in pairs:
        if key in result:
            raise ValueError(f"repeated JSON member {key!r}")
        result[key] = value
    return result


def json_integer(token: str) -> int:
    """A JSON integer token as an int. Python refuses to convert more than 4300
    digits, but JSON has no leading zeros, so any token with more than 19 digits
    lies outside i64 and stands for an out-of-range value of its sign."""
    digits = token.lstrip("-")
    if len(digits) > 19:
        return -(2 ** 64) if token.startswith("-") else 2 ** 64
    return int(token)


def host_parse(text: str) -> dict[str, str] | tuple[int, bool, list[str], list[int]]:
    """The host's whole input path from JSON text: malformed JSON and repeated
    member names are `invalid-input` (the spec's two host tests), then `host_check`.
    Python also reads NaN and Infinity, but as floats, which `host_check` refuses.
    An integer too long for Python to convert is still an integer outside i64,
    so it reaches `host_check` and answers `invalid-range` after its checks."""
    try:
        value = json.loads(text, object_pairs_hook=unique_members, parse_int=json_integer)
    except (ValueError, RecursionError):
        return error("invalid-input")
    return host_check(value)


def host_check(value: Any) -> dict[str, str] | tuple[int, bool, list[str], list[int]]:
    """The host's checks: an error, or the stock, policy, ID strings and quantities."""
    if not isinstance(value, dict) or set(value) != {"available", "policy", "requests"}:
        return error("invalid-input")
    available, policy, requests = value["available"], value["policy"], value["requests"]
    if type(available) is not int or policy not in ("partial", "all-or-nothing") \
            or not isinstance(requests, list):
        return error("invalid-input")
    for request in requests:
        if not isinstance(request, dict) or set(request) != {"id", "quantity"}:
            return error("invalid-input")
        if not isinstance(request["id"], str) or not ID_PATTERN.fullmatch(request["id"]):
            return error("invalid-input")
        if type(request["quantity"]) is not int:
            return error("invalid-input")
    integers = [available] + [request["quantity"] for request in requests]
    if any(number not in INT64 for number in integers):
        return error("invalid-range")
    return (available, policy == "all-or-nothing", [request["id"] for request in requests],
            [request["quantity"] for request in requests])


def host_decode(value: Any) -> dict[str, str] | list[Any]:
    """The host's checks, then the component's initial stack."""
    checked = host_check(value)
    if isinstance(checked, dict):
        return checked
    available, whole, ids, quantities = checked
    return [available, whole, lean_host("encode", ids), quantities]


def host_encode(requests: list[dict[str, Any]], stack: list[Any]) -> dict[str, Any]:
    return lean_host("answer", {"ids": [request["id"] for request in requests], "stack": stack})


def run_case(index: int, case: dict[str, Any]) -> dict[str, Any]:
    result: dict[str, Any] = {"name": case["name"]}
    decoded = host_decode(case["input"])
    if isinstance(decoded, dict):
        actual, result["ran"] = decoded, "host"
    else:
        with tempfile.TemporaryDirectory(prefix="firth-inventory-") as directory:
            observation = gate.rebuild(
                {"name": f"case-{index}", "entry": ENTRY, "source": str(SOURCE),
                 "source_path": SOURCE.name},
                Path(directory), stack=decoded, fuel=FUEL)
        stack = [value["literal"]["value"] for value in observation["stack"]]
        actual = host_encode(case["input"]["requests"], stack)
        result.update(ran="firth", kernel_cost=observation["kernel_cost"],
                      requests=len(case["input"]["requests"]))
    result["outcome"] = "pass" if actual == case["expected"] else "fail"
    if result.get("ran") == "firth" and result["kernel_cost"] > cost_bound(result["requests"]):
        result.update(outcome="fail", detail=f"cost {result['kernel_cost']} over the bound")
    if result["outcome"] == "fail":
        result["actual"] = actual
    return result


def main() -> int:
    parser = argparse.ArgumentParser(description=__doc__.splitlines()[0])
    parser.add_argument("--only", nargs="*", help="case names to run")
    parser.add_argument("--jobs", type=int, default=4)
    parser.add_argument("--json", type=Path, help="write the per-case results here")
    args = parser.parse_args()
    cases = json.loads((ROOT / "specs/inventory-allocation-cases.json").read_text(encoding="utf-8"))["cases"]
    selected = [(i, c) for i, c in enumerate(cases) if not args.only or c["name"] in args.only]
    build_toolchain()
    with ThreadPoolExecutor(max_workers=args.jobs) as pool:
        results = list(pool.map(lambda item: run_case(*item), selected))
    for result in results:
        cost = f" (kernel cost {result['kernel_cost']})" if "kernel_cost" in result else ""
        where = f" [{result['ran']}]" if "ran" in result else ""
        extra = f": {result.get('detail') or result.get('actual')}" if result["outcome"] != "pass" else ""
        print(f"{result['outcome']:7} {result['name']}{where}{cost}{extra}")
    counts = {outcome: sum(r["outcome"] == outcome for r in results) for outcome in ("pass", "fail")}
    print(f"{counts['pass']} pass, {counts['fail']} fail of {len(results)}")
    if args.json:
        args.json.write_text(json.dumps(results, indent=1) + "\n", encoding="utf-8")
    return 1 if counts["fail"] else 0


if __name__ == "__main__":
    raise SystemExit(main())
