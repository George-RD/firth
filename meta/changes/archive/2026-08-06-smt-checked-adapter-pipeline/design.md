# Design: smt-checked-adapter-pipeline

The dependency-free SMT boundary will expose a pure request constructor:
`checkedSmtRequest profile formula` returns either a typed `SmtRequest` or a
typed translation error. It first validates the exact pinned profile and the
closed-world fragment classification, then collects integer and Boolean
variables from the IR, assigns stable sort-specific symbols in lexical order,
and renders a complete SMT-LIB2 QF_LIA script. Source identifiers never appear
in solver symbols.

The request contains the profile, original typed formula, generated bindings,
and serialised script. Queue construction stores it alongside the existing
length-framed obligation request. Queue validation requires the request to
rebuild exactly from the obligation formula and profile, so forged or stale
scripts cannot be interpreted as eligible external requests. The existing
typed `SmtResult` remains the result boundary; solver execution and outcome
classification remain outside this unit.

## Changes

ADDED:
- Checked QF_LIA request and deterministic SMT-LIB serialisation functions in
  `src/smt/Firth/SmtBoundary.lean`.
- Regression assertions in `src/elaborator/FirthRefinementTest.lean`.

MODIFIED:
- `src/elaborator/Firth/Refinement.lean` stores and validates typed requests in
  eligible SMT queue entries.

REMOVED:
- None.

RENAMED:
- None.
