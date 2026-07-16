---
id: res.patch-compat-prior-art
nodes: [firth.runtime.patch]
sources: [src.firth-prd, src.firth-kernel-spec-draft, src.liskov-wing.behavioural-subtyping, src.liquid-types, src.hicks-nettles.dynamic-software-updating, src.wadler.linear-types]
date: 2026-07-16
---

# Compatible word replacement under refinement types

## Question and recommendation

Let the live dictionary contain `D(w) = (T_old, p_old)`. A replacement
`p_new` is compatible when every already-checked caller that is valid against
`T_old` remains safe and every property available from `T_old` remains true
after calls resolve to `p_new`. Write this behavioural refinement judgement as
`T_new <=patch T_old`, meaning that the new implementation contract is a
behavioural subtype of the old public contract.

For v1, retain `T_old` as the public `WordType` stored in `D` and replace only
the body:

```text
D(w)  = (T_old, p_old)
D_old[w : T_old] |- p_new : T_new
T_new <=patch T_old
----------------------------------
D_new = D_old[w := (T_old, p_new)]
```

The second premise checks self-recursion and mutual recursion against stable
public signatures. The third premise licenses subsumption from `T_new` to
`T_old`. Consequently the dictionary well-formedness proof for every other
word remains valid and only the replacement body's obligations need checking,
as required by R9. A stronger inferred contract may be attached to the patch as
evidence, but callers must not see it until a separately governed interface
version is published and affected code is checked against that version.

Changing stack layout, base representation, row quantification or usage
annotations is not a compatible v1 replacement. Such a change needs a new word
name or version plus an explicit adapter and, if live state changes, a state
transition proof. This separates local word replacement from the more general
dynamic software update problem described by Hicks and Nettles.

## Prior-art approaches

### Exact contract equality

The simplest rule accepts a patch only when its declared stack effect and every
refinement are syntactically identical to the old contract. It is cheap,
decidable and clearly safe, but rejects useful changes. A replacement that
accepts more inputs or proves a more precise result is harmless to old callers,
yet equality rejects it. Predicate equivalence is also rarely syntactic, so
minor specification refactoring would cause false incompatibility.

### Structural function subtyping

Ordinary function subtyping makes inputs contravariant and outputs covariant.
This is the right skeleton for stack words: the replacement must accept at
least the old input set and return values within the old output set. It handles
base and quotation types compositionally, but unrefined structural types alone
do not preserve semantic promises, termination claims, cost bounds or effects.

### Behavioural refinement subtyping

Liskov and Wing strengthen structural subtyping with substitutability of
preconditions, postconditions, invariants and history properties. Liquid Types
shows a practical automation route: reduce refinement subtyping to logical
implications and discharge a conservative decidable fragment automatically.
This combination best matches Firth. It is local, permits useful strengthening,
and produces explicit Lean or SMT obligations.

### Contextual or whole-image refinement

The most permissive rule accepts an update when no complete program context can
distinguish it in a forbidden way. It can justify representation changes,
adapters and coordinated multi-word updates, but direct contextual equivalence
is generally not a practical incremental check. Whole-image rechecking has a
similar cost and conflicts with R9. Firth should reserve these approaches for a
future governed image-transition protocol, not use them as the v1 word-patch
compatibility rule.

## Variance rule

Represent a refined word contract schematically as:

```text
T = forall rho. rho . A | Pre(x, s) -> rho . B | Post(x, s, y, s')
```

Here `A` and `B` are ordered stack suffixes, `x` and `y` name their values, and
`s` and `s'` are logical pre-state and post-state observations. They may include
`World` observations when the word is effectful.

For `T_new <=patch T_old`, require:

1. **Same erased calling convention.** The row binders, suffix lengths, value
   order, runtime representations and usage annotations match. V1 performs no
   implicit stack or representation coercions. Quotation types apply the same
   rule recursively, but quotation usage remains exact until kernel OPEN-3 is
   resolved.
2. **Contravariant inputs.** Every old-valid input is new-valid:
   `Pre_old(x, s) => Pre_new(x, s)`. Equivalently, the new input refinement is
   equal or weaker. If value subtyping later exists at an ABI boundary, each
   old input type must be a subtype of the corresponding new input type.
