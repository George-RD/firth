You are writing programs in Firth, a new stack language. You have never seen it before; everything you know about it is in the documentation below. Programs are run with the portable runner described in 'Getting started', so only what that runner supports will execute.

For each task, write a complete Firth source file whose entry word is named `main`. Helper words are allowed. Each run may take up to 1,000,000 steps.

Do not use any tool except reading this prompt file and writing your answer file, and do not use the internet. After you answer, you will be shown how each answer did on its task's example: the result, or the diagnostics if it failed. You may then fix your answers; there is at most 1 such round.

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
input is the top of the stack. Names such as `n` and `result` only document
the stack: they are not variables, and writing `n` in the body is an
unresolved name. The body works on the stack itself. To refer to inputs by
name, bind them with `locals`, which takes one value off the stack for each
name, the last name from the top:

```firth
: difference
  (forall ρ; ρ a:Int^many b:Int^many -- ρ r:Int^many)
  locals { a b } { a b prim - };
```

Inside the second braces, `a` and `b` can be used any number of times. The
result is whatever the block leaves on the stack; `r` is never assigned.
The names follow the stack effect from left to right, so the top input is the
last name. A block that opens the body and uses the stack effect's names in
another order, such as `locals { b a }` here, is refused with
`firth.name.locals-order`: it would give `b` the value the effect calls `a`.

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

## Saved regression tests

The same public runner can check saved input/output cases against both the VM
and reference interpreter:

```sh
python3 tools/loop/firth_run.py test examples/mvp/choose-increment.tests.json
```

A suite uses the following format. `source` is relative to the suite file,
not the current working directory. Every case names its entry explicitly.

```json
{
  "schema": "firth.tests.v1",
  "source": "choose-increment.firth",
  "cases": [
    {"name": "increment when true", "entry": "main", "stack": [41, true], "expected_stack": [42]},
    {"name": "keep value when false", "entry": "main", "stack": [41, false], "expected_stack": [41]},
    {"name": "call helper directly", "entry": "increment", "stack": [9], "expected_stack": [10]}
  ]
}
```

A suite must have 1 to 128 cases with unique non-empty names, fit within
1,048,576 UTF-8 bytes, and use at most 256 values per input or expected stack.
Both stacks use the portable integers, Booleans and sequences listed below;
`true` never matches `1`. Unknown or duplicate JSON fields, invalid values and empty suites
are rejected before a build. Absolute source paths are not accepted. Relative
paths such as `../src/component.firth` are supported.

The toolchain builds once per suite. Each case then checks and compiles the
source in a separate scratch workspace, compares both hosts, and checks the
expected stack. A failure does not skip later cases. `--fuel` has the same
bounds as `run` and applies separately to every case. Exhaustion is a failure,
not a passing test. Version 1 does not support expected-error cases or skips.

A completed suite prints one `firth.test-results.v1` JSON report to stdout with
`status`, `passed`, `failed` and ordered `cases`. Its exit code is `0` only when
all cases pass, otherwise `1`. Invalid input or a setup/build failure instead
prints a JSON error to stderr and exits `1`; command usage errors exit `2`.
Each completed execution retains its `trace_comparison` label. A matching
expected stack does not upgrade unsupported quotation-trace comparison to
agreement, prove a source contract or establish compiler correctness.

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

The default fuel budget is 100,000 steps, and `--fuel` accepts an integer from
0 to 1,000,000 (the largest budget the VM adapter accepts). Each host records
only the first 4096 trace events; later steps still run and are charged, the
final stack and kernel cost are compared in full, and the trace comparison is
then reported as `agreed-prefix` rather than `agreed`. Recursive
definitions are permitted, but exhausting the bound does not prove divergence
and is never accepted as a successful run. A call in last position (a word
call, `call` or `if` as the final instruction of a word or quotation body) is a
tail call: it reuses the current frame, so loops written as tail recursion run
until fuel rather than hitting a depth limit. Non-tail recursion deeper than
256 administrative frames traps with `resource-fault` on the VM alone, which is
reported as a mismatch rather than agreement. Quotations that own linear
captures keep their own frame. See `examples/programs/` for loops, factorial,
Fibonacci and an allocator that run on both hosts. The VM and
reference interpreter report cost differently: VM word entry and capture
restoration carry administrative target charges, so reference cost is compared
with `kernel_cost`, not the larger `vm_cost`. Capture restoration still consumes
VM fuel; a zero kernel charge does not make a VM instruction free to execute.

