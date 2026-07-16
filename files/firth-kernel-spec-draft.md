# Firth Kernel Calculus
## Specification, DRAFT v0.1 — NOT FROZEN

Status: draft for review and mechanisation. This document becomes normative only after the Lean mechanisation validates it (PRD §9). Sections marked **[OPEN]** contain proposed decisions awaiting confirmation; everything else is proposed as settled.

---

### 1. Overview

The kernel is a typed concatenative calculus. A program is a sequence of atoms; sequencing is function composition; the machine state is a single value stack. There are no variables, no binders, and no environment. Quotations (first-class program fragments) provide all higher-order structure. Recursion comes from the dictionary, not from a combinator.

The kernel is parameterised over a signature Σ of primitive base types and primitive words (arithmetic, comparisons, and effectful operations). Primitives are opaque typed constants to the kernel; the metatheory quantifies over any well-typed Σ.

### 2. Syntax

```
Atom      a ::= lit c            push a literal constant
             | [ p ]             push a quotation of program p
             | dup | drop | swap
             | dip | call | compose | quote
             | if
             | w                 dictionary word reference
             | prim π            primitive from Σ

Program   p ::= ε | a p          (sequences; ε is the empty program)

Value     v ::= c                literal constant
             | ⟦p⟧               quotation value (code)

Stack     V ::= · | V v          (bottom to top)

Dictionary D : Name ⇀ (WordType, Program)
```

Ten kernel atoms plus literals, quotation formation, word reference, and the primitive family. Removal of any loses expressive power (R1): `dup`/`drop` are the structural rules, `swap` is exchange, `dip`/`call` are the eliminators for quotations, `compose`/`quote` are the constructors beyond literal formation, `if` is decision, words are recursion.

### 3. Types

```
ValueType  τ ::= ι                       base type from Σ (Bool ∈ Σ required)
              | [ Σ₁ → Σ₂ ]ᵘ             quotation type, usage u

StackType  Σ ::= ρ                       row variable
              | Σ · τ                    stack extended with τ

WordType     ::= ∀ρ⃗. Σ₁ → Σ₂            prenex row-polymorphic

Usage      u ::= many | linear
```

**Rows.** Stack types are rows over a row variable, giving "rest of the stack" polymorphism. Quantification is prenex only: row variables are bound at word signatures, never inside types. **This is a deliberate restriction**: it keeps inference decidable (R3) and is the known-good region from prior art; higher-rank stack polymorphism is explicitly excluded from the kernel.

**Usage.** Every value type carries a usage. Base types from Σ declare their usage (numbers are `many`; resource types such as handles or the World token are `linear`). A quotation's usage is `many` if formed by `[p]` syntax (pure code), and is the meet of embedded values' usages when formed by `quote`/`compose`: embedding a linear value makes the quotation linear. `dup` requires `many`; `drop` requires `many`. Linear values must be consumed exactly once. There is no borrowing; the stack is the ownership model (G3).

### 4. Typing Rules

Judgement: `D ⊢ p : Σ₁ → Σ₂` (program p transforms stack type Σ₁ into Σ₂, under dictionary D).

```
(EMPTY)     D ⊢ ε : Σ → Σ

(SEQ)       D ⊢ a : Σ₁ → Σ₂    D ⊢ p : Σ₂ → Σ₃
            ─────────────────────────────────────
            D ⊢ a p : Σ₁ → Σ₃

(LIT)       c : ι ∈ Σ
            D ⊢ lit c : Σ → Σ · ι

(QUOT)      D ⊢ p : Σ₁ → Σ₂
            D ⊢ [p] : Σ → Σ · [Σ₁ → Σ₂]ᵐᵃⁿʸ

(DUP)       usage(τ) = many
            D ⊢ dup : Σ · τ → Σ · τ · τ

(DROP)      usage(τ) = many
            D ⊢ drop : Σ · τ → Σ

(SWAP)      D ⊢ swap : Σ · τ₁ · τ₂ → Σ · τ₂ · τ₁

(CALL)      D ⊢ call : Σ₁ · [Σ₁ → Σ₂]ᵘ → Σ₂

(DIP)       D ⊢ dip : Σ₁ · τ · [Σ₁ → Σ₂]ᵘ → Σ₂ · τ

(COMPOSE)   D ⊢ compose : Σ · [Σ₁→Σ₂]ᵘ¹ · [Σ₂→Σ₃]ᵘ² → Σ · [Σ₁→Σ₃]ᵘ¹⊓ᵘ²

(QUOTE)     D ⊢ quote : Σ · τ → Σ · [Σ' → Σ' · τ]ᵘˢᵃᵍᵉ⁽τ⁾    (Σ' fresh row)

(IF)        D ⊢ if : Σ · Bool · [Σ→Σ']ᵘ¹ · [Σ→Σ']ᵘ² → Σ'

(WORD)      D(w) = (∀ρ⃗. Σ₁ → Σ₂, _)
            D ⊢ w : (Σ₁ → Σ₂)[ρ⃗ := Σ⃗]      (instantiation)

(PRIM)      π : Σ₁ → Σ₂ ∈ Σ
            D ⊢ prim π : Σ₁ → Σ₂
```

