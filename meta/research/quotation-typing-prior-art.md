---
id: res.quotation-typing-prior-art
nodes: [firth.language.types]
sources: [src.firth-prd, src.firth-kernel-spec-draft, src.mirth-repository, src.kitten-repository, src.cat-typing-functional-stack-languages, src.cat-simple-higher-order-inference, src.cat-nested-polymorphism-report]
date: 2026-07-16
---

# Quotation typing prior art and recommendation

## Scope and conclusion

This note compares Mirth, Kitten, and Cat against Firth's v0.1 kernel draft.
It focuses on quotation formation, higher-order list combinators, stack rows,
linearity across quotation boundaries, and failure modes relevant to a small
Lean-mechanised kernel.

The recommendation is to keep Firth quotation effects monomorphic and row
polymorphism prenex at word boundaries. A quotation owns any values embedded by
`quote` and any literal values embedded in its stored code; constructing or
composing quotations transfers that ownership. Its usage is `many` exactly
when every owned value has `many` usage, and `linear` otherwise. With the order
`linear <= many`, the Firth-derived proposal uses the meet:

```text
many   meet many   = many
many   meet linear = linear
linear meet many   = linear
linear meet linear = linear
```

Prior art supports this shape but does not validate it: Mirth has no reviewed
mechanised proof, Kitten has no linear-capture soundness result, and Cat has no
affine usage dimension. OPEN-3 therefore remains unresolved until Lean proves
preservation and linearity safety for Firth's rules. The current `if` rule also
accepts branch quotations of arbitrary usage, but the operational semantics
executes one and silently discards the other. If the unchosen quotation owns a
linear value, linearity safety is false. For v1, require both branch quotations
passed to `if` to have usage `many`. This is a local, decidable restriction and
needs no borrowing, subtyping, or effect system. A future ownership-aware
conditional may return the unchosen capture, but that is not required in the
kernel.

## Comparison

### Mirth

Mirth describes itself as strongly and statically linear. Its implementation
distinguishes ordinary value types from resources. Resources occupy a separate
part of stack types, and ordinary `dup` and `drop` are unavailable for them.
This is the closest of the three systems to Firth's ownership objective.

Mirth does not make the Joy-style runtime quotation the centre of higher-order
programming. Braced blocks have arrow types, and higher-order words take named
word parameters such as `map(f)`, `filter(f)`, and `fold(g)`. The compiler's
specialiser removes higher-order word parameters where possible. Blocks also
exist as compiler values and can be closure-converted, but the common library
idiom is a parameterised word rather than an unrestricted polymorphic quotation
passed around at runtime.

Representative signatures use an explicit stack context:

```text
List.map(f)    : (*c a -> *c b) *c List(a) -> *c List(b)
List.filter(f) : (*c a -> *c Bool) *c List(a) -> *c List(a)
List.fold(g)   : (a a -> a) List(a) -> Maybe(a), under context *c
```

The important lesson is architectural. Mirth avoids much first-class
polymorphic-quotation pressure by specialising named higher-order parameters,
while still threading an untouched stack context. It separately provides
resource-specific combinators such as `+map`; ordinary combinators must not be
assumed to preserve linear resources merely because their value-stack effects
line up.

No published mechanised soundness proof was found in the reviewed source. The
specialiser contains capture-related TODOs, so Mirth is evidence for a practical
design, not a proof that Firth may omit capture accounting.

### Kitten

Kitten has first-class quotations with lexical capture. Parsed quotations are
scope-resolved into explicit captures, typechecked, lifted to generated words,
and closure-converted. Its `call` has the row-polymorphic shape:

```text
R..., (R... -> S... +P) -> S...
```

Here `+P` is a permission row, used for effects. It is not a linear or affine
usage annotation. Kitten's stack kinds distinguish value, stack, permission
label, and permission rows.

Kitten demonstrates why higher-order stack inference quickly becomes
higher-rank. Its regeneralisation pass explicitly transforms the callback row
in `map` from an outer quantified variable into a quantifier local to the
function argument:

```text
forall rho sigma a b.
  rho * List(a) * (sigma * a -> sigma * b) -> rho * List(b)

becomes

forall rho a b.
  rho * List(a) * (forall sigma. sigma * a -> sigma * b) -> rho * List(b)
```

The standard library types `map` with an effect-polymorphic callback and calls
it once per element. `filter` takes a pure predicate, and the folds take a
binary callback. These combinators reuse their callback, so an ownership system
must require the callback value to be duplicable or represent it as a static
parameter rather than a consumed closure.

Kitten has an experimental pass named `Linearize`, but it inserts explicit
`copy` and `drop` operations according to lexical occurrence counts. It does
not give closure values a Firth-style affine ownership type, and the source
marks the pass experimental with unfinished typed-term generation and branch
accounting. Permission rows therefore must not be treated as evidence that a
captured resource is used exactly once.

