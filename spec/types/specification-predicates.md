# Specification Predicates and Refinement Contracts

## Status and boundary

This is the normative v0.1 type-system specification for predicates used in
refinements. It completes the `predicate` nonterminal referenced by the
surface syntax specification. It does not revise the frozen kernel calculus.

A public word contract is:

```
Contract(w) = (WordType, Spec)
Spec = (Pre, Post, Totality?)
```

`WordType` is the erased prenex stack effect from the frozen kernel. `Spec` is
elaborator metadata. Refinements are checked at word boundaries and are erased
before a kernel `Program` is executed. The kernel dictionary contains only the
erased `WordType` and kernel body.

The elaborator must therefore preserve this invariant:

```
elaborate(source word) = (erased WordType, kernel Program, checked Spec)
erase(checked Spec) = no kernel instruction
```

No predicate application, proof step, registry lookup, or diagnostic operation
may add an atom, value, dictionary field, or runtime effect to the consumer's
kernel program.

## 1. Typed predicate values

For v0.1, a predicate over value sorts `τ⃗ = τ1 ... τn` has the typed value
shape:

```
Predicate(τ⃗) = τ1^many × ... × τn^many -> Bool^many
```

The result is one ordinary replayable Boolean value. The predicate is a
logical value in the elaborator, not a first-class runtime value. A zero-arity
predicate has shape `() -> Bool^many`.

The corresponding Firth predicate word has exactly this erased boundary:

```
forall ρ; ρ x1:τ1^many ... xn:τn^many -- ρ result:Bool^many
```

The row `ρ` is optional only when the ordinary surface notation omits a
vacuous row variable. Arguments and the result are always `many`. A predicate
word is rejected if it consumes or produces a `linear` value, mentions
`World`, has an effectful primitive in its transitive body, or has any boundary
other than the row-preserving Boolean result above. The ordinary kernel typing
and linearity rules still check its body.

Predicate arguments are first-order value expressions. v0.1 admits named
boundary anchors and literals whose types match the registered argument sorts.
Rows, quotations, words as values, `World`, opaque resources, and implicit
binders are not predicate arguments. A predicate cannot inspect or alter the
runtime stack except through the values explicitly supplied at its boundary.

A predicate word must be total when it is used as a refinement predicate. A
Firth body that can diverge is not silently treated as total. Totality is a
separate Lean-checkable obligation and is part of the predicate declaration
hash. A predicate without a successful totality proof remains an open
obligation and cannot make its containing word accepted.

## 2. Predicate references and declarations

The surface form is a predicate name followed by zero or more arguments. The
existing refinement notation therefore has the form:

```
predicate      = qualified-name { predicate-argument }
predicate-argument = anchor-name | pre-anchor | literal
qualified-name = name
anchor-name   = word-name
pre-anchor    = "old." , anchor-name
```

The surface syntax specification owns the surrounding `type-expression`
production. `old.x` explicitly names the immutable pre-state snapshot of input
anchor `x`; an unqualified name in `Post` resolves only to an output anchor.

`qualified-name` is resolved exactly like a word name. It never means an
arbitrary host-language expression. Argument arity, order, and value sorts
come from the declaration, not from source inference.

Every predicate reference resolves to one registry entry with this identity:

```
(qualified-name, semantic-version, argument-sorts, definition-hash)
```

The registry entry records:

1. whether the definition is a Firth word or a Lean definition;
2. the exact predicate boundary and result sort `Bool`;
3. purity and totality evidence;
4. the canonical typed predicate IR and its kernel representation;
5. an optional SMT translation, translation-rule hash, soundness-proof hash,
   semantics profile, and required solver features.

The definition hash is content-addressed over the canonical definition, typed
IR, purity and totality evidence, and host proof/module evidence. All hashes
use the existing content-addressed discharge-record contract and canonical
serialisation. Transitive predicate and callee contract hashes are included in
the discharge record, so changing a dependency invalidates dependent evidence.
This specification introduces no second hash scheme.

The registry has exactly one active semantic version for each qualified name.
The source syntax does not select a version. A reference uses the active entry;
an absent active entry, duplicate active entries, or equal-version entries with
different hashes is an ambiguity diagnostic. Version changes therefore change
the resolved identity and invalidate dependent discharge records. Resolution
never chooses by import order, source order, or solver availability.

### 2.1 Firth predicate words

A Firth predicate word is an ordinary word whose checked boundary satisfies
Section 1. Its body is elaborated and erased to the same frozen kernel atom set
as every other word. The registry stores its canonical qualified name, version,
contract hash, body hash, and typed predicate IR. A refinement reference stores
that stable identity and does not inline or execute the body in the consumer.

### 2.2 Lean predicate definitions

A Lean definition is eligible only when it is declared through the predicate
registry and elaborates to the same typed predicate IR and kernel-level
representation required of a Firth predicate word. The Lean kernel checks its
termination, type, purity boundary, and the semantics-preservation theorem
connecting its definition to that IR. The registry stores the Lean declaration
name, module hash, proof hash, and semantic version.

