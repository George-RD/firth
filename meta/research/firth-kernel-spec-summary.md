---
id: res.firth-kernel-spec.summary
nodes: [firth.language.kernel]
sources: [src.firth-kernel-spec-draft]
date: 2026-07-17
---

## Frozen v0.1 summary

The kernel is a typed concatenative calculus over one value stack, with no
variables, binders, environment, or return stack. Its atoms are literals,
quotation formation, `dup`, `drop`, `swap`, `dip`, `call`, `compose`, `quote`,
`if`, dictionary words, and opaque primitives. `push v` is administrative
syntax used only by the operational semantics.

The primitive signature `Γ` and stack rows `Σ` are distinct. Value types attach
usage directly to base types and quotation types. Quotation usage is the meet
of every embedded `quote` or `lit` value, recursively through nested quotation
bodies. The empty meet is `many`; `[lit h]` is linear for a linear handle.
`compose` meets operand usage, `call` and `dip` consume one quotation in their
transition and accept either usage, and `if` requires both `many` branches with
identical stack effects. `dup` and `drop` require `many`.

The dictionary is `D : Name ⇀ (WordType, Program)`, where `WordType` is a
prenex erased stack effect and contains no refinements. The elaborator owns the
public `(WordType, Spec)` contract. A compatible replacement preserves erased
`WordType` and dictionary well-formedness, then separately proves refinement
subsumption by weakening inputs and strengthening outputs.

The small-step semantics is deterministic and uses program concatenation for
`call` and word unfolding. Lean obligations target determinism, preservation,
progress, finite-trace at-most-once linearity safety, conditional exact-once
under termination with empty linear residue, and cost invariance. The World
token is normative for v0.1. Effectful-word observational refinement remains
the registered proposed gap.
