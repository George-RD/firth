# Proposal: s5-bounded-cost-envelope

## Motivation

Seven obligations in the active profile still had an empty `satisfied_by`, so
coverage reported them ungenerated and exhaustion stayed out of reach whatever
else was finished. Six of them are bookkeeping: the todos that discharge the
VM, the image, the patch protocol, the compiler, R6 and R7 are all done and
just needed wiring. `sc-s5` was the one with nothing to point at.

## Scope

- A witness for PRD S5: a non-trivial program, its stated specification, and a
  pinned gate that checks every clause of the criterion.
- The `cost.kernel` field on `firth.vm-run.v1`, without which the two hosts
  cannot be compared on cost for any program that calls a dictionary word.
- Wiring all seven ungenerated obligations.
- The disposition of the one blocked todo, with the evidence it rests on.

## Out of scope

- Extending `Gamma` so a terminating control loop becomes expressible.
  `dec.s5-cost-envelope-witness` records why the v0.1 vocabulary cannot
  express one and what it would take; that is a registry version change and a
  maintainer decision.
- Deleting the preserved `loop/*` branch ref. The disposition is recorded; the
  forge operation is a maintainer's.