The reviewed implementation is valuable evidence for closure conversion and
ranked stack polymorphism, but not a soundness result for linear captures. Its
regeneralisation code is deliberately conservative and contains an explicit
limitation around descending into already quantified types.

### Cat

Cat's formal subset makes quotations first-class function values. `[p]` pushes
the function denoted by `p`; `eval` applies the function on top of the stack.
The type language distinguishes value variables from stack variables, and the
core primitive types have the shapes Firth expects:

```text
eval    : A, (A -> B) -> B
dip     : A, b, (A -> C) -> C, b
compose : (A -> B), (B -> C) -> (A -> C)
if      : A, Bool, (A -> B), (A -> B) -> B
```

The paper's formal subset covers only integers, booleans, and function types,
so it does not specify list `map`, `filter`, or `fold`. Their callback shapes
can be extrapolated from `eval`, but doing so reintroduces the first-class
polymorphism problem. Diggins' follow-up report states that plain
Hindley-Milner inference is insufficient for higher-order stack instructions
without annotations because first-class polymorphism is required.

Cat also supplies the clearest warning against relying on attractive paper
rules without a mechanised algorithm. The language designer reported that
nested polymorphism was not handled compositionally: factoring `dup dip` into a
word changed the inferred type of a program using `[id]`. This was an inference
failure rather than a demonstrated preservation counterexample, but it breaks
the local refactoring property Firth requires. Cat also has no affine usage
dimension, so `dup`, `drop`, `compose`, and `if` do not address captured-resource
ownership.

## Recommended decidable Firth rule

### Type formation and generalisation

1. Quotation types remain `[S1 -> S2]^u`, with no quantifier inside the
   quotation type.
2. Row and value variables are generalised only at dictionary word signatures.
   Quotation literals inside a word are checked at one monomorphic
   instantiation. A quotation needing two distinct stack-row instantiations in
   the same word is rejected or written twice.
3. Let `literalUsage(p)` be the meet of `usage(type(c))` for every `lit c`
   occurring in `p`, recursively including literals inside nested quotation
   bodies. The empty meet is `many`. The usage of `[p]` is
   `literalUsage(p)`: it is `many` only when every embedded literal has a
   `many` type, and is `linear` when any embedded literal has a `linear` type.
   A linear value supplied later through the quotation's input stack is not an
   embedded literal and does not affect the stored quotation's usage.
4. `quote` transfers the top value into the quotation. The quotation usage is
   `usage(t)`. No copy is made.
5. `compose` consumes both input quotations and transfers all their captures to
   the result. The result usage is the meet of the operands.
6. `call` and `dip` remove one quotation value and splice its body once in a
   single transition, so both accept either usage. This local ownership
   transfer does not assert that execution of the body terminates.
7. `if` requires two `many` quotations with identical stack effects. This makes
   discarding the unchosen branch admissible.
8. `dup` and `drop` remain restricted to `many`. There is no implicit coercion
   from `linear` to `many`.

These rules are syntax-directed apart from first-order row unification. The
usage calculation is a four-entry table, so it does not affect decidability.

### Higher-order library words

Words that may invoke a callback zero or more times require a `many` callback.
Indicative signatures are:

```text
map    : forall rho a b.
         rho * List(a) * [rho * a -> rho * b]^many
         -> rho * List(b)

filter : forall rho a. usage(a) = many =>
         rho * List(a) * [rho * a -> rho * Bool]^many
         -> rho * List(a)

fold   : forall rho a b.
         rho * b * List(a) * [rho * b * a -> rho * b]^many
         -> rho * b
```

Firth v1 uses the same `rho` row for the collection word and its callback. The
implementation must hide its traversal state with stack combinators before each
callback invocation. This is less expressive than Kitten's independently
higher-rank callback row, but it is predictable and decidable.

Ordinary `filter` cannot discard a linear element on a false predicate result.
The v1 signature therefore restricts element usage to `many`. A future linear
collection API should use `partition`, returning both accepted and rejected
resources, or take an explicit disposer whose effect is visible. A supposedly
linear callback passed to `map` or `fold` is also rejected because repeated
invocation would require duplicating the closure.

## Worked kernel examples

Let `H` be a linear handle, `Int` and `Bool` be `many`, and `r`, `s`, `t` be
stack rows.

### `call`

```text
[prim positive?] : r -> r * [s * Int -> s * Bool]^many
call             : r * Int * [r * Int -> r * Bool]^many -> r * Bool
```

The literal quotation contains no `lit` and owns no capture, so it is `many`.
`call` removes the quotation value and splices its code once in that transition;
over any finite trace, the same linear quotation is invoked at most once.

### `dip`

```text
dip : r * t * [r -> s]^u -> s * t
```

The quotation may be linear because `dip` removes it without duplication in
one transition. The buried value is moved out of the active prefix and
scheduled for restoration if the quotation terminates; it is not copied or
dropped by the `dip` transition.

