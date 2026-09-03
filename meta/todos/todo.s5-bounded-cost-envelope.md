---
node: firth.runtime.vm
status: done
created: 2026-09-03
---

# S5 bounded cost envelope witness

Requires: rust-vm-implementation mvp-agent-compiler-adapter mvp-agent-vm-adapter mvp-agent-elaborate-adapter

## Goal

Discharge PRD S5: a non-trivial program written, verified to a stated
specification, and executed on the VM within a bounded cost envelope.

## Acceptance criteria

- A non-trivial Firth program exists with a stated specification carrying its
  shape, its declared word types, its behaviour and its cost bound.
- A pinned gate elaborates and compiles the program, runs it on the VM and on
  the Lean reference interpreter, and refuses any drift between the stated
  specification and what the toolchain actually checked and measured.
- The two hosts agree on the kernel-comparable cost exactly, and the VM's own
  charge stays inside the stated envelope.
- The gate is deterministic and is invoked by
  `python3 tools/loop/coverage.py --run-gates`.

## Verification

- `python3 tools/loop/check_s5_envelope.py`
- `python3 tools/loop/coverage.py --run-gates`
- `lake build`, `lake test`
- `$CAIRN scan`, `$CAIRN hook all`

## Non-goals

- A terminating control loop. `dec.s5-cost-envelope-witness` records why the
  v0.1 vocabulary cannot express one and what a `Gamma` extension would need.
- Refinement-level verification. The stated specification is the checked word
  type until the SMT slice lands.
