# Firth Kernel Calculus
## Specification, v0.1 Frozen

Status: frozen and normative for the Firth v0.1 kernel. The Lean
mechanisation targets zero admitted proofs. A mechanisation erratum requires a
governed decision and does not silently change this specification.

### 1. Overview

The kernel is a typed concatenative calculus. A program is a sequence of atoms;
sequencing is function composition; and machine state is a single value stack.
There are no variables, binders, or an environment. Quotations provide all
higher-order structure. Recursion comes from the dictionary, not from a
combinator.

The kernel is parameterised by a primitive signature `Gamma`, written `Γ`,
which declares base types and primitive operations. Primitive operations are
opaque typed constants to the kernel; the metatheory quantifies over every
well-formed `Γ`.

### 2. Syntax

```
Atom      a ::= lit c            push a literal constant
             | [ p ]             push a quotation of program p
             | dup | drop | swap
             | dip | call | compose | quote
             | if
             | w                 dictionary word reference
             | prim π             primitive from Γ

Program   p ::= ε | a p          sequences; ε is the empty program

Value     v ::= c                literal constant
             | ⟦p⟧               quotation value

Stack     V ::= · | V v          bottom to top

Dictionary D : Name ⇀ (WordType, Program)
```

The kernel atoms are minimal for v0.1: `dup` and `drop` are structural rules,
`swap` is exchange, `dip` and `call` eliminate quotations, `compose` and
`quote` construct quotations beyond literal formation, `if` selects a branch,
words provide recursion, and `prim π` supplies the operations declared by
`Γ`.

### 3. Types

```
BaseType       β ::= ι^u                         base type and usage
ValueType      τ ::= β
                    | [ Σ₁ → Σ₂ ]^u              quotation type and usage

StackType      Σ ::= ρ                           row variable
                    | Σ · τ                      stack extended with τ

WordType           ::= ∀ρ⃗. Σ₁ → Σ₂               prenex erased stack effect
Usage          u ::= many | linear
```

`Γ` is the primitive signature and `Σ` is a stack type. They are distinct
judgement components. `Γ` must contain `Bool^many`; resource types such as
handles and `World` are declared `linear`, while ordinary numeric types are
declared `many`.

Rows are rest-of-stack rows. Quantification is prenex only: row variables are
bound at word signatures, never inside types. Higher-rank stack polymorphism,
subtyping, and overloading are outside v0.1 to keep inference decidable.

The usage of `β = ι^u` is `u`. Literal constants are always `many`, even when
`Γ` contains a linear resource type. Define `literalUsage(p) = many`, after
checking recursively that every `lit c` in `p`, including nested quotation
bodies, has a many base type. A quotation's full usage is
`quotationUsage(p,C) = literalUsage(p) ⊓ meet(usage(v) for v in C)`, where `C`
is the list of already-linear or many stack values captured by the quotation.
The empty meet is `many`. Thus a closed `[p]` quotation is `many`, while a
quotation capturing a linear stack value is `linear`. The meet is
`many ⊓ many = many` and every meet involving `linear` is `linear`.

This is a kernel invariant: no linear value is introduced by a replayable
literal. Linear values arise from word inputs already on the stack, from any
primitive signature that yields a linear result, and from capture of an
already-linear stack value by `quote`. World threading is one example of an
effectful primitive that can yield a linear value, not the sole source.

`dup` and `drop` require `many`; there is no implicit `linear` to `many`
coercion. A linear value may be moved, consumed by a primitive, buried by
`dip`, or transferred into a linear quotation, but it may not be duplicated or
silently discarded.

### 4. Typing Rules

The program judgement is `Γ;D ⊢ p : Σ₁ → Σ₂`. Value and stack judgements are
`Γ;D ⊢ᵥ v : τ` and `Γ;D ⊢ᵥ V : Σ`.