**Dictionary well-formedness.** `D` is well-formed when, for every `w` with `D(w) = (T, p)`, the body checks against the declared signature *assuming all declared signatures*: `D ⊢ p : T`. Declared signatures license (mutual) recursion; no fixpoint combinator exists. Non-termination is expressible; the type system guarantees safety, not totality. Totality claims belong to the refinement layer.

**Linearity as consumption counting.** The rules above enforce linearity structurally: a linear value can only be moved (`swap`), buried and revived (`dip`), consumed by a primitive, or embedded into a (then-linear) quotation. Branches of `if` must agree on consumption because both have the same type. **[OPEN-1]** Whether usage is better formalised as a kinding judgement or as capability flags on types is a mechanisation-time decision; the two are equivalent on paper, and whichever proves cleaner in Lean wins.

### 5. Operational Semantics

Small-step over configurations `⟨V ∣ p⟩`. One administrative atom, `push v` (push an arbitrary value), exists only in the semantics, not the surface syntax.

```
(S-LIT)     ⟨V ∣ lit c ; p⟩        → ⟨V c ∣ p⟩
(S-PUSH)    ⟨V ∣ push v ; p⟩       → ⟨V v ∣ p⟩
(S-QUOT)    ⟨V ∣ [q] ; p⟩          → ⟨V ⟦q⟧ ∣ p⟩
(S-DUP)     ⟨V v ∣ dup ; p⟩        → ⟨V v v ∣ p⟩
(S-DROP)    ⟨V v ∣ drop ; p⟩       → ⟨V ∣ p⟩
(S-SWAP)    ⟨V v₁ v₂ ∣ swap ; p⟩   → ⟨V v₂ v₁ ∣ p⟩
(S-CALL)    ⟨V ⟦q⟧ ∣ call ; p⟩     → ⟨V ∣ q ; p⟩
(S-DIP)     ⟨V v ⟦q⟧ ∣ dip ; p⟩    → ⟨V ∣ q ; push v ; p⟩
(S-COMP)    ⟨V ⟦q₁⟧ ⟦q₂⟧ ∣ compose ; p⟩ → ⟨V ⟦q₁ ; q₂⟧ ∣ p⟩
(S-QUOTE)   ⟨V v ∣ quote ; p⟩      → ⟨V ⟦push v⟧ ∣ p⟩
(S-IF-T)    ⟨V true  ⟦q₁⟧ ⟦q₂⟧ ∣ if ; p⟩ → ⟨V ∣ q₁ ; p⟩
(S-IF-F)    ⟨V false ⟦q₁⟧ ⟦q₂⟧ ∣ if ; p⟩ → ⟨V ∣ q₂ ; p⟩
(S-WORD)    ⟨V ∣ w ; p⟩            → ⟨V ∣ body_D(w) ; p⟩
(S-PRIM)    ⟨V V_args ∣ prim π ; p⟩ → ⟨V V_results ∣ p⟩    (per δ_π from Σ)
```

Note the absence of a return stack: `call` and `word` unfold by program concatenation, which makes tail calls free and the semantics a pure rewrite system. Effectful primitives are modelled by threading a `linear` World token (see §7); the step relation itself stays deterministic.