3. **Covariant outputs.** Under an old-valid input, every new outcome satisfies
   the old guarantee: `Pre_old(x, s) and Post_new(x, s, y, s') =>
   Post_old(x, s, y, s')`. Equivalently, the new output refinement is equal or
   stronger. Each new output value type must be a subtype of the corresponding
   old output type if value subtyping exists.
4. **No wider observations.** The new body may not add a trap, exception,
   divergence, effect trace or cost that the old contract excludes. If the old
   contract promises termination or a cost bound, the new contract must retain
   or strengthen that promise. If the old contract intentionally leaves one of
   these properties unspecified, compatibility need not invent a guarantee.
5. **Stable linear capabilities.** The replacement consumes and produces the
   same linear positions exactly once. Usage changes are rejected even where a
   semantic coercion might appear plausible, because existing compiled callers
   were checked under the old duplication and disposal capabilities.

Refinement direction is therefore easy to state but easy to reverse by
mistake: weaken requirements on input, strengthen guarantees on output.

## Examples and counterexamples

Assume mathematical integers in these examples, so machine overflow is not an
unstated observation.

### Compatible input weakening and output strengthening

```text
old: forall rho. rho . {x : Int | x > 0}
                  -> rho . {y : Int | y >= x}

new: forall rho. rho . {x : Int | x >= 0}
                  -> rho . {y : Int | y = x + 1}
```

The old precondition implies the new one, and `y = x + 1` with `x > 0`
implies `y >= x`. Old callers gain an implementation that accepts more states
and returns a more precise result, so the patch is compatible.

### Incompatible input strengthening

```text
old: forall rho. rho . {x : Int | x != 0} -> rho . Int
new: forall rho. rho . {x : Int | x > 0}  -> rho . Int
```

The old-valid input `x = -1` is a counterexample. It satisfies `x != 0` but
not `x > 0`, so an already-checked caller can reach a state rejected by the
replacement.

### Incompatible output weakening

```text
old: forall rho. rho . {x : Int | x >= 0}
                  -> rho . {y : Int | y > x}

new: forall rho. rho . {x : Int | x >= 0}
                  -> rho . {y : Int | y >= x}
```

For `x = 0`, the new postcondition permits `y = 0`, which violates the old
promise `y > x`. The replacement is incompatible even though its erased stack
effect is identical.

### Incompatible stack or usage change

Replacing `rho . Int -> rho . Int` with
`rho . Int . Int -> rho . Int` underflows every old caller that supplies one
integer. Replacing an output marked `many` with a linear output is also
incompatible: old callers may legally `dup` or `drop` it. Refinements cannot
repair either calling-convention break.

### Compatible cost strengthening

If the old contract guarantees `cost <= 20 + 2 * x` and the new proof gives
`cost <= 15 + x` for all old-valid `x >= 0`, then the new bound implies the old
bound and is compatible. A new bound `cost <= 30 + 2 * x` is not compatible:
at `x = 0`, it permits a cost of 30 where the caller was promised at most 20.

## The linear `World` thread

Wadler's linear-world account supports Firth's proposed representation of
effects: an effectful word has one linear `World` input and one linear `World`
output, and neither may be duplicated or discarded. Patch compatibility must
preserve both the structural thread and its behavioural relation.

An old pure word has no `World` position. A new body that performs an effect
cannot typecheck at the stable old contract because it has no `World` token to
consume. This makes adding an untracked effect to a pure word structurally
incompatible.

For an already effectful word, matching `World` positions proves only ordered,
exactly-once threading. It does not prove that the same effects occur. The
refinement layer must expose an abstract observation such as a state relation
or event trace. If an old word promises one write to device register `r`, a new
implementation that performs the same write and additionally updates an
internal value is compatible only when that internal change is outside the
old observable contract. A second device write is a counterexample when the
old postcondition permits exactly one event. Likewise, returning a fresh or
duplicated logical `World` rather than the unique successor violates linearity
even if ordinary output predicates happen to hold.

