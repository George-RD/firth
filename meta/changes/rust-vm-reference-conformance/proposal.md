# Proposal: rust-vm-reference-conformance

## Motivation

`todo.rust-vm-reference-conformance` asks for the VM side of the differential
contract: a deterministic boundary that compares a Rust execution with the
Lean reference contract over the five field groups `target-spec.md` §7 fixes,
namely terminal status, canonical residual stack, residual frames, the hidden
`WorldState` observation, the classified trap, and the cost report.

Today the crate compares only what `fixtures/kernel.tsv` states, and it does
so inline in one test with private rendering helpers. The world observation
is never compared, `stuck` rows are never classified, and there is no
representation at all for fuel exhaustion as a third outcome or for the
`bounded-fuel-inconclusive` verdict the frozen strategy requires when both
hosts spend an equivalent budget.

## Scope

- A production `conformance` module holding the canonical observation record,
  the partial reference contract, the comparison, and the verdict, including
  `bounded-fuel-inconclusive`.
- Deterministic witnesses for the classes the frozen row format cannot state:
  hidden world observation, classified traps, malformed input, fuel
  exhaustion, primitive faults, one-sided exhaustion, and cost breakdown.
- Routing the existing frozen corpus through the same comparison, so the
  fixture boundary and the adapter are one path rather than two.

## Out of scope

- Any change to Lean interpreter semantics, to the frozen fixture row format,
  or to compiler lowering.
- A general fuzzing harness. Only deterministic witnesses are available at
  this point, and the module claims nothing more.
