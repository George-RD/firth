# Stack-Effect Type System

## Status and boundary

This document is the normative v0.1 surface type-system specification for Firth.
It supplements, and does not revise, the frozen kernel calculus in
`files/firth-kernel-spec-draft.md`. The kernel draft is authoritative for atom
semantics, erased stack effects, ownership transfer, and small-step execution.
This document defines the algorithm that checks surface word bodies before they
are lowered to that kernel.

The elaborator produces an erased type and a checked specification:

```text
elaborate(word) = (WordType, kernel Program, checked Spec)
erase(checked Spec) = no kernel instruction
```

Surface names, stack-entry anchors, refinements, and diagnostic spans are
elaborator metadata. The kernel dictionary stores only the erased word type and
kernel body. No inference rule in this document adds a kernel atom or a runtime
operation.

## 1. Type language

### 1.1 Kinds and usage

Firth has declared nominal value sorts and a distinct kind for stack-row
variables. Value sorts are not word-level type variables in v0.1. Usage is
not a coercion or a subtyping relation.

```text
Usage       u ::= many | linear
BaseType    β ::= ι^u
ValueType   τ ::= β | [Σ1 -> Σ2]^u
StackType   Σ ::= ρ | Σ · τ
WordType    T ::= forall ρ1 ... ρn; Σ1 -> Σ2
```

`many` values may be duplicated or discarded by structural rules. `linear`
values must not be duplicated, silently discarded, or consumed by two distinct
execution events. A linear value may be moved, consumed by a primitive, buried
by `dip`, or transferred into a quotation.

The only quantified variables in an erased `WordType` are row variables. The
symbols `A` and `B` used later for library-family notation are meta-level
placeholders for declared nominal sorts; each concrete dictionary word
instantiates them before checking. They are not additional scheme binders.

Usage forms a two-point meet used only when ownership is combined:

```text
many   meet many   = many
many   meet linear = linear
linear meet many   = linear
linear meet linear = linear
```

The empty meet is `many`. There is no implicit conversion from `linear` to
`many`. Literal constants are always `many`; a literal whose declared sort is
linear is rejected rather than treated as a replayable resource.

### 1.2 Surface stack effects

The canonical surface notation is the parenthesised stack effect defined by
`spec/surface/syntax.md`. It names entries for diagnostics and refinement
anchors while retaining the bottom-to-top order of the kernel stack. The right
side is the top of the stack.

```text
stack-effect ::= "(" [ "forall" row-name { row-name } ";" ]
                 stack-items "--" stack-items ")"
stack-items  ::= [ stack-item { stack-item } ]
stack-item   ::= row-name | ( word-name ":" type-expression )
type-expression ::= type-name [ usage ] [ refinement-set ]
usage        ::= "^many" | "^linear"
```

An empty `stack-items` side is a closed empty row. A row variable is a stack
item, not a value entry. The surface grammar owns quotation and predicate
productions. Source quotation literals are the only surface quotation form;
quotation-valued boundary entries are represented only in internal schemes as
`[Σ1 -> Σ2]^u` and remain monomorphic at the use site.

Every row variable occurring in a source effect must be bound by its `forall`
clause, and the surface parser enforces row-tail position and rejects
`firth.type.invalid-signature` for a misplaced row. The `forall` clause is
omitted only when no row variable occurs. Internally every word has an explicit
prenex scheme. Row variables are quantified only at word or primitive scheme
boundaries, never inside a quotation type. A local quotation is checked at one
monomorphic instantiation.
A word that needs two row instantiations writes two quotations or factors the
code into separate words.

Entry names do not participate in erased type equality. Within one contract,
input and output names must be globally unique. An output that represents a
consumed input uses a new name and may refer to the old name in a refinement as
`old.name`. Internal inference notation in later sections may omit the
parentheses and use `R` for the row represented by a sequence of stack items;
that shorthand is not additional source syntax.

### 1.3 Refinement attachment

A refined entry has the form `name:τ{P1, ..., Pn}`. Refinements are optional
metadata on a typed boundary, not value constructors. The list is a conjunction
and is normalised in source order. Each predicate reference is checked against
the registry and typed predicate boundary specified by
`spec/types/specification-predicates.md`.

The permitted scopes are:

