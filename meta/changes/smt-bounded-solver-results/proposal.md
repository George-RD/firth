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

- Promoting a checked `unsat`. `ExternalOutcome` still has no checked-unsat
  constructor, and adding one without the record and its recheck would put an
  unrechecked result into evidence. That is the next todo.
- Fetching or vendoring the pinned solver. The runner refuses when it is
  absent or is not the pinned binary, with a stable code.
