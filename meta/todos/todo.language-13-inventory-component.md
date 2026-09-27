---
node: firth.toolchain.agent
status: open
created: 2026-09-08
---

Requires: language-04-differential-execution language-06-source-refinement-execution language-10-inventory-contract language-11-arithmetic-comparison language-12-data-and-modules

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
  417 + 767n + 264n(n-1)/2 kernel steps; that bound is measured, not proved.
  Still open: the policy-change demonstration and toolchain-checked
  properties (`language-06`).

## Traceability

PRD G8/G9/S5; dec.usable-language-milestones, first real consumer.
