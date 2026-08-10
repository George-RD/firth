# Firth v0.1 Agent Language Guide

Version: 0.1

This guide is the complete language input for an agent authoring a small Firth
application. The companion manifest names the machine-facing diagnostic
interface and the versioned source-to-execution entry points. Do not infer
syntax, typing, ownership, or failure handling from host-language conventions.

## 1. The programming model

Firth is concatenative. A program consumes the value stack from bottom to top,
then produces a new stack. Items in a body execute from left to right. There is
no implicit application, precedence rule, hidden variable, or implicit stack
shuffle.

The checked pipeline has four boundaries:

1. **Elaboration** parses source, resolves names, checks stack effects and
   linear ownership, discharges refinement obligations, and produces a checked
   kernel program.
2. **Compilation** lowers each checked kernel atom structurally to the target
   instruction set. Compilation must not change the program's stack effect or
   behaviour.
3. **Reference execution** evaluates the checked kernel program. This is the
   behavioural oracle.
4. **VM execution** runs the compiled target program with the same initial
   stack, primitive profile, and finite fuel when bounded comparison is used.

A successful application therefore has two matching observations: the
reference result and the VM result. A compiler or VM mismatch is an error, not a
new language meaning.

The language has one observable stack. Runtime call frames and instruction
pointers are administrative implementation state. Values, quotations, words,
primitive effects, terminal outcomes, and bounded traces are compared through
the machine-facing contracts in the manifest.

## 2. Lexical rules and source files

Identifiers are case-sensitive ASCII names. A word name begins with a letter
and may contain letters, digits, `-`, `?`, and `!`. Qualified names join word
names with `.`. Row variables begin with `ρ`. Integers may be negative.
Characters use single quotes. Strings use double quotes and the escapes `\\`,
`\"`, `\n`, `\r`, and `\t`.

A line comment begins with `\` and ends at the newline. A block comment begins
with `(*` and ends at the first `*)`; block comments do not nest. Unterminated
strings and comments are errors.

A source file contains vocabulary declarations, `use` declarations, and word
definitions:

```text
vocab <name> { ... }
use <vocabulary> [as <alias>];
: <word-name> <stack-effect> <body>;
```

The outer file is an implicit vocabulary. A word is exported by default. A
qualified reference is resolved by its canonical name. An unqualified
reference is accepted only when exactly one visible candidate exists. Ambiguous
or missing names are errors. Definitions in one vocabulary are visible
throughout that vocabulary, so recursive words may be declared without textual
forward declarations.

A body contains literals, quotations, kernel atoms, primitives, word names, and
local blocks:

```text
item ::= literal | quotation | kernel-atom | prim <name> | word-name
       | locals { <name> ... } { <body> }
quotation ::= [ <body> ]
```

The reserved kernel atoms are `dup`, `drop`, `swap`, `dip`, `call`, `compose`,
`quote`, and `if`. A primitive is written as `prim <name>`. The primitive name
must be present in the execution adapter's validated Gamma profile. A literal
is always a replayable `many` value. It cannot introduce a linear resource.

The grammar accepts character and string tokens, but a program may use them
only when the Gamma profile declares corresponding nominal sorts and literal
types. The guide's MVP profile permits source-visible `Int`, `Bool`, `Handle`,
and `Bytes` values, plus the hidden linear `World` token used by effectful
primitives. The gate validates the same profile in the companion manifest.
Examples therefore use integer and Boolean literals only.

## 3. Stack effects

Every word declares a parenthesised effect. Stack entries are written bottom to
top, with the right side representing the resulting top of stack:

```text
(forall ρ; <inputs> -- <outputs>)
```

A row variable is a stack tail, not a value. It must be bound in `forall` when
it appears in the effect. A value entry is `name:Type^usage`. `^many` is the
default usage and may be omitted. A linear value must be written `^linear`.
Names identify diagnostic anchors and refinement inputs. They do not affect
runtime type equality.

Examples:

```text
( -- n:Int^many )
(forall ρ; ρ n:Int^many -- ρ n:Int^many)
(forall ρ; ρ h:Handle^linear -- ρ)
```

The type language uses declared nominal base sorts and quotation types:

```text
Usage       = many | linear
BaseType    = Sort^Usage
ValueType   = BaseType | [InputEffect -> OutputEffect]^Usage
StackType   = Row | StackType ValueType
WordType    = forall Row...; StackType -> StackType
```

The quotation form in `ValueType` is an internal checked scheme. It is not
source syntax for a named boundary entry. In source, write a nominal type name
for each boundary value and use brackets in a body to create quotation code.

`many` values may be duplicated or discarded. `linear` values may be moved or
consumed exactly according to their checked ownership flow. There is no
conversion from `linear` to `many`. A linear value must not be duplicated,
silently discarded, or consumed by two execution events.

The checker unifies rows from the top down and performs an occurs check. An
unresolved residual equation is a type failure, not a guessed default. The
checker does not select among overloads or use source order as a default. A
word call instantiates fresh row variables for the word's prenex scheme. A
local quotation is checked at one monomorphic use site.

## 4. Body operations and quotations

Concatenation applies each item's effect to the current stack. The core rules
are:

| Item | Stack action |
| --- | --- |
| literal | Push a declared `many` literal. |
| `dup` | Duplicate a top `many` value. |
| `drop` | Remove a top `many` value. |
| `swap` | Exchange the top two values. |
| `call` | Consume and execute one quotation. |
| `dip` | Consume a quotation, execute it below the protected top value, then restore that value. |
| `compose` | Consume two quotations and push their concatenation. Ownership is the meet of both quotation usages. |
| `quote` | Move the top value into a one-slot quotation. A linear capture makes the quotation linear. |
| `if` | Consume a `many` Boolean and two `many` quotations with equal effects, then execute the selected branch. |
| word name | Resolve and execute the dictionary word. |
| `prim p` | Apply the deterministic Gamma transition for primitive `p`. |

A quotation is written with brackets. It is code, not a list:

```text
[ 1 prim + ]
```

A closed quotation containing only `many` values is `many`. A quotation that
captures a linear value is `linear`, and cannot be copied or dropped. `if`
requires both branches to have the same effect and to be `many`, because the
unchosen branch may be discarded. `compose` preserves a linear ownership
footprint instead of weakening it.

Named locals are pure sugar. They do not create variables or an environment.
`locals {a b} { a b prim + }` selects the declared stack entries, emits the
canonical structural operations, and then checks the resulting kernel program.
A `many` local selected several times is copied with `dup`. A linear local must
be selected exactly once. Unused declared locals are explicitly focused and
dropped only when their usage permits it.

For example, this word adds its two inputs:

```text
: add-top-two
  (forall ρ; ρ a:Int^many b:Int^many -- ρ result:Int^many)
  locals { a b } { a b prim + };
