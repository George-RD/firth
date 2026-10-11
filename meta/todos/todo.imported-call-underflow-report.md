---
node: firth.toolchain.agent
status: open
created: 2026-10-11
---

# Report a short call to an imported word as its file writes it

## Goal

A call to an imported word whose effect has no row, handed too few values,
gets a report that lists no values and names the word canonically. With
`lib.firth`:

```
export v.g;
vocab v {
: g ( a:Int^many b:Int^many -- r:Int^many ) prim + ;
}
```

and `mid.firth`:

```
import "lib.firth";
use v as w;
: h ( -- r:Int^many ) 1 w.g ;
```

`firth_run.py check mid.firth` says "`v.g` in `h` takes 2 values (), bottom
to top, but only 1 value is on the stack before it: `1` (Int). `h` declares
no inputs, but its body takes 1 input." with the hint "Push the missing value
before `v.g`, or take it as an input in the signature." The list of the
values `v.g` takes is empty, and the call is named `v.g`, not `w.g` as the
file writes it. The same word declared in the same file gets "`w.g` in `h`
needs 2 values, ..." (#242). The message has the shape of the pipeline's
account of the values (`shortExplanation`), not of erasure's shortfall, so an
imported call seems to reach the account path with no input names; this is
inferred from the output and not yet traced.

## Acceptance criteria

- The report for the example above names the call `w.g` in its message and
  hint, and either lists `v.g`'s inputs (`a:Int`, `b:Int`) or leaves the
  empty list out.
- A test in `src/agent/Firth/Agent/` or `src/compiler/FirthImportsTest.lean`
  covers it, and fails if either part is undone.

## Traceability

The reviewer on PR #242, as a non-blocking note. It reproduces identically
on main (8ce2c8f), so it is filed under rule 15 rather than widening #242.
