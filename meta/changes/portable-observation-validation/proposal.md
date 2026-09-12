# Proposal: fail-closed portable observation comparison

## Problem

At PR #109 head `9d5aa71e32824f55bdc8701a8fe82e9dff09d2c3`, the
portable acceptance gate compares result stacks with Python equality before
validating their values. Matching malformed objects can pass, and Python
compares a Boolean payload equal to an integer. The pure-world sentinel has
the same coercion gap. Returned quotations do not have a shared body/capture
representation, so equality of their transport fields cannot establish
quotation equivalence.

## Scope

Implement the portable-comparison slice of `language-03-runtime-conformance`.
Validate both result stacks before comparison, reject returned quotations
explicitly, validate pure-world sentinels without numeric coercion, and reject
ambiguous adapter JSON. Add negative cases through the actual Python boundary
and real compiler/VM/reference quotation-result cases in the existing CI gate.

## Boundaries

No change to kernel semantics, proof modules, authoring inputs, frozen source
corpus, or expected arithmetic results. Internal quotations remain supported
when executed to supported scalar results. Source proof admission, Rust image
validation, the remaining runtime reviews, and the differential generator
remain separate open work. This does not accept or merge the baseline.
