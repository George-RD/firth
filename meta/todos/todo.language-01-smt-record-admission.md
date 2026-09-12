---
node: firth.toolchain.smt
status: done
created: 2026-09-08
---

Requires: language-00-boundary-regressions

## Goal

Make SMT discharge-record admission impossible to forge.

## Acceptance criteria

- Reproduce the public checkedUnsat/makeDischargeRecord bypass against the current head.
- Admit records only through a checked promotion bound to formula, assumptions, request, solver profile and proof-module identities. Caller-selected constructors or strings are not proof.
- Reject forged, replayed, stale and mismatched results through the public refinement boundary. Keep unknown/timeout distinct from verified.
- Add negative tests and rerun source and compiled proof-binding checks; intentional proof changes must be reviewed, not repinned to hide a failure.

## Traceability

PR #109 review discussion_r3930474585; PRD G4, R8/R9/R15.

## Implementation slice: record promotion and current rerun binding

The `smt-record-promotion` change moves `checkUnsat` inside
`makeDischargeRecord`, rejects caller-created or previously promoted
`checkedUnsat` values, and migrates both solver and refinement callers.
`recordRerunVerdict` also rechecks a record against the current canonical
obligation instead of trusting the caller's `rechecked` tag. The existing
Lean suites cover both regressions, successful construction, metadata drift,
formula replay, non-unsat outcomes and stale rerun records.

This todo stays **open**. Matching metadata on a public raw `uncheckedUnsat`
value is not authenticated solver evidence, and a matching public rerun
verdict does not prove a process was invoked. The next admission slice must
make the production runner/result provenance unforgeable across the public
boundary, retain injected runners only as explicit test seams, and include
transitive translation helpers in proof-binding coverage. Do not substitute
this bounded fix or a green finite suite for the full acceptance criteria.

See `meta/changes/smt-record-promotion/` for scope and verification.

## Implementation slice: complete Lean source binding

The `smt-source-envelope` change binds each translation rule and soundness
region to all Lean package sources plus the Lake configuration, dependency
lock and toolchain pin. This includes unmarked helpers and their local
transitive dependencies. Old records intentionally become stale. Unsupported
source roots, third-party packages, symlinked inputs and ambiguous pin
initializers are refused, not silently omitted.

This closes the identified source-helper coverage gap for the declared,
dependency-free Lake build. It does not establish solver-process provenance:
matching raw `uncheckedUnsat` data and public rerun verdicts remain
unauthenticated. The parent task remains **open** until the production runner
boundary and its public-admission acceptance tests are complete.

## Implementation slice: attested solver provenance

The `smt-attested-provenance` change makes the production runner boundary
unforgeable across the public boundary. Every solver result and rerun verdict
leaves `Firth.Smt.Solver` wrapped in `Attested`, whose constructor is private
to that module, the one module that spawns the solver. Only `solvePinned` and
`rerunPinned`, which resolve the pinned executable from an explicit absolute
path or `FIRTH_SMT_SOLVER`, verify its digest against the pin and spawn it in
this process, produce `Provenance.pinnedProcess`; a caller-supplied runner or
the public `injected` wrapper produces `Provenance.injectedRunner`. The
refinement boundary keeps every metadata check, promotion and recheck
unchanged and, as the last gate, publishes a discharge record only from a
`pinnedProcess` value; anything else is deferred with the stable code
`firth.smt.unattested-provenance`. A validated `sat` stays
provenance-independent, because a countermodel is a refutation and never
evidence. The model-fetching run is now classified before it is parsed, and
the model parser accepts one explicit grammar. `SmtSolver` joins the governed
proof modules, `tools/loop/check_smt_attestation.py` refuses in-repository
ways around the seal, and the positive branch is exercised by the pinned
binary in the `smt-pinned-solver` CI job.

The acceptance criteria are met: the public bypass is reproduced by the
retained failing-before evidence; records are admitted only through a checked
promotion bound to formula, assumptions, request, profile and proof-module
identities and produced by the pinned process; forged, replayed, stale and
mismatched results are rejected with unknown and timeout kept distinct from
verified; and the negative tests, source-envelope and compiled-manifest checks
are rerun with the regenerated pins recorded for review. See
`meta/changes/smt-attested-provenance/` and
`meta/decisions/smt-attested-provenance.md`.

## Residual limitations

- The pinned solver's `unsat` is trusted within the PRD R8 allowance and
  `spec/smt/refinement-discharge-architecture.md` section 3: no certificate is
  checked, and an unsat core is an explanation, not a proof.
- The digest is computed by the host's `sha256sum` or `shasum`, and there is a
  window between computing it and spawning the executable. That is the same
  host trust the compiled proof-module authentication already relies on.
- The pin names linux-arm64-glibc-2.38. Every other platform can only refuse,
  so `lake test` exercises refusals and injected seams and the positive,
  record-producing branch is exercised only by the `smt-pinned-solver` job on
  an arm64 runner.
- Lean `private` is a naming discipline, not a proof. In this repository it is
  backed by the lint, the source envelope and the compiled manifest; Lean
  callers outside the repository are outside the trusted computing base.
- No production consumer of `PipelineResult.dischargeRecords` exists yet:
  `Pipeline.finishWords` fails any word with a non-empty SMT queue. Wiring the
  queue through the pinned solver is `language-06-source-refinement-execution`.
