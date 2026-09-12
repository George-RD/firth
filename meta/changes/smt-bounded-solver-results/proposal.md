# Proposal: smt-bounded-solver-results

## Motivation

The solver profile pinned an identity, invocation options, a wall-clock bound
and a memory bound, and nothing in the repository used any of it. There was no
invocation, no classification of an answer, and no way for a result to say
which request it answered.

## Scope

- `src/smt/Firth/SmtSolver.lean`: the invocation seam, the pin refusals, the
  bounded process runner, total transcript classification, and the model
  parser.
- Binding every result to its request's canonical identity, and refusing a
  result that is not so bound.

## Out of scope

- Promoting a checked `unsat`. `classifyTranscript` maps a bare `unsat` to
  `uncheckedUnsat`; the promotion, the discharge record and its recheck are
  delivered by the sibling `smt-discharge-record-recheck` unit and owned by
  `smt-record-promotion`, so no result is promoted here without a record.
- Fetching or vendoring the pinned solver. The runner refuses when it is
  absent or is not the pinned binary, with a stable code.
