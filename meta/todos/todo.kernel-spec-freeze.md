---
node: firth.language.kernel
status: open
created: 2026-07-16
---

Requires: quotation-typing-prior-art, patch-compat-prior-art

## Goal
Finalise the kernel calculus draft for Lean mechanisation and define the freeze gate.

## Acceptance criteria
- Resolve quotation typing, effect usage, cost-table, and patch-compatibility questions in a decision-backed spec revision.
- Add administrative `push v` syntax, a (PUSH) typing rule, and explicit value/stack typing judgements.
- Rename overloaded Sigma notation so primitive signatures and stack rows are distinct.
- Define base-type usage attachment in the ValueType grammar.
- Define linear consumption exactly, including the terminal-stack leak rule.
- State Sigma/delta_pi well-formedness requirements guaranteeing determinism and progress.
- Keep kappa as an uninstantiated total-function parameter; concrete values belong to vm-target-spec.
- State the atom set, typing judgement, operational semantics, and cost semantics without unresolved normative ambiguity.
- Define a freeze checklist requiring Lean definitions to agree with the prose before the kernel becomes normative.

## Traceability
Serves G1, G6, G7 and requirements R1, R2, R3, R5, R7, R9, R10, R11, R15; enables success criterion S1.
