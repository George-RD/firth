---
id: dec.diffharness-fuzz-strategy
nodes:
  - firth.toolchain.diffharness
status: accepted
date: 2026-07-17
---
# Differential Fuzzing Strategy

## Context

The reference interpreter defines kernel behaviour, while the compiler and
future Rust VM are independently exposed to implementation errors. The
harness must therefore compare checked kernel programs at the semantic
boundary, without making a generator, compiler, or harness part of the
trusted computing base. The VM remains a trusted but unverified component as
required by PRD R8. It must exercise the frozen v0.1 syntax and typing invariants:
one value stack, quotations as the only higher-order value, dictionary word
unfolding, deterministic primitives, many-only literals, and linear `World`
threading. The pinned Lean host is `leanprover/lean4:v4.30.0`; the selected
production VM host is Rust, as recorded in `dec.host-languages`.

## Decision

Build a deterministic, seed-replayable differential harness in Lean that
generates mostly well-typed closed dictionaries and entry programs, executes
each case with the Lean reference interpreter and the compiled target, and
compares canonical terminal observations. Keep a smaller well-formed-only
negative corpus for elaborator and target-error checks; it is never treated as
evidence that a compiler accepted an invalid program.

## Rationale

Well-typed generation reaches the compiler and VM semantic boundary with a
useful oracle, while a small negative mode covers the checker boundary without
confusing rejection with behaviour. The fixed primitive registry keeps Lean
and Rust executions comparable and makes replay independent of ad hoc host
extensions. Treating dual fuel exhaustion as inconclusive avoids declaring
agreement merely because two executions stopped at the same arbitrary limit.

## Generation

The generator constructs a typed stack state together with a remaining size
and quotation-depth budget. At each step it chooses an atom whose typing rule
can consume the current state, then updates the state from that rule. Choices
are weighted so every kernel rule has a coverage quota, rather than allowing
short literal-only programs to dominate. The generator records a rule-coverage
bitmap and rejects a case that does not meet its requested quota.

The coverage plan includes `ε` and sequencing, many literals, closed
quotations, nested quotations, `dup`, `drop`, `swap`, `dip`, `call`, `compose`,
`quote`, both `if` branches, dictionary words, and every declared deterministic
`prim π`. `quote` receives special weight when the current top value is linear
so that capture is tested, including nested capture and subsequent exactly-once
consumption. `if` is generated only with a many `Bool` and two many quotations
whose effects are identical. Literal generation is restricted to base values
declared many, including recursively nested quotation literals where present;
it never fabricates a linear resource.

Each case carries a generated signature view over a fixed, versioned primitive
registry `Γ`, a finite dictionary `D`, and an entry word. The registry is the
intersection implemented by the Lean interpreter and Rust VM, with canonical
serialisable arguments and deterministic deltas. Generated cases may choose
only registry entries; adding a primitive requires updating both hosts and the
registry version. A host-only extension or arbitrary generated-primitive ABI
is out of scope for this corpus. Stack-aware construction tracks usage, so `dup` and
`drop` are offered only for many values and the single linear `World` token is
threaded through effectful primitives. Dictionary entries are generated from
declared erased word types and checked mutually recursively. A second mode
generates syntactically well-formed but ill-typed terms to exercise structured
diagnostics, rejected primitive shapes, unknown words, invalid branch effects,
and linearity errors. This negative mode compares acceptance and diagnostic
shape, not runtime terminal configurations.

Recursion is introduced through dictionary references. Generated cases have a
fuel budget and a recursion/depth cap; they may terminate or exhaust fuel.
Primitive deltas are pure deterministic test doubles in that shared registry,
including a model `World` transition. External I/O and nondeterminism are
excluded from the oracle corpus until a deterministic effect model and target
ABI are specified.

## Execution and agreement

The interpreter is run first on the checked kernel dictionary and entry word.
The compiler then emits the target representation consumed by the future Rust
VM. Both runners use a case-local immutable `Γ`, `D`, initial stack, and cost
table `κ`. Values and quotations are serialised into a canonical form with
dictionary names and program sequences, so equality is structural rather than
pointer-based. A terminating result agrees only when both status is terminal,
the residual program is `ε`, the canonical value stacks are equal in order,
and the relevant deterministic `World` observation is equal. A target trap,
malformed instruction, stack fault, or compiler rejection for a well-typed case
is a mismatch. Target-side errors use a versioned taxonomy covering malformed
instruction, unknown primitive, stack/type fault, resource fault, and fuel
exhaustion. A well-typed kernel case may not produce the first four; a
negative target corpus is expected to produce the declared class and is
compared with that classification rather than a terminal stack. The
interpreter remains authoritative when an implementation choice is ambiguous.

