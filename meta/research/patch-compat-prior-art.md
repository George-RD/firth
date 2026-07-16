---
id: res.patch-compat-prior-art
nodes: [firth.runtime.patch]
sources: [src.firth-prd, src.firth-kernel-spec-draft, src.liskov-wing.behavioural-subtyping, src.liquid-types, src.hicks-nettles.dynamic-software-updating, src.wadler.linear-types]
date: 2026-07-16
---

# Compatible word replacement under refinement types

## Scope and type-system boundary

This result defines compatible replacement for pure words and for
refinement-typed words whose specifications concern ordinary inputs, outputs,
termination and cost. It does not define observational refinement for an
already effectful word. The kernel can preserve the linear `World` position,
but Firth has not yet chosen whether effect observations are modelled by an
abstract state relation, an event trace, or both. That dependency is registered
as `dec.gap-firth-runtime-patch-should-effectful-verified-patch-compatibility-use-an`.

The kernel and elaborator layers must not be conflated:

- The kernel dictionary has type `D : Name -> (WordType, Program)`, where
  `WordType = forall rho*. StackIn -> StackOut`. It contains prenex erased
  stack effects, including usage annotations, but no refinements.
- The elaborator owns the public refinement contract. Write it as
  `C(w) = (W, S)`, where `W : WordType` is the erased stack effect and
  `S : Spec` contains preconditions, postconditions and any stated totality or
  cost properties.

For a pure or refinement-typed word, a compatible v1 patch keeps the public
pair `C_old(w) = (W_old, S_old)` stable and replaces only the kernel body.
A candidate body elaborates to kernel program `q_new`, erased word type
`W_new`, and implementation specification `S_new`:

```text
D_old(w) = (W_old, q_old)        C_old(w) = (W_old, S_old)
Elab(C_old, p_new) = (q_new, W_new, S_new)
W_new = W_old                    S_new <=spec S_old
-----------------------------------------------------
D_new = D_old[w := (W_old, q_new)]
C_new = C_old
```

This deliberately creates two separate obligations:

1. **Kernel dictionary preservation.** Prove exact erased `WordType` equality
   `W_new = W_old`, prove `D_old |- q_new : W_old`, and reconstruct dictionary
   well-formedness for `D_new`. All other dictionary signatures and bodies are
   unchanged.
2. **Elaborator refinement subsumption.** Prove
   `S_new <=spec S_old`, meaning that every call allowed by `S_old` is accepted
   by `S_new` and every outcome of `S_new` on those calls satisfies `S_old`.

Self-recursion and mutual recursion are checked against stable entries in
`C_old`, including `w : (W_old, S_old)`. The stronger implementation spec is
evidence for admitting `q_new`, not a silent change to the contract visible to
callers. Publishing it as a new public contract requires a separately governed
interface version and rechecking affected code.

Changing stack layout, base representation, row quantification or usage
annotations is not a compatible v1 replacement. Such a change needs a new word
name or version plus an explicit adapter and, if live state changes, a state
transition proof. This separates local word replacement from the more general
dynamic software update problem described by Hicks and Nettles.

## Prior-art approaches

### Exact pair equality

The simplest rule requires syntactic equality of both `W` and `S`. It is cheap,
decidable and safe, but rejects useful changes. A replacement that accepts more
inputs or proves a more precise result is harmless to old callers, yet exact
`Spec` equality rejects it. Predicate equivalence is also rarely syntactic.

### Structural function subtyping

Ordinary function subtyping makes inputs contravariant and outputs covariant.
It is the right logical skeleton for `Spec`, but it is not a kernel `WordType`
rule in Firth v1. The kernel explicitly excludes subtyping, so erased stack
effects remain invariant. Structural subtyping alone also does not preserve
semantic promises, termination claims, cost bounds or effects.

### Behavioural refinement subtyping

Liskov and Wing's method rule requires the old precondition to imply the new
one and the new postcondition to imply the old one, preserving the behaviour
available to a caller. Their stronger treatment of arbitrary history
properties is more restrictive and requires equal corresponding
preconditions. Firth borrows the call-level precondition and postcondition
direction for `Spec` subsumption, not a claim that this alone preserves every
Liskov-Wing history property.

Liquid Types supplies a practical automation route: reduce refinement
subtyping to logical implications and discharge a conservative decidable
fragment automatically. This combination best matches Firth's elaborator. It
is local, permits useful strengthening, and produces explicit Lean or SMT
obligations while leaving the kernel type system unchanged.

