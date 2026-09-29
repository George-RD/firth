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

The portable runner handles pure programs with signed 64-bit integer, Boolean
and sequence inputs and results. Words, qualified vocabulary names, stack operations,
quotations, conditionals and named locals can be composed within that profile.
The executable portable primitives are `prim +`, `-`, `*`, `div`, `mod`, `<`,
`=`, `and`, `or`, `not` and the `seq-int.*` / `seq-bool.*` sequence operations
(`empty`, `len`, `at`, `push`, `set`).

This is not yet a general-purpose application platform. Text, file/network
I/O, `send`, a package manager, a general-purpose standard library and an
editor language server are not provided by this runner. The broader
language design and checker support more than the portable execution adapter.
A small core vocabulary exists in `stdlib/core.firth`; it is not automatically
loaded into programs. See the [support table](docs/getting-started.md#supported-execution-profile)
before choosing a program to build.

## Documentation

Start with the [roadmap to a useful language](docs/roadmap.md) for acceptance
milestones and the tracked correctness/application work still open.

- [Getting started](docs/getting-started.md): the executable user and agent workflow.
- [Agent language guide](docs/firth-agent-guide.md): the language guide an
  authoring agent is given, with Getting started, in the S7 authoring eval. It
  describes the checker's diagnostics. Its design surface is wider than the
  executable profile documented above.
- [Example programs](examples/programs/README.md): checked programs run on both
  hosts against expected results (factorial, sort, sieve, gcd and more).
- [S7 authoring eval](eval/s7/README.md): the fixed task set, protocol and
  recorded results of measuring how well models write Firth.
- [Kernel specification](files/firth-kernel-spec-draft.md) and
  [VM target specification](src/runtime/vm/target-spec.md): language and target semantics.
- [Roadmap](docs/roadmap.md): milestones and the honest status of each PRD goal.

## Verification and its limits

Lean mechanises the core kernel metatheory, including determinism,
preservation and progress. Separately, Lean proofs in `src/proofs/` show that
some exported Firth programs meet their specifications when run by the
reference interpreter: the inventory allocator (conservation, no
over-allocation, the fulfilment policy, i64 range and a cost bound) and smaller
programs such as `gcd`. `src/proofs/records.json` binds each proof to the word
body digests it covers. None of this proves the compiler or the VM: their
agreement with the reference interpreter rests on differential testing.

The portable runner compares successful terminal outcomes, final stacks and
kernel-comparable cost. It validates finite trace bounds but does **not** claim
full trace equivalence. Effectful observations are refused rather than reduced
to a misleading Boolean comparison. VM administration is reported separately
from kernel cost. Fuel exhaustion and integer overflow are failures, not
successful comparisons.

CI builds Lean, runs its suites, the proof escape-hatch audit and the
proof-pin checks, and checks the Rust VM. It then executes the authored corpus,
the documented multiword examples, the example programs against their expected
results, the inventory allocator's fixed acceptance corpus and cost bound, and
a seeded differential campaign. Python regressions exercise request wiring and
provenance tampering. The examples are implementation fixtures, not evidence of
independent agent authorship; that is what the S7 eval measures. Passing the
finite corpus is not a universal compiler proof.

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
python3 examples/programs/check_programs.py
```

For changes to governed code, also run the proof manifest check in
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
| `src/exports/`, `src/proofs/` | Kernel programs exported to Lean, and Lean proofs about them |
| `src/diffharness/` | Differential compiler-versus-reference testing |
| `examples/mvp/` | Authored corpus and executable regression examples |
| `examples/programs/` | Example programs with expected results |
| `examples/inventory/` | The inventory allocator (the first real consumer) |
| `stdlib/` | Standard library written in Firth (small so far) |
| `eval/s7/` | The S7 authoring eval |
| `docs/` | Getting started, the agent guide and the roadmap |
| `tools/loop/firth_run.py` | Source checking and execution command |
| `spec/`, `specs/`, `files/` | Specifications and design material |
| `cairn.blueprint`, `meta/` | Architecture and development provenance |
| `archive/loop/` | Frozen autonomous-loop machinery, kept for reference |

## Licence

See [LICENSE](LICENSE) and the licensing posture in the
[product requirements](files/firth-prd.md).
