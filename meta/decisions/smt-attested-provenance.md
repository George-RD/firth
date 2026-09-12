---
id: dec.smt-attested-provenance
nodes: [firth.toolchain.smt, firth.toolchain.elaborator]
status: accepted
related: [dec.smt-bounded-solver-invocation, dec.smt-discharge-record-recheck, dec.smt-adapter-integration-tests]
informed_by: [src.refinement-discharge-architecture, src.z3-5.0.0-release]
date: 2026-09-09
---

# Attested solver provenance: the sealed wrapper, where it lives, and what it gates

## Context

`dec.smt-discharge-record-recheck` made `checkUnsat` the only producer of
`checkedUnsat` and put promotion at the boundary, and said why that was not
yet enough: "`ExternalOutcome` is a public inductive, so nothing in the type
stops a caller from constructing a `checkedUnsat` and presenting it as already
checked." The `smt-record-promotion` slice closed that particular door and
left the parent todo open with the sentence that names this decision's
problem: "Matching metadata on a public raw `uncheckedUnsat` value is not
authenticated solver evidence, and a matching public rerun verdict does not
prove a process was invoked."

Concretely, before this unit a hand-built
`{ profile := defaultSolverProfile, requestIdentity := canonicalRequestIdentity request, outcome := .uncheckedUnsat "unsat" }`
passed every check in `recordExternalOutcome` and was published as a discharge
record, for a false obligation; a public `.rechecked record` was published by
`recordRerunVerdict`; and a stub `SolverRunner` that reported the pinned digest
reached both through `solve` and `rerunDischargeRecord`.

`dec.smt-bounded-solver-invocation` records that "`SolverRunner` is a record of
three effects and `processRunner` is the only implementation that spawns
anything" and that "the pin is verified before the invocation, not after".
Both stand. What was missing was a way for the boundary to tell a value that
came from that verified invocation apart from a value that merely looks like
one.

## Decision

### The sealed type lives in the module that spawns the solver

`Firth.Smt.Solver.Attested α` wraps a value with a `Provenance` behind a
constructor that is `private` to `SmtSolver.lean`. That module is the one
place a solver process is spawned, so it is the one place that can know
whether the pin was exercised, and the constructor's scope is exactly that
knowledge's scope. Outside the module a caller can read `provenance` and
`value`, and can build an `injectedRunner` value through `injected`, but
cannot build a `pinnedProcess` value by any construction the elaborator
accepts: the anonymous constructor, structure instance notation, the named
constructor, `with` updates and constructor patterns all fail to elaborate,
which was checked against Lean 4.30.0 before this was adopted.

`solvePinned` and `rerunPinned` are the only producers of `pinnedProcess` and
the only production callers of `processRunner`. `solve` and
`rerunDischargeRecord` remain, take a caller-supplied runner, and always yield
`injectedRunner`: whatever a runner says about its executable is a claim the
runner made, not something this module established.

Putting the type in `SmtSolver` rather than in `SmtBoundary` follows from
that. `SmtBoundary` is pure and public, and everything pure stays public: the
record, its construction, its recheck and the promotion rule are all data and
functions over data that any caller may run. The one thing a caller may not
do is assert that a process ran, and that assertion belongs with the process.

### Provenance is the last gate

`recordExternalOutcome` and `recordRerunVerdict` now take the attested types,
bind `.value` where the plain result was, and run every metadata guard, the
promotion inside `makeDischargeRecord` and the recheck exactly as before. Only
after all of those succeed is `provenance` consulted, and only `pinnedProcess`
publishes a record; anything else is deferred with the stable code
`firth.smt.unattested-provenance` and the reason `unattestedProvenance`.

Ordering it last is deliberate. Every earlier refusal is about the data, and
every one of them must stay observable with an injected result, because that
is how `lake test` exercises them on a host with no solver. A provenance check
placed first would collapse every injected case into one code and hide the
guards behind it. Placed last, an injected result that is deferred for its
provenance is also a result that would have been admitted had the pinned
process produced it, which is the strongest thing the injected suites can say.

### A validated `sat` is provenance-independent

A countermodel that satisfies the premises and falsifies a conclusion is a
refutation of the obligation whoever produced it; the boundary validates it
against the formula and reports a failed refinement. It never becomes
evidence, so there is nothing for provenance to protect, and gating it would
turn a true counterexample from an untrusted runner into a deferral for no
gain in soundness.

### `DischargeRecord` and `PipelineResult` stay public