```text
Pre       input anchors only
Post      output anchors only, plus old.input anchors
Totality  the complete word boundary
```
`Pre` and `Post` use the entry predicate syntax owned by the surface
specification. `Totality` is whole-word contract metadata in `Spec` and the
predicate registry; it is attached by the contract declaration or tooling
representation, not written as an entry predicate. No extra surface token is
introduced by this document.

A refinement does not change `WordType`. The elaborator must check anchor
visibility, argument sorts, purity, totality, registry identity, and the
predicate IR before attaching it. Unsupported or undecided predicates remain
obligations and are never guessed as true, false, or uninterpreted runtime
operations.

## 2. Algorithmic environments and judgments

The primitive environment `Γ` contains literal sorts, prenex primitive
signature schemes, and their ownership behaviour. Primitive schemes instantiate
fresh row variables at each use. The dictionary `D` contains only declared
erased word schemes and bodies. The contract environment `C` maps each word
name to its erased scheme and checked `Spec`. The algorithmic environment `Δ`
contains existential row, value-type, and usage metavariables. These
metavariables are solved locally by unification and are never generalised into
a `WordType`. A refinement environment `E` maps visible anchors to their
immutable typed boundary values.

The core algorithmic judgment is:

```text
Δ; Γ; D; C; E_in ⊢ p : Σ1 => Σ2 ! O ▷ E_out
```

It checks program `p` from input row `Σ1` to output row `Σ2`, transforms
refinement environment `E_in` to `E_out`, and returns an ordered list `O` of
proof and refinement obligations. A value judgment
`Δ; Γ; D; C; E_in ⊢v v : τ` checks a value and leaves the environment unchanged.
A word signature is inferred by creating a fresh input row and generalising only
row variables that do not occur in the environment or unresolved obligations.

The algorithm is syntax-directed. Sequencing checks the left atom, then checks
the remainder against the left output. Primitive and dictionary lookup are
performed only after name resolution. There is no search over alternative
overloads and no defaulting based on source order, import order, or solver
availability.

Every rule below threads `E_in` and `E_out` as well as its ordered obligation
list. An omitted `!O` means `![]`; an omitted environment transition means
`E_out = E_in`. Sequencing feeds the left rule's `E_out` into the right rule's
`E_in`, and concatenates obligations as `O1 ⊕ O2`, preserving source order. A
word call extends the continuation environment with its substituted postcondition.
A quotation checks its body against a snapshot of the environment and does not
leak that snapshot's extensions. No rule may discard an obligation.

### 2.1 Row unification

Row equations are first-order equations over a distinct row-variable kind.
Unification proceeds in this order:

1. Compare the top entries when both sides are extensions.
2. Unify their value sorts and usage premises.
3. Continue with the two tails.
4. Bind a row variable only after the occurs check succeeds.
5. Canonicalise the substitution by variable identity and report residual
   equations as obligations.

The occurs check rejects a binding such as `ρ = ρ · Int^many`. A row variable
cannot be bound to a value variable, quotation, or refinement. Value type
unification likewise compares base sorts and quotation effects structurally.
Quotation effects unify their input rows and output rows without introducing a
quantifier inside the quotation.

The algorithm terminates because each row equation either removes a matching
extension, binds a fresh variable to a smaller expression, or fails. The
resulting substitution is unique up to fresh-variable renaming. The printed
substitution uses first-introduction order for variables.

### 2.2 Word generalisation

At a dictionary word boundary, the algorithm generalises row variables that
are not free in `Γ`, `D`, or unresolved obligations. The resulting scheme is
prenex. Local quotations are never generalised. Instantiating a dictionary word
creates fresh variables for every quantified row variable, then checks the
instantiated body at that one use site.

Recursive and mutually recursive words are checked against their declared
schemes. The body must check against the declared erased effect before any
optional refinement obligations are considered. Non-termination is allowed by
the kernel and is not silently converted into a total refinement fact.

## 3. Typing and ownership rules

The following rules are the algorithmic form of the frozen kernel rules. `R` is
an arbitrary row and `τ` is a value type.