### `quote`

```text
r * H --quote--> r * [s -> s * H]^linear
```

The handle moves into the quotation. `dup` and `drop` on the result are type
errors. Calling it later moves the same handle onto the execution stack.

### `compose`

```text
q1 : [r -> s]^linear
q2 : [s -> t]^many
compose(q1, q2) : [r -> t]^linear
```

Both input quotation values are consumed. Their code and captures are moved
into one result. Since one operand owns a linear value, the result is linear.
Composing two `many` quotations yields `many`.

### `if`

```text
r * Bool * [r -> s]^many * [r -> s]^many --if--> s
```

Both branches must have the same effect and both must be `many`. The selected
quotation is executed; discarding the other is safe because it owns no linear
value.

The current draft would also accept:

```text
r * Bool * [r -> s]^linear * [r -> s]^many
```

This must fail. When the second branch is selected, the first quotation and its
captured linear value disappear without consumption.

## Explicit failure cases

- `dup` or `drop` applied to `[S1 -> S2]^linear` fails the existing usage
  premise.
- `[lit h]` is `linear` when `h` has a linear base type, even though it has no
  dynamic capture. Duplicating or dropping it fails. The same recursive check
  applies when `lit h` occurs inside a nested quotation body.
- Inferring a literal quotation as `many` without checking all embedded literal
  types fails because duplicating its stored code could materialise the same
  linear literal more than once.
- `compose` fails when the first output row cannot unify with the second input
  row.
- A composite quotation is never inferred `many` if either operand is
  `linear`; doing so would permit duplication of an owned resource.
- `if` fails when branch stack effects differ or either branch quotation is
  `linear`.
- `map`, `filter`, or `fold` fails with a `linear` callback because the body may
  invoke the callback more than once.
- Ordinary `filter` fails for a linear element type because rejection would
  discard an element.
- A local quotation value cannot be instantiated at two different stack rows.
  Firth requires two literals, factoring into separately instantiated words, or
  an explicit future higher-rank feature.
- A quotation whose body leaks a linear input fails ordinary program typing;
  marking the quotation itself `many` does not weaken the body's stack effect.

## Lean mechanisation implications

1. Define `Usage` as a two-element inductive type and `meet` by cases. Prove
   commutativity, associativity, idempotence, and that `meet u v = many` exactly
   when both operands are `many`.
2. Make quotation value typing record both its stack effect and an ownership
   footprint. For source `[p]`, compute that footprint recursively from every
   embedded `lit c`; for runtime quotations, include every embedded `push v`.
   A syntactically closed source quotation is not automatically `many` because
   its stored code may contain a linear literal.
3. State ownership transfer explicitly in preservation lemmas for `S-QUOTE`
   and `S-COMP`. Neither rule duplicates a runtime value.
4. Prove `S-CALL` and `S-DIP` remove one quotation value and splice its body
   once in that transition, without copying either the body or its ownership
   footprint.
5. Strengthen `IF` with two `many` premises. The `S-IF-T` and `S-IF-F` proofs
   then use a lemma that a `many` quotation contains no owned linear value.
6. Represent row variables and value variables as different kinds. Instantiate
   only prenex word schemes, use an occurs check, and do not generalise local
   quotation values.
7. Keep algorithmic typing syntax-directed and prove it sound against the
   declarative rules before claiming principal types. Cat's factoring failure
   should become a regression case even though Firth intentionally rejects the
   higher-rank generality that exposed it.
8. State linearity safety over arbitrary finite traces as at-most-once use: no
   linear value is duplicated, silently discarded by a structural or control
   transition, or consumed by two distinct events. A value may remain live
   indefinitely when execution diverges. Unrestricted recursion therefore
   makes an unconditional eventual exact-once theorem undischargeable.
   Exact-once consumption may be proved only for terminating executions, with
   an explicit totality premise and a terminal-stack condition that leaves no
   unconsumed linear values.
9. Add negative examples for linear literals in duplicated quotations,
   discarded linear branches, repeated linear callbacks, and linear filtering
   to the metatheory test corpus.

## OPEN-3 disposition

The usage meet is a Firth-derived proposal for `quote` and `compose`, subject to
an ownership footprint that includes both dynamic captures and embedded
literals. Prior art supports the direction but does not prove it. In
particular, `many meet linear = linear` is the conservative candidate, not a
validated theorem, until the Lean model establishes preservation and
at-most-once linearity safety.

The current `if` rule exposes a separate soundness hole discovered while
checking quotation boundaries. The v1 recommendation is that both branch
quotations be `many`, but OPEN-3 itself remains proposed and explicitly
unresolved pending the Lean proof and the correction of literal quotation
usage in the normative kernel rules. A larger ownership-aware conditional
would need to return or otherwise account for the unselected linear capture
and should not be inferred from the current semantics.