```

Its canonical structural prefix is `swap swap`, followed by `prim +` when the
primitive consumes the selected values in that order. The source local names
are not runtime names.

## 5. Refinements and proof obligations

A refinement is metadata on a typed boundary, not a runtime value or kernel
instruction:

```text
(forall ρ;
  ρ x:Int^many{positive x} --
  ρ y:Int^many{positive y})
```

Input anchors are available to preconditions. Output anchors are available to
postconditions. A consumed input can be named in a postcondition only as
`old.x`. A brace list is a conjunction in source order. Predicate names resolve
through the same canonical name rules as words.

A predicate is pure, total, and replayable. Its arguments and Boolean result are
`many`. It cannot consume or produce a linear value, mention `World`, or reach
an effectful primitive. A missing registry entry, wrong arity, wrong sort,
missing totality evidence, unsupported translation, or incomplete proof is a
non-success state. Never guess a predicate as true, false, or uninterpreted.

The checker first infers the erased stack effect, then resolves predicate
identities, builds typed predicate metadata, generates obligations, and
checks evidence. Refinements erase completely. For the same body, adding a
refinement must not add or remove a kernel atom or runtime effect.

A refinement contract is:

```text
Contract(word) = (WordType, Spec)
Spec = (Pre, Post, optional Totality)
```

A caller must satisfy the callee precondition. The callee postcondition then
becomes available to the continuation. Replacement or patch checks compare
exact erased word types, including usage annotations, before checking any
contract relation.

## 6. Deterministic diagnostics

Diagnostic payloads are JSON envelopes with these required fields:

```json
{
  "schema_version": "1.0",
  "payload_kind": "diagnostic",
  "payload_id": "non-empty-stable-id",
  "request_id": "non-empty-request-id",
  "body": {}
}
```

The source, checked-kernel, target, execution, and observation records named
by the companion manifest are structured JSON bodies for the four pipeline
adapters. They carry `request_id` as their correlation field; they are not
diagnostic envelopes and do not repeat `payload_kind`, `payload_id`, or `body`.

The supported payload kinds for diagnostic envelopes are `diagnostic`, `typed_hole`,
`signature_search_request`, and `signature_search_response`. Locations carry a
non-empty path or URI and one-based start and end line and column positions.
The end position must not precede the start position.

A diagnostic body contains a stable code, severity, message key and parameters,
location, cause, nullable expected and actual stack descriptions, ordered
obligations, and optional proposed fixes. Diagnostic codes use one of the
stable namespaces `type`, `linearity`, `refinement`, `elaboration`, `syntax`,
`name`, `search`, or `protocol`, for example:

```text
firth.type.stack-mismatch
firth.linearity.usage-mismatch
firth.refinement.not-decided
firth.syntax.invalid-name
firth.name.ambiguous-use
firth.protocol.invalid-code
```

Typed holes carry a hole identifier, location, and an opaque inferred stack
state. Search requests carry an opaque stack-effect query, an optional opaque
refinement query, a positive page size no greater than 1000, a page, and an
optional cursor. Search responses carry the same pagination fields and matches
with a word identifier, opaque signature, match kind, and rank.

Diagnostics are ordered by source URI or path, range start, range end, stable
code, payload identifier, and obligation identifier. Search matches are ordered
by ascending rank, then word identifier. Do not use map iteration, import order,
solver availability, or host addresses to break a tie. Duplicate JSON members,
malformed JSON, empty identifiers, unsupported versions, invalid locations, and
out-of-order matches are protocol failures.

The diagnostic loop is:

1. Submit one source request with a fresh request identifier.
2. Parse every returned envelope and reject protocol-invalid payloads.
3. Sort valid diagnostics with the specified key.
4. Apply only a proposed fix whose applicability is accepted by the caller.
5. Re-elaborate the changed word and repeat until success or a non-success
   obligation remains.

A timeout, unknown solver result, missing proof, or deferred obligation is not
success. Preserve its obligation identifier and evidence state for the next
request.

## 7. Elaboration, compilation, and execution workflow

For each application:

1. Write a source file containing only the syntax in this guide and primitive
names permitted by the validated MVP Gamma profile (`Int`, `Bool`, `Handle`,
`Bytes`; effectful primitives additionally consume hidden `World`).
2. Declare every word's complete boundary effect before writing its body.
3. Run the validated elaboration adapter. Its logical contract is
`firth.elaborate.v1`; a successful result is a checked word dictionary and
kernel program. A failure is a sorted diagnostic set.
4. Keep the checked kernel program and its erased effects as the compiler
   input. Do not compile source text directly.
5. Lower literals, quotations, structural atoms, word calls, and primitives
using the validated compilation adapter (`firth.compile.v1`). Unknown atoms,
words, and primitives fail before execution.
6. Run the same checked kernel program through the reference entry point.
7. Run the target output through the VM entry point with the same initial stack,
   Gamma profile, image, and fuel.
8. Compare terminal status, bottom-to-top observable stack, classified trap
   status, hidden world observation, residual bounded trace, and the
   deterministic cost report. A mismatch fails the application.

A normal terminal result has no remaining code and reports the final stack.
Fuel exhaustion is not divergence proof and must be classified as
`bounded-fuel-inconclusive` unless both sides meet the comparison contract.
Target traps include `malformed-instruction`, `unknown-word`,
`unknown-primitive`, `stack-fault`, `type-fault`, `resource-fault`,
`primitive-fault`, `fuel-exhausted`, and `patch-fault`.

The VM instruction vocabulary is `PUSH_LITERAL`, `PUSH_QUOTE`, `PUSH_CAPTURE`,
`DUP`, `DROP`, `SWAP`, `CALL`, `DIP`, `COMPOSE`, `QUOTE`, `IF`, `CALL_WORD`,
and `PRIM`. `CALL_WORD` resolves the current dictionary entry at call time.
Compilation must not inline it when doing so would change word redefinition
behaviour. A primitive threads the hidden linear `World` token and state; the
World token is not an observable value.

## 8. Worked applications

These examples are small model-authored application shapes. The manifest
identifies the versioned logical adapters that the executable MVP gate must
provide and the contracts used to rebuild and compare them.

### 8.1 Increment

```text
: increment
  (forall ρ; ρ n:Int^many -- ρ result:Int^many)
  1 prim +;
