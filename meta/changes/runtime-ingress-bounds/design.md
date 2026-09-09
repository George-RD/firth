# Design: runtime-ingress-bounds

Move the existing `measure_*` helpers from std-only image patching into
`resource_bounds.rs`, included by the no_std core as well as std builds.
Measurement uses checked aggregate byte accounting and inspects lengths before
iterating, copying, hashing or canonical encoding. Images use the exact wire
size, with 4096-element vector limits and a 1 MiB total limit. Input stacks use
the same canonical value-vector accounting with their own 1 MiB budget.

`validate_image` measures first, which covers direct execution, the image
store, rollback and byte decoding. The named report entry validates before
looking up a word, so even a missing entry cannot bypass bounds. Both report
and diagnostic execution validate initial-stack size, shape and quotation
capture indices before machine construction. Rejected diagnostic inputs have
no execution cost, frames, trace or World mutation.

Remove the second traversal of quotation code from both value and instruction
validation. A quotation advances nesting exactly once; a captured quotation
advances it in `validate_value_structure`, not once again in its parent.
Level 32 remains accepted and level 33 rejected for both code and captures.

Public-API integration tests cover before/after rejection, exact boundaries,
unexecuted nested data, malformed capture indices and std/no_std parity.
A subprocess deadline regression distinguishes bounded validation from the
old exponential walk without risking an unbounded test worker. Passing these
finite tests is not a general complexity or memory-safety proof.
