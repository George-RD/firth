# Design: smt-discharge-record-recheck

## Approach

`dec.smt-discharge-record-recheck` records the decisions that shape this unit:
that `checkUnsat` is the sole producer of a checked `unsat`, that records are
content-addressed by canonical framed string rather than by digest, that every
derived field is recomputed rather than accepted, that the binding is plain
strings so a record does not depend on the elaborator's types, that rechecking
returns the request rather than a verdict because the rerun is still required,
and that the rebuilt record must equal the recorded one.

The unit splits along the effect boundary. `SmtBoundary` holds the pure half:
promotion, construction, and the recheck that rebuilds the formula, revalidates
every binding and recomputes every derived field. `SmtSolver` holds
`rerunDischargeRecord`, which is the half that needs `IO`: recheck, solve with
the pinned runner, promote through `checkUnsat`, rebuild, and require equality
with the record in hand. Keeping the drift cases pure means `lake test`
exercises all of them on a host with no solver, matching the constraint
`dec.smt-bounded-solver-invocation` records for the runner seam.

`recordExternalOutcome` stays pure and does not rerun: in that position the
answer in hand is this run's answer, so it records and rechecks. The rerun
exists for a record loaded from a previous elaboration.

## Changes

ADDED:
- `ExternalOutcome.checkedUnsat`, produced only by `Firth.Smt.checkUnsat`.
- `CheckFailure` and `CheckFailure.code`: the six ways promotion can refuse.
- `ObligationBinding`, `DischargeRecord`, `canonicalNormalisedFormula` and
  `makeDischargeRecord`.
- `Fragment.canonical`, `canonicalSolverProfile` and `canonicalDischargeRecord`,
  which give a record an address of its own.
- `RecheckFailure`, `RecheckFailure.code` and `recheckDischargeRecord`.
- `Firth.Smt.Solver.RecheckVerdict`, `RecheckVerdict.code` and
  `rerunDischargeRecord`.
- `Firth.Refinement.obligationBinding` and `Firth.Refinement.recheckRecord`.
- `PipelineResult.dischargeRecords` and `Firth.Refinement.recordRerunVerdict`,
  the result boundary a rerun reports through.
- `LeanEscalationReason.dischargeRecordRejected`.
- `meta/decisions/smt-discharge-record-recheck.md`.

MODIFIED:
- `recordExternalOutcome`: promotes an `uncheckedUnsat` through the checked
  adapter, builds a record, rechecks it, and either exposes it or queues the
  obligation for Lean with the failure's code. A result that arrives already
  promoted is refused.
- `Refusal` and `RecheckVerdict` moved from `SmtSolver` to `SmtBoundary`, so
  the elaborator can report a rerun without importing the runner.
- `discharge`: its fold now carries `dischargeRecords`, which it silently
  dropped.
- `externalReason` and `externalData`: total again over the widened
  `ExternalOutcome`, failing closed on `checkedUnsat`.
- `src/smt/FirthSmtSolverTest.lean`: promotion refusals, record construction,
  recheck drift, and the rerun verdicts under an injected runner.
- `src/elaborator/FirthRefinementTest.lean`: an unchecked `unsat` creates no
  record, a checked one creates exactly one with no Lean queue and no
  diagnostic, the record binds the obligation id, the normalised formula and
  the request identity, `recheckRecord` rebuilds the request, and a stale body
  hash is `recordStale`.
- Both generated manifests, regenerated.
