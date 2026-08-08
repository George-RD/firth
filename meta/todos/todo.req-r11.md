---
node: firth.language.kernel
status: done
created: 2026-08-08
---

# Kernel Non-Local Effect Isolation
# Goal
Make each word's semantics depend only on its body and the signatures of referenced words, with no untracked non-local effects.

Requires: kernel-metatheory

## Acceptance criteria
- Define the kernel-side effect and dependency boundary that determines a word's semantics from its body and referenced signatures.
- Prove that well-formed word bodies cannot introduce an untracked non-local effect through sequencing, quotations, dictionary lookup, or primitive execution.
- Add executable Lean checks covering direct references, nested quotations, recursive dictionary references, and rejected effect leakage.
- Keep the zero-admit check passing with no `sorry`, `admit`, or `axiom`.

## Traceability
Satisfies PRD R11 and obligation `req-r11`.
