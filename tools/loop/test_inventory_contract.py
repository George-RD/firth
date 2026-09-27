#!/usr/bin/env python3
"""Validate the independent consumer specification, NOT a Firth implementation."""
from __future__ import annotations

import hashlib
import json
import re
import unittest
from pathlib import Path
from typing import Any

ROOT = Path(__file__).resolve().parents[2]
ORIGINAL_CASES = {
    "empty-batch", "full-allocation", "partial-final", "zero-stock", "partial-oversize-first",
    "whole-oversize-first", "whole-remainder", "whole-zero-stock", "maximum-quantity", "maximum-batch",
    "negative-stock", "zero-quantity", "oversized-stock", "boolean-quantity", "float-quantity",
    "unknown-member", "duplicate-id", "range-before-duplicate", "unknown-policy",
}
# SHA-256 of those 19 cases, in file order, as canonical JSON (sorted keys, no spaces).
ORIGINAL_CASES_SHA256 = "25cc791046bca2c04483e323d6333c6459f9904b59055f589cea96745655d6eb"


def model(value: Any) -> dict[str, Any]:
    def error(code: str) -> dict[str, str]:
        return {"status": "error", "code": code}
    if not isinstance(value, dict) or set(value) != {"available", "policy", "requests"}:
        return error("invalid-input")
    available, policy, requests = value["available"], value["policy"], value["requests"]
    if type(available) is not int or policy not in ("partial", "all-or-nothing") or not isinstance(requests, list):
        return error("invalid-input")
    for request in requests:
        if not isinstance(request, dict) or set(request) != {"id", "quantity"}:
            return error("invalid-input")
        if not isinstance(request["id"], str) or not re.fullmatch(r"[A-Za-z0-9_-]{1,32}", request["id"]):
            return error("invalid-input")
        if type(request["quantity"]) is not int:
            return error("invalid-input")
    if not 0 <= available <= 1000000 or len(requests) > 64 or any(not 1 <= r["quantity"] <= 1000000 for r in requests):
        return error("invalid-range")
    if len({r["id"] for r in requests}) != len(requests):
        return error("duplicate-id")
    remaining, allocations = available, []
    for request in requests:
        demand = request["quantity"]
        take = min(remaining, demand) if policy == "partial" else (demand if demand <= remaining else 0)
        reason = "fulfilled" if take == demand else ("partial" if take else ("out-of-stock" if remaining == 0 else "insufficient-stock"))
        allocations.append({"id": request["id"], "quantity": take, "reason": reason})
        remaining -= take
    return {"status": "ok", "remaining": remaining, "allocations": allocations}


class InventoryContractTests(unittest.TestCase):
    def setUp(self) -> None:
        self.corpus = json.loads((ROOT / "specs/inventory-allocation-cases.json").read_text())

    def test_fixed_cases_match_independent_model(self) -> None:
        self.assertEqual(self.corpus["schema"], 1)
        names = [case["name"] for case in self.corpus["cases"]]
        self.assertEqual(len(names), len(set(names)))
        for case in self.corpus["cases"]:
            with self.subTest(case=case["name"]):
                self.assertEqual(model(case["input"]), case["expected"])

    def test_conservation_order_and_bounds(self) -> None:
        for case in self.corpus["cases"]:
            result = case["expected"]
            if result["status"] != "ok":
                continue
            with self.subTest(case=case["name"]):
                self.assertEqual(sum(a["quantity"] for a in result["allocations"]) + result["remaining"], case["input"]["available"])
                self.assertGreaterEqual(result["remaining"], 0)
                self.assertEqual([a["id"] for a in result["allocations"]], [r["id"] for r in case["input"]["requests"]])
                for allocation, request in zip(result["allocations"], case["input"]["requests"]):
                    self.assertGreaterEqual(allocation["quantity"], 0)
                    self.assertLessEqual(allocation["quantity"], request["quantity"])

    def test_original_cases_retained(self) -> None:
        # The 19 cases committed before the contract freeze may not be removed or renamed.
        # Their inputs and expected outputs are pinned too, not just their names.
        names = {case["name"] for case in self.corpus["cases"]}
        self.assertLessEqual(ORIGINAL_CASES, names)
        original = [case for case in self.corpus["cases"] if case["name"] in ORIGINAL_CASES]
        digest = hashlib.sha256(json.dumps(original, sort_keys=True, separators=(",", ":")).encode()).hexdigest()
        self.assertEqual(digest, ORIGINAL_CASES_SHA256)

    def test_every_error_code_and_reason_is_exercised(self) -> None:
        codes = {case["expected"]["code"] for case in self.corpus["cases"] if case["expected"]["status"] == "error"}
        reasons = {a["reason"] for case in self.corpus["cases"] if case["expected"]["status"] == "ok" for a in case["expected"]["allocations"]}
        self.assertEqual(codes, {"invalid-input", "invalid-range", "duplicate-id"})
        self.assertEqual(reasons, {"fulfilled", "partial", "out-of-stock", "insufficient-stock"})

    def test_fraction_and_exponent_numbers_decode_as_non_integers(self) -> None:
        cases = {case["name"]: case for case in self.corpus["cases"]}
        for name in ("float-quantity", "exponent-quantity"):
            with self.subTest(case=name):
                self.assertIsInstance(cases[name]["input"]["requests"][0]["quantity"], float)
        self.assertIn('"quantity":1e0', (ROOT / "specs/inventory-allocation-cases.json").read_text())

    def test_policy_change_and_zero_allocation_loophole(self) -> None:
        cases = {case["name"]: case for case in self.corpus["cases"]}
        partial, whole = (cases[name]["expected"] for name in ("partial-oversize-first", "whole-oversize-first"))
        self.assertNotEqual(partial, whole)
        self.assertEqual([a["quantity"] for a in partial["allocations"]], [5, 0, 0])
        self.assertEqual([a["quantity"] for a in whole["allocations"]], [0, 3, 2])
        self.assertGreater(sum(a["quantity"] for a in whole["allocations"]), 0)


if __name__ == "__main__":
    unittest.main()
