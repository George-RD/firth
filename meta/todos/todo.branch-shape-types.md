---
node: firth.toolchain.agent
status: open
created: 2026-09-28
---

# Name the types in a depth-mismatched `if` found by erasure

An `if` whose branches change the stack depth by different amounts is
refused by erasure (`ErasureError.branchShape`) before the type checker runs,
wherever it sits. Erasure tracks depths, not types, so its report says what
each branch takes and pushes, which branch leaves more and by how many, and
the edit (`drop` in the longer branch, or push that many values in the
shorter one), but not the types of the values involved. The type checker's
report of a mismatch it finds itself names both branch stacks with their
types and suggests a value to push.

## Goal

The erasure report names the types of the values the longer branch leaves,
as the type checker's does, so the hint can say which values to push (for
example `0` for an Int).

## Notes

This needs erasure to carry types, or the pipeline to type the two branch
quotations on their own when erasure refuses the `if`. Erasure has to refuse
the `if` because the stack depth after it is unknown, so later locals cannot
be placed.
