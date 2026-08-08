# Proposal: per-word-proof-obligations

## Motivation
The kernel currently exposes one global `DictionaryWellTyped` premise. That
premise is sufficient for preservation, but it does not produce a stable,
machine-readable proof obligation per dictionary word. Without per-word
records, a vocabulary checker cannot report which word was checked or
invalidate only the changed word and its dependants.

## Scope

- Add a Lean record for a checked kernel word containing its identity, body,
  referenced word signatures, required kernel premises, checker name, and
  result.
- Build the record from the existing typed-word and dependency judgements,
  compose records for a vocabulary without treating unchecked records as
  accepted, and invalidate transitive dependants of a changed word.
- Exercise independent checking, vocabulary composition, and transitive
  invalidation in the interpreter test executable.

## Out of scope

- Persisting records outside Lean or adding a serialisation format beyond the
  derived machine-readable representation.
- Replacing the existing dictionary-wide preservation theorem.
- Incremental caching, body hashing, or compiler and runtime integration.
