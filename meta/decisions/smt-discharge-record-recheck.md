---
id: dec.smt-discharge-record-recheck
nodes: [firth.toolchain.smt]
status: accepted
related: [dec.smt-bounded-solver-invocation, dec.smt-adapter-soundness-bridge, dec.smt-checked-adapter-pipeline]
informed_by: [src.refinement-discharge-architecture]
date: 2026-09-03
---

# Discharge records: what a record is, who may make one, and what rechecking proves

## Context

`spec/smt/refinement-discharge-architecture.md` §3 requires a content-addressed
`DischargeRecord` carrying every input that determined a discharge, and says
that a cache hit is usable only when all of those inputs and the solver profile
match exactly, that rechecking recreates the formula from the typed IR,
verifies the hashes and profile, and reruns the selected checker, and that a
stale, missing or mismatched record is an open obligation rather than a
remembered success.

Before this unit `ExternalOutcome` had no checked-unsat constructor at all:
`dec.smt-bounded-solver-invocation` deliberately left a bare `unsat` as
`uncheckedUnsat`, because adding a checked constructor without the record and
its recheck would have put an unrechecked result into evidence.

## Decision

### `checkUnsat` is the only producer of `checkedUnsat`, and promotion happens at the boundary

`ExternalOutcome.checkedUnsat` is not something a solver can answer or a
transcript can classify into.
`classifyTranscript` still produces `uncheckedUnsat` and nothing else, and the
one function that promotes it verifies, in order: that the profile is the
pinned profile and is the request's own profile, that the request rebuilds to
itself under the checked adapter, that the result is bound to that request's
canonical identity, that the translation-rule and soundness-proof bindings are
valid and are the request's, and that the formula classifies into the fragment
the pinned profile supports.

That last check is not bookkeeping. `validUnderBinding_of_scriptUnsatisfiable`
is the bridge theorem that says what an `unsat` establishes, and its
hypotheses are about a QF_LIA formula; promoting an `unsat` for a formula
outside that fragment would claim a soundness argument the repository does not
have.

`ExternalOutcome` is a public inductive, so nothing in the type stops a caller
from constructing a `checkedUnsat` and presenting it as already checked. The
pipeline therefore does not accept one: `recordExternalOutcome` refuses a
result that arrives already promoted, and promotes an `uncheckedUnsat` itself
by calling `checkUnsat`. "Checked somewhere" is exactly the claim a record must
not rest on, and this is what turns "`checkUnsat` is the only producer" from a
property of the code as written into a property the boundary enforces.

Making promotion a single function called at the boundary is also what makes
the negative claim checkable: an audit of "can an unchecked answer become
evidence" is a search for constructions of `checkedUnsat`, and there is exactly
one.

`makeDischargeRecord` repeats those bindings rather than assuming
`checkUnsat` established them against *this* request, because the result and
the request reach it as separate arguments. Without that repetition a checked
result for one request could be recorded against another, and the record would
name a question the solver never answered.

### Records are content-addressed by canonical framed string, not by digest

`normalisedFormulaHash`, `smt2Hash`, `evidenceHash` and `requestIdentity` are
canonical framed strings, the same construction `obligationIdentity` and
`canonicalSmtRequest` already use, and `canonicalDischargeRecord` gives the
whole record an address of the same kind. The identity of a record is
determined by its bytes either way, and framing keeps a second hash
implementation off the evidence path. The elaborator already owns one digest
boundary, for the governed proof modules, and it earns its keep because those
digests are compared against a manifest written by another tool. Here both
sides of every comparison are computed in the same process from the same
definitions, so a digest would add a trusted component and buy nothing.

The field names keep the spec's `_hash` spelling because the spec names them,
and because what matters about them is that they are a content address, not
which function computed it.

