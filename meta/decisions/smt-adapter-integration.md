---
id: dec.smt-adapter-integration
nodes: [firth.toolchain.smt]
status: accepted
related: [dec.smt-adapter-integration-tests, dec.smt-record-integrity-tests, dec.smt-discharge-record-recheck, dec.smt-bounded-solver-invocation, dec.smt-adapter-soundness-bridge, dec.smt-solver-profile-binding]
informed_by: [src.refinement-discharge-architecture, src.z3-5.0.0-release, src.z3-licence]
date: 2026-09-03
---

# Closing the external SMT slice: what the whole chain binds, and the one gap closing it exposed

## Context

`todo.smt-adapter-integration` is the parent of eight units. Seven of them
landed a piece: the solver pin, the checked adapter pipeline, the encoder and
serialiser proofs, the normaliser and VC-generator proofs, the proof bindings,
bounded invocation, discharge records with their recheck and rerun, record
integrity coverage, and slice-level integration coverage.

Closing the parent is not a formality. Its criteria are the union of the
children's, and a union can have a hole no child owned.

## Decision

### The parent's proof-binding criterion covers five stages, and only three were bound

The criterion, and `spec/smt/refinement-discharge-architecture.md` §3 behind
it, names five: the typed-IR normaliser, the VC generator, the sort and theory
encoder, each registered predicate translation, and the final SMT-LIB
serialiser. "Their translation-rule and soundness-proof hashes are included in
the discharge record."

`defaultSmtProofBindings` bound the encoder and the serialiser (plus the
adapter bridge that says what an `unsat` establishes). It did not bind the
normaliser or the VC generator, because `tools/loop/update_smt_proof_bindings.py`
read only `src/smt/Firth/SmtBoundary.lean` and those two live in the
elaborator. No child todo owned that gap: `todo.smt-normaliser-vc-proofs` asked
for the proofs and got them, and `todo.smt-serialiser-proof-bindings` asked for
the serialiser's identities and got those.

It is a real gap rather than a bookkeeping one. Without it a record carries
`normaliserVersion` and `vcGeneratorVersion`, which are context strings set by
the caller, so the normaliser could change while a stored record kept claiming
provenance. That is exactly the failure the sentence exists to prevent.

So the generator now reads both files, and the bindings are four translation
rules and six soundness proofs: encoder, serialiser, normaliser and VC
generator rules, and encoder, serialiser, adapter, normaliser,
normaliser-validity and VC-generator proofs.

`normaliser-validity` is separate from `normaliser` because the theorems are
separate: `evalPredicate_normaliseConjunction` and its corollaries say the
normalised predicate has the source semantics, while `valid_normaliseFormula_iff`
says normalising a formula preserves validity, and it sits far from the others
because it needs `Valid`. Naming them apart is honest about what each hash
covers, and the generator refuses two rule sets or two proof sets that share a
name for the same reason.

`normaliseFormula` moved up beside the other two normaliser definitions so one
marked region covers the rule set. Nothing between them referred to it.

### Names may be shared across kinds, never within one

A rule set and its soundness proofs share a name on purpose: `encoder` rules
and `encoder` proofs are two hashes about one stage. Two rule sets sharing a
name would make a hash ambiguous about what it covers, so the generator refuses
it.

### The recorded normalised formula is the VC generator's output

`dec.smt-discharge-record-recheck` records why `normalisedFormulaHash`
addresses `request.formula`: §3 puts the normaliser ahead of the VC generator,
so an obligation's formula is already in the shape the encoder consumes, and
nothing rewrites it on the way to the serialiser. Binding the normaliser's
proofs into the record is the other half of that argument. The claim is no
longer only that the pipeline is normalised, but that the proofs saying so are
identified by the record, so a record cannot outlive them.

## Consequences

- Every stage §3 names is now identified in every request and every record. A
  change to any of them invalidates every stored record, which is the intended
  cost and is what `tools/loop/test_smt_proof_bindings.py` catches without a
  build.
- `firthRecordIntegrityTest` asserts the counts and that no two stages share a
  soundness hash, so adding a stage without a hash, or copying one, fails.
- The remaining trust in the slice is exactly what the PRD's R8 allows: the
  pinned solver's `unsat`, inside the fragment the bridge theorem covers, from
  a binary whose digest was verified before it ran. Nothing else the solver
  says is evidence: a `sat` is a failed refinement, and everything else is
  deferred.
- Unsat cores are recorded as evidence and never as certificates, per §3's own
  rejection of treating them as such. The decision script does not request one
  today, so the evidence address covers the answer text.