**Terminal configurations:** `⟨V ∣ ε⟩` (done). Everything else must step (progress).

### 6. Metatheory Obligations

To be mechanised in Lean with zero admits (S1):

1. **Determinism.** Each configuration has at most one successor. (Immediate from rule syntax; each atom has exactly one applicable rule per value-shape.)
2. **Preservation.** If `D ⊢ p : Σ₁ → Σ₂`, `⊢ V : Σ₁`, and `⟨V ∣ p⟩ → ⟨V' ∣ p'⟩`, then `D ⊢ p' : Σ' → Σ₂` and `⊢ V' : Σ'` for some Σ'.
3. **Progress.** A well-typed non-terminal configuration steps.
4. **Linearity soundness.** In any trace of a well-typed program, each linear value introduced is consumed exactly once.
5. **Cost invariance.** (§8) Cost of a trace is well-defined and compositional over `SEQ`.

### 7. Effects **[OPEN-2, proposed decision]**

Effects are not kernel constructs. The proposed model: Σ declares a linear base type `World`, and every effectful primitive has type `Σ · World · args → Σ · World · results`. Linearity forces a single, ordered thread of effects through the program; pure programs simply never mention World. This keeps the kernel semantics a deterministic rewrite system, makes effect order provable, and costs nothing at runtime (the token compiles to nothing). Alternatives considered and rejected for the kernel: a monadic layer (heavier, duplicates what linearity already provides) and unrestricted effectful primitives (destroys determinism of the semantics and most of the metatheory).

### 8. Cost Semantics

Each step rule carries a cost from a constant table: `κ(a)` for kernel atoms, `κ(π)` per primitive from Σ, `κ(unfold)` for S-WORD. Cost of a trace is the sum of its steps. The table is a parameter of the semantics, not fixed by it: targets instantiate it (a microcontroller VM and a JIT would differ). Claims of the form "word w costs at most f(inputs)" are refinement-layer statements proved against this parameterised semantics (R10). The kernel guarantees only that cost is deterministic and compositional.

### 9. What the Kernel Deliberately Excludes

- **Refinements.** Refinement types, SMT obligations, and functional-correctness specs live in the elaboration layer and in Lean. Kernel types are simple types plus rows plus usage. This keeps the metatheory small and the kernel type checker trivially decidable.
- **Names and namespaces.** The dictionary maps opaque names to typed bodies; naming grammar, vocabularies, and visibility (PRD §4.1) are surface concerns that erase to dictionary entries.
- **Locals.** Named locals desugar to `dip`/`swap`/`dup` patterns (R2). The desugaring is specified with the surface language, not here.
- **Concurrency.** Out of scope for kernel v1. The World-token model leaves room for a partitioned-token extension later; nothing in v1 forecloses it.
- **Higher-rank rows, subtyping, overloading.** Excluded to protect decidability and inference (R3).

### 10. Open Questions Register

- **[OPEN-1]** Usage formalisation style (kinds vs capability flags): decide during mechanisation.
- **[OPEN-2]** Effects: World token proposed above; confirm during mechanisation of preservation.
- **[OPEN-3]** Quotation usage inference at `compose`/`quote` boundaries: the meet rule is proposed; verify no soundness gap when composing linear-capturing quotations under `dup`-free discipline.
- **[OPEN-4]** Whether `swap` generalises to an indexed family (e.g. `rot`) as kernel atoms or stays minimal with derived shuffles: proposal is minimal kernel, derived shuffles in `firth.core`, cost table may special-case them later.
- **[OPEN-5]** Bool as required base type vs Church-encoded quotational booleans: proposal is required base type, because `if` as a kernel atom simplifies the cost model and the typing of branches. Encodings remain possible but are not the kernel's problem.

### 11. Relationship to Requirements

R1 (minimality): §2. R2 (desugaring target): this calculus is the target. R3 (decidability): prenex rows, no subtyping, §3. R4 (linearity): §3–4. R5 (interpreter as oracle): §5 is the interpreter's spec. R10 (cost): §8. R11 (local reasoning): no environment, no non-local constructs, word meaning = body + callee signatures by construction. R15 (specs as words): enabled by keeping refinements out of the kernel and expressing predicates as dictionary words over it.