```text
EMPTY       R => R ! []

SEQ         a : R1 => R2 ! O1 ▷ E1     p : R2 => R3 ! O2 ▷ E2
            where a starts with E_in and p starts with E1
            ---------------------------------------------------
            a p : R1 => R3 ! (O1 ⊕ O2) ▷ E2

LIT         c : ι^many in Γ
            lit c : R => R · ι^many ! []

QUOT        Δ; Γ; D; C; E0 ⊢ p : S1 => S2 ! O ▷ E1
            literalUsage(p) = many
            [p] : R => R · [S1 -> S2]^many ! O ▷ E0

DUP         usage(τ) = many
            dup : R · τ => R · τ · τ ! []

DROP        usage(τ) = many
            drop : R · τ => R ! []

SWAP        swap : R · τ1 · τ2 => R · τ2 · τ1 ! []

CALL        call : R1 · [R1 -> R2]^u => R2 ! []

DIP         dip : R1 · τ · [R1 -> R2]^u => R2 · τ ! []

COMPOSE     compose : R · [R1 -> R2]^u1 · [R2 -> R3]^u2
                      => R · [R1 -> R3]^(u1 meet u2) ! []

QUOTE       quote : R · τ => R · [R' -> R' · τ]^(many meet usage(τ)) ! []
            where R' is fresh

IF          if : R · Bool^many · [R -> S]^many · [R -> S]^many => S ! []

WORD        D(w) = forall ρ⃗; R1 -> R2
            C(w) = (forall ρ⃗; R1 -> R2, Spec)
            θ = [ρ⃗ ↦ fresh rows]
            α = bind formal anchors to current input and fresh output anchors
            O_w = instantiate(Spec, θ, α, E); E' = extend(E, Spec.Postθα)
            w : R1θ => R2θ ! O_w, with continuation environment E'

PRIM        Γ(π) = forall ρ⃗; R1 -> R2
            θ = [ρ⃗ ↦ fresh rows]
            prim π : R1θ => R2θ ! []
```

`instantiate(Spec, θ, α, E)` substitutes row variables with `θ`, maps formal
input anchors through `α` to the caller's current boundary entries, allocates
fresh output anchors, resolves the callee precondition in `E`, and appends that
obligation to `O_w`. Its postcondition is substituted by `θα` and added to the
continuation environment `E'`. The `Spec` is never stored in `D` or emitted
into the kernel.

A surface quotation literal `[p]` is closed code and has usage `many` only
when the recursive `literalUsage(p)` check succeeds. That check visits nested
quotation bodies and rejects every linear literal. A quotation created by
`quote` transfers the top stack value into its ownership footprint. It is
`linear` when that value is linear. Neither rule copies a captured value.

`call` and `dip` consume one quotation value and splice its body once. They
accept either quotation usage. `compose` consumes both quotation values and
meets their ownership footprints. `if` requires equal branch effects and two
`many` quotations, so the unchosen branch can be discarded safely.

### 3.1 Restricted and repeated values

The following premises are mandatory and produce errors when they fail:

- `dup` and `drop` require a `many` value, including a quotation value.
- `lit` requires a `many` declared literal sort, recursively inside quotes.
- A quotation that captures a linear value is linear and cannot be duplicated or
  dropped.
- `compose` meets operand usage and cannot produce `many` from a linear input.
- `if` rejects a linear branch even if the other branch is `many`.
- A callback passed to a word that may invoke it more than once must be
  `many`.
- Ordinary `filter` requires a `many` element type because a false result
  discards the element. A linear collection API must return both partitions or
  make disposal explicit in its effect.

An ownership error is attached to the operation that would duplicate or lose
the value, not to a later stack mismatch. The diagnostic includes the first
capture or declaration span that established linear ownership.

### 3.2 Higher-order library contracts

The v0.1 library contracts use one prenex row for the collection and callback.
`A` and `B` are declared nominal sorts selected when a concrete library word
is defined, not value-type quantifiers. `Γ` declares each instantiated
`List(A)` as a nominal base sort. All collection element sorts in these
contracts have `many` usage; recursive ownership inside a collection is
outside v0.1. The quotation brackets use the internal value-type notation.
In these displays, bare `A`, `B`, `Bool`, and `List(A)` or `List(B)` abbreviate
their `^many` base-sort forms; the collection value itself is also `many`.


```text
map    : forall ρ;
         ρ List(A) [ρ A -> ρ B]^many -- ρ List(B)

filter : forall ρ;
         ρ List(A) [ρ A -> ρ Bool]^many -- ρ List(A)

fold   : forall ρ;
         ρ B List(A) [ρ B A -> ρ B]^many -- ρ B
```

