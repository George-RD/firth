---
node: firth.toolchain.interpreter
status: open
created: 2026-09-27
---

Requires: language-06b-program-property-proofs

## Goal

Prove a program's kernel cost bound as a function of its input size, from the
stated cost semantics, instead of fitting it from measurements. PRD R10: "All
timing or memory claims shall be derivable from the stated cost semantics,
not from measurement alone." The first consumer is the inventory allocator's
bound, currently `417 + 767n + 264n(n−1)/2` kernel steps, fitted by
`examples/inventory/measure_cost.py`.

## Acceptance criteria

- The program logic of `language-06b` carries kernel cost, so a proof gives
  both a result and an upper bound on the steps taken.
- A theorem states that for every input the host can hand the allocator,
  with n requests, the reference interpreter's kernel cost for
  `allocate-batch` is at most the stated f(n), and the run terminates. It is
  admitted and rechecked like the property proofs of `language-06b`.
- The bound in `examples/inventory/run_cases.py` and the README is the proved
  f(n). `measure_cost.py` stays as a check that the measured costs are within
  it.
- The same two gaps as `language-06b` are stated: VM agreement, including the
  VM's own cost accounting, rests on differential testing, and the proof
  carries the i64 side condition.

## Traceability

PRD R10, S5. Split from `language-06-source-refinement-execution` on 27
September 2026.
