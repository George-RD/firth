---
node: firth.toolchain.agent
status: done
created: 2026-10-11
---

# Name the operation inside a nested `if` that takes a value from below

Found in the scored S7 run of 2026-10-11 (sonnet-firth-3's warehouse, round
1, `eval/s7/harder/runs/2026-10-11-scored/sonnet-firth-3/solutions-1.json`).
`fillb` is refused with `firth.type.branch-mismatch` at its outer `if`
(line 74, column 11): "the true branch takes 1 value from the stack below
the `if` and leaves 1 value". The value is taken by `addto` in the true
branch of the inner `if` on line 72, `[ 30 p prim + 1 addto ] [ ] if`,
whose block never pushed the sequence `addto` updates. The author's fix
pushed `m3` before the inner condition. The report points at the outer
branch and says nothing of `addto`, so it is misleading.

No one-token edit can be named here: inserting the local `m` alone checks
at 8 places in the branch (checked with `firth_run.py check` at 35c73c1),
and `m2` and `m3` are in scope too.

## Acceptance criteria

- The report for `fillb` names `addto` on line 72, in the inner `if`, as
  the operation that takes the value from below the outer `if`.
- The report main gave at 35c73c1 is planted in the test and fails it.

## Done

Met by the inner-reach change: the `fillb` case in
`src/agent/Firth/Agent/ElaboratorDiagnosticsTest.lean` (`runInnerReachTests`)
checks that the report names `addto` "in the true branch of the `if` at line
72, column 39", with its missing values, and plants the message main gave at
35c73c1 as a report that must fail the case. The effect on real answers is in
`eval/s7/report-changes/inner-reach/` (54 of 6,959 reports change, none
changes status, code or location). The case where both paths of the inner
`if` reach below the branch still falls back to the older wording; that is
recorded in `todo.internal-operation-diagnostics`.