The callback is `many` because the body may invoke it repeatedly. A linear
callback is rejected rather than copied. A local callback quotation is not
re-generalised for each invocation. These restrictions preserve decidable
inference and avoid higher-rank quotation polymorphism.

## 4. Refinement checking and compatibility

Refinement checking runs after the erased stack effect has been inferred and
before the word is accepted. It does not rerun type inference with predicates
as type constructors.

The logical body, replacement, and totality obligations are defined solely by
`spec/types/specification-predicates.md` Section 3. This document supplies the
typed boundary and ordering in which those obligations are generated; it does
not restate their formulas.

At a call site, the callee's precondition is an obligation in the caller's
refinement environment, and its postcondition becomes visible on returned
anchors. The caller is accepted only when every required obligation has
successful proof evidence. Deferred, escalated, timed-out, unknown, or
incomplete evidence is a non-acceptance state until the approved Lean or SMT
route returns successful evidence. A failed or missing proof cannot make a word
accepted.

Refined word replacement uses the universal boundary relation defined in
`spec/types/specification-predicates.md` Section 3. A caller-site proof does not
substitute for the replacement check. The old and new erased `WordType`s must
be exactly equal modulo alpha-renaming of their prenex row binders, including
stack shape and usage annotations, before that relation is attempted.

Refinement attachment and erasure never change the kernel atom stream for the
same body. Replacement bodies may differ only when the universal boundary
relation and all frozen patch obligations accept them. Effectful replacement
compatibility is outside this v0.1 type-system contract and remains deferred to
the registered patch-compatibility gap. Predicate resolution, canonical IR,
hashes, totality, and diagnostic ordering are owned by
`spec/types/specification-predicates.md`.

If either erased `WordType` mentions the linear `World` base, the replacement is
rejected in v0.1; the deferred patch-compatibility gap must be resolved before
effectful observational replacement is admitted.


## 5. Deterministic diagnostics

Type diagnostics use the versioned agent envelope and the source span of the
operation that first makes the obligation impossible. The core operation names
below preserve the existing elaborator and test contract. Surface parsing,
name-resolution, and signature-provenance diagnostics are delegated to their
own contracts.

| Code | Condition |
| --- | --- |
| `firth.type.stack-mismatch` | stack entries or base types cannot unify |
| `firth.type.occurs-check` | a row or value variable would contain itself |
| `firth.linearity.usage-mismatch` | an operation needs `many` but receives `linear` |
| `firth.linearity.literal-not-many` | a literal declares a linear sort |
| `firth.linearity.invalid-quotation-usage` | stored quotation ownership is inconsistent |
| `firth.type.expected-quotation` | `call`, `dip`, or a higher-order operation receives a non-quotation |
| `firth.type.quotation-input-mismatch` | a quotation input row does not match the current row |
| `firth.type.quotation-compose-mismatch` | quotation effects do not compose |
| `firth.type.branch-mismatch` | `if` branch effects differ |
| `firth.type.stack-underflow` | an atom lacks a required stack entry |
| `firth.type.unknown-literal` | a literal has no declaration in `Γ` |
| `firth.type.declared-effect-mismatch` | a body does not satisfy its declared effect |
| `firth.type.unresolved-obligation` | inference leaves an unsupported equation |

Other existing stack-checker paths retain their established codes, including
`firth.type.expected-bool`, `firth.type.word-input-mismatch`,
`firth.type.primitive-input-mismatch`, and `firth.type.invalid-signature`.
Name and provenance failures remain owned by the surface and agent contracts.

Repeated callbacks and ordinary linear filtering use
`firth.linearity.usage-mismatch`. Local quotation polymorphism uses
`firth.type.stack-mismatch`. Refinement diagnostics are the codes in the
predicate specification. When several diagnostics exist, order them using the
agent envelope's location key: URI when present, otherwise path; primary range
start, primary range end, stable code, then `payload_id`, then obligation
identifier. Within one operation, report the ownership error before the
consequent row mismatch. Diagnostics contain canonical substituted types and
never depend on hash-map iteration, source import order, or solver availability.


## 6. Conformance examples

The examples use `Int^many`, `Bool^many`, a linear `Handle^linear`, and rows
`r`, `s`, and `t`. Inference displays use internal row shorthand; word
boundaries use the parenthesised surface grammar from `spec/surface/syntax.md`.

### 6.1 Accepted inference and composition

```text
1 2 prim plus
```

