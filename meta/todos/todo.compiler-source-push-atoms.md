---
node: firth.toolchain.compiler
status: open
created: 2026-10-02
---

## Problem

`compileWords` admits a checked word whose program holds a `push` atom, the
interpreter's administrative step that `dip` and `quote` create at run time.
The elaborator never writes one, but a hand-made `firthCompile` request can
(`tools/loop/check_trust_boundaries.py` relies on this to test a forged linear
quotation). The compiler then disagrees with the reference interpreter on
cost: the interpreter charges nothing for `(S-PUSH)`
(`Interpreter.lean`, `dec.gap-firth-language-kernel-kappa-cost-table-does-not-categorise`),
while the lowered `PUSH_LITERAL` or `PUSH_QUOTE` charges one kernel unit.

`compileWords_correct` (`src/compiler/Firth/LoweringSimulation.lean`) excludes
these programs with its `noPushProgram` hypothesis, so it does not cover every
program the compiler accepts. The reviewer accepted the hypothesis on #215
(step 3 of `todo.compiler-vm-agreement-proof`), provided step 4 discharges it
by evaluation for the allocator's words.

## Acceptance criteria

- Either `compileWords` refuses a source-level `push` atom, with the trust
  boundary check moved to a form the elaborator can produce, and
  `noPushProgram` is proved from a successful `compileWords` so the hypothesis
  goes; or the decision to keep admitting it is recorded, with the cost
  disagreement stated wherever the theorem is cited.
- A planted request with a source-level `push` shows the chosen behaviour.
