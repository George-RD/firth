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

A Firth program is a set of words. Each word declares its stack effect, and
the checker holds it to that. This one sums 1 to n with a tail-recursive
loop (`examples/programs/sum-to.firth`):

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

Run it with `--entry sum-to --stack '[100]'` and you get `[5050]` from both
the VM and the reference interpreter. It's also proved correct in Lean for
every `n` of at least 0 whose sum fits in an i64 (`src/proofs/records.json`).

What works, and where to check it:

- **Values.** Signed 64-bit `Int`, `Bool`, and sequences `Seq Int` and
  `Seq Bool`. The primitives are `prim +`, `-`, `*`, `div` and `mod`
  (Euclidean; a zero divisor traps), the comparisons `<`, `<=`, `>`, `>=`
  and `=`, and `and`, `or` and `not`. Sequences have `empty`, `len`, `at`,
  `push` and `set`. The support table is in
  [Getting started](docs/getting-started.md#supported-execution-profile).
- **Structure.** Words, qualified vocabulary names, quotations, `call`,
  `dip`, `if`, and recursion. Tail calls run in constant frames. Named
  `locals` compile to the kernel's `pick` and `roll`, and a `locals` block
  that opens a word must bind its inputs in stack-effect order.
- **Diagnostics.** The checker reports the first error in each word it
  checks, not just the first in the program, and names the word. Where it
  can, a hint states an edit the checker has applied and rechecked. A
  syntax error still stops the file there, and a word that calls one with
  an invalid signature is reported as unchecked
  (`docs/firth-agent-guide.md`, the diagnostics section).
- **Real programs.** 13 example programs, including sort, sieve, gcd,
  Fibonacci and factorial, run 141 cases on both hosts against expected
  results: 130 values and 11 expected traps. 5 more programs must be
  refused by the checker (`python3 examples/programs/check_programs.py`).
  The inventory allocator (`examples/inventory/`) passes all 53 cases of
  its fixed contract. 30 run on both hosts, and 23 are invalid inputs its
  host must reject (`python3 examples/inventory/run_cases.py`).
- **Proofs about programs.** 6 contracts are proved in Lean over the
  reference interpreter. They cover 15 distinct word bodies (16 exported
  words, because the same `abs` is in two files). One of them is the whole
  allocator: conservation, no over-allocation, the fulfilment policy, i64
  range and a cost bound. That meets goal S5 in the
  [roadmap](docs/roadmap.md). The host's ID encoding and the way it attaches
  results to IDs are proved too and run from Lean. The gaps stated there are
  that the compiler and VM agree with the reference only by differential
  testing, and that the host's JSON handling (the Python checks and
  transport, and the Lean executable's JSON glue) is tested, not proved.

## How well models write it

The S7 eval ([eval/s7/README.md](eval/s7/README.md)) gives a model the docs
and 20 fixed tasks, then scores its answers against hidden tests. Sub-agent
authors also see `AGENTS.md`. The same tasks in Python are the baseline,
and both models scored 20 of 20 there in run 4.

Claude Sonnet 5 writes Firth about as reliably as Python: 19 of 20 on its
first answers in run 4, and 20 of 20 after feedback. It's much slower,
though. In run 4 its first answer took about 6 minutes, against 11 seconds
in Python.

Claude Haiku 4.5 is the harder test, and it still mostly fails. Runs 5 to
13 were Haiku only, and each sample gets two rounds of checker feedback:

| Haiku 4.5 runs | Samples | Tasks passed per sample, after feedback |
| --- | --- | --- |
| Runs 4 to 8 | 1 to 4 a run | 0 to 8 of 20 |
| Run 9 | 4 | 3, 12, 17 and 0 of 20 |
| Run 10 (control) | 10 per arm | 0 to 13 of 20 |
| Run 11 | 20 per arm | 0 to 17 of 20 |

Run 9 looked like a jump, but run 10 re-ran its build and run 8's side by
side and the gain didn't reproduce. That fits sample-to-sample variance
better than an effect of the multi-error feedback. Run 11 told arm B to use
`locals` instead of stack shuffling. Authors did as asked (shuffle words
fell from 37% of first answers to 6%), but tasks passed were 154 against 177
across 20 samples an arm, which isn't significant. Runs 12 and 13 let
authors run the checker themselves. Both stopped early without a result.
Most authors given the checker made calls the protocol doesn't allow, such
as extra pipes after the check command or reads of its saved output, and
each of those voids the sample.

So Firth has two gaps to close for models: Haiku can't yet write it
reliably, and even Sonnet is slow. Each run's full results are in the
eval README.

## Known gaps

- No cross-file imports: a program is one file, and `stdlib/core.firth` is
  not loaded automatically (`todo.language-12-data-and-modules`).
- No text, characters, file or network I/O, or `send` on the executable
  path. Source refinement annotations are rejected rather than checked.
- Non-tail recursion deeper than 256 frames traps on the VM.
- No package manager, general standard library or language server.
- Goals S2 (sustained differential fuzzing), S3 (live patching), S4 (a
  self-hosted standard library), S6 (a third-party VM) and S7 (measured
  machine authorship against a mainstream-language baseline) are open.
  See the [roadmap](docs/roadmap.md).

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
