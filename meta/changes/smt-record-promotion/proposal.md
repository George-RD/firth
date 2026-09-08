# Proposal: smt-record-promotion

## Motivation

PR #109 review discussion_r3930474585 identifies a public constructor bypass:
`makeDischargeRecord` accepts `ExternalOutcome.checkedUnsat` without owning the
promotion. Separately, `recordRerunVerdict` publishes a caller-supplied record
without checking its binding to the current obligation.

This is a bounded implementation slice of `todo.language-01-smt-record-admission`,
traced to PRD G4 and R8/R9/R15. It does not complete that todo.

## Scope

Move promotion into record construction, migrate its production callers, reject
pre-promoted results, and recheck rerun records at the refinement result boundary.
Cover both successful construction and forged, stale and mismatched inputs in
the existing Lean suites. Preserve unknown/timeout as deferred outcomes.

## Boundaries

Public result and record structures are data, not authenticated proof objects.
This change does not authenticate caller-created raw solver transcripts or prove
that a caller-created rerun verdict came from a real invocation. A trusted
production runner boundary and transitive translation-helper binding remain open.
Do not mark the parent todo, baseline acceptance or MVP complete.
