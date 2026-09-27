---
node: firth.ecosystem.specs
status: done
created: 2026-09-08
---

## Goal

Freeze an independent first-consumer contract and acceptance cases.

## Acceptance criteria

- Specify ordered stock allocation, partial and all-or-nothing policies, input bounds, duplicate IDs, output reasons and error precedence.
- Commit fixed positive/negative cases before the Firth implementation; include a case rejecting the allocate-nothing loophole and a policy-change case.
- Keep the host responsible for JSON decoding and persistence, and the Firth component responsible for the allocation calculation. Document concurrency outside the pure contract.
- Validate the corpus and independently review its expected outcomes. Completing this specification does not satisfy the Firth application milestone.

## Verification

- `python3 tools/loop/test_inventory_contract.py`
- Frozen 27 September 2026: all expected outcomes re-derived by hand from the
  specification and again blind by a separate agent from the text alone. 32
  cases were added for gaps the original 19 left (the count, quantity and ID
  bounds, `available` types, error precedence, exact fit and case-sensitive
  IDs); the original 19 are unchanged and the test keeps them. The host/Firth
  split is now stated in the specification.

## Traceability

specs/inventory-allocation.md and specs/inventory-allocation-cases.json; PRD G9/S5.