The record's own address quotes the whole solver profile, licence and
acquisition source included, through `canonicalSolverProfile`.
`canonicalRequestIdentity` quotes only the fields that determine what was asked
and of which binary, because that is all a result must be bound to; a record
outlives the run, and §6 makes the binary, version, licence and invocation
options part of it.

### The recorded normalised formula is the one the encoder consumed

`spec/smt/refinement-discharge-architecture.md` §3 names the normaliser ahead
of the VC generator in the translation chain, so by the time an obligation
exists its formula is already in the shape the encoder consumes.
`checkedSmtRequest` takes that formula and nothing rewrites it on the way to
the serialiser, so `canonicalNormalisedFormula request.formula` addresses the
normaliser's output rather than a second artefact that never reached the
solver.

`Firth.Elaborator.Refinement.normaliseFormula` is not that stage. It collapses
a conjunct list into one predicate and exists to carry
`valid_normaliseFormula_iff`, which is a proof-side device; putting it on the
translation path would change every emitted script for no gain in what the
record binds. Recording its output instead would have content-addressed
something the discharge did not depend on, which is the failure mode this field
exists to prevent.

### The whole source location is recorded

§3 lists "source location" as a record field. The binding carries the path and
both ends of the span, offsets included, rather than only where it starts: a
record that kept the start alone could not be pointed back at the text it came
from, which is the only thing the field is for.

### Every derived field is recomputed, never accepted

`makeDischargeRecord` takes the obligation binding, the request, the
normalised formula and a checked result, and derives the translation hashes,
the normalised-formula address, the SMT-LIB address, the request identity, the
solver identity, version, executable digest and invocation options, the
profile and the evidence address from those. It accepts no caller's claim
about any of them. A record therefore cannot assert a translation, a request
or an evidence payload it was not produced under, which is the property that
makes the recheck below meaningful rather than circular.

The one thing it does take on trust is the obligation binding, because that is
elaborator-owned; `Refinement.obligationBinding` is the only function that
builds one, and it reads every field off the obligation's own context.

### The binding is plain strings, not elaborator types

`ObligationBinding` holds the word id, body hash, erased word type hash, spec
hash, callee contract hashes, predicate definition hashes, generator and
normaliser versions, toolchain revision and source location as strings and
naturals. A record is a wire artefact that outlives the elaboration that
produced it, so coupling it to the elaborator's types would be the wrong
dependency as well as the wrong direction: `firth.toolchain.smt` does not
depend on the elaborator's `Obligation`, and a record read back from disk must
not need one.

### Rechecking returns the request; it does not return a verdict

`recheckDischargeRecord` rebuilds the formula from the typed IR, revalidates
every binding, recomputes every field that is derivable without a solver and
compares it with the recorded one, and then returns the `SmtRequest` to run. It
deliberately does not conclude anything about satisfiability, because it
cannot: it has verified that the inputs still hold, and §3 asks for the rerun
as well.

One field is not derivable without a solver: `evidenceHash` addresses what the
solver said, so nothing but a run can recompute it.

`rerunDischargeRecord` is the other half, and lives in `SmtSolver` because it
is the half that needs `IO`. It rechecks, solves with the pinned runner,
promotes the answer through `checkUnsat`, rebuilds a record from the rerun,
and requires the rebuilt record to agree with the recorded one on every input.
Agreement across the whole record, rather than on the result field alone, is
what makes the record content-addressed in practice: a rerun that agrees on
`unsat` but disagrees on the serialised script or the invocation options has
not confirmed this record, it has produced a different one.

`evidenceHash` is the exception, because evidence is an output. §3 makes a
cache hit conditional on the inputs and the profile matching, and the same
`unsat` may come back with a different unsat core; requiring the core to
reproduce byte for byte would report a benign difference as tampering. So the
rerun compares every field but that one, and the verdict carries the rebuilt
record, whose evidence is what this run said.

A rerun that answers something other than a promotable `unsat` carries the
outcome alongside the refusal, because "the record no longer holds" and "the
obligation is now disproved by a model" are different facts and only the
outcome tells them apart.