Integers are signed: `-3` is a literal and `3 5 prim -` is `-2`. `prim +`,
`prim -` and `prim *` must stay within the signed 64-bit range
(`-9223372036854775808..9223372036854775807`) for portable execution; overflow
fails instead of wrapping. `prim <`, `prim <=`, `prim >`, `prim >=` and
`prim =` take two integers and push a Boolean for `if`: `a b prim <=` is
whether `a` is at most `b`, so `3 3 prim <=` is `true` and `3 3 prim <` is
`false`. `prim and`, `prim or` and `prim not` combine Booleans.
`prim div` and `prim mod` are Euclidean: `a b prim div` is the quotient `q`
and `a b prim mod` the remainder `r` with `a = b*q + r` and `0 <= r < |b|`, so
`-7 2 prim div` is `-4` and `-7 2 prim mod` is `1`. A zero divisor traps with
`primitive-fault` on both hosts, and `-9223372036854775808 -1 prim div`
overflows on the VM like `prim *`. The reference interpreter's integers are unbounded; the
finite VM's refusal is not evidence of agreement.

The comparison gate validates every returned scalar before comparing stacks.
It rejects malformed values, Boolean/integer payload coercions, and unsupported
quotation results. Quotations may still be created and consumed inside a
program, as in the conditional example above. This is not full quotation or
execution-trace equivalence.

## Supported execution profile