### Contextual or whole-image refinement

The most permissive rule accepts an update when no complete program context can
distinguish it in a forbidden way. It can justify representation changes,
adapters and coordinated multi-word updates, but direct contextual equivalence
is not a practical incremental check. Whole-image rechecking has a similar
cost and conflicts with R9. Firth should reserve these approaches for a future
governed image-transition protocol.

## Recommended variance rules

Represent an elaborator contract schematically as:

```text
W = forall rho. rho . A -> rho . B
S = requires Pre(x); ensures Post(x, y)
C = (W, S)
```

Here `A` and `B` are ordered stack suffixes, while `x` and `y` name their
logical values. For a pure or refinement-typed replacement require:

1. **Invariant erased stack effect.** `W_new = W_old`. Row binders, suffix
   lengths, value order, base representations, quotation shapes and usage
   annotations must match. V1 performs no implicit stack, representation or
   usage coercions. This is kernel equality, not refinement variance.
2. **Contravariant input refinements.** Every old-valid input is new-valid:
   `Pre_old(x) => Pre_new(x)`. The new precondition is equal or weaker.
3. **Covariant output refinements.** Under an old-valid input, every new
   outcome satisfies the old guarantee:
   `Pre_old(x) and Post_new(x, y) => Post_old(x, y)`. The new postcondition is
   equal or stronger.
4. **No wider stated observations.** If `S_old` promises termination or a cost
   bound, `S_new` must retain or strengthen that promise. If `S_old`
   intentionally leaves a property unspecified, compatibility need not invent
   a guarantee.
5. **Invariant linear capabilities.** Usage annotations are part of `W`, so
   the replacement consumes and produces the same linear positions. Existing
   callers retain exactly the duplication and disposal capabilities for which
   they were checked.

If Firth later adds elaborator-level value subtyping, logical input types may
vary contravariantly and output types covariantly only when both erase to the
same kernel `W`. The v1 kernel dictionary still sees equality.

Refinement direction is easy to reverse by mistake: weaken requirements on
input, strengthen guarantees on output.

## Examples and counterexamples

Assume mathematical integers, so overflow is not an unstated observation. All
refinement examples share the erased kernel word type
`W = forall rho. rho . Int -> rho . Int`.

### Compatible input weakening and output strengthening

```text
S_old: requires x > 0;  ensures y >= x
S_new: requires x >= 0; ensures y = x + 1
```

The old precondition implies the new one, and `y = x + 1` with `x > 0`
implies `y >= x`. `W` is unchanged, so both the kernel equality and
elaborator subsumption obligations hold.

### Incompatible input strengthening

```text
S_old: requires x != 0; ensures true
S_new: requires x > 0;  ensures true
```

The old-valid input `x = -1` is a counterexample. It satisfies `x != 0` but
not `x > 0`, so an already-checked caller can reach a state rejected by the
replacement.

### Incompatible output weakening

```text
S_old: requires x >= 0; ensures y > x
S_new: requires x >= 0; ensures y >= x
```

For `x = 0`, the new postcondition permits `y = 0`, which violates the old
promise `y > x`. The replacement is incompatible even though `W` is equal.

### Incompatible erased `WordType`

Replacing kernel type `forall rho. rho . Int -> rho . Int` with
`forall rho. rho . Int . Int -> rho . Int` underflows every old caller that
supplies one integer. Replacing an output marked `many` with a linear output is
also incompatible because old callers may legally `dup` or `drop` it. These
fail kernel equality before any refinement query is generated.

### Compatible cost strengthening

If `S_old` guarantees `cost <= 20 + 2 * x` and `S_new` proves
`cost <= 15 + x` for all old-valid `x >= 0`, the new bound implies the old
bound. A new bound `cost <= 30 + 2 * x` is incompatible: at `x = 0`, it
permits a cost of 30 where the caller was promised at most 20.

## The linear `World` boundary

Wadler's linear-world account supports Firth's proposed structural
representation of effects. An effectful kernel `WordType` has one linear
`World` input and one linear `World` output, and neither may be duplicated or
discarded.

An old pure word has no `World` position. A new body that performs an effect
cannot check at the equal erased `W_old` because it has no `World` token to
consume. Adding an untracked effect to a pure word is therefore rejected by the
kernel obligation.

