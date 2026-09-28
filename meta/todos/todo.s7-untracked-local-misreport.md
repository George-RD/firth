---
node: firth.toolchain.agent
status: done
created: 2026-09-28
---

# A branch mismatch inside `locals` is reported as an untracked local

Done in #145 (`42330f6`): an `if` whose branches leave different depths is
reported at the `if`, with its expected and actual stacks, not as an
untracked local. #148 (merged as `e1e698a`) extends that to every depth-mismatched `if`,
wherever it sits, including one whose quotation is bound to a local. The
last criterion, a separate scored re-run of the MVP set, moves to
`todo.s7-mvp-rerun`.

Found in S7 run 5 (`eval/s7/runs/2026-09-28-haiku-cec3707/`, see
`eval/s7/README.md`). `firth.elaboration.untracked-local` was the largest
single diagnostic in Haiku's last-round failures (4 of 12). It stayed on
`ledger` through all three answers.

## Goal

When the two branches of an `if` inside a `locals` block leave different
stacks, the checker says the local "is used after `call`, `dip` or `if` ran
a quotation whose stack effect is not known here". Its hint says inline
quotations with a fixed effect are fine. The actual mistake is the branch
mismatch, which the same `if` outside `locals` reports as
`firth.type.branch-mismatch`. Report the branch mismatch, with its expected
and actual stacks, in both places.

Planted case (fails today with `untracked-local`; passes once `[ drop b ]`
becomes `[ b ]`):

```firth
: main (forall ρ; ρ a:Int^many b:Int^many -- ρ r:Int^many)
  locals { a b } { a 0 prim < [ drop b ] [ b ] if a prim + };
```

## Acceptance criteria

- The planted program above gets `firth.type.branch-mismatch`, not
  `untracked-local`, in a diagnostics test.
- `untracked-local` stays for its real case: a quotation whose effect is not
  known, such as one passed in as a value.
- The S7 MVP set is re-run afterwards, as a separate scored run.