| Feature | Current portable runner |
| --- | --- |
| External inputs and final results | Signed 64-bit integers, Booleans, and sequences of either as JSON arrays (`[1, 2]` is a `Seq Int`, `[true]` a `Seq Bool`; `[]` takes its type from the word's signature) |
| Source type name for integers | `Int`, signed; literals may be negative (`-3`) |
| Primitive operations | `prim +`, `prim -`, `prim *`, `prim div`, `prim mod` : `Int Int -- Int` (`div` and `mod` trap on a zero divisor); `prim <`, `prim <=`, `prim >`, `prim >=`, `prim =` : `Int Int -- Bool`; `prim and`, `prim or` : `Bool Bool -- Bool`; `prim not` : `Bool -- Bool`; `prim seq-int.empty`, `.len`, `.at`, `.push`, `.set` and the same for `seq-bool` (see `examples/programs/README.md`) |
| Sequences | `Seq Int` and `Seq Bool`, written `{ 1 2 3 }` or `{ true false }`; a negative or out-of-range `at` or `set` index traps with `primitive-fault` on both hosts |
| Definitions | Explicit stack effects, multiple words, qualified vocabulary names, recursion with finite fuel |
| Composition | Core stack operations, quotations, `call`, `if`, named locals (a block takes its values off the stack; a local may be used any number of times, inside `if` branches, inside quotations and inside nested blocks. A local can't be used after running a quotation whose stack effect is unknown there, such as one passed in as a value; that is refused with `firth.elaboration.untracked-local`); matching checked effects are required |
| Quotations as external inputs/results | Explicitly rejected; returned bodies and captures do not yet have a shared comparison format |
| Text and character execution | Not implemented by the portable compiler/adapters |
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
python3 tools/loop/mvp_agent_gate.py
python3 tools/loop/check_language_examples.py
```

`check_language_examples.py` exercises the examples, both conditional paths,
word ordering, row preservation, external input failures, a type error, fuel
exhaustion and overflow. It also invokes the documented check/run/test commands
and runs saved suites covering expected results, typed mismatches and failure
continuation.
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

A refused program gets one diagnostic for each word the checker refuses: that
word's first error, found by checking the word against the declared stack
effects of the words it calls, whatever their bodies do. So two mistakes in two
words are reported together, and fixing one never hides or moves the other. Its
`message_params.word` names the word. A word that calls one whose declared
effect is not a valid signature (`firth.type.invalid-signature`) is not
type-checked, and is reported as `firth.type.unchecked-word` at that call, so
it is never taken for a checked word; its own errors show once that signature
is fixed. When a word's report depends on the declared effect of a word it
calls that is itself reported, the message ends by saying so ("`g` calls `f`,
which has an error of its own; this report assumes `f` keeps its stack
effect."), and `message_params.assumes` lists those words: if the fix for `f`
is to its stack effect rather than its body, `g`'s report can change or go.
The checker tests this: it checks `g` again with other effects for `f` (four
fixed ones, and `f`'s own with other types: all of them, only the outputs',
and each one alone), and names `f` when one of them changes the report once
checking gets as far as it. A report none of them
changes, such as an underflow at `g`'s own `locals`, has no sentence; nor has
one that another effect only stops the check before, such as a report about
the branch of an `if` that does not call `f`. When only the edit a hint offers was
checked against `f`'s effect (the edited word calls `f`, and erasure, which
reads the shape of every call, did not stop before that call), the hint ends
by saying so ("That edit was
checked assuming `f`, which has an error of its own, keeps its stack
effect."), and `message_params.edit_assumes` lists those words.
A syntax error, a duplicate name or a `use` that names no vocabulary in the
file or reuses an alias ends the file there: the words before a bad `use` are still reported.
Each diagnostic in one response has its own payload identifier.

The diagnostic loop is:

1. Submit one source request with a fresh request identifier.
2. Parse every returned envelope and reject protocol-invalid payloads.
3. Sort valid diagnostics with the specified key.
4. Apply only a proposed fix whose applicability is accepted by the caller.
5. Fix every reported word, re-elaborate, and repeat until success or a
   non-success obligation remains.

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

<document path="examples/programs/README.md">
# Example programs

Small programs that use arithmetic, comparison, conditionals, tail-recursive
loops and sequences. `check_programs.py` runs every case in `cases.json` through the checker
and compiler, then on both the VM and the reference interpreter, and fails
unless both hosts agree and produce the expected stack.

```sh
python3 examples/programs/check_programs.py
python3 tools/loop/firth_run.py run examples/programs/factorial.firth --entry fact --stack '[5]'
```

## Primitives

Integers are signed 64-bit values; a literal may be negative (`-3`).

```
a b prim +    \ Int Int -- Int
a b prim -    \ Int Int -- Int   (3 5 prim - gives -2)
a b prim *    \ Int Int -- Int
a b prim div  \ Int Int -- Int   (Euclidean quotient: -7 2 prim div gives -4)
a b prim mod  \ Int Int -- Int   (Euclidean remainder, never negative: -7 2 prim mod gives 1)
a b prim <    \ Int Int -- Bool   (a less than b)
a b prim <=   \ Int Int -- Bool   (a at most b: 3 3 prim <= gives true)
a b prim >    \ Int Int -- Bool   (a greater than b)
a b prim >=   \ Int Int -- Bool   (a at least b)
a b prim =    \ Int Int -- Bool
p q prim and  \ Bool Bool -- Bool
p q prim or   \ Bool Bool -- Bool
p prim not    \ Bool -- Bool
flag [ then-branch ] [ else-branch ] if
```

A result that does not fit a signed 64-bit integer traps on the VM.

`<=` differs from `<`, and `>=` from `>`, only at equal values, so check
that case: `3 3 prim <=` and `3 3 prim >=` give `true`, `3 3 prim <` and
`3 3 prim >` give `false`. `comparisons.firth` checks that a sequence never
decreases, counts the elements in a range, finds the largest element and the
index of its first occurrence, and clamps a value.

`div` and `mod` satisfy `a = b*q + r` with `0 <= r < |b|`, as Lean's `Int./`
and `Int.%`. A zero divisor traps with `primitive-fault` on both hosts.
`division.firth` has a quotient-and-remainder word, a decimal digit sum and
Euclid's greatest common divisor.

## Loops

A loop is a word that calls itself as its last action, directly or as the last
action of an `if` branch. The VM runs such a call in the caller's frame, so the
loop is bounded by the step budget (100,000 steps per run by default, up to
1,000,000 with `--fuel`), not by call depth. `sum-to` at 7000 takes about
91,000 kernel steps. Its trace comparison is `unsupported-quotation-values`
(every loop runs `if` on quotation branches), so it does not exercise the
`agreed-prefix` path, which the gate's unit tests cover.
A recursive call followed by more work still nests and traps past 256 frames.

## Locals

`locals { a b } { ... }` names the top values. Inside the block a name can be
used any number of times, inside `if` branches, and inside quotations (the
value is captured when the quotation is built). `locals.firth` has factorial,
Fibonacci and an allocation step written this way. A `locals` block nested
inside a quotation can use the outer block's names too.

A block takes its values off the stack: in `locals { a } { swap }` the
`swap` exchanges the two values below `a` (`swap-below`).

The last name takes the top value, so a block that opens a word's body lists
the inputs in the stack effect's order. Using the effect's names in another
order is refused with `firth.name.locals-order`, which says what each name
would have held.

A local can't be used after `call`, `dip` or `if` runs a quotation whose stack
effect isn't known at that point: a quotation passed in as a value, one
returned by another quotation, or `[ call ]` itself. The checker can't tell
where the local sits afterwards, so it refuses the program with
`firth.elaboration.untracked-local` rather than guess. Quotations written
inline, like `[ 1 prim + ] call` or `[ 1 prim + ] [ ] compose call`, are fine
(`quotations.firth`). An `if` whose two branches leave different numbers of
values is a type error, reported as `firth.type.branch-mismatch` at that
`if`, however deeply it is nested and whatever follows it
(`refused/if-branch-shape.firth`). Where it can follow the word's body, the
report names each value by the source that pushed it (a local, a literal, an
input, or the result of an operation) and says either which operation in a
branch takes a value the branch did not push, or what each branch leaves. The
programs under `refused/` must be rejected.

## Sequences

`Seq Int` and `Seq Bool` hold any number of integers or Booleans. They are
ordinary values: a sequence can be used any number of times, and `push` and
`set` return a new one. `sequences.firth` sums, counts, builds a range and
indexes. `sieve.firth` finds primes with a sieve of Eratosthenes that clears
entries in place, and `sort.firth` sorts by insertion, swapping neighbours
with `set`.

```
{ 1 2 3 }                  \ -- Seq Int      (a literal; { true false } is a Seq Bool)
prim seq-int.empty         \ -- Seq Int
xs prim seq-int.len        \ Seq Int -- Int
xs i prim seq-int.at       \ Seq Int Int -- Int
xs x prim seq-int.push     \ Seq Int Int -- Seq Int
xs i x prim seq-int.set    \ Seq Int Int Int -- Seq Int   (element i becomes x)
```

`seq-bool.empty`, `.len`, `.at`, `.push` and `.set` are the same for
`Seq Bool`. A negative index, or one at or past the length, traps with
`primitive-fault` on both hosts; `at` never returns a default and `set`
never grows the sequence. A case with `expect_trap` checks that: both hosts
must stop with that trap at the same stack and kernel cost. `{ }` is refused
because it has no element type; write `prim seq-int.empty`. On the command
line and in `cases.json` a sequence is a JSON array, and `[]` takes its type
from the word's signature:

```sh
python3 tools/loop/firth_run.py run examples/programs/sequences.firth --entry sum --stack '[[4, 5, 6]]'
```

## Limits

- `allocate.firth` is one step of `specs/inventory-allocation.md`; the whole
  batch is `examples/inventory/`.
- The trace comparison reports `unsupported-quotation-values` for these
  programs, because `if` puts quotations on the stack. Final stacks, costs and
  trace lengths are still compared.

</document>

Answer every task in this exact format, one block per task, and nothing that could be mistaken for one:

### task: <task id>
```firth
<source>
```

If you believe a task cannot be written with what is available, still give your best attempt, and add one line after the block starting `NOTE:`.

# Tasks

## bowling
rolls lists the pins knocked down by each roll of one complete, valid game of ten-pin bowling. A game has ten frames. In frames 1 to 9, a first roll of 10 is a strike and ends the frame; otherwise the frame has two rolls. A frame scores its pins plus a bonus: after a strike, the pins of the next two rolls; after a spare (two rolls in one frame totalling 10), the pins of the next roll. The tenth frame has a third roll only when its first two rolls make a strike or a spare; those extra rolls count once, as the tenth frame's bonus. Return the running total after each frame (ten numbers).
Inputs on the stack, bottom to top: rolls: Seq Int.
Outputs left on the stack, bottom to top: totals: Seq Int.
Example: stack [{ 10 7 3 9 0 10 0 8 8 2 0 6 10 10 10 8 1 }] becomes [{ 20 39 48 66 74 84 90 120 148 167 }].

## lru
A cache holds at most cap distinct keys (cap is at least 1). Process keys in order. If a key is in the cache, it is a hit and becomes the most recently used key. Otherwise it is a miss: if the cache already holds cap keys, the least recently used key is removed first, then the key is added as the most recently used. The cache starts empty. Return the number of misses and the keys left in the cache, from least to most recently used. keys has at most 60 elements.
Inputs on the stack, bottom to top: cap: Int, keys: Seq Int.
Outputs left on the stack, bottom to top: misses: Int, cache: Seq Int.
Example: stack [2, { 1 2 1 3 2 }] becomes [4, { 3 2 }].

## rpn
Evaluate a program for a stack calculator. Token i is kinds[i] and vals[i] (the two sequences have the same length). Kinds: 0 pushes vals[i]; 1 to 4 pop b (the top), then a, and push a + b, a - b, a * b, or a divided by b with the quotient rounded toward zero (-7 and 2 give -3); 5 pushes a copy of the top value. vals[i] is used only by kind 0. Stop at the first error. Return (result, status): status 1 when a token needs more values than the calculator's stack holds, 2 when a division has b = 0, and, after the last token, 3 when the stack does not hold exactly one value. With status 1, 2 or 3, result is 0. Otherwise status is 0 and result is the one value left.
Inputs on the stack, bottom to top: kinds: Seq Int, vals: Seq Int.
Outputs left on the stack, bottom to top: result: Int, status: Int.
Example: stack [{ 0 0 0 3 1 }, { 2 3 4 0 0 }] becomes [14, 0].

## edit-cost
Return the least total cost of turning xs into ys with these edits: inserting one element costs insert, deleting one costs delete, and replacing one element with a different value costs replace. insert, delete and replace are each at least 1. Each sequence has at most 25 elements.
Inputs on the stack, bottom to top: xs: Seq Int, ys: Seq Int, insert: Int, delete: Int, replace: Int.
Outputs left on the stack, bottom to top: cost: Int.
Example: stack [{ 1 2 3 }, { 1 3 4 }, 1, 1, 1] becomes [2].

## shortest-hops
A directed graph has nodes 0 to n - 1 and edges froms[k] -> tos[k] of weight weights[k] (the three sequences have the same length; weights are 0 or more; there can be several edges between two nodes). For every node, find the least total weight of a path from source to it and, among the paths with that weight, the fewest edges. Return both as sequences of length n: dist[v] and hops[v], each -1 when v cannot be reached. The source has distance 0 and 0 hops. n is at most 12 and there are at most 40 edges.
Inputs on the stack, bottom to top: n: Int, froms: Seq Int, tos: Seq Int, weights: Seq Int, source: Int.
Outputs left on the stack, bottom to top: dist: Seq Int, hops: Seq Int.
Example: stack [4, { 0 0 1 2 }, { 1 2 3 3 }, { 1 4 1 1 }, 0] becomes [{ 0 1 4 2 }, { 0 1 1 2 }].

## merge-ranges
Range k covers the whole numbers from starts[k] to ends[k], both included (the two sequences have the same length, and starts[k] <= ends[k]); the ranges are in no particular order. Merge ranges that overlap or are next to each other (as 1 to 3 and 4 to 6 are) until no two of them do. Return the merged ranges' starts and ends, ordered by start, and how many whole numbers they cover in all. There are at most 30 ranges.
Inputs on the stack, bottom to top: starts: Seq Int, ends: Seq Int.
Outputs left on the stack, bottom to top: merged-starts: Seq Int, merged-ends: Seq Int, covered: Int.
Example: stack [{ 8 1 4 15 }, { 10 3 6 15 }] becomes [{ 1 8 15 }, { 6 10 15 }, 10].

## tiny-vm
Run a program for a machine with four registers r[0] to r[3], which start as regs. Instruction i is code[3i], code[3i+1], code[3i+2]: an operation op and two operands a and b (code's length is a multiple of 3; a register operand is always 0 to 3). Operations: 0 halts; 1 sets r[a] to b; 2 adds r[b] to r[a]; 3 subtracts r[b] from r[a]; 4 multiplies r[a] by r[b]; 5 copies r[b] into r[a]; 6 jumps to instruction b if r[a] is not 0; 7 jumps to instruction b if r[a] is less than 0. Execution starts at instruction 0 and otherwise goes to the next instruction. Before each instruction: if its number is not between 0 and the number of instructions minus 1, stop with status 1; otherwise, if limit instructions have already been executed, stop with status 2. Executing a halt stops with status 0. Return the registers, the number of instructions executed (a halt counts) and the status. limit is at most 300.
Inputs on the stack, bottom to top: code: Seq Int, regs: Seq Int, limit: Int.
Outputs left on the stack, bottom to top: regs-out: Seq Int, executed: Int, status: Int.
Example: stack [{ 1 0 5 1 1 1 1 2 1 4 1 0 3 0 2 6 0 3 0 0 0 }, { 0 0 0 0 }, 100] becomes [{ 0 120 1 0 }, 19, 0].

## lis-smallest
Return a longest strictly increasing subsequence of xs (elements in their original order, not necessarily next to each other, each greater than the one before). When there are several, return the one whose values are smallest in dictionary order: the smallest first value, then among those the smallest second value, and so on. xs has at most 30 elements.
Inputs on the stack, bottom to top: xs: Seq Int.
Outputs left on the stack, bottom to top: lis: Seq Int.
Example: stack [{ 5 1 6 2 7 3 }] becomes [{ 1 2 3 }].
