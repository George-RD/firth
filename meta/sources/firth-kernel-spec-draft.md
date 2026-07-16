---
id: src.firth-kernel-spec-draft
file: files/firth-kernel-spec-draft.md
verification: verified
type: kernel calculus specification draft
date: 2026-07-16
sha256: db11bd9b9eb98457fb87d32581ee12915f6fa0268c571c46cd7c45e9acc9944d
---

Draft specification v0.1 of the Firth kernel calculus: a typed concatenative calculus with a single value stack, no variables, no binders, no environment. Defines the kernel atom set (ten atoms plus literals, quotation formation, dictionary word reference, and primitive family), the typing judgement D ⊢ p : Σ₁ → Σ₂ with prenex row-polymorphic stack types and linearity, the small-step operational semantics over configurations ⟨V ∣ p⟩ as a pure rewrite system, the linear World effect model, and the cost parameter table κ. Status is draft for review and mechanisation; becomes normative only after Lean mechanisation validates it.
