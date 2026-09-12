# Design: s5-bounded-cost-envelope

## Approach

The witness is a protocol handler, which is one of the two examples S5 itself
offers, because the other one cannot be written honestly at v0.1. The
reasoning, and what a terminating control loop would need, is in
`dec.s5-cost-envelope-witness`.

The specification is data, not prose, so the gate can check it. It states the
program's shape, the declared word type of every definition, the behaviour,
and the cost bound. The shape clauses are the load-bearing ones: without them
a later refactor that inlined the handlers into a straight-line sequence would
still satisfy the result and the envelope while destroying what makes the
witness non-trivial. The gate counts static call sites in the elaborated
program and, separately, the calls the session actually makes, which it reads
off the gap between the two cost charges.

Comparing costs across hosts needed one change. The VM charges one
administrative entry per dictionary call and the reference interpreter does
not, so their totals differ for any program that calls a word. The MVP corpus
never called one, which is why the difference had not surfaced.
`firth.vm-run.v1` responses now carry `cost.kernel` alongside `cost.total`,
the same quantity the frozen fixture corpus records as its `lean_cost` column,
and the two gates compare that against the reference total.

Six obligations are wired to todos that already discharge them. R6 is
"individually replaceable in a running image without restarting", which is
what `tests/lifecycle.rs` drives end to end. R7 is "accepted only if its stack
effect and stated refinements are compatible", which is the patch protocol's
exact erased-word-type equality plus the elaborator's contract subsumption.

## Changes

ADDED:
- `examples/s5/protocol-handler.firth` and `protocol-handler.spec.toml`.
- `tools/loop/check_s5_envelope.py`, pinned on the `sc-s5` row.
- `meta/decisions/s5-cost-envelope-witness.md` and
  `meta/decisions/elaborator-pipeline-boundary-recovery-disposition.md`.
- `meta/todos/todo.s5-bounded-cost-envelope.md`.
- Blueprint path `examples/s5` on `firth.runtime.vm`.

MODIFIED:
- `src/runtime/vm/src/adapter.rs`: `cost.kernel`, with a witness that a
  dictionary call separates the two charges.
- `tools/loop/obligations.toml`: all seven ungenerated rows wired.
- `tools/loop/test_mvp_agent_coverage.py`: every pinned gate must exist,
  rather than there being exactly one.
- `meta/todos/todo.recover-elaborator-pipeline-boundary.md`: the disposition.