```

With `n = 41`, the reference and VM observations both have one `Int` result,
`42`, on the stack. The primitive must have the declared effect
`Int^many Int^many -- Int^many`.

### 8.2 Conditional increment

```text
: choose-increment
  (forall ρ; ρ n:Int^many flag:Bool^many -- ρ result:Int^many)
  [ 1 prim + ] [ ] if;
```

Both branches have effect `ρ n:Int^many -- ρ n:Int^many`. With `flag = true`,
`n` is incremented. With `flag = false`, the empty branch preserves `n`.
The two branch quotations are closed and `many`, so discarding the unchosen
branch is safe.

### 8.3 Linear one-shot operation

```text
: send-once
  (forall ρ; ρ w:World^linear h:Handle^linear b:Bytes^linear
    -- ρ w2:World^linear)
  locals { h b } { h b prim send };
```

The manifest's Gamma profile declares `send` as consuming
`World^linear Handle^linear Bytes^linear` and producing `World^linear`.
The World token is declared in the checked effect but is hidden from the
observable result. Each handle and byte input is selected once. Inserting
`dup`, `drop`, or a second selection is a linearity error. A successful run
reports the primitive's deterministic world observation and leaves only the
threaded hidden token in the administrative stack.

## 9. Authoring checklist

Before submitting an application, verify all of the following:

- Every identifier resolves uniquely and every primitive is in the manifest
  profile.
- Every word has a complete stack effect with explicit row binders.
- Literals are `many`; linear values are selected, moved, or consumed exactly
  once.
- Quotations have compatible effects and valid ownership.
- `if` branches have equal effects and `many` ownership.
- Refinements name registered pure total predicates and have discharged
  evidence.
- Elaboration succeeds without deferred or unknown obligations.
- Compilation consumes the checked kernel program and rejects unknown targets.
- Reference and VM observations agree for terminal status, stack, trap class,
  hidden world observation, bounded trace, and cost.
- The source, transcript, and result hashes are recorded by the manifest before
  the application is considered part of the MVP corpus.

When an item fails, report the stable diagnostic or comparison classification.
Do not hide a failure by changing the expected result, weakening a type, or
assuming host-language behaviour.
