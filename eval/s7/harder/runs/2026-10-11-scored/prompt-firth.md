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

A program with imports is loaded from the source file's directory. `--root DIR`
(accepted by `check`, `run` and `test`) names another source root, for imports
that use `..` to reach files above it.

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

| Feature | Current portable runner | Checked by |
| --- | --- | --- |
| External inputs and final results | Signed 64-bit integers, Booleans, and sequences of either as JSON arrays (`[1, 2]` is a `Seq Int`, `[true]` a `Seq Bool`; `[]` takes its type from the word's signature) | `sequences.firth` cases, including `[[]]` for `sum` and `count`; `test_firth_run.py` (`test_only_exact_portable_values_are_allowed_in_both_stacks`, `test_sequences_are_arrays_of_one_element_type`); `test_mvp_agent_gate.py` (`test_input_values_distinguish_booleans_from_integers`, `test_input_integers_cover_the_signed_64_bit_range`) |
| Source type name for integers | `Int`, signed; literals may be negative (`-3`) | `signed.firth` and `division.firth` cases |
| Primitive operations | `prim +`, `prim -`, `prim *`, `prim div`, `prim mod` : `Int Int -- Int` (`div` and `mod` trap on a zero divisor); `prim <`, `prim <=`, `prim >`, `prim >=`, `prim =` : `Int Int -- Bool`; `prim and`, `prim or` : `Bool Bool -- Bool`; `prim not` : `Bool -- Bool`; `prim seq-int.empty`, `.len`, `.at`, `.push`, `.set` and the same for `seq-bool` (see `examples/programs/README.md`) | `division.firth`, `comparisons.firth`, `booleans.firth`, `sequences.firth`, `sort.firth` (`seq-int.set`) and `sieve.firth` (`seq-bool.empty`, `seq-bool.set`) cases, with `refused/bool-plus.firth`; `tail_calls.rs` (`a_zero_divisor_faults` for `div` and `mod`, `comparisons_order_every_pair_of_edge_integers`, `boolean_primitives_match_the_reference_definitions`); overflow cases in `check_language_examples.py` |
| Sequences | `Seq Int` and `Seq Bool`, written `{ 1 2 3 }` or `{ true false }`; a negative or out-of-range `at` or `set` index traps with `primitive-fault` on both hosts | `sequences.firth` trap cases (`element` and `third` for `Seq Int`, `flag` and `clear-flag` for `Seq Bool`), `signed.firth` trap cases, `sort.firth` `replace` trap cases; `tests_fixtures.rs` (`sequence_indexes_past_the_end_fault_at_every_magnitude`, `set_outside_the_sequence_faults_at_every_magnitude`) |
| Definitions | Explicit stack effects, multiple words, qualified vocabulary names, recursion with finite fuel | `factorial.firth` and `fib.firth` cases; `qualified-call.firth` in `check_language_examples.py`; `refused/if-branch-shape.firth`, `refused/reserved-type-name.firth`; the `fuel-exhausted` case in `check_language_examples.py` |
| Composition | Core stack operations, quotations, `call`, `if`, named locals (a block takes its values off the stack; a local may be used any number of times, inside `if` branches, inside quotations and inside nested blocks. A local can't be used after running a quotation whose stack effect is unknown there, such as one passed in as a value; that is refused with `firth.elaboration.untracked-local`); matching checked effects are required | `locals.firth`, `quotations.firth` and `nested-loop.firth` cases; `refused/call-unknown-effect.firth`, `refused/dip-unknown-effect.firth`, `refused/nested-quotation-result.firth` |
| Quotations as external inputs/results | Explicitly rejected; returned bodies and captures do not yet have a shared comparison format | `test_portable_observations.py` (`test_quotation_results_are_explicitly_unsupported`); a quotation-shaped input in `test_firth_run.py` |
| Text and character execution | Not implemented by the portable compiler/adapters | `refused/text-literal.firth`, `refused/char-literal.firth` |
| `send`, file/network I/O, external resources | Not implemented by this portable execution path | `refused/send.firth` |
| Source refinement annotations `{...}` | Rejected with `firth.refinement.unsupported-source` until source predicates and bodies are translated and checked, even when the annotation happens to be true | `check_trust_boundaries.py` (`firth.refinement.unsupported-source`) |
| Linear effects and pushed linear quotation values | Not supported by the portable compiler; unsupported ownership is rejected rather than erased | `check_compiler_admission.py` (linear kernel cases and a forged linear quotation push) |
| Multi-file programs | `import "path.firth";` first in a file, then `export name ...;` to offer words; paths are relative to the importing file and stay inside the source root; an importer sees the exported words of its direct imports only; one program is one dictionary, so two files defining one name are refused; files load imports first, the root last, and cycles are refused | `FirthImportsTest.lean` (load order, a known-bad program for each import refusal, the loader's source-root refusals, the compiler's binding of imported files); `examples/inventory/policy_change.py` (both clients import `allocator.firth`); `test_firth_run.py` (`test_a_suite_source_resolves_its_imports_under_the_given_root`); `test_mvp_agent_gate.py` (`test_rebuild_passes_imported_files_to_elaborate_and_compile`) |
| Core vocabulary | `stdlib/core.firth` exports its words (`export core.identity ...`); a program imports it by a relative path and then writes `use core;`. It is not automatically imported | `FirthPipelineTest.lean` (elaborates `stdlib/core.firth` and checks each word's lowered body); `refused/core-not-imported.firth`; the `use` and `use as` cases in `FirthImportsTest.lean` import a vocabulary of the same shape, not `stdlib/core.firth` itself |
| General-purpose standard library, package manager, editor language server | Future work | Not applicable: nothing is offered |

In the "Checked by" column, a `.firth` name, unless another check is named
with it, is a program whose cases are in `examples/programs/cases.json` and
are run on both hosts by `examples/programs/check_programs.py`; those under
`refused/` must be refused with the diagnostic code in their case's
`expect_error` field. The Python checks are in `tools/loop/`, the Lean tests
in `src/`, and the Rust tests in `src/runtime/vm/`. A row's checks cover what
the row promises or refuses; they are tests, not proofs.

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

A source file contains imports, vocabulary declarations, `use` declarations,
exports and word definitions:

```text
import "<path>.firth";
export <name> ...;
vocab <name> { ... }
use <vocabulary> [as <alias>];
: <word-name> <stack-effect> <body>;
```

The outer file is an implicit vocabulary. Within its file a word declared in a
vocabulary is visible from every vocabulary by its qualified name, but a word
declared outside any vocabulary is visible only outside them. Other files see a
word only if it is exported (below). A qualified reference is resolved by its canonical name.
An unqualified reference is accepted only when exactly one visible candidate
exists. Ambiguous or missing names are errors. Definitions in one vocabulary are visible
throughout that vocabulary, so recursive words may be declared without textual
forward declarations.

A program may span files. `import` lines come first, and the path is relative
to the importing file's directory (letters, digits, `.`, `_`, `-`, `/`, ending
in `.firth`; `..` is allowed but may not leave the source root). Inside a file
words are visible as described above. Across files only words listed in
`export` are visible, and only from files you import directly: imports are not
transitive.

```text
\ lib/math.firth
export twice;
: twice (forall ρ; ρ n:Int^many -- ρ r:Int^many) dup prim +;

\ main.firth
import "lib/math.firth";
: main ( -- r:Int^many ) 21 twice;
```

An imported word keeps its own canonical name, with no file prefix, and the
whole program is one dictionary. Two files that define the same name are
refused (`firth.name.duplicate-canonical`), even if neither exports it. So wrap
a library's helper words in a `vocab` (export `util.helper`, then `use util;`),
or keep top-level names distinct. Calling an unexported word gives
`firth.name.not-exported`.

Files load once each, imports first, the root last; cycles are refused. Each
file is checked on its own. An error in an imported file is reported with that
file's path, and the importer gets `firth.name.import-failed` at the import
instead of being checked. Fix the imported file first.

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
file or reuses an alias ends that file there: the words before a bad `use` are still reported.
An imported file that ends this way is reported under its own path, and each
file that imports it gets `firth.name.import-failed`.
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

## sokoban
Play moves in a warehouse puzzle and report what happened. The floor is a grid of width columns and height rows; cell (row r, column c) is number r times width plus c, and cells[i] is 0 for floor, 1 for wall and 2 for a goal (a goal is also floor). The worker stands on cell player, and boxes lists the cells holding boxes: box k starts on boxes[k]. Each move is 0 up (to the cell width lower in number), 1 right (one higher), 2 down (width higher), 3 left (one lower) or 4 undo. Read the moves in order. Before reading each move, the first one included, if every box is on a goal, stop: the puzzle is solved and the moves not yet read are not used. A move in a direction looks at the next cell t that way from the worker. If t is a wall, the move is blocked and nothing changes. If t holds a box, look at the cell u beyond it in the same direction: if u is a wall or holds a box, the move is blocked; otherwise the box moves to u and the worker to t, which is a push. Otherwise the worker moves to t, which is a step. A push or a step is recorded in the history, the latest last; a blocked move is not. A pushed box is dead if, after the push, it is not on a goal, has a wall above or below it, and also has a wall to its left or right. An undo takes back the latest move in the history and removes it from the history: the worker moves back the way it came, and if that move was a push, its box moves back too. An undo with an empty history does nothing. Return the worker's final cell, the final cell of each box (in the order of boxes), the number of moves read, the number of moves left in the history, the number of pushes made (an undone push still counts), the number of blocked moves, the number of undos that took a move back, the number of pushes that left a box dead (again counting undone ones), and whether every box is on a goal at the end. width and height are 3 to 12; cells has width times height values, each 0 to 2, and every cell in the first or last row or column is a wall; player and every value of boxes are cells that are not walls, boxes has 1 to 6 values, and no two of player and the boxes are the same cell; moves has at most 200 values, each 0 to 4.
Inputs on the stack, bottom to top: width: Int, height: Int, cells: Seq Int, player: Int, boxes: Seq Int, moves: Seq Int.
Outputs left on the stack, bottom to top: player: Int, boxes: Seq Int, read: Int, history: Int, pushes: Int, blocked: Int, undos: Int, dead: Int, solved: Bool.
Example: stack [6, 5, { 1 1 1 1 1 1 1 0 0 0 0 1 1 0 0 0 0 1 1 0 0 0 2 1 1 1 1 1 1 1 }, 9, { 15 }, { 2 1 2 3 3 4 4 0 3 3 4 1 1 }] becomes [16, { 21 }, 13, 6, 3, 1, 3, 1, false].

## checkers
Play draughts on an 8 by 8 board, both sides moving by a fixed rule, and report the result. Only the 32 dark squares are used, numbered 0 to 31: square i is in row r = i divided by 4, rounded down (row 0 at the top), and in column 2 times (i mod 4), plus 1 when r is even. board[i] is 0 for empty, 1 for a white man, 2 for a white king, 3 for a black man and 4 for a black king. White men move up (towards row 0) and black men down; kings move both ways. A step moves a piece to an empty square diagonally next to it, in a direction it may move. A jump moves a piece over a diagonally next square holding a piece of the other side, in a direction it may move, to the empty square just beyond; the piece jumped over is taken off the board at once, and the square the capturing piece started from counts as empty during the capture, so it may land there. A capture is a sequence of jumps by one piece: after each jump, if that piece can jump again from where it landed, it must, and a capture is complete only when it cannot, except that a man that lands on the far row (row 0 for white, row 7 for black) is crowned king and its capture ends there. A man that steps onto its far row is crowned too. The side to move must capture if any of its pieces can; then it plays the complete capture that takes the most pieces, choosing among equals the one whose piece starts on the lowest-numbered square, then the one whose list of landing squares, read in order, is lower at the first place the lists differ, whatever its last landing. If it cannot capture it makes the step whose piece starts on the lowest-numbered square, and among those the step to the lowest-numbered square. White moves first if turn is 0 and black if turn is 1, then the sides alternate. Before each move, if the side to move has no capture or step, it has lost and play stops; otherwise, if plies moves have been played, play stops; otherwise it moves. So a side with no move when the limit is reached has still lost. Return the final board, the number of moves played, the number of pieces white took, the number black took, the number of men crowned (by a step or at the end of a capture, on either side), and the result: 1 if white won, 2 if black won, 0 if play stopped at the move limit. board has 32 values, each 0 to 4, with at most 12 pieces of each side, no white man on row 0 and no black man on row 7; turn is 0 or 1; plies is 1 to 40.
Inputs on the stack, bottom to top: board: Seq Int, turn: Int, plies: Int.
Outputs left on the stack, bottom to top: board: Seq Int, played: Int, white_took: Int, black_took: Int, crowned: Int, result: Int.
Example: stack [{ 0 0 0 0 0 0 0 0 0 0 3 0 0 0 0 0 3 3 0 0 0 0 0 0 3 0 0 0 1 0 0 0 }, 0, 2] becomes [{ 0 0 0 0 0 0 0 1 0 0 0 0 0 0 0 0 0 0 0 0 3 0 0 0 0 0 0 0 0 0 0 0 }, 2, 3, 0, 0, 0].

## regex
Match strings against a regular expression given as tokens. Token 0 to 25 is that letter; 26 is '.', matching any one letter; 27 '*', 28 '+' and 29 '?' are postfix operators; 30 is '|'; 31 '(' and 32 ')'. The pattern's grammar: an alternation is one or more sequences separated by '|'; a sequence is zero or more items, one after another; an item is an atom followed by zero or more postfix operators; an atom is a letter, '.', or '(' alternation ')'. The whole pattern is one alternation. A postfix operator applies to its item's atom together with any operators already after it, so ab* repeats only the b and (a*)? is a*?: '*' matches zero or more repeats, '+' one or more, '?' zero or one. A sequence matches its items one after another (an empty sequence matches the empty string), and an alternation matches if any of its sequences does. A pattern that does not fit the grammar, such as one with an operator where an atom should start, a '(' never closed or a ')' with no '(' open, is invalid. The strings are given together: string j has lens[j] letters, and chars holds every string's letters, string 0 first. For each string, return whether the whole string matches the pattern, and the length of the longest start of it (from no letters up to all of them) that matches, or -1 if none does. Also return how many strings match whole and whether the pattern is valid; for an invalid pattern every string gives false and -1, the count is 0 and validity is false. pattern has at most 20 tokens, each 0 to 32; lens has 1 to 8 values, each 0 to 12, adding up to the length of chars; every value of chars is 0 to 25.
Inputs on the stack, bottom to top: pattern: Seq Int, lens: Seq Int, chars: Seq Int.
Outputs left on the stack, bottom to top: full: Seq Bool, longest: Seq Int, count: Int, valid: Bool.
Example: stack [{ 0 27 1 30 31 2 3 32 28 }, { 3 2 4 0 3 1 3 }, { 0 0 1 2 3 2 3 2 3 2 3 2 1 0 1 1 }] becomes [{ true true true false false true false }, { 3 2 4 -1 2 1 2 }, 4, true].

## swiss
Run a Swiss-system chess tournament and report the standings. Player p has rating ratings[p]. Scores count half points: a win is 2, a draw 1, a loss 0. Play rounds rounds. At the start of each round, rank the players by score, highest first, then by rating, highest first, then by player number, lowest first. If the number of players is odd, the lowest-ranked player who has not yet had a bye gets one: they score 2 and do not play this round. This is done before pairing, and that player is left out of it. Then pair the others: repeatedly take the highest-ranked player not yet paired this round, and pair them with the highest-ranked unpaired player they have not played before in this tournament; if they have played every unpaired player, pair them with the highest-ranked unpaired player anyway, which is a rematch. In each pair, white goes to the player who has had white fewer times so far; if equal, to the player whose last game was played as black, if exactly one of them (a player who has played no game has no last game); otherwise to the player taken first. A bye is not a game and does not count as a last game. The games of a round are played in the order they were paired, and their results are read from results in that order, round after round: 0 means white won, 1 a draw, 2 black won. Return each player's final score; each player's Buchholz score, the sum of the final scores of the opponents of every game they played (an opponent met twice counts twice; a bye adds nothing); the player numbers ranked by final score, then Buchholz score, then rating, each highest first, then player number, lowest first; the number of times each player had white; and the number of rematches. ratings has 2 to 12 values, each 1,000 to 3,000; rounds is 1 to 7 and below the number of players; results has rounds times (the number of players divided by 2, rounded down) values, each 0 to 2.
Inputs on the stack, bottom to top: ratings: Seq Int, rounds: Int, results: Seq Int.
Outputs left on the stack, bottom to top: scores: Seq Int, buchholz: Seq Int, ranking: Seq Int, whites: Seq Int, rematches: Int.
Example: stack [{ 1500 1600 1400 1700 }, 2, { 0 1 2 0 }] becomes [{ 3 0 3 2 }, { 5 5 3 3 }, { 0 2 3 1 }, { 1 0 1 2 }, 0].

## warehouse
Run a warehouse for days days, numbered from 0, and report the totals. There are products 0 to P - 1, where P is the length of price; product p sells for price[p] a unit. Stock is held in lots, each with a quantity, an expiry day and the order in which it arrived. A pending order for a product waits in that product's backorder queue with the quantity still owed and the day it was placed. Taking q units of a product means taking them from its lots with the earliest expiry first, and among equal expiries the lot that arrived first; a lot that reaches 0 is gone. When a lot of a product arrives, it is added, and then while that product has a backorder and units in stock, the oldest backorder is filled as far as the stock allows: the units taken are shipped, and the backorder is gone once nothing is owed. On each day d, in this order: first, every lot whose expiry day is before d is thrown away. Second, for each product in order, a supply ordered earlier that is due on day d arrives as a lot of rq[p] units expiring on day d + shelf[p]. Third, the events of day d happen in the order listed: event e is on day ev_day[e], for product ev_prod[e], with quantity ev_qty[e]. Kind 1 is a delivery: a lot of that quantity arrives, expiring on day ev_expiry[e]. Kind 2 is a customer order: if the product has any backorder, the whole order joins the end of its backorder queue; otherwise as many units as are in stock, up to the quantity, are taken and shipped, and any units not shipped join the end of the queue as a backorder placed on day d. Fourth, every backorder placed on day d - 7 or earlier is cancelled, and the units it still owes (even if it was partly filled) count as cancelled. Fifth, for each product in order, if it has no supply on the way and its units in stock are at most rp[p], a supply is ordered, due on day d + lead[p]; a supply stops being on the way when it arrives in the second step, so another can be ordered that same day. Every unit shipped earns its product's price. Return the units in stock of each product at the end, the total earned, the units shipped, the units thrown away, the units cancelled, the number of supplies ordered, and the units still owed on backorder at the end. price, rp, rq, lead and shelf have the same length P, 1 to 5; each price is 1 to 1,000, each rp 0 to 100, each rq 1 to 200, each lead 1 to 10 and each shelf 1 to 30; days is 1 to 60. The five event sequences have the same length, at most 80; ev_day is 0 to days - 1 and never decreases from one event to the next; ev_kind is 1 or 2; ev_prod is 0 to P - 1; ev_qty is 1 to 200; ev_expiry is ev_day to ev_day + 60 for a delivery and 0 for an order.
Inputs on the stack, bottom to top: days: Int, price: Seq Int, rp: Seq Int, rq: Seq Int, lead: Seq Int, shelf: Seq Int, ev_day: Seq Int, ev_kind: Seq Int, ev_prod: Seq Int, ev_qty: Seq Int, ev_expiry: Seq Int.
Outputs left on the stack, bottom to top: stock: Seq Int, earned: Int, shipped: Int, discarded: Int, cancelled: Int, supplies: Int, owed: Int.
Example: stack [12, { 3 }, { 0 }, { 1 }, { 10 }, { 1 }, { 0 0 3 4 }, { 1 2 2 2 }, { 0 0 0 0 }, { 5 2 4 1 }, { 1 0 0 0 }] becomes [{ 0 }, 6, 2, 3, 5, 1, 0].

## cache-sim
Simulate a two-level cache and report its counters. Memory is made of blocks numbered 0 to 255. The first level has s1 sets of w1 places and the second level s2 sets of w2 places; block a belongs to set a mod s1 in the first level and a mod s2 in the second. Each place holds a block and a dirty mark. Each set keeps its blocks in order of use, least recently used first; using a block moves it to the most recent end, and putting a block into a set adds it at the most recent end after removing the least recently used block if the set is full (that block is evicted). Access i is to block addrs[i], a write if writes[i] is true and a read otherwise. If the block is in the first level, that is a first-level hit: it is used, and marked dirty if the access is a write. Otherwise it is a first-level miss, and: if the block is in the second level, that is a second-level hit and it is used there; otherwise it is a second-level miss, the block is read from memory and put into the second level unmarked, and if that evicts a dirty block, that block is written to memory. Then the block is put into the first level, marked dirty if the access is a write. If that evicts a dirty block b from the first level, b is written to the second level: if b is there it is used and marked dirty; otherwise it is put into the second level marked dirty, and if that evicts a dirty block, that block is written to memory. A clean evicted block is simply dropped. Return the number of first-level hits, first-level misses, second-level hits, second-level misses, memory reads and memory writes, the number of places in either level holding a dirty block at the end (a block dirty in both levels counts twice), and the blocks left in the first level, set 0 first, each set least recently used first. s1, w1 are 1 to 4 and s2, w2 are 1 to 8; addrs and writes have the same length, at most 200; every value of addrs is 0 to 255.
Inputs on the stack, bottom to top: s1: Int, w1: Int, s2: Int, w2: Int, addrs: Seq Int, writes: Seq Bool.
Outputs left on the stack, bottom to top: l1_hits: Int, l1_misses: Int, l2_hits: Int, l2_misses: Int, mem_reads: Int, mem_writes: Int, dirty: Int, l1_blocks: Seq Int.
Example: stack [1, 2, 1, 2, { 1 2 1 3 2 4 5 }, { false true false false false true false }] becomes [1, 6, 1, 5, 5, 1, 1, { 4 5 }].

Imports are not available in this run: an `import` cannot reach `stdlib/`, so define every word your answer uses in the answer itself.
