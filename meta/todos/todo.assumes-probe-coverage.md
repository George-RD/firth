---
node: firth.toolchain.elaborator
status: open
created: 2026-09-29
---

# Name a callee whose fix changes its arity in a way no probe tries

## Problem
A report names a refused callee in `assumes` only when one of the probe
effects (#176) changes it once checking gets as far as the report. The
probes are four fixed effects and the callee's own effect with other types,
so they never add or remove one of the callee's own values. Some fixes do
exactly that, and then the report depends on the callee without saying so.
Codex's case on #176:

```
: f ( -- a:Int b:Int ) true 1 2 ;
: g ( -- r:Int ) f prim + drop true 1 prim + ;
```

`f`'s body leaves three values. With `f` fixed to `( -- z:Bool a:Int b:Int )`,
`g`'s report at its second `prim +` shows a stack with one more value. Every
fixed probe underflows at the first `prim +`, and every own-effect probe
changes a type that first `prim +` needs, so both only stop the check before
the report, and `g`'s report carries no sentence. That is the report main
gives, so nothing is claimed that is false, but the author is not warned.

## Acceptance criteria
- `g` above names `f`, by deciding dependence from which declared effects
  each part of a report came from, or by probes that add and remove one of
  the callee's own values, with the cost kept within
  `todo.assumes-probe-cost`.
- No report gains a name that the effect-substitution check over the corpus
  does not confirm.
- A test for `g`, and a planted bug that drops the new coverage and fails it.
