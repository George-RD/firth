---
node: firth.toolchain.agent
status: done
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

## Resolution

Typing finds the word (`closedCallFor` in
`src/elaborator/Firth/StackEffect.lean`). When a definition is refused with a
word-input mismatch, or with an `if` branch that cannot run on the stack below
it, the definition is checked again once for each word it calls whose effect
has no row, with that word given a row. If exactly one of them removes the
refusal, the diagnostic names it. The report then says that the word takes the
whole stack because its effect has no row, and the hint writes the effect with
`forall ρ` from the source (`withRowText`). The hint also gives the other way:
call the word only where nothing is below its inputs. It names no single fix,
because in both primes-up-to answers giving the calling word no row makes the
program check as well.

In the four corpus reports, writing the effect the hint gives clears this
error. Both primes-up-to answers then check but pass 2 of 5 hidden tests,
because of the authors' own logic errors. Both count-distinct answers stop at
a stack underflow in `main` that was already there. None of the four passes
its hidden tests. No other report in runs 10 to 12 or the harder calibration
pools changes, and no answer moves between accepted and refused.

`runClosedCalleeTests` in `ElaboratorDiagnosticsTest.lean` covers the branch
case (primes-up-to, verbatim) and the call case. The test writes the hint's
effect into the source and checks that the program is then accepted. It also
checks that a call with a row, and a closed call given values of the wrong
types (at the call and in a branch), are not given this report. A call or
`dip` of a quotation refused this way (`firth.type.quotation-input-mismatch`)
is not covered: no corpus answer has one.
