# Portable differential execution

The driver builds and invokes the real Firth elaborator, Lean reference
interpreter, compiler and Rust VM. Python generates source, coordinates
processes and states what each generated fragment must compute (the oracle
below); it does not run Firth source.

From the repository root with the pinned Lean and Rust toolchains installed:

```sh
python3 src/diffharness/harness.py run --seed 0 --seed 1 --seed 20260909 --cases 24
python3 src/diffharness/harness.py replay .firth-differential/seed-.../original.json
python3 src/diffharness/harness.py shrink .firth-differential/seed-.../original.json --shrink-steps 64
python3 tools/loop/test_diffharness.py
```

The default campaign is 72 cases: 24 per seed, each containing one to six typed
fragments. `--size` changes the maximum fragment count (up to 24). Each index
rotates through a required feature, then composes randomly selected fragments
with independently seeded literals and row inputs. The same seed and index
produce the same recipe for this generator version. Replay checks the saved
source against its recipe and executes those exact bytes, not a new random case.

The profile includes signed integers, Booleans, row-polymorphic inputs, both
external conditional branches, multiword calls, qualified names, locals, nested
quotations, quote/call, compose, dip and swap, and the integer primitives `+`,
`-`, `*`, `div` and `mod` with both operand orders. Conditionals are also driven
by `<` and `=` combined with `and`, `or` and `not`. One literal in five is an
edge value (`MIN`, `MAX`, their neighbours, `-1`, `0`, `1`, `2`, `±2^31`,
`±2^32`); the rest are from -50 to 50. Cases therefore reach zero divisors,
`MIN div -1` and signed 64-bit overflow. Every original and reduced source is
re-elaborated.

### Expected results

`expected()` in `harness.py` is an oracle written from the documented meaning
of each fragment, not from either host: division is Euclidean (the remainder is
never negative), a zero divisor faults, the reference's integers are unbounded
and the portable VM faults when `+`, `-`, `*` or `div` leaves the signed 64-bit
range. For each host it gives the final stack, or the fault with the faulting
primitive's two operands left above the row input. Each host must match it
exactly; otherwise the case is `oracle-mismatch`, naming the host. This catches
a bug the reference and the VM share, which host agreement cannot (rule 10 in
`AGENTS.md`). Its hand-worked checks and planted shared bugs (truncating
division, a signed remainder, swapped operands, a reversed `<`, a VM that
returns 0 for a zero divisor, a bounded reference) are in
`tools/loop/test_diffharness.py`.

Three outcomes pass, each only when both hosts match the oracle:

- `agreement`: both succeed, and stacks, kernel cost and traces match.
- `expected-trap`: both fault where the oracle says a zero divisor faults.
- `expected-portable-overflow`: the reference succeeds with its unbounded
  result and the VM faults at the first primitive that leaves the 64-bit range.
  This is the documented difference between the two hosts, not an agreement.

Raw VM cost may differ. Both hosts exhausting fuel is
`bounded-fuel-inconclusive`, not agreement. One-sided exhaustion, a trap the
oracle does not predict, checker/compiler rejection, malformed transport and
process failures have separate failure classes and all fail the finite gate.
The oracle does not model cost, traces or fuel; those keep the checks below.
A process timeout is distinct from interpreter/VM fuel exhaustion. The fuel
budget defaults to 4096 per generated case and is bounded by the gate's
`MAX_FUEL`, the largest budget the VM adapter accepts. Each host records at
most `MAX_TRACE_EVENTS` (4096) trace events.

An agreement also compares the two traces event by event through the gate's
`compare_traces`: both traces are projected onto kernel-charged steps, their
lengths and per-step charges must match, and when no intermediate stack holds
a quotation every projected stack must be equal. A projected event that
differs is the `trace-mismatch` failure class. Every generated case starts
with `[ ] [ dup drop ] if`, so intermediate stacks hold quotations and the
campaign records the label `unsupported-quotation-values` in its summary's
`trace_comparisons` rather than a stack-for-stack agreement; the label is
neither a failure nor agreement.

