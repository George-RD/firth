#!/usr/bin/env python3
"""Check the repeated-ID scan on IDs that differ in only one of their parts.

The frozen corpus never has two IDs that agree on some of their four encoded
parts and differ in another, so a scan that skipped a part would still pass
it. Each case here is a batch whose IDs share every part but one, with or
without a real repeat at the first, middle or last pair of requests. Every
case runs through the host in `run_cases.py`, on the VM and the reference
interpreter, and must equal the independently tested model in
tools/loop/test_inventory_contract.py and stay within the cost bound.
"""
from __future__ import annotations

import sys
from concurrent.futures import ThreadPoolExecutor
from typing import Any

import run_cases as host

sys.path.insert(0, str(host.ROOT / "tools" / "loop"))
from test_inventory_contract import model  # noqa: E402

BATCH = 5
REPEATS = [None, (0, 1), (1, 3), (BATCH - 2, BATCH - 1), (0, BATCH - 1)]


def ids_differing_in(part: int) -> list[str]:
    """BATCH distinct 32-character IDs that differ only within `part`."""
    base = list("abcdefgh" "ijklmnop" "qrstuvwx" "yzABCDEF")
    ids = []
    for k in range(BATCH):
        text = base.copy()
        text[8 * part + 7] = host.ALPHABET[k]
        ids.append("".join(text))
    return ids


def cases() -> list[dict[str, Any]]:
    found = []
    for part in range(4):
        for repeat in REPEATS:
            ids = ids_differing_in(part)
            if repeat is not None:
                ids[repeat[1]] = ids[repeat[0]]
            given = {"available": 10, "policy": "partial",
                     "requests": [{"id": text, "quantity": 1} for text in ids]}
            name = f"part-{part}-" + ("distinct" if repeat is None else f"repeat-{repeat[0]}-{repeat[1]}")
            found.append({"name": name, "input": given, "expected": model(given)})
    return found


def main() -> int:
    host.gate.build_toolchain()
    selected = cases()
    if {case["expected"]["status"] for case in selected} != {"ok", "error"}:
        raise SystemExit("check_scan: the cases must include both distinct and repeated IDs")
    with ThreadPoolExecutor(max_workers=4) as pool:
        results = list(pool.map(lambda item: host.run_case(*item), enumerate(selected)))
    for result in results:
        extra = f": {result.get('detail') or result.get('actual')}" if result["outcome"] != "pass" else ""
        print(f"{result['outcome']:5} {result['name']} (kernel cost {result['kernel_cost']}){extra}")
    passed = sum(result["outcome"] == "pass" for result in results)
    print(f"{passed} pass, {len(results) - passed} fail of {len(results)}")
    return 0 if passed == len(results) else 1


if __name__ == "__main__":
    raise SystemExit(main())
