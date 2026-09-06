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

The default fuel budget is 4096 steps. `--fuel` accepts an integer from 0 to
100000. Recursive definitions are permitted, but exhausting the bound does
not prove divergence and is never accepted as a successful run. Increase the
bound only after checking that the program should terminate. The VM and
reference interpreter report cost differently: VM word-entry administration
is additional overhead, so reference cost is compared with `kernel_cost`,
not the larger `vm_cost`.

Addition must stay within `0..9223372036854775807` for portable execution.
Overflow fails instead of wrapping. The reference interpreter's natural
numbers are unbounded; the finite VM's refusal is not evidence of agreement.

## Supported execution profile

| Feature | Current portable runner |
| --- | --- |
| External inputs and final results | Non-negative integers through `9223372036854775807`, and Booleans |
| Source type name for integers | `Int`; the executable literal representation is currently non-negative |
| Primitive operations | `prim +` |
| Definitions | Explicit stack effects, multiple words, qualified vocabulary names, recursion with finite fuel |
| Composition | Core stack operations, quotations, `call`, `if`, named locals; matching checked effects are required |
| Quotations as external inputs/results | Not exposed by this runner |
| Negative integers, text and character execution | Not implemented by the portable compiler/adapters |
| `send`, file/network I/O, external resources | Not implemented by this portable execution path |
| Refinements and linear effects | Wider checker/solver facilities exist; this runner is not an end-to-end effectful/refinement application interface |
| Core vocabulary | `stdlib/core.firth` contains identity, duplication, discard and exchange examples; it is not automatically imported |
| General-purpose standard library, package manager, editor language server | Future work |

In particular, the `send-once` example in the frozen agent guide describes the
intended linear-effect surface, not an executable network operation available
through `firth_run.py`. An unsupported primitive must be rejected by compilation.

## What a successful run establishes

The runner checks source, compiles the checked representation, and compares
successful terminal status, final stack and kernel-comparable cost with the
Lean reference interpreter. It bounds each execution and validates the trace
lengths. It does **not** establish full trace equivalence, arbitrary effect
agreement, a universal compiler-correctness theorem or the business intent of
the application. Non-pure world observations are refused.

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
