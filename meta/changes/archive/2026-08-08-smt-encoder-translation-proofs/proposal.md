# Proposal: smt-encoder-translation-proofs

## Motivation

The SMT boundary currently renders supported predicates but has no machine-checked
correspondence between source evaluation and the encoded QF_LIA fragment. This
leaves sort selection and every pure translation rule dependent on review rather
than Lean proofs.

## Scope

- Add a typed QF_LIA encoding and prove its integer and predicate semantics
  preserve the existing source evaluator.
- Prove formula encoding accepts exactly the supported fragment and preserves
  premise and conclusion semantics.
- Exercise the proof declarations and rejection paths in the Lean test driver.

## Out of scope

- Solver process execution, SMT-LIB parsing, serialiser proof bindings, and
  unsupported or effectful predicate semantics.
