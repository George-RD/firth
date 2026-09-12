# Proposal: smt-attested-provenance

## Motivation

`todo.language-01-smt-record-admission` stayed open after the promotion and
source-envelope slices because a matching raw `uncheckedUnsat` value and a
matching public `rechecked` verdict are data, not evidence that the pinned
solver was ever run. `recordExternalOutcome` published a discharge record for
a hand-built result, even for a false obligation, and `recordRerunVerdict`
published a caller-labelled record; a stub `SolverRunner` reporting the pinned
digest reached both. PR #109 review discussion_r3930474585 identifies the
public constructor bypass; PRD G4 and R8/R9/R15 are the requirements.

## Scope

Seal the producer. Every solver result and rerun verdict leaves
`Firth.Smt.Solver` in an `Attested` wrapper whose constructor is private to
that module, the one module that spawns a process. `solvePinned` and
`rerunPinned` resolve the pinned executable, verify its digest and spawn it,
and are the only producers of `pinnedProcess`; caller-supplied runners and the
public `injected` wrapper produce `injectedRunner`. The refinement boundary
keeps every metadata check, promotion and recheck unchanged and, last, admits
a record only from `pinnedProcess`; everything else is deferred with
`firth.smt.unattested-provenance`. The model run is classified before it is
parsed and the model parser accepts one explicit grammar. `SmtSolver` joins the
governed proof modules, a forge lint refuses in-repository ways around the
seal, and the positive branch runs against the pinned binary on an arm64 CI
job. The parent todo is closed with its residual limitations recorded.

## Boundaries

The pinned solver's `unsat` remains trusted within the PRD allowance; no
certificate is checked. The host digest tool and the window between digest and
spawn are host trust the proof-module authentication already relies on. Lean
`private` is a naming discipline backed by the lint, the source envelope and
the compiled manifest; out-of-repository Lean callers are outside the TCB. No
production consumer of `PipelineResult.dischargeRecords` exists yet; wiring the
SMT queue through the pinned solver is `language-06`. Baseline acceptance is
not claimed by this change.
