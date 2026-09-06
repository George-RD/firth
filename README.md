# Firth

Firth is an experimental concatenative language in the Forth tradition.
Programs are sequences of small words with declared stack effects. Lean checks
source types and ownership; a compiler lowers checked programs to a small Rust
VM. The reference interpreter defines the expected behaviour.

## Write and run a program

Start with [Getting started](docs/getting-started.md) for installation,
syntax, input values, errors and the current execution limits. From the
repository root, with the pinned Lean and Rust toolchains installed:

```sh
python3 tools/loop/firth_run.py check examples/mvp/choose-increment.firth
python3 tools/loop/firth_run.py run examples/mvp/choose-increment.firth \
  --entry main --stack '[41, true]'
```

The result has `"status": "success"` and `"stack": [42]`. The runner builds the
adapters, checks the source, compiles it, and requires matching VM and reference
results. Select the entry by its source name; its position in the file does not
choose which word runs.

## Current scope

The portable runner handles pure programs with non-negative integer and Boolean
inputs and results. Words, qualified vocabulary names, stack operations,
quotations, conditionals and named locals can be composed within that profile.
The only executable portable primitive is `prim +`.

This is not yet a general-purpose application platform. Text, signed integer
execution, file/network I/O, `send`, a package manager, a standard library and
an editor language server are not provided by this runner. The broader
language design and checker support more than the portable execution adapter.
See the [support table](docs/getting-started.md#supported-execution-profile)
before choosing a program to build.

## Documentation

- [Getting started](docs/getting-started.md): the executable user and agent workflow.
- [Agent language guide](docs/firth-agent-guide.md): the frozen v0.1 language
  guide used by the original authored corpus. Its full design surface is wider
  than the executable profile documented above.
- [Kernel specification](files/firth-kernel-spec-draft.md) and
  [VM target specification](src/runtime/vm/target-spec.md): language and target semantics.
- [Development runbook](docs/loop-runbook.md): the governed development loop,
  not an application-authoring tutorial.

## Verification and its limits

Lean mechanises the core kernel metatheory, including determinism,
preservation and progress. This is distinct from proving every compiler
implementation detail or an application's intended business behaviour.

The portable runner compares successful terminal outcomes, final stacks and
kernel-comparable cost. It validates finite trace bounds but does **not** claim
full trace equivalence. Effectful observations are refused rather than reduced
to a misleading Boolean comparison. VM administration is reported separately
from kernel cost. Fuel exhaustion and integer overflow are failures, not
successful comparisons.

CI builds Lean, runs its suites and proof-binding checks, checks the Rust VM,
then executes the original authored corpus and the documented multiword
examples. Python regressions exercise request wiring and provenance tampering.
The new examples are implementation fixtures, not evidence of independent
agent authorship. Passing the finite corpus is not a universal compiler proof.

## Build and test

Pins: Lean `leanprover/lean4:v4.30.0`, Rust `1.93.0`, Python `3.11` or newer.
No external SMT executable is required for the portable examples.

```sh
lake build
lake test
(cd src/runtime/vm && cargo fmt --check && \
  cargo clippy --locked --all-targets -- -D warnings && cargo test --locked)
python3 tools/loop/mvp_agent_gate.py
python3 tools/loop/check_language_examples.py
```

For changes to governed code, also run the proof manifest and Cairn checks in
[AGENTS.md](AGENTS.md). Do not rewrite expected results or proof pins to conceal
a failing gate.

## Repository layout

| Path | Purpose |
| --- | --- |
| `src/elaborator/` | Lean source parser, checking and erasure |
| `src/compiler/` | Checked-kernel to target compiler |
| `src/interpreter/` | Reference execution and kernel metatheory |
| `src/runtime/vm/` | Rust VM, image lifecycle and target contract |
| `src/agent/` | Structured diagnostic and elaboration adapters |
| `src/smt/` | Refinement solver integration |
| `examples/mvp/` | Authored corpus and executable regression examples |
| `tools/loop/firth_run.py` | Source checking and execution command |
| `spec/`, `specs/`, `files/` | Specifications and design material |
| `cairn.blueprint`, `meta/` | Architecture and development provenance |

## Licence

See [LICENSE](LICENSE) and the licensing posture in the
[product requirements](files/firth-prd.md).
