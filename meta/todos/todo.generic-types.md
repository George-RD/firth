---
node: firth.language.types
status: open
created: 2026-10-13
---

## Goal

Let a program write a result or optional type once and use it at several
types, e.g. `Result Int Int` and `Result (Seq Int) Int`, in place of one
`variant` declaration per instantiation.

## Acceptance criteria

- Type parameters on `record` and `variant` declarations, and type
  application in stack effects, with a total erasure to the same flat form
  `dec.typed-records-and-variants` defines (one erased layout per
  instantiation).
- Linear type arguments handled: a parameter used as a variant payload is
  refused for a linear argument, as a non-generic payload is.
- Stable errors for the wrong number of arguments and for unknown parameters,
  each with a planted-bug test.

## Traceability

Deferred by `dec.typed-records-and-variants` (rejected alternative: a fixed
`Result T E`). `todo.language-12` does not wait for it.
