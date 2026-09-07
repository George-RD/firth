---
node: firth.toolchain.elaborator
status: open
created: 2026-09-08
---

## Goal

Reject unchecked guarantees and malformed adapter input.

## Acceptance criteria

- Source refinements on inputs, outputs, helpers and vocabulary words must not produce checked artefacts until translated and discharged. Test both true and false annotations.
- Empty programs fail with a structured diagnostic. Unsupported linear quotation values fail instead of losing ownership metadata.
- Malformed quotation capture-state lengths fail before canonical hashing in direct, literal and nested positions. Real process tests must detect crashes, not just exceptions in mocks.
- Run tools/loop/check_trust_boundaries.py and the complete language and governance gates. Record red and green commits without changing expectations or proof pins.

## Traceability

PR #109; PRD G2-G4, R4/R8/R12. Implementation is on the PR; acceptance remains pending the final gates.