For an already effectful word, equal `World` positions prove only ordered,
single-threaded, at-most-once use over finite traces. They do not prove that the
same external actions occur.
Until the registered gap selects an observable state or trace contract, this
research does not define `S_new <=spec S_old` for effectful words. The verified
patch protocol must reject such patches as unsupported, or route them through
a separately ratified mechanism. It must not infer compatibility from `World`
linearity alone.

The patch operation itself must not consume the program's `World` token behind
the program's back. VM installation is a control-plane transition whose
atomicity and image-state effects belong to the patch protocol. If patching is
modelled inside Firth later, it must be an explicit effectful primitive with its
own contract.

## Lean and SMT obligations

The verified-patch manifest should bind the word name, old `WordType` hash, old
`Spec` hash, old image version, new kernel body hash, compiled body hash, and
proof artefacts.

### Kernel-level obligations

1. **Manifest freshness.** The live slot still has the expected old `W_old`
   and image version.
2. **Elaboration erasure.** Lean checks that elaborating the replacement
   produces kernel body `q_new` with erased type `W_new`.
3. **Exact `WordType` equality.** A decidable kernel checker proves
   `W_new = W_old`, including rows, value order, quotation shape and usage.
4. **Body typing.** Lean checks `D_old |- q_new : W_old` using stable
   dictionary signatures, including `w : W_old` for recursive calls.
5. **Dictionary preservation.** Lean constructs a proof that replacing only
   `body_D(w)` leaves `D_new` well-formed. This avoids rechecking callers and
   mutually recursive neighbours.
6. **Compiler correspondence.** The accepted kernel body is bound to target
   code whose execution refines the reference interpreter. Until the compiler
   proof exists, this remains an explicitly empirical differential-test gate.
7. **Atomic installation and rollback.** Verify the payload before making it
   reachable, change the dictionary slot atomically, and retain the old slot
   until rollback is safe. A failed check changes no live image state.
8. **Version-cut semantics.** Under S-WORD, a body already unfolded into the
   current program continues as old code, while later lookups use the new body.
   The VM must implement the same cut or establish a safe quiescence point.

### Elaborator-level obligations

1. **Implementation spec.** Lean checks the replacement against `S_new` while
   recursive references use the stable public pair `(W_old, S_old)`.
2. **Input implication.** Prove `Pre_old => Pre_new`.
3. **Output implication.** Prove
   `Pre_old and Post_new => Post_old`, relating dependent outputs to the same
   logical inputs.
4. **Stated totality and cost.** Prove every termination or cost guarantee in
   `S_old` from `S_new`.
5. **Pure scope.** Confirm that `W_old` has no `World` position. If it does,
   reject compatibility until the effectful observational gap is resolved.

SMT is appropriate for decidable refinement implications, counterexample
search and cost arithmetic. Each query should be normalised as an unsatisfiable
negation, for example `Pre_old and not Pre_new`, and its result bound to the
manifest. Lean remains responsible for the surrounding elaboration,
substitution, kernel typing and dictionary-preservation theorems. Predicates
outside the SMT fragment require a Lean proof; an unknown or timeout rejects
the patch rather than weakening the old `Spec`.

## Feed-forward requirements

### Kernel-spec-freeze

Define a body-replacement and version-cut theorem solely over erased
`WordType`: if `D_old` is well-formed, `D_old(w) = (W, q_old)`, and
`D_old |- q_new : W`, then replacing only the body preserves dictionary
well-formedness and old kernel-typed callers. Do not add refinements to kernel
`WordType`. The elaborator specification must separately state the
`(WordType, Spec)` contract and its subsumption judgement.

Kernel-spec-freeze must also treat the registered effectful-observation gap as
a dependency before claiming verified replacement for words containing
`World`. OPEN-3 remains a dependency before allowing elaborator quotation
contracts to vary, even when their erased quotation types remain equal.

### Verified-patch protocol

Specify distinct hashes and evidence for erased `WordType` equality and
elaborator `Spec` subsumption. The protocol also needs compiled-body
correspondence evidence, atomic slot swap, version-cut semantics, rollback
retention, and structured diagnostics identifying whether a kernel equality or
logical implication failed. Effectful patches remain unsupported until the
registered gap is resolved and incorporated into `Spec`.

## Downstream gap

`dec.gap-firth-runtime-patch-should-effectful-verified-patch-compatibility-use-an`
asks whether effectful compatibility uses an abstract `World`
pre-state/post-state relation, an event trace, or both. Resolving it must define
observable effect refinement, SMT or Lean proof obligations, and the patch
protocol's treatment of added, removed and reordered actions.
