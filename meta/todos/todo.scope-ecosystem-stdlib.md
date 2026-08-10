---
node: firth.ecosystem.stdlib
status: open
created: 2026-08-10
---

# Scope Ecosystem Stdlib
Requires:

## Goal
Define the initial standard library as Firth source with a small, portable vocabulary usable by Firth programs.

## Acceptance criteria
- Add a small core vocabulary under the declared `stdlib` path, written in Firth rather than a host-language implementation.
- Give every included word an explicit stack effect and ensure the vocabulary is consumable by the elaborator without introducing new kernel semantics.
- Exercise a basic Firth program using the vocabulary through the existing language gates and record the boundary for future verification work.

## Traceability
Serves the PRD 4.4 standard-library obligation `scope-ecosystem-stdlib` and the MVP reading of success criterion S4.

## Verification
- `lake build`
- `lake test`
- `python3 tools/loop/test_select_unit.py`
- `python3 tools/loop/test_coverage.py`
- `cairn scan`
- `cairn hook all`
