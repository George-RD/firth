You are writing programs in Firth, a new stack language. You have never seen it before; everything you know about it is in the documentation below. Programs are run with the portable runner described in 'Getting started', so only what that runner supports will execute.

For each task, write a complete Firth source file whose entry word is named `main`. Helper words are allowed. Do not use tools, files or the internet; answer from the documentation alone.

<document path="docs/getting-started.md">
# Getting started with Firth

This guide describes the **implemented portable execution profile**, rather
than every feature in the language design. It is also the starting point for
an agent authoring and running a program.

## Installation

The current distribution is the source repository. There is no standalone
release installer. Install Git, Python 3.11 or newer, a C toolchain, and the
[elan](https://github.com/leanprover/elan#installation) and
[rustup](https://rustup.rs/) toolchain managers. Ubuntu needs a working C
compiler and linker; on macOS install the Xcode command-line tools.

```sh
git clone https://github.com/George-RD/firth.git
cd firth
```

Until PR #109 is merged, its runner is on this branch:

```sh
git checkout claude/firth-workflow-orchestration-rmqipj
```

The checked-in pins select Lean `leanprover/lean4:v4.30.0` and Rust `1.93.0`.
Do not substitute an arbitrary Lean version: proof-module identities are
verified against the pinned build. Rust's pin includes rustfmt and clippy.

```sh
python3 --version
lake --version
cargo --version
lake build
(cd src/runtime/vm && cargo build --locked)
```

Run commands from the repository root. The runner rebuilds its three Lean
adapters and the Rust executable incrementally before use. Build messages do
not contaminate its JSON output. No external SMT solver is needed for the
pure examples below. The CI workflow tests the source build on Ubuntu 24.04;
other environments must pass the same gates before their results are trusted.

## First program

Create `add.firth`:

```firth
: main
  ( -- result:Int^many )
  41 1 prim +;
```

A colon begins a word definition and a semicolon ends it. The parentheses
state its stack effect: this word consumes nothing and returns one integer.
The body runs left to right. `41` and `1` push values; `prim +` consumes both
and pushes their sum. `^many` means a value can be copied or discarded.

```sh
python3 tools/loop/firth_run.py check add.firth
python3 tools/loop/firth_run.py run add.firth --entry main
```

The run result is a JSON object containing:

```json
{"status":"success","command":"run","entry":"main","stack":[42]}
```

The actual object also includes `words`, `fuel`, `kernel_cost` and `vm_cost`.
The example above shows the result fields to inspect, not the entire output.
`check` validates definitions but does not establish that every feature has a
portable compiler implementation. `run` also compiles and executes.

## Inputs, multiple words and branches

`examples/mvp/choose-increment.firth` contains:

```firth
: main
  (forall ρ; ρ n:Int^many flag:Bool^many -- ρ result:Int^many)
  [ increment ] [ identity ] if;

: increment
  (forall ρ; ρ n:Int^many -- ρ result:Int^many)
  1 prim +;

: identity
  (forall ρ; ρ n:Int^many -- ρ result:Int^many)
  ;
```

`ρ` is the untouched part of the stack. `forall ρ` binds it. The rightmost
input is the top of the stack. Names such as `n` label the type boundary;
they are not ordinary mutable variables.

Brackets create a quotation: code that runs only when called or selected.
`if` consumes the Boolean below the two quotations and executes the first
quotation for `true`, or the second for `false`.

```sh
python3 tools/loop/firth_run.py check examples/mvp/choose-increment.firth
python3 tools/loop/firth_run.py run examples/mvp/choose-increment.firth \
  --entry main --stack '[41, true]'
python3 tools/loop/firth_run.py run examples/mvp/choose-increment.firth \
  --entry main --stack '[41, false]'
```

These runs return stacks `[42]` and `[41]`. JSON stack values are written
bottom to top. Booleans must be JSON `true` and `false`, not strings. The
runner checks the supplied values against the selected word's declared input
types before executing.

The entry is explicit. It can precede a helper, follow it, or itself be a
helper. A final unused definition does not become the entry by accident.
The checked dictionary, including the entry itself, is passed to the
reference interpreter so ordinary calls and recursion resolve consistently.

```sh
python3 tools/loop/firth_run.py run examples/mvp/choose-increment.firth \
  --entry increment --stack '[9]'
```

That returns `[10]`. A qualified entry uses its full source name, such as
`arithmetic.increment`, not the compiler's mangled target identifier.

## More executable examples

| File | Entry and input stack | Expected output stack |
| --- | --- | --- |
| `examples/mvp/double.firth` | `main`, `[21]` | `[42]` |
| `examples/mvp/double.firth` | `main`, `[true, 21]` | `[true, 42]` |
| `examples/mvp/qualified-call.firth` | `main`, `[41]` | `[42]` |
| `examples/mvp/locals-add.firth` | `main`, `[20, 22]` | `[42]` |
| `examples/mvp/quoted-value.firth` | `main`, `[]` | `[42]` |

The doubling example uses `dup prim +`. The qualified-call example defines
a word inside `vocab arithmetic { ... }`. The locals example uses
`locals { a b } { a b prim + }`, which elaborates to stack operations rather
than a runtime environment. See the frozen
[agent language guide](firth-agent-guide.md) for the wider grammar and
ownership model; the support table below takes precedence for this runner.

## Errors and finite execution

Normal successful output is one JSON object on stdout with exit status `0`.
A source, input, compilation, execution or comparison failure produces a JSON
error on stderr and exit status `1`. Argument usage errors use argparse's
message and exit status `2`. Do not interpret a missing result as success.

```sh
# Wrong input type: this must fail, not coerce true to 1.
python3 tools/loop/firth_run.py run examples/mvp/double.firth \
  --entry main --stack '[true]'

# Unknown entry: this must fail, not fall back to another word.
python3 tools/loop/firth_run.py run examples/mvp/double.firth \
  --entry missing --stack '[21]'
```

The default fuel budget is 4096 steps, which is also the largest budget the VM
adapter accepts: `--fuel` accepts an integer from 0 to 4096. Recursive
definitions are permitted, but exhausting the bound does not prove divergence
and is never accepted as a successful run; recursion deeper than 256
administrative frames traps with `resource-fault` on the VM alone, which is
reported as a mismatch rather than agreement. The VM and
reference interpreter report cost differently: VM word entry and capture
restoration carry administrative target charges, so reference cost is compared
with `kernel_cost`, not the larger `vm_cost`. Capture restoration still consumes
VM fuel; a zero kernel charge does not make a VM instruction free to execute.

Addition must stay within `0..9223372036854775807` for portable execution.
Overflow fails instead of wrapping. The reference interpreter's natural
numbers are unbounded; the finite VM's refusal is not evidence of agreement.

The comparison gate validates every returned scalar before comparing stacks.
It rejects malformed values, Boolean/integer payload coercions, and unsupported
quotation results. Quotations may still be created and consumed inside a
program, as in the conditional example above. This is not full quotation or
execution-trace equivalence.

## Supported execution profile

| Feature | Current portable runner |
| --- | --- |
| External inputs and final results | Non-negative integers through `9223372036854775807`, and Booleans |
| Source type name for integers | `Int`; the executable literal representation is currently non-negative |
| Primitive operations | `prim +` |
| Definitions | Explicit stack effects, multiple words, qualified vocabulary names, recursion with finite fuel |
| Composition | Core stack operations, quotations, `call`, `if`, named locals; matching checked effects are required |
| Quotations as external inputs/results | Explicitly rejected; returned bodies and captures do not yet have a shared comparison format |
| Negative integers, text and character execution | Not implemented by the portable compiler/adapters |
| `send`, file/network I/O, external resources | Not implemented by this portable execution path |
| Source refinement annotations `{...}` | Rejected with `firth.refinement.unsupported-source` until source predicates and bodies are translated and checked, even when the annotation happens to be true |
| Linear effects and pushed linear quotation values | Not supported by the portable compiler; unsupported ownership is rejected rather than erased |
| Core vocabulary | `stdlib/core.firth` contains identity, duplication, discard and exchange examples; it is not automatically imported |
| General-purpose standard library, package manager, editor language server | Future work |

In particular, the `send-once` example in the frozen agent guide describes the
intended linear-effect surface, not an executable network operation available
through `firth_run.py`. An unsupported primitive must be rejected by compilation.

## Source guarantees are not inferred from syntax

A word containing a refinement annotation is currently refused before erasure.
For example, `: main ( -- n:Int^many{n > 0} ) 0 ;` must not receive checked
artefacts. Returning `1` instead does not make source refinement checking
implemented: that annotated word is refused too. Write a plain typed word for
typed-only execution; do not remove a required contract merely to get a pass.
Empty source, including a vocabulary with no words, is a structured
`firth.elaboration.empty-program` failure.

The solver's internal unit/integration facilities do not establish that a
predicate written in source was translated or discharged. See the
[roadmap](roadmap.md) for the separate source-refinement implementation task.

## What a successful run establishes

The runner checks source, compiles the checked representation, and compares
successful terminal status, final stack and kernel-comparable cost with the
Lean reference interpreter. It bounds each execution and compares the two
traces event by event after projecting both onto kernel-charged steps: the
projected lengths and per-step charges must match, and when no intermediate
stack holds a quotation every stack must be equal (`trace_comparison:
agreed`). A program whose intermediate stacks hold quotations is labelled
`unsupported-quotation-values` instead, which is neither a failure nor a
claim of agreement. It does **not** compare residual programs or frames
across hosts, establish arbitrary effect agreement, a universal
compiler-correctness theorem or the business intent of the application.
Non-pure world observations are refused.

The low-level JSON adapters are internal pipeline boundaries. A string such
as `"checking_state":"checked"` is not an externally authenticated proof.
Use the source runner rather than constructing purported checked records by
hand. A successful `check` is not a security sandbox for untrusted host code.

For an agent, the working loop is: declare the stack effect, write a small
word, run `check`, run an explicit entry with representative inputs, and
inspect both the exit status and JSON. Preserve failing cases as tests. Never
replace an expected output just because the implementation produced another.

## Reproduce the checks

```sh
lake build
lake test
(cd src/runtime/vm && cargo fmt --check && \
  cargo clippy --locked --all-targets -- -D warnings && cargo test --locked)
python3 tools/loop/test_mvp_agent_gate.py
python3 tools/loop/test_mvp_agent_coverage.py
python3 tools/loop/mvp_agent_gate.py
python3 tools/loop/check_language_examples.py
```

`check_language_examples.py` exercises the examples, both conditional paths,
word ordering, row preservation, external input failures, a type error, fuel
exhaustion and overflow. It also invokes the documented check/run commands.
These fixtures test implementation behaviour; they are not presented as a
fresh independent-agent benchmark. The original four authored examples keep
their separate source and transcript provenance in the MVP manifest.

## Troubleshooting

**`lake` or `cargo` not found:** install elan/rustup, then ensure their binary
directories are on PATH in the shell running Python. Build from the repository
root so the checked-in toolchain pins apply.

**Proof-module hash unavailable or mismatched:** check the Lean pin and use a
clean build. Do not skip the check or regenerate the committed manifest merely
to get a passing result. An intentional change to governed proof modules needs
a reviewed rebuild and updated bindings under the repository's development
procedure.

**A word checks but does not compile:** compare its primitives and value types
with the portable support table. Parsing or checking a wider design feature
does not imply the VM adapter implements it.

**Fuel exhausted or VM/reference mismatch:** retain the source, inputs, entry,
fuel and diagnostic. Treat the run as failed. Do not weaken comparison to make
the example pass.

## Compiler trust boundary

See [compiler admission](compiler-admission.md) for source binding, direct
kernel checking and the distinction between content hashes and proof.

</document>

<document path="docs/firth-agent-guide.md">
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

</document>

Answer every task in this exact format, one block per task, and nothing that could be mistaken for one:

### task: <task id>
```firth
<source>
```

If you believe a task cannot be written with what is available, still give your best attempt, and add one line after the block starting `NOTE:`.

# Tasks

## triple
Return three times n.
Inputs on the stack, bottom to top: n: Int.
Outputs left on the stack, bottom to top: r: Int.
Example: stack [4] becomes [12].

## sum3
Return a + b + c.
Inputs on the stack, bottom to top: a: Int, b: Int, c: Int.
Outputs left on the stack, bottom to top: r: Int.
Example: stack [1, 2, 3] becomes [6].

## times10
Return ten times n.
Inputs on the stack, bottom to top: n: Int.
Outputs left on the stack, bottom to top: r: Int.
Example: stack [3] becomes [30].

## affine
Return 4*x + 7.
Inputs on the stack, bottom to top: x: Int.
Outputs left on the stack, bottom to top: r: Int.
Example: stack [1] becomes [11].

## pair-sum
Leave b and then a + b on the stack (a + b on top).
Inputs on the stack, bottom to top: a: Int, b: Int.
Outputs left on the stack, bottom to top: b: Int, s: Int.
Example: stack [2, 5] becomes [5, 7].

## select
If flag is true return a, otherwise return b.
Inputs on the stack, bottom to top: a: Int, b: Int, flag: Bool.
Outputs left on the stack, bottom to top: r: Int.
Example: stack [7, 9, true] becomes [7].

## not
Return the Boolean negation of p.
Inputs on the stack, bottom to top: p: Bool.
Outputs left on the stack, bottom to top: r: Bool.
Example: stack [true] becomes [false].

## and
Return p AND q.
Inputs on the stack, bottom to top: p: Bool, q: Bool.
Outputs left on the stack, bottom to top: r: Bool.
Example: stack [true, false] becomes [false].

## xor
Return p XOR q (true when exactly one is true).
Inputs on the stack, bottom to top: p: Bool, q: Bool.
Outputs left on the stack, bottom to top: r: Bool.
Example: stack [true, false] becomes [true].

## majority
Return true when at least two of p, q, r are true.
Inputs on the stack, bottom to top: p: Bool, q: Bool, r: Bool.
Outputs left on the stack, bottom to top: m: Bool.
Example: stack [true, false, true] becomes [true].

## count-true
Return how many of p, q, r are true, as an Int.
Inputs on the stack, bottom to top: p: Bool, q: Bool, r: Bool.
Outputs left on the stack, bottom to top: n: Int.
Example: stack [true, false, true] becomes [2].

## max
Return the larger of a and b.
Inputs on the stack, bottom to top: a: Int, b: Int.
Outputs left on the stack, bottom to top: r: Int.
Example: stack [3, 8] becomes [8].

## min3
Return the smallest of a, b and c.
Inputs on the stack, bottom to top: a: Int, b: Int, c: Int.
Outputs left on the stack, bottom to top: r: Int.
Example: stack [4, 2, 9] becomes [2].

## abs-diff
Return |a - b|.
Inputs on the stack, bottom to top: a: Int, b: Int.
Outputs left on the stack, bottom to top: r: Int.
Example: stack [3, 10] becomes [7].

## clamp
Return x limited to the range lo..hi (lo <= hi is guaranteed).
Inputs on the stack, bottom to top: x: Int, lo: Int, hi: Int.
Outputs left on the stack, bottom to top: r: Int.
Example: stack [15, 0, 10] becomes [10].

## is-even
Return true when n is even.
Inputs on the stack, bottom to top: n: Int.
Outputs left on the stack, bottom to top: r: Bool.
Example: stack [6] becomes [true].

## sum-to
Return 0 + 1 + ... + n.
Inputs on the stack, bottom to top: n: Int.
Outputs left on the stack, bottom to top: r: Int.
Example: stack [4] becomes [10].

## factorial
Return n! (0! = 1).
Inputs on the stack, bottom to top: n: Int.
Outputs left on the stack, bottom to top: r: Int.
Example: stack [4] becomes [24].

## fib
Return the n-th Fibonacci number, with fib(0) = 0 and fib(1) = 1.
Inputs on the stack, bottom to top: n: Int.
Outputs left on the stack, bottom to top: r: Int.
Example: stack [6] becomes [8].

## gcd
Return the greatest common divisor of a and b (both at least 1).
Inputs on the stack, bottom to top: a: Int, b: Int.
Outputs left on the stack, bottom to top: r: Int.
Example: stack [12, 18] becomes [6].

## power
Return base raised to exp (0^0 = 1).
Inputs on the stack, bottom to top: base: Int, exp: Int.
Outputs left on the stack, bottom to top: r: Int.
Example: stack [3, 4] becomes [81].

## collatz-steps
Return how many Collatz steps it takes n (n >= 1) to reach 1: halve even numbers, map odd n to 3n + 1.
Inputs on the stack, bottom to top: n: Int.
Outputs left on the stack, bottom to top: r: Int.
Example: stack [6] becomes [8].

