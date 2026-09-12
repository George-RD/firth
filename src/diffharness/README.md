# Portable differential execution

The driver builds and invokes the real Firth elaborator, Lean reference
interpreter, compiler and Rust VM. Python generates source and coordinates
processes; it is not an alternative language interpreter.

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

The profile includes non-negative integers, Booleans, addition, row-polymorphic
inputs, both external conditional branches, multiword calls, qualified names,
locals, nested quotations, quote/call, compose, dip and swap. Integers and
composition are bounded so generated executions stay below the portable signed
64-bit limit. Every original and reduced source is re-elaborated.

Only successful, well-formed pure observations with matching stacks and kernel
cost count as agreement. Raw VM cost may differ. Both hosts exhausting fuel is
`bounded-fuel-inconclusive`, not agreement. One-sided exhaustion, traps,
portable integer overflow, checker/compiler rejection, malformed transport and
process failures have separate failure classes and all fail the finite gate.
A process timeout is distinct from interpreter/VM fuel exhaustion. The fuel
budget is bounded at 4096, the largest budget the VM adapter accepts.

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
reducing literals and branch flags. A reduction must re-elaborate, retain the
same failure kind, stage and traps, and decrease the recipe's complexity.
`--shrink-steps` caps candidate executions (default 32; maximum 256).
`budget-exhausted` is not a minimality claim; `fixed-point` describes only the
implemented reduction rules. Fuel and quotation depth are not independently
minimised in this initial source-fragment shrinker.

Exit 0 means every executed case agreed, including a formerly failing replay
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