A record is a wire artefact that outlives the elaboration that produced it,
and `PipelineResult` is the elaborator's own result type. Neither is a
capability: holding a record is not the same as the pipeline having admitted
one, and the boundary is where admission happens. Sealing either would
couple a stored artefact to a process that no longer exists, which is the
wrong direction, and the recheck and rerun that §3 requires would still be
needed. The seal is on the producer of the evidence, not on the evidence.

### A test profile is rejected

A second `SolverProfile` for tests, pointing at a local binary, was
considered and rejected. `validSolverProfile` is equality with
`defaultSolverProfile`, so a test profile would either be refused by every
guard or would need those guards weakened. The injected runner already gives
the suites every refusal and drift case; what it cannot give is the positive
branch, and that branch is exercised against the pinned binary itself on the
platform the pin names.

### The pinned executable is resolved by rule, not searched

`pinnedExecutable` takes an explicit absolute path if one is given; otherwise
`FIRTH_SMT_SOLVER` must hold an absolute path. A relative path, explicit or
from the environment, is refused, and `PATH` is never searched: which file is
meant must not depend on where the process was started. Resolution says
nothing about what is at the path; the digest pin, verified by `verifyPin`
before any invocation, does. An executable that cannot be resolved is a runner
with no path, so it is refused as `executableMissing` after the same profile
and request checks an injected runner sees, and after the record's own drift
check in a rerun.

### `private` is name mangling, and what backs it

Lean's `private` does not remove the constructor; it mangles its name, and
metaprogramming could rebuild it. Within this repository that is refused by
`tools/loop/check_smt_attestation.py`, a lint that requires exactly one
`private mk ::` inside `structure Attested`, refuses `Attested.mk`,
`_private` and mangled-name metaprogramming elsewhere under `src/`, and
requires exactly two provenance-gated record-publishing sites in
`Refinement.lean`. The source envelope binds every Lean file and the compiled
proof-module manifest, which now includes `SmtSolver.olean`, binds the built
module. Lean callers outside the repository are outside the trusted computing
base, which is where the PRD already puts them.

### The model run is classified before it is parsed

Two review findings are fixed in the same unit because they are about what a
`pinnedProcess` result may contain. The second, model-fetching invocation is
classified by `classifyTranscript` like the first, so a crash, a resource
limit or an answer other than `sat` on that run is reported as that and never
parsed into a counterexample; only a `sat` answer has the text after its first
line parsed. `parseModel` accepts one grammar: one outer list, an optional
leading `model` keyword, `define-fun` entries for declared symbols at their
sort, nothing after the closing paren, and no symbol defined twice.

## Relation to the earlier decisions

The frontmatter relation is `related`, not `supersedes`. `dec.smt-bounded-solver-invocation`
still describes the seam, the pin, the wall clock and the second invocation,
and this decision depends on all of it; its sentence "`processRunner` is the
only implementation that spawns anything" is refined to "and `solvePinned` is
its only production caller". `dec.smt-discharge-record-recheck` still describes
promotion, the record and both halves of the recheck; its sentence "`checkUnsat`
is the only producer of `checkedUnsat`, and promotion happens at the boundary"
stands, and the boundary now asks one more question after promoting.
`dec.smt-adapter-integration-tests` still describes what an integration test
of the slice has to run and what it may assume; its sentence "a bare `unsat`
from the pinned solver, bound to the queued request, is promoted and does
discharge" is now true only when "from the pinned solver" is what the type
says, so the injected suite asserts the deferral instead, and the positive
branch it could not run is run by the pinned binary in CI.

## Consequences

- `LeanEscalationReason` gained `unattestedProvenance`, with the stable code
  `firth.smt.unattested-provenance` from `Firth.Smt.Solver`.
- `Refinement.lean` imports `SmtSolver`, so `SmtSolver.olean` is a governed
  proof module and the manifest has seven entries.
- The injected suites assert deferral where they asserted a record, build
  fixture records through the public constructor, and state in their headers
  that the record-producing branch needs the pinned binary.
- `src/smt/FirthSmtPinnedRefusalTest.lean` runs on every CI host, and
  `src/smt/FirthSmtPinnedSolverTest.lean` runs in the `smt-pinned-solver` job
  on an arm64 runner after the host's `sha256sum` confirms the pin.
- The TCB manifest's solver condition names the spawned, digest-verified
  process and lists `unattested-provenance` among the excluded results.
- No production consumer of `PipelineResult.dischargeRecords` exists yet;
  wiring the SMT queue through `solvePinned` is `language-06`.
