---
id: res.firth-kernel-spec.summary
nodes: [firth.language.kernel]
sources: [src.firth-kernel-spec-draft]
date: 2026-07-16
---

## Machine Model

A single value stack V, no return stack, no environment, no variables. Execution is a pure rewrite over configurations ⟨V ∣ p⟩ where p is a program (sequence of atoms). Sequencing is function composition. Terminal configuration is ⟨V ∣ ε⟩. An administrative atom push v exists only in the semantics, not the surface syntax.

## Atom Set

Ten kernel atoms plus three families:

- **Structural:** dup, drop, swap (duplication, discarding, exchange, each with linearity constraints)
- **Quotation eliminators:** call (execute a quotation), dip (execute a quotation beneath the top value)
- **Quotation constructors:** compose (concatenate two quotations), quote (lift a value into a quotation)
- **Control:** if (conditional over a Bool value with two quotation branches)
- **Literals:** lit c (push a constant)
- **Quotation formation:** [p] (push a quotation of program p)
- **Dictionary words:** w (reference by name, resolved to body_D(w))
- **Primitives:** prim π (opaque typed operations from signature Σ)

Removal of any atom loses expressive power (per R1).

## Quotations

Quotations ⟦p⟧ provide all higher-order structure. call and dip are the eliminators; compose and quote are the constructors beyond literal quotation formation. Recursion comes from the dictionary D : Name ⇀ (WordType, Program), not from a fixpoint combinator. Dictionary well-formedness requires each word body to check against its declared signature assuming all declared signatures, which licenses mutual recursion.

## Typing Judgement

D ⊢ p : Σ₁ → Σ₂, a program transforms stack type Σ₁ into Σ₂ under dictionary D.

**Stack types** Σ are rows over a row variable ρ, giving rest-of-stack polymorphism. Quantification is prenex only: row variables are bound at word signatures, never inside types. This keeps inference decidable (R3) and is the known-good region from prior art; higher-rank stack polymorphism is explicitly excluded from the kernel.

**Value types** τ are either base types ι from Σ (with Bool ∈ Σ required) or quotation types [Σ₁ → Σ₂]ᵘ carrying a usage annotation.

**Usage** u ∈ {many, linear}. Base types from Σ declare their usage (numbers are many; resource types such as handles or the World token are linear). A quotation's usage is many if formed by [p] syntax (pure code), and is the meet of embedded values' usages when formed by quote/compose. dup and drop require many. Linear values must be consumed exactly once. There is no borrowing; the stack is the ownership model (G3).

**Linearity** is enforced structurally: a linear value can only be moved (swap), buried and revived (dip), consumed by a primitive, or embedded into a (then-linear) quotation. Branches of if must agree on consumption because both have the same type. An open question [OPEN-1] asks whether usage is better formalised as a kinding judgement or as capability flags on types; the two are equivalent on paper and whichever proves cleaner in Lean wins.

## Operational Semantics

Small-step over configurations ⟨V ∣ p⟩. Each atom has exactly one applicable rule per value shape, giving determinism. Key rules:

- S-LIT: push constant onto stack
- S-DUP/S-DROP/S-SWAP: structural operations
- S-CALL: ⟨V ⟦q⟧ ∣ call ; p⟩ → ⟨V ∣ q ; p⟩ (unfolds by concatenation)
- S-DIP: ⟨V v ⟦q⟧ ∣ dip ; p⟩ → ⟨V ∣ q ; push v ; p⟩ (executes q, restores v)
- S-COMP: concatenates two quotations
- S-QUOTE: lifts a value into a push-based quotation
- S-IF-T/S-IF-F: selects the appropriate branch
- S-WORD: unfolds to body_D(w) (recursion source)
- S-PRIM: applies δ_π from Σ

No return stack: call and word unfold by program concatenation, making tail calls free and the semantics a pure rewrite system.

## Metatheory Obligations

To be mechanised in Lean with zero admits (S1): determinism, preservation, progress, linearity soundness, cost invariance.

## Linear World Effect Model

Effects are not kernel constructs. Σ declares a linear base type World, and every effectful primitive has type Σ · World · args → Σ · World · results. Linearity forces a single ordered thread of effects through the program; pure programs never mention World. This keeps the kernel semantics a deterministic rewrite system, makes effect order provable, and costs nothing at runtime (the token compiles to nothing). Alternatives considered and rejected: a monadic layer (heavier, duplicates what linearity already provides) and unrestricted effectful primitives (destroys determinism). [OPEN-2] confirms this during mechanisation of preservation.

## Cost Semantics

Each step rule carries a cost from a constant table κ: κ(a) for kernel atoms, κ(π) per primitive from Σ, κ(unfold) for S-WORD. Cost of a trace is the sum of its steps. The table is a parameter of the semantics, not fixed by it, so targets instantiate it (a microcontroller VM and a JIT would differ). Claims of the form "word w costs at most f(inputs)" are refinement-layer statements proved against this parameterised semantics (R10). The kernel guarantees only that cost is deterministic and compositional over sequencing.

## Deliberate Exclusions

Refinements (live in the elaboration layer, not the kernel); names and namespaces (dictionary maps opaque names to typed bodies; naming grammar is a surface concern); named locals (desugar to dip/swap/dup patterns); concurrency (out of scope for kernel v1, though the World-token model leaves room for a partitioned-token extension); higher-rank rows, subtyping, and overloading (excluded to protect decidability and inference, R3).

## Open Questions

[OPEN-1] Usage formalisation style (kinds vs capability flags): decide during mechanisation. [OPEN-2] Effects: World token proposed; confirm during mechanisation of preservation. [OPEN-3] Quotation usage inference at compose/quote boundaries: verify no soundness gap. [OPEN-4] Whether swap generalises to an indexed family (e.g. rot) as kernel atoms or stays minimal with derived shuffles. [OPEN-5] Bool as required base type vs Church-encoded quotational booleans: proposal is required base type because if as a kernel atom simplifies the cost model and the typing of branches.
