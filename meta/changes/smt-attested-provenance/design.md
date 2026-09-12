# Design: smt-attested-provenance

The digest pin authenticates the binary; a sealed type authenticates that the
pin was actually exercised in this process. Everything pure stays public. The
only value that can admit a discharge is one whose constructor lives in the
module that spawns the solver.

`Firth.Smt.Solver.Attested α` carries a `Provenance` and a value behind a
`private mk ::` constructor. Outside `SmtSolver.lean` the anonymous
constructor, structure instance notation, the named constructor, `with`
updates and constructor patterns all fail to elaborate, while both projections
stay readable; this was checked against Lean 4.30.0 before the design was
adopted. `injected` is the one public way to build a value and always yields
`injectedRunner`. `solveWith` and `rerunWith` are private and take the
provenance as an argument; `solve` and `rerunDischargeRecord` pass
`injectedRunner`, `solvePinned` and `rerunPinned` pass `pinnedProcess` and are
the only callers of `processRunner`. `verifyPin` is unchanged and runs for
both provenances, so the refusals are identical; a pinned executable that
cannot be resolved is a runner with no path, refused as `executableMissing`
after the same profile and request checks, and after the record's drift check
in the rerun.

The executable is resolved by rule: an explicit absolute path wins, otherwise
`FIRTH_SMT_SOLVER` must hold an absolute path; a relative path is refused and
`PATH` is never searched. Only the digest pin says what is at the path.

`recordExternalOutcome` and `recordRerunVerdict` take the attested types and
bind `.value` where the result was. Every guard, promotion through
`makeDischargeRecord` and recheck run as before, so each refusal stays
observable with injected results; the provenance check is the last gate and
yields `LeanEscalationReason.unattestedProvenance` with the stable code. A
validated `sat` is provenance-independent because a countermodel that refutes
the obligation is a refutation, never evidence. `DischargeRecord` and
`PipelineResult` do not change: a record is a wire artefact and the result is
the elaborator's, and neither is a capability.

The model run is classified by `classifyTranscript` before its output is
parsed, with only a `sat` answer parsed, from its second line onward, as a
model. `parseModel` accepts exactly one outer list, an optional leading
`model` keyword, entries of declared symbols at their sort, and nothing after
the closing paren; a symbol defined twice is an error.

`Refinement.lean` imports `SmtSolver`, so `SmtSolver.olean` joins the governed
proof modules after `SmtBoundary`; the manifest grows to seven entries. Every
Lean edit changes all ten source-envelope hashes while no marked region body
changes; both are regenerated from the final sources and the pinned build.

`tools/loop/check_smt_attestation.py` is a lint, not a proof: one sealed
constructor inside `structure Attested`, no `Attested.mk`, `_private` or
mangled-name metaprogramming elsewhere under `src/`, and exactly two
provenance-gated `dischargeRecords := [...]` sites in `Refinement.lean`.
