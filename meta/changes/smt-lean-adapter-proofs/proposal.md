# Proposal: smt-lean-adapter-proofs

## Motivation

The encoder and serialiser theorems already related the source formula to the
script that is emitted, but nothing said what an answer to that script means.
Without such a theorem a discharge record would record a solver's verdict
about a string with no stated relation to the obligation, which is precisely
the trust the checked-artefact boundary is supposed to withhold.

The translation-rule and soundness-proof hashes were two literal constants
with no producing tool, so they pinned a value rather than binding a
translation.

## Scope

- The adapter-soundness bridge and the evaluability lemmas it needs.
- `tools/loop/update_smt_proof_bindings.py` and its drift test.
- Extending the axiom audit to every theorem the soundness hashes cover.

## Out of scope

- Solver invocation, discharge records, and their recheck. Those are the next
  three todos in the chain and depend on this one.
- `renderSmtLib` totality. `checkedSmtRequest` still returns an error rather
  than a request if a binding is somehow missing, which fails closed; proving
  it cannot happen is a strengthening, not a correctness gap.
