# Proposal: runtime-conformance-closure

Close the remaining comparison and bounding gaps under
`todo.language-03-runtime-conformance` (PRD R5/R7/R8). The Rust conformance
renderer still collapses every quotation to `quotation-many` or
`quotation-linear` and every residual frame to `word@pc`, so different
bodies, captures, continuations and saved `DIP` values compare as agreement
through the library API and `firth-vm run`. The `firth.vm-run.v1` adapter
drops quotation bodies, omits frames and reports cumulative rather than
per-event charges, and no pinned gate compares traces at all, so a reordered
program with the same final stack passes. The executor recurses natively
without a bound and aborts the process on deep recursion, clones the whole
machine at every step, and both CLI readers buffer unboundedly; the JSON
transport is quadratic in object size, refuses escaped surrogate pairs and
counts quotation depth in a different unit from the decoder. Fuel is unbounded
on the Rust side while Python bounds it at 100000, pre-consumed capture
bitmaps are admitted, and nothing on an observation surface says that the
evidence digests are unauthenticated.

Render quotations and frames in full and make a usage-only or `word@pc`
reference an explicit unsupported comparison, never agreement. Report
per-event charges, per-event and residual frames, trap subcodes and an
admission label from the adapter, and compare the two hosts' traces event by
event after projecting both onto kernel-charged steps, labelling
quotation-valued traces unsupported rather than accepting them. Cap
administrative call depth and fuel, replace the per-step clone with a bounded
checkpoint, bound both readers, and fix the transport. Prove the S5 witness's
both-branches claim from the traces, bind the manifest's declared contract to
the gate, and add a subprocess-deadline gate for the bounds.

This is branch verification under bounded tests, not baseline acceptance.
There is still no cross-host quotation normal form, residual programs and
frames are not compared across hosts, evidence digests remain unauthenticated
and patch admission remains delegated to the caller's verifier.
