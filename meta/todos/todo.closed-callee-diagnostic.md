---
node: firth.toolchain.agent
status: open
created: 2026-10-10
---

# Say that a callee's effect is closed when it is refused for what lies below

A word whose effect has no row takes the whole stack. When it is called with
anything else below its inputs, the report does not say so. In
`eval/s7/runs/2026-09-29-locals-guide/arm-b/haiku-firth-1/answer-3.md`
(`primes-up-to`), `is-prime` is declared `(num:Int^many -- result:Bool^many)`
and called inside a branch of `prime-loop`, where the stack also holds the
caller's row. Before `dec.closed-effect-under-locals` the report was
"`is-prime` in `prime-loop` needs Int on top of the stack, but the stack before
it is .. ?t33 ?t32 ?t31 ?t33 ?t33", though `num`, an Int, is on top. Since
then the call's locals are lifted out of its way, and the report moved to the
`if`: "the false branch takes (empty)". Neither says that `is-prime` takes the
whole stack, or that declaring it `(forall ρ; ρ num:Int^many -- ρ
result:Bool^many)` lets it be called there. Runs 10 to 12 and both harder
calibration pools have 4 such reports, in 2 answers of one sample.

## Acceptance criteria

- When a call to a word with no row in its input is refused because the
  stack holds more than its inputs, at the call or at an `if` whose branch
  makes that call, the diagnostic names the word, says its effect has no row
  so it takes the whole stack, and shows the effect with `forall ρ`.
- A refusal of a call with a row, or of a closed call whose top values have
  the wrong types, does not say this.
- A planted failure restoring the old report fails a test.
