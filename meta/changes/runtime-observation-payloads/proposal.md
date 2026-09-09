# Proposal: runtime-observation-payloads

Fix two observation defects under `todo.language-03-runtime-conformance`
(PRD R5/R7/R8). The Rust conformance renderer currently collapses every byte
vector to `bytes` and every primitive value to `primitive`, so distinct
residual stacks can compare as agreement. Named-entry report execution runs
the right word but labels its root cost steps and trace frames `main`.

Preserve byte payloads and primitive tags/payloads in an unambiguous textual
form. Attribute report execution to the resolved word, including quotation
execution within that word. Add public-API regressions which fail against the
unchanged runtime, and retain the frozen Lean corpus and all proof pins.

This is a bounded correction, not complete conformance acceptance. Quotation
result bodies/captures and residual frame state remain lossy in the separate
Rust comparison surface. Full trace comparison, image/patch proof admission,
SMT process provenance and the baseline audit remain open.