```
(EMPTY)     Γ;D ⊢ ε : Σ → Σ

(SEQ)       Γ;D ⊢ a : Σ₁ → Σ₂    Γ;D ⊢ p : Σ₂ → Σ₃
            ─────────────────────────────────────
            Γ;D ⊢ a p : Σ₁ → Σ₃

(LIT)       c : ι^many ∈ Γ
            Γ;D ⊢ lit c : Σ → Σ · ι^many

(PUSH)      Γ;D ⊢ᵥ v : τ
            Γ;D ⊢ push v : Σ → Σ · τ

(QUOT)      Γ;D ⊢ p : Σ₁ → Σ₂
            Γ;D ⊢ [p] : Σ → Σ · [Σ₁ → Σ₂]^many

(DUP)       usage(τ) = many
            Γ;D ⊢ dup : Σ · τ → Σ · τ · τ

(DROP)      usage(τ) = many
            Γ;D ⊢ drop : Σ · τ → Σ

(SWAP)      Γ;D ⊢ swap : Σ · τ₁ · τ₂ → Σ · τ₂ · τ₁

(CALL)      Γ;D ⊢ call : Σ₁ · [Σ₁ → Σ₂]^u → Σ₂

(DIP)       Γ;D ⊢ dip : Σ₁ · τ · [Σ₁ → Σ₂]^u → Σ₂ · τ

(COMPOSE)   Γ;D ⊢ compose :
              Σ · [Σ₁ → Σ₂]^{u₁} · [Σ₂ → Σ₃]^{u₂}
              → Σ · [Σ₁ → Σ₃]^{u₁ ⊓ u₂}

(QUOTE)     Γ;D ⊢ quote : Σ · τ → Σ · [Σ' → Σ' · τ]^{many ⊓ usage(τ)}
            where Σ' is a fresh row

(IF)        Γ;D ⊢ if :
              Σ · Bool^many · [Σ → Σ']^many · [Σ → Σ']^many → Σ'

(WORD)      D(w) = (∀ρ⃗. Σ₁ → Σ₂, _)
            Γ;D ⊢ w : (Σ₁ → Σ₂)[ρ⃗ := Σ⃗]

(PRIM)      π : Σ₁ → Σ₂ ∈ Γ
            Γ;D ⊢ prim π : Σ₁ → Σ₂
```

The `if` branches must both be `many` and have identical stack effects. The
unchosen branch is then safe to discard. `call` and `dip` consume their
quotation value once in the transition and accept either quotation usage.
`compose` consumes both quotation values and transfers their ownership to the
result. `quote` transfers the top value without copying it.

Value typing assigns `Γ;D ⊢ᵥ c : ι^many` when `c : ι^many ∈ Γ` and assigns a
quotation value its stored program effect and usage. Stack typing is the
pointwise typing of its values against `Σ`, preserving order and usage.

Dictionary well-formedness requires every `D(w) = (T,p)` to satisfy
`Γ;D ⊢ p : T` while assuming all declared erased signatures, which permits
mutual recursion. The dictionary contains no refinement specifications.
Non-termination is expressible; the kernel guarantees safety, not totality.

Primitive-signature well-formedness requires each declared `π` to have one
typed input and output stack shape, a deterministic total delta operation on
that shape, and ownership behaviour consistent with its usage annotations.
`δ_π` may return linear resources whenever its typed signature declares a
linear result, whether or not it threads `World`; it may neither duplicate nor
silently discard a linear value. These
conditions, together with dictionary well-formedness and the syntax-directed
rules, are the assumptions used by determinism and progress.

### 5. Operational Semantics

Small-step execution is over configurations `⟨V ∣ p⟩`. The administrative atom
`push v` exists only in the semantics, not surface syntax.

```
(S-LIT)     ⟨V ∣ lit c ; p⟩          → ⟨V c ∣ p⟩    (c : ι^many)
(S-PUSH)    ⟨V ∣ push v ; p⟩         → ⟨V v ∣ p⟩
(S-QUOT)    ⟨V ∣ [q] ; p⟩            → ⟨V ⟦q⟧ ∣ p⟩
(S-DUP)     ⟨V v ∣ dup ; p⟩         → ⟨V v v ∣ p⟩
(S-DROP)    ⟨V v ∣ drop ; p⟩        → ⟨V ∣ p⟩
(S-SWAP)    ⟨V v₁ v₂ ∣ swap ; p⟩    → ⟨V v₂ v₁ ∣ p⟩
(S-CALL)    ⟨V ⟦q⟧ ∣ call ; p⟩      → ⟨V ∣ q ; p⟩
(S-DIP)     ⟨V v ⟦q⟧ ∣ dip ; p⟩     → ⟨V ∣ q ; push v ; p⟩
(S-COMP)    ⟨V ⟦q₁⟧ ⟦q₂⟧ ∣ compose ; p⟩ → ⟨V ⟦q₁ ; q₂⟧ ∣ p⟩
(S-QUOTE)   ⟨V v ∣ quote ; p⟩       → ⟨V ⟦push v⟧ ∣ p⟩
(S-IF-T)    ⟨V true ⟦q₁⟧ ⟦q₂⟧ ∣ if ; p⟩ → ⟨V ∣ q₁ ; p⟩
(S-IF-F)    ⟨V false ⟦q₁⟧ ⟦q₂⟧ ∣ if ; p⟩ → ⟨V ∣ q₂ ; p⟩
(S-WORD)    ⟨V ∣ w ; p⟩             → ⟨V ∣ body_D(w) ; p⟩
(S-PRIM)    ⟨V V_args ∣ prim π ; p⟩ → ⟨V V_results ∣ p⟩ per δ_π from Γ
```

`call` and `w` unfold by program concatenation. There is no return stack, so
the semantics is a pure rewrite system. Effectful primitives thread the
linear `World` value. `S-LIT` can therefore only push a many literal; it never
introduces a linear resource. Terminal configurations are `⟨V ∣ ε⟩`; every other
well-typed configuration can take a step.