Splitting the pure half from the effectful half also keeps every drift case
reachable from `lake test` on a host with no solver, which is the same
constraint `dec.smt-bounded-solver-invocation` records for the runner seam.

### Recheck failures are distinct deferred reasons

`RecheckFailure` separates a stale record (it is for another obligation) from
a tampered one (a recomputed field disagrees) from profile, digest, option and
translation drift, from a request mismatch, from a result that is not `unsat`,
and from an obligation that no longer translates at all. They are all deferred
non-success, so the pipeline treats them alike; naming them apart is for the
diagnostic, because "the solver moved" and "the record was edited" call for
different responses from whoever reads it.

### The pipeline promotes, records, rechecks, and does not rerun

`recordExternalOutcome` is pure and stays pure. On an `uncheckedUnsat` it
promotes, builds the record, rechecks it, and on success returns it in
`PipelineResult.dischargeRecords`; on any failure it queues the obligation for
Lean with that failure's code. It does not rerun the solver, because in that
position the answer in hand *is* this run: rerunning would re-ask the question
the result already answers. The rerun exists for a record loaded from a
previous elaboration.

`recordRerunVerdict` is where that rerun reaches the same boundary. The rerun
needs `IO` and the pinned runner, so it lives with the runner as
`rerunDischargeRecord`; what crosses back into the elaborator is a verdict, and
only a rechecked one yields a record. Splitting it that way is what lets the
result boundary stay in a pure, governed proof module while the rerun that §3
requires still reaches it.

## Relation to dec.smt-bounded-solver-invocation

That decision's last consequence records that `ExternalOutcome` has no
checked-unsat constructor and that promoting a bare `unsat` is this unit's
work. This decision is the discharge of exactly that sentence, and it is now
the current account of promotion: the constructor exists, `checkUnsat` is its
producer, and the refinement boundary calls it.

The frontmatter relation is `related`, not `supersedes`, because cairn's
`supersedes` asserts the target is retired and it is not: everything that
decision records about the runner seam, the pin, the wall clock, the second
invocation for a model, and binding a result to its request stands unchanged
and is depended on here.

## Consequences

- `PipelineResult` gained `dischargeRecords`, which is the refinement-discharge
  result boundary through which a validated `unsat` is exposed. It is empty for
  every other external outcome, so "was this discharged externally" is a
  question about one field.
- `LeanEscalationReason` gained `dischargeRecordRejected`, which is what a
  promoted `unsat` that produced no acceptable record escalates as. Reusing
  `uncheckedUnsatRejected` would have said the solver's answer was unchecked,
  and `externalRequestIneligible` would have said the request was, and neither
  is what happened. A promotion that is refused still escalates as
  `uncheckedUnsatRejected`, because that is precisely what happened.
- The construction and recheck failures inside the pipeline's promotion path
  are unreachable under the guards that precede them. They stay because they
  make "every record this boundary emits is a record that rechecks" true by
  construction rather than by an argument about guards written elsewhere, and
  because the guards and the recheck are separate code that can drift apart.
- `Refusal` and `RecheckVerdict` moved from `SmtSolver` to `SmtBoundary`. The
  boundary already owns `CheckFailure` and `RecheckFailure`, and the elaborator
  needs the verdict to report a rerun without importing the runner.
- `externalReason` and `externalData` map `checkedUnsat` to the same rejection.
  That branch is reachable only if a future caller routes a checked outcome
  through the generic escalation path, and it fails closed there rather than
  being a partial match.
- A record cannot outlive its translation. Regenerating the proof bindings
  changes `defaultSmtProofBindings`, and `recheckDischargeRecord` compares the
  recorded hashes against those, so every stored record becomes an open
  obligation on the next translation change. That is the intended cost.
- Nothing writes a record to disk yet. Serialisation and the cache are outside
  this unit; what exists is the record, its construction rule, and both halves
  of its recheck.
