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

## What Firth can do today

A Firth program is a set of words, each with a declared stack effect that the
checker verifies. This one sums 1 to n with a tail-recursive loop
(`examples/programs/sum-to.firth`):

```firth
: sum-to
  (forall ρ; ρ n:Int^many -- ρ r:Int^many)
  0 swap sum-acc;

: sum-acc
  (forall ρ; ρ acc:Int^many n:Int^many -- ρ r:Int^many)
  dup 0 prim =
  [ drop ]
  [ dup 1 prim - [ prim + ] dip sum-acc ] if;
```

Run with `--entry sum-to --stack '[100]'`, it returns `[5050]` on both the VM
and the reference interpreter. `sum-to` is also proved correct in Lean for
every `n` of at least 0 whose sum fits in 64 bits
(`src/proofs/records.json`).

What works, with where to check it:

- **Values.** Signed 64-bit `Int`, `Bool`, and sequences `Seq Int` and
  `Seq Bool`. Arithmetic, comparison and Boolean primitives are `prim +`,
  `-`, `*`, `div`, `mod` (Euclidean; a zero divisor traps), `<`, `=`,
  `and`, `or` and `not`. The sequence operations are `empty`, `len`, `at`,
  `push` and `set`. See the support table in
  [Getting started](docs/getting-started.md#supported-execution-profile).
- **Structure.** Words, qualified vocabulary names, quotations, `call`,
  `dip`, `if`, and recursion, where tail calls run in constant frames. Named
  `locals` compile to the kernel's `pick` and `roll`. A `locals` block that
  opens a word must bind its inputs in the order of the stack effect.
- **Diagnostics.** The checker reports the first error in each word it
  checks, not only the first in the program, and each diagnostic names its
  word. A syntax error still stops the file there, and a word that calls
  one with an invalid signature is reported as unchecked
  (`docs/firth-agent-guide.md`, the diagnostics section).
- **Real programs.** 12 example programs, including sort, sieve, gcd,
  Fibonacci and factorial, run 116 cases (including expected traps)
  against expected results on both hosts, and 5 more programs must be
  refused by the checker
  (`python3 examples/programs/check_programs.py`). The inventory allocator
  (`examples/inventory/`) passes all 53 cases of its fixed contract: 30
  run on both hosts, and 23 are invalid inputs its host must reject
  (`python3 examples/inventory/run_cases.py`).
- **Proofs about programs.** 5 contracts are proved in Lean over the
  reference interpreter. They cover 15 distinct word bodies (16 exported
  words, because the same `abs` is in two files), including the whole
  allocator
  (conservation, no over-allocation, the fulfilment policy, i64 range and a
  cost bound). This is goal S5 in the [roadmap](docs/roadmap.md), met with
  two stated gaps: the compiler and VM agree with the reference only by
  differential testing, and the Python host that feeds the allocator is
  tested, not proved.

## How well models write it

The S7 eval ([eval/s7/README.md](eval/s7/README.md)) gives a model only the
docs (and, for sub-agent authors, `AGENTS.md`) and 20 fixed tasks, then scores its answers against hidden tests. The
same tasks in Python are the baseline: both models scored 20 of 20 there in
run 4.

| Author | Firth, first answer | Firth, after feedback |
| --- | --- | --- |
| Claude Sonnet 5 (run 4) | 19 of 20 | 20 of 20 |
| Claude Haiku 4.5 (runs 4 to 8) | 0 to 6 of 20 | 0 to 8 of 20 |

A strong model writes Firth about as reliably as Python, but it takes much
longer: about 6 minutes against 11 seconds for the first answer in run 4.
A weaker model mostly fails. In run 8 each Haiku sample repeated a few
basic mistakes on nearly every task, and two rounds of feedback did
not get past them. The results for each run are in the eval README.

## Known gaps

- No cross-file imports: a program is one file, and `stdlib/core.firth` is
  not loaded automatically (`todo.language-12-data-and-modules`).
- No text, characters, file or network I/O, or `send` on the executable
  path. Source refinement annotations are rejected rather than checked.
- Non-tail recursion deeper than 256 frames traps on the VM.
- No package manager, general standard library or language server.
- Goals S2 (sustained differential fuzzing), S3 (live patching), S4 (a
  self-hosted standard library), S6 (a third-party VM) and S7 (measured
  machine authorship against a mainstream-language baseline) are open. See the [roadmap](docs/roadmap.md).

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
preservation and progress. The program proofs above run over the reference
interpreter, and `src/proofs/records.json` binds each one to the digests of
the word bodies it covers. None of this proves the compiler or the VM: their
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