### 6. Metatheory Obligations

Lean mechanisation targets zero admitted proofs (S1):

1. **Determinism.** Every configuration has at most one successor.
2. **Preservation.** A step from a well-typed configuration produces a
   well-typed configuration with an appropriately residual stack type. In
   particular, `S-QUOTE` preserves the captured value's usage in the resulting
   quotation ownership footprint, and `S-LIT` preserves the many-only literal
   invariant.
3. **Progress.** Every well-typed non-terminal configuration steps.
4. **At-most-once linearity safety.** Over every finite execution trace, no
   linear value is duplicated, silently discarded, or consumed by two distinct
   events. Divergence may leave a linear value live indefinitely.
5. **Conditional exact-once.** Exact-once consumption is proved only for an
   execution with an explicit termination premise and a terminal configuration
   with empty linear residue. A terminating trace that leaves a linear value on
   the terminal stack is a linearity failure, even though divergence may leave
   a value live indefinitely.
6. **Cost invariance.** Cost is well-defined and compositional over `SEQ`
   under the parameterised table in §8.

### 7. Effects

Effects are represented by the linear base type `World` in `Γ`. An effectful
primitive has a signature `Σ · World^linear · args → Σ · World^linear · results`.
The single ordered World thread is normative for v0.1. Pure programs do not
mention `World`; the token compiles to nothing. The kernel does not define
observational refinement for effectful word replacement. That question remains
the registered proposed gap
`dec.gap-firth-runtime-patch-should-effectful-verified-patch-compatibility-use-an`.

### 8. Cost Semantics

Each step carries a cost from the uninstantiated total table `κ`: `κ(a)` for
kernel atoms, `κ(π)` for primitives, and `κ(unfold)` for `S-WORD`. A trace cost
is the sum of its step costs. Targets instantiate `κ`; concrete target values
belong to the VM target specification. The kernel guarantees determinism and
compositionality of cost, not a target-specific bound.

### 9. Dictionary and Patch Layering

The kernel dictionary `D` stores only erased entries `(WordType, Program)`.
`WordType` is the prenex stack effect, including usage annotations, and never
contains refinements. The elaborator owns the public contract
`C(w) = (WordType, Spec)`.

A v0.1 replacement has two independent obligations:

1. **Kernel dictionary preservation.** The replacement has exactly the old
   erased `WordType`, its body checks against that type under the dictionary,
   and dictionary well-formedness is reconstructed.
2. **Elaborator refinement subsumption.** The replacement specification
   subsumes the old contract by weakening accepted inputs and strengthening
   guaranteed outputs. These obligations are discharged by Lean or the
   elaborator's approved SMT fragment.

Effectful-word observational refinement is outside the v0.1 freeze. Equal
`World` positions prove only ordered at-most-once token use, not equality of
external actions. Such patches require the proposed gap to be resolved before
they can be admitted.

### 10. What the Kernel Deliberately Excludes

- Refinement types, SMT obligations, and functional-correctness specifications
  live in the elaborator and Lean.
- Namespaces, naming grammar, vocabularies, and visibility are surface
  concerns that erase to dictionary entries.
- Named locals desugar to `dip`/`swap`/`dup` patterns.
- Concurrency is outside v0.1. A future partitioned World-token extension may
  be proposed without changing this freeze.
- Higher-rank rows, subtyping, overloading, and implicit usage coercions are
  excluded to protect decidability and inference.

### 11. Open Questions Register

The following are mechanisation questions that do not alter the frozen v0.1
rules: usage formalisation as kinds or capability flags; proof details for the
World token; whether `swap` later gains indexed shuffles; and whether Bool is
also offered through a Church encoding. OPEN-3 is resolved by the accepted
decision `dec.gap-firth-language-kernel-open-3-validate-quotation-usage-meet-inference`.

### 12. Relationship to Requirements

R1 and R2 are covered by the minimal atom set and kernel target. R3 is covered
by prenex rows, no subtyping, and syntax-directed rules. R4 is covered by
usage-aware values and the at-most-once obligations. R5 is defined by §5. R7
is covered by §9. R10 is covered by §8. R11 follows from the absence of an
environment and from word meaning being determined by body and erased callee
signatures. R15 is enabled by keeping specifications in the elaborator.

### 13. Freeze Checklist

The Lean v0.1 definitions must agree with this document on the atom set,
`Γ` versus `Σ` notation, value and stack typing, recursive quotation usage,
the `if` many and equal-effect premises, administrative `push`, deterministic
`δ_π` and dictionary well-formedness, finite-trace at-most-once safety,
conditional exact-once termination, World threading, erased patch obligations,
and the parameterised total cost table. Any mismatch is a governed erratum,
not an implicit specification change.
