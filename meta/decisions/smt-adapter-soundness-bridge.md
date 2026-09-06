---
id: dec.smt-adapter-soundness-bridge
nodes: [firth.toolchain.smt]
status: accepted
related: [dec.refinement-discharge-architecture]
informed_by: [src.refinement-discharge-architecture]
date: 2026-09-03
---

# What an SMT `unsat` verdict establishes, and how its provenance is bound

## Context

`todo.smt-lean-adapter-proofs` asks for semantics-preservation proofs across
the translation pipeline, a proof that the serialiser preserves the encoded
formula, and computed translation-rule and proof hashes bound to every request
and record.

The encoder and serialiser theorems already existed. Two things did not: any
theorem saying what an answer to the emitted script means, and any tool
producing the hashes, which were two literal constants.

## Decision

### The bridge concludes validity over binding valuations, not `Valid`

The emitted script asserts the premises and the negation of the conclusions,
so a model of it is a valuation satisfying the premises and falsifying some
conclusion, and `unsat` says no such model exists. Turning that into a
statement about the obligation runs into a mismatch between two model
theories.

An SMT model is total: it assigns every declared symbol. A Lean `Valuation` is
a partial association list, and a predicate mentioning an unbound variable
evaluates to `none`, which is neither true nor false.
`Firth.Elaborator.Refinement.Valid` quantifies over every valuation, including
one that satisfies the premises while leaving a conclusion's variable unbound.
No solver answer can rule that case out, because the solver never considers
such an assignment.

The bridge therefore concludes `ValidUnderBinding`, which quantifies over
valuations binding the formula, and `Binds` is the same totality condition
`validatesCounterexample` already imposes on a model offered as a
counterexample. The two discharge paths are consequently not symmetric: Lean
discharge reaches the unrestricted `Valid`, because a closed predicate
evaluates identically under every valuation, and external discharge reaches
`ValidUnderBinding`. Stating that precisely is the point. Claiming `Valid`
from an `unsat` would be the kind of quiet overreach the checked-artefact
boundary exists to prevent.

`validUnderBinding_of_scriptUnsatisfiable` also requires the formula to be
QF_LIA-encodable, and that hypothesis is load-bearing rather than
bureaucratic: without it a formula containing an untranslatable predicate
would have no model at all, `ScriptUnsatisfiable` would hold vacuously, and
the theorem would prove anything. `checkedSmtRequest` already refuses such a
formula before any solver contact, and `checkedSmtRequest_formula` records
that the adapter does not rewrite the formula it was asked about, so a verdict
on the request is a verdict on the obligation.

### The hashes cover marked regions, not the whole file

The translation-rule and soundness-proof hashes live in
`defaultSmtProofBindings`, inside the very file whose translation rules they
cover. A whole-file hash would therefore have no fixed point: writing the
hashes would change the file and so the hashes.

`tools/loop/update_smt_proof_bindings.py` hashes explicitly marked regions
instead: two translation-rule regions, the QF_LIA encoder and the SMT-LIB
serialiser, and three soundness regions, the theorems for each of those plus
the adapter bridge. `defaultSmtProofBindings` sits outside every marked
region, so the generator is a fixed point, and `tools/loop/test_smt_proof_bindings.py`
asserts that rather than assuming it. Marked regions are also more honest than
a whole-file hash, which would churn on a comment while saying nothing about
whether a translation rule moved.

The alternative, normalising the hash literals out of a whole-file digest, was
rejected: it hides which bytes are covered behind a rewriting rule.

## Consequences

- A discharge record can state what its solver answer established, and the
  statement is a Lean theorem rather than a convention.
- Editing a translation rule or one of its proofs without regenerating the
  bindings is a test failure, so a record cannot outlive the translation it
  was produced under.
- `ValidUnderBinding` is weaker than `Valid`. An obligation whose conclusions
  mention a variable its premises do not is discharged only over valuations
  that bind it, which is exactly what the solver examined.
