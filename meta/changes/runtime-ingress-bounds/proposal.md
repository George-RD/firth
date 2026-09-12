# Proposal: runtime-ingress-bounds

Close the direct-image and initial-stack resource-admission gap under
`todo.language-03-runtime-conformance` (PRD R5/R7/R8). The byte decoder and
patch path bound their inputs, but public in-memory execution and image-store
construction currently hash and traverse data outside those same limits.
Quotation validation also traverses nested code twice per level, making a
small, valid deeply nested image expensive to validate before fuel applies.

Reuse the existing allocation-free patch size accounting in the core, reject
oversized images and input values before canonical hashing or execution, and
visit quotation bodies only once per structural pass. Match the binary
format's quotation-depth convention for captured values. Keep the original
language corpus and proof pins unchanged.

This slice does not authenticate image or patch proof digests, solve SMT
process provenance, bound all runtime allocations, or establish complete
conformance. Legacy infallible image-construction helpers remain unchecked;
the accepted-image and execution boundaries must reject their invalid output.