A Lean declaration that is merely an opaque callback, an axiom, an unsafe
function, or an unconnected proposition is rejected. It cannot bypass Firth
name resolution, typed arguments, kernel lowering, or deterministic
obligations. If its IR cannot be constructed, the diagnostic identifies the
missing kernel representation rather than accepting a host escape hatch.

### 2.3 Canonical predicate IR

The typed predicate IR is the shared representation for Firth and Lean
definitions:

```
PredIR ::= truth | falsity | and PredIR PredIR
        | or PredIR PredIR | atom SemanticIdentity [ValueIR]
ValueIR ::= typed-literal (sort, literal) | typed-variable | typed-tuple
SemanticIdentity = (qualified-name, semantic-version, argument-sorts)
RegistryIdentity = (SemanticIdentity, definition-hash)
```

`typed-variable` is a boundary anchor carrying its declared sort. The
elaborator rejects a value sort for which it cannot construct `ValueIR`; it
does not stringify or treat that value as uninterpreted. Integer and Boolean
values lower to the existing SMT boundary constructors. Other declared
first-order sorts lower to the Lean route unless a registered semantics
preserving backend encoder exists. The SMT boundary may therefore support a
strict subset without changing the normative IR.

A Firth body and an eligible Lean definition must produce structurally equal
`PredIR` for the same `SemanticIdentity`, after canonical name, sort, and
argument ordering. Evidence hashes are registry and discharge metadata, not
semantic IR nodes. The Lean semantics-preservation theorem proves equality of
their predicate meanings and binds the registry evidence hashes. The predicate
definition's own body lowers to a kernel `Program`; an `atom` in a consumer's
`PredIR` is elaborator metadata and never a new kernel atom.

## 3. Refinement environments and composition

At a word boundary, the elaborator creates immutable logical anchors for the
named input and output stack entries. Anchor names must be unique across the
complete contract; an input and output may not both be named `x`. Any
duplicate is a deterministic `firth.refinement.duplicate-anchor` error.
Input anchors are available to `Pre`. Output anchors are available to `Post`.
Postconditions refer to consumed or renamed input values only with the
explicit `old.x` pre-anchor form. These anchors are specification metadata and
are never hidden runtime binders.

A refinement set is a source list of predicate references:

```
RefinementSet = [P1, ... , Pn]
normalise([]) = truth
normalise([P1, ... , Pn]) = P1 and normalise([P2, ... , Pn])
```

All predicates in a brace list must type-check against the same boundary
environment. The list is conjunction, not sequential execution. The
source-order normalised tree is the normative formula material, as required by
the accepted SMT normaliser decision. Source spans remain attached for
diagnostics. Predicate identity sorting is used only for independent
dependency traversal and cache invalidation, never to reorder formula meaning.
A predicate word may compose other pure predicate words in its own body only
through ordinary concatenative calls whose erased effects satisfy Section 1.

For a checked word body, the primary obligation is:

```
Pre_body(stack_in) and Sem(kernel_body, stack_in, stack_out)
  implies Post_body(stack_out)
```

`Sem` is the frozen kernel semantics. It is not extended with predicate
steps. Totality and replacement subsumption use the existing elaborator
obligations and the refinement discharge boundary:

```
Pre_old(x) implies Pre_new(x)
Pre_old(x) and Post_new(x,y) implies Post_old(x,y)
Pre_old(x) and Total_old(x) implies Total_new(x)
```

## 4. Elaboration and erasure algorithm

For each refinement at a word boundary, the elaborator performs these steps:

1. Parse the brace list and record each predicate span.
2. Resolve the qualified name and semantic version deterministically.
3. Check argument count, anchor visibility, literal type, and declared sort.
4. Check the registry purity, linearity, totality, and kernel-representation
   evidence.
5. Build the typed predicate IR, replacing anchors with stable symbolic stack
   variables and literals with typed constants.
6. Normalise the refinement list to a conjunction while retaining source spans.
7. Attach the result to `Pre`, `Post`, or `Totality` in `Spec`.
8. Erase every refinement token from `WordType` and lower the word body through
   the ordinary surface-to-kernel path.
The IR normaliser uses the existing bounded kernel walk: at most 10,000
remaining nodes, 10,010 links, and 1 MiB of canonical name and literal bytes.
Exceeding a bound queues the obligation for Lean escalation with reason
`kernel-budget-exceeded`; it never sends an incomplete formula to SMT and
renders through the existing deferred `firth.refinement.not-decided` path.

The output is deterministic for the same source, dictionary, registry, and
pinned toolchain. Predicate definitions are not re-resolved during SMT
translation. The translator consumes the typed IR and its registry hashes.
Pure registered definitions may be emitted in dependency order, with ties broken
by the canonical predicate identity. Recursive, missing, stale, or untranslated
definitions are not approximated. They are escalated to Lean or remain deferred
under the existing non-success rules.

No unsupported predicate is converted to `truth`, `falsity`, an uninterpreted
runtime primitive, or a guessed solver formula.