with `prim plus : r Int^many Int^many -> r Int^many` infers the declared effect
of the primitive composition. The untouched row is preserved.

```text
compose : r [s -> t]^many [t -> u]^many
          -> r [s -> u]^many
```

The middle rows unify. If the second quotation instead starts at `v`, the
algorithm reports `firth.type.quotation-compose-mismatch` and the residual row
equation.

```text
[dup] call
```

is accepted only when the quotation's input type satisfies the `dup` premise.
A quotation literal with only many literals is `many`. A closed quotation that
contains `lit h` where `h` is linear is rejected by `literalUsage`.

### 6.2 Accepted ownership transfer

```text
r Handle^linear --quote--> r [s -> s Handle^linear]^linear
```

The handle is moved into the quotation. Calling that quotation later moves it
back to the execution stack. No copy occurs and `dup` or `drop` on the
quotation is rejected.

```text
r [s -> t]^linear [t -> u]^many --compose--> r [s -> u]^linear
```

The result remains linear because ownership from the first quotation is
transferred to it.

### 6.3 Rejected linearity and control cases

```text
Handle^linear dup
Handle^linear drop
lit h                 where h : Handle^linear
```

fail with `firth.linearity.usage-mismatch` for each structural operation and
`firth.linearity.literal-not-many` for the literal. The failed operation cannot
be repaired by inserting an implicit copy or disposer.

```text
r Bool^many [r -> s]^linear [r -> s]^many if
```

fails with `firth.linearity.usage-mismatch`, even though the effects match. Two
branches with different effects fail with `firth.type.branch-mismatch`.

A callback with a linear quotation type passed to `map`, `filter`, or `fold`
fails with `firth.linearity.usage-mismatch`. A linear element type passed to
ordinary `filter` fails with the same code because rejection would discard it.

### 6.4 Refinement cases

```text
(forall ρ; ρ x:Int^many{positive x} -- ρ y:Int^many{positive y})
```

is accepted when `positive` resolves to a registered pure, total predicate
with the declared `Int` boundary and the body obligation is discharged. The
predicate is attached to `Spec`, not emitted into the kernel body.

```text
(forall ρ; ρ h:Handle^linear{is-open h} -- ρ h2:Handle^linear)
```

is rejected with `firth.refinement.linear-argument` because a predicate may
not consume or produce a linear value. A missing predicate is rejected with
`firth.refinement.unknown-predicate`; an unproved translation remains
`firth.refinement.not-decided`.

## 7. Lean mechanisation obligations

The v0.1 mechanisation must establish at least the following without `sorry` or
`admit`:

1. `Usage` and `meet` have commutativity, associativity, idempotence, and the
   characterisation `meet u v = many` exactly when both operands are `many`.
2. Row and value unification terminate, respect the occurs check, and produce
   substitutions sound and complete for the first-order equations.
3. Algorithmic typing is sound with respect to the frozen declarative typing
   rules. If inference succeeds, the erased program has the inferred effect.
4. Prenex generalisation and instantiation preserve typing, while local
   quotations are never silently re-generalised.
5. `quote` and `compose` preserve the ownership footprint and never duplicate a
   captured value. `call` and `dip` consume and splice one quotation exactly
   once per transition.
6. The strengthened `if` rule permits discarding the unchosen branch because a
   `many` quotation contains no owned linear value.
7. Over every finite execution trace, no linear value is duplicated, silently
   discarded, or consumed by two distinct events. Exact-once consumption is
   proved only with termination and an empty linear residue premise.
8. Refinement attachment and erasure preserve the inferred erased effect and
   kernel atom stream. Predicate obligations are stable under canonical
   serialisation and deterministic normalisation.
9. Every conformance example above has a positive derivation or the named
   negative diagnostic. Local quotation polymorphism is rejected by the
   monomorphic quotation rule.

These obligations are proof targets for the Lean implementation. They do not
add runtime semantics or permit the type-system specification to amend the
frozen kernel.

## 8. Conformance checklist

An implementation conforms when it satisfies the surface grammar in
`spec/surface/syntax.md`, the algorithm and proof obligations in Sections 2,
3, and 7, and the frozen-kernel ownership rules. It must also satisfy the
refinement boundary and erasure contract in
`spec/types/specification-predicates.md`, and produce the stable diagnostics
and examples in Sections 5 and 6. This checklist is a cross-reference, not a
second set of typing rules.