Costs are reported separately from semantic equality. Each runner emits a
breakdown by kernel atom, primitive, and word unfolding. The harness checks
that the interpreter trace uses the kernel's parameterised `κ` compositionally;
it does not require equal raw VM instruction counts. Once the VM target
specification instantiates `κ`, a target cost report is checked against that
instantiation and stored with the result. This preserves R10 without making
target-specific lowering costs look like semantic divergence.

Fuel exhaustion is a bounded observation, not a proof of divergence. If both
runners exhaust their equivalent semantic budget, the result is
`bounded-fuel-inconclusive`, not agreement; the artefact retains both bounded
traces and final machine states for diagnosis. If one runner terminates and the
other exhausts, or they return different traps, the case fails. A seeded
recursion corpus may additionally mark expected non-termination, but the
harness must still report the bound and never claim an unbounded divergence
proof. Different implementation step counts use a semantic fuel budget
derived from `κ`, with a documented conservative target translation once the
Rust VM cost table exists. A future stronger bounded trace/state relation may
promote this outcome only through a new accepted decision.

## Shrinking and failure artefacts

Shrinking is deterministic and keeps the original seed. It minimises, in
order, dictionary size and unused words, entry length, quotation depth,
primitive arguments, initial stack, and fuel. Every candidate is rechecked for
dictionary closure and the same mode's typing/diagnostic precondition. Atom
deletion and quotation-body shrinking are attempted before structural rewrites;
`if` branches shrink in lockstep to preserve equal effects. Linear `World`
paths, every other linear base type, and every quotation whose usage meet is
linear are shrunk only through usage-aware constructors. A failure is
accepted as minimal only after no ordered shrinker preserves the same failure
classification.

The reproducible artefact is JSON plus human-readable source: original and
minimised seeds, generator version, Lean toolchain identity, compiler and VM
identities, `Γ`, `D`, entry program, initial stack, `κ`, fuel translation,
coverage bitmap, interpreter and target outcomes, canonical terminal stacks,
cost breakdowns, and bounded traces. The artefact is sufficient to replay
offline without network access. It must not contain host secrets or raw
external resources.

## Consequences

The harness will require a versioned shared primitive registry, canonical value
serialisation, and explicit bounded outcomes. It will produce more
inconclusive recursive cases than a permissive timeout policy, but those cases
remain useful replay and shrink inputs. Target encoding, the concrete Rust
process boundary, and external-effect observables remain follow-up decisions
for the compiler and VM specifications.

## Corpus and CI

The checked-in seed corpus contains one small deterministic witness per kernel
rule and per important interaction: nested quotation capture, linear `World`
through `dip`/`call`, `compose` ownership, both `if` branches, word unfolding,
primitive errors, and bounded recursion. Seeds are named and versioned; a
generator change either preserves their meaning or records a corpus revision.
Failure artefacts are added only when they are minimised, reproducible, and
licence-safe.

The initial Lean-only CI gate, using the exact `lean-toolchain`, runs
`git diff --check`, `lake build`, the deterministic seed corpus, and the
zero-admit scan once source targets exist. PR jobs run the seed corpus plus a
fixed small random matrix keyed by commit. Nightly jobs run larger fixed seed
sets, multiple recorded seeds, shrink/replay tests, coverage quotas, and the
negative diagnostic corpus. When the Rust VM and compiler target are wired,
the same Lean harness invokes the Rust VM, runs the cross-host differential
matrix, and stores failure artefacts as CI outputs. Rust formatting, build,
tests, and target conformance remain VM gates; they do not replace the Lean
oracle.

This commits the project to deterministic replay, structural terminal equality,
explicit bounded-divergence handling, and separate cost validation. It leaves
the exact Rust instruction encoding, target `κ` table, external-effect
observables, and VM process boundary to the compiler and VM specifications.