## 5. Diagnostics

Diagnostics are deterministic and use the versioned agent envelope. Each
obligation has a stable `obligation_id`, the source word boundary, and the
predicate source span. Predicate diagnostics use these codes:

| Code | Condition |
| --- | --- |
| `firth.refinement.unknown-predicate` | no registry entry resolves the name |
| `firth.refinement.ambiguous-predicate` | more than one active entry remains after name, arity, and sort matching |
| `firth.refinement.arity-mismatch` | argument count differs from the declaration |
| `firth.refinement.anchor-not-found` | an argument names no boundary anchor |
| `firth.refinement.duplicate-anchor` | an input or output row repeats an anchor name |
| `firth.refinement.argument-type-mismatch` | an argument type differs from its declared sort |
| `firth.refinement.linear-argument` | a predicate would consume or produce a linear value |
| `firth.refinement.effectful-predicate` | `World` or an effectful callee is reachable |
| `firth.refinement.not-total` | totality evidence is absent or fails |
| `firth.refinement.no-kernel-representation` | a Lean definition cannot lower to the typed IR and kernel path |
| `firth.refinement.unsupported` | the predicate is outside the selected discharge fragment or has no registered translation |
| `firth.refinement.not-decided` | a registered backend translation exists but Lean or SMT has not produced acceptance evidence |
| `firth.refinement.counterexample` | a validated countermodel disproves a refinement obligation |

When several diagnostics exist, sort them using the agent envelope order:
source path, source range start, source range stop, diagnostic code, payload ID,
then obligation ID. Predicate span is the source range for this purpose.
Only a validated `sat` countermodel is a failed obligation. Every other
external outcome, including timeout, unknown, malformed output, resource
exhaustion, translation failure, solver or profile mismatch, and incomplete
proof evidence, is deferred non-success evidence and cannot be accepted.

## 6. Examples

The examples use `Int`, `Bool`, and `many` base values. Assume `positive`,
`nonzero`, and `is-open` are registered pure total predicates with compatible
boundaries. Assume `prim add` has effect `Int^many Int^many -- Int^many`.
These are contract fixtures; the referenced registry declarations and their
evidence are assumed by the examples, not silently invented by elaboration.

### Accepted input and output refinements

```
: inc-positive
  ( forall ρ; ρ x:Int^many{positive x} -- ρ y:Int^many{positive y} )
  1 prim add ;
```

The input predicate is a precondition and the output predicate is a
postcondition. The body lowers to `lit 1 ; prim add`; no predicate atom is
added. A pure predicate `larger old.x y` may instead express the relational
postcondition when its registered boundary accepts the two logical anchors.

### Accepted composition

```
: bounded
  ( forall ρ; ρ x:Int^many{positive x, nonzero x}
    -- ρ y:Int^many{positive y, nonzero y} )
  1 prim add ;
```

The brace lists become deterministic conjunctions. A predicate word may call
`positive` and `nonzero` in its own pure body, and the resulting body still
lowers to ordinary kernel terms.

### Rejected examples

```
: bad-linear
  ( forall ρ; ρ h:Handle^linear{is-open h} -- ρ h:Handle^linear ) ;
```

Rejected with `firth.refinement.linear-argument`: refinement predicates cannot
consume a linear resource. A predicate that mentions `World` or calls an
effectful primitive is rejected with `firth.refinement.effectful-predicate`.

```
: bad-name ( forall ρ; ρ x:Int^many{missing x} -- ρ x:Int^many ) ;
```

Rejected with `firth.refinement.unknown-predicate`. A reference with the wrong
number or type of arguments reports the corresponding deterministic error.

### Unsupported but not guessed

```
: nonlinear ( forall ρ; ρ x:Int^many{prime? x} -- ρ x:Int^many ) ;
```

If `prime?` has no registered translation and no Lean proof, the obligation is
`firth.refinement.unsupported`. A registered translation without acceptance
evidence instead produces `firth.refinement.not-decided`. Neither outcome is
sent to SMT as an uninterpreted predicate or treated as accepted.

A recursive predicate is outside the SMT fragment. It may use the Lean route
only when its totality, typed IR, and semantics-preservation evidence succeed.
A quotation-valued argument, hidden binder, or opaque Lean callback is
rejected in v0.1. The diagnostic names the exact boundary and leaves the
kernel program unchanged.
## 7. Conformance requirements

An implementation conforms only if it can demonstrate that:

1. accepted predicate words and Lean definitions have the Section 1 boundary;
2. every accepted host definition lowers to the same typed predicate IR and
   kernel representation, with Lean proof evidence where applicable;
3. refinement checking changes `Spec` only and never changes the kernel atom
   stream for the same word body;
4. conjunction, resolution, and diagnostics are deterministic;
5. negative and unsupported examples fail without guessed semantics;
6. the predicate hashes are included in per-word discharge evidence.

The elaborator owns these checks. The frozen kernel continues to check only
`WordType`, kernel programs, primitive signatures, and the ordinary linearity
invariants.