The patch operation itself must not consume the program's `World` token behind
the program's back. VM-level installation is a control-plane transition whose
atomicity and image-state effects belong to the patch protocol. If patching is
modelled inside Firth later, it must be an explicit effectful primitive with its
own `World` contract.

## Lean and SMT obligations

The verified-patch protocol should carry a manifest binding the word name,
old contract hash, old body or image version, new kernel body hash, compiled
body hash, and proof artefacts. Acceptance must discharge the following:

1. **Manifest freshness.** The live slot still has the expected old contract
   and version. This prevents a proof for one image from being replayed over a
   different definition.
2. **Elaboration and body typing.** Lean checks the elaborated `p_new` against
   `T_new` using the stable dictionary signatures, including `w : T_old` for
   recursive calls, with no admitted lemmas.
3. **Erased compatibility.** A decidable checker proves equality of row
   quantification, stack arity and order, runtime representations, and usage
   annotations. It recursively checks quotation calling conventions.
4. **Input implication.** For each input refinement, prove
   `Pre_old => Pre_new` in the refinement environment.
5. **Output simulation.** Prove
   `Pre_old and Post_new => Post_old`, relating dependent outputs to the same
   logical inputs and pre-state. Branch, trap, exception, termination and cost
   obligations are included when stated by `T_old`.
6. **Linearity and `World`.** Lean checks exact consumption of every linear
   value. For effectful words, prove the new state or trace relation refines the
   old one and preserves a single ordered `World` successor.
7. **Dictionary preservation.** Construct a proof that replacing only
   `body_D(w)` leaves `D_new` well-formed at `T_old`. This is the theorem that
   avoids rechecking callers and mutually recursive neighbours.
8. **Compiler correspondence.** Bind the accepted kernel body to target code
   whose execution refines the reference interpreter. Until the compiler proof
   exists, the protocol must label this as an empirical gate backed by the
   differential harness, not as a proved patch property.
9. **Atomic installation and rollback.** Verify the code payload before making
   it reachable, change the dictionary slot atomically, and retain the old slot
   until rollback is safe. A failed check changes no live image state.
10. **Version-cut semantics.** Under kernel S-WORD, a body already unfolded
    into the current program continues as old code, while later word lookups
    use the new body. The VM must implement the same cut or establish a safe
    quiescence point. Quotations containing the name `w` resolve it when their
    S-WORD step occurs, not when the quotation was created.

SMT is appropriate for decidable refinement implications, counterexample
search and cost arithmetic. Each query should be normalised as an unsatisfiable
negation, for example `Pre_old and not Pre_new`, and its result bound to the
manifest. Lean remains responsible for the surrounding typing, substitution,
linearity, dictionary-preservation and installation theorems. Predicates
outside the SMT fragment require a Lean proof; an unknown or timeout rejects
the patch rather than weakening the contract.

## Feed-forward requirements

### Kernel-spec-freeze

Before freezing the kernel, define dictionary replacement and version-cut
semantics explicitly, state the `<=patch` judgement at the elaboration boundary,
and prove a replacement theorem: a well-formed dictionary remains well-formed
and every old-typed caller remains safe when one body is replaced under the
premises above. Confirm that OPEN-2 provides enough abstract `World` state or
trace structure for effect refinement, and resolve OPEN-3 before allowing
higher-order quotation contracts to vary.

### Verified-patch protocol

Specify a stable public-contract hash, proof-carrying patch manifest, Lean and
SMT verification pipeline, compiled-body correspondence evidence, atomic slot
swap, version-cut rule and rollback retention policy. The protocol should emit
structured diagnostics identifying the failed implication and, when SMT finds
one, a concrete counterexample. Interface changes outside v1 compatibility
must be routed to a versioned adapter or governed image-transition mechanism.

## Material design question

The CTO must decide whether v1 contracts describe observable effects as an
abstract pre-state/post-state relation, an event trace, or both. Exact `World`
threading proves sequencing but cannot by itself decide whether adding,
removing or reordering external actions is a behavioural refinement. This choice
must be settled before effectful word patches can receive the same compatibility
guarantee as pure words.