## Evidence and replay

`--artifacts DIR` selects the output directory; the default is
`.firth-differential/`. Each failed case gets an exclusive subdirectory holding
`original.json` and source, plus a bounded reduction where eligible. JSON
retains every attempted adapter's request, stdout, stderr, exit, decoded
response and failure classification. Output is capped at 4 MiB combined per
adapter; truncated output and invalid UTF-8 are explicit errors. Deadlines
cover stdin, stdout, stderr and inherited pipes. This POSIX runner is exercised
on Linux CI; native Windows support is not claimed.

Records include generator version, seed/index, source and input, fuel, feature
labels, Git revision, Python version, adapter/driver digests and toolchain pins.
Successful campaigns also retain a summary with identities and feature counts.
The driver never rewrites the authored MVP corpus or proof bindings.

Replay builds the local adapters and refuses changed toolchain identities by
default. `--allow-toolchain-drift` permits a deliberate comparison after a fix;
its output is labelled as drifted rather than an identical replay. The output
also states whether the original failure signature was reproduced. Saved
commands and paths are diagnostic data and are never executed. Shrinking does
not proceed when the saved failure signature is not reproduced.

Shrinking removes unused words, whole typed fragments and row inputs before
reducing literals (towards zero, for negative ones too) and branch flags. A reduction must re-elaborate, retain the
same failure kind, stage and traps, and decrease the recipe's complexity.
`--shrink-steps` caps candidate executions (default 32; maximum 256).
`budget-exhausted` is not a minimality claim; `fixed-point` describes only the
implemented reduction rules. Fuel and quotation depth are not independently
minimised in this initial source-fragment shrinker.

Exit 0 means every executed case passed, including a formerly failing replay
that now succeeds. Exit 1 means a mismatch, trap, inconclusive result or other
case failure. Exit 2 means configuration, build or replay validation failed.

## Limits

This is a small, bounded source campaign, not the sustained S2 campaign or a
compiler-correctness proof. Generation uses typed fragment constructors, not
an unrestricted grammar or a full kernel-term generator. Coverage counters
count generated features, not semantic coverage or proof coverage. The trace
comparison covers kernel-charged steps and scalar stacks only: there is no
claim of equivalence for residual programs, quotation-valued stacks, linear
World/effectful behaviour, returned quotations, general I/O, recursive-program
generation, source refinement proofs or negative target-bytecode fuzzing.
Existing trust-boundary and VM suites remain separate gates.

The unit suite deliberately uses fake Python subprocess adapters to test the
driver's plumbing and hostile outputs without requiring Lean/Rust locally.
Those tests are not compiler evidence. CI additionally executes the real
seeded source campaign and retains its diagnostics and failure artefacts.
`check_failure_roundtrip.py` also executes an intentionally zero-fuel case on
the real adapters, shrinks it and replays both original and reduced records.
It requires explicit non-passing exhaustion and matching toolchain identities;
these expected failures are not counted as successful language executions.

## Locals erasure

`check_locals_erasure.py` tests `locals` erasure against the meaning of the
source rather than against a second host. It generates words that use locals
(nested blocks, shadowing, repeated uses, uses inside quotations and `if`
branches, after `call`, `dip` and `compose`, quotations kept in locals) by
running each program as it is built, in a small Python interpreter where a
block takes its values off the stack and a name pushes the value bound to it.
Each program then runs through the real elaborator, compiler and both hosts;
the final stack must equal the interpreter's. Only the documented checker
limits (`firth.elaboration.untracked-local` and `firth.elaboration.hidden-local`)
are counted as refusals; any other refusal of a generated program fails, and
so does a run in which fewer programs are accepted than refused.

```sh
python3 src/diffharness/check_locals_erasure.py --seed 0 --seed 1 --seed 2 --cases 100 --artifacts /tmp/firth-locals
```
