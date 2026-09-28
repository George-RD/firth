---
node: firth.toolchain.agent
status: open
created: 2026-09-08
---

Requires: language-04-differential-execution language-06b-program-property-proofs language-06c-proved-cost-bound language-10-inventory-contract language-11-arithmetic-comparison language-12-data-and-modules

## Goal

Run and modify an inventory-allocation component written in Firth.

## Acceptance criteria

- Implement the calculation as Firth words and expose the specified host interface. Run the fixed acceptance corpus on the compiled VM and reference interpreter.
- Check stock conservation and policy properties without weakening them; preserve independent expected results, invalid-input handling and output reasons.
- Demonstrate changing partial fulfilment to all-or-nothing while preserving other requirements, with changed-word/dependency checks and regression evidence.
- Add an executable acceptance gate to the obligations row before setting this task done. A Python model or fixture validator is not the Firth implementation.

## Progress

- 27 September 2026: `examples/inventory/allocator.firth` implements the
  calculation with its bounds and repeated-ID checks. `run_cases.py` is the
  host, and CI runs the fixed corpus on both hosts: all 53 cases pass (the 3
  negative-input cases since signed `Int`). The worst case cost is at most
  165 + 202n + 163n(n-1)/2 kernel steps since `pick` and `roll` (#125) and
  the scan's move to locals (417 + 767n + 264n(n-1)/2 before, which the
  costliest ID shape exceeded); that bound is measured over every ID shape,
  not proved.
  Still open: toolchain-checked properties and a proved cost bound
  (`language-06b`, `language-06c`).
- 27 September 2026: `examples/inventory/policy_change.py` changes a
  partial client (`policy-change/partial.firth`) to all-or-nothing and runs in
  CI. From the compiler's word digests and call graph it checks that only the
  client word `reserve` changed and nothing depends on it. It runs all 30
  Firth-reaching cases through both clients on both hosts, against the corpus
  where the policy matches and the tested model plus the spec's properties
  where it does not. Firth has no imports, so each program is the allocator's
  source followed by the client's.

## Traceability

PRD G8/G9/S5; dec.usable-language-milestones, first real consumer.
