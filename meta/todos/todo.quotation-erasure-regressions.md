---
node: firth.toolchain.elaborator
status: in_progress
created: 2026-09-09
---

## Goal

Fix quotation erasure regressions exposed by the actual differential campaign.

## Acceptance criteria

- `[ dup drop ]`, `[ swap ]`, cumulative drops and nested stack-only quotations
  must infer non-empty inputs instead of failing because the search bound is one.
- Explicit source `dip` must reach the existing kernel/checker semantics.
- Keep independent exact kernel goldens and the original failing generated cases.
- Pass pinned Lean proofs, source/compiled binding checks, the same real seed
  matrix and complete repository gates. Do not weaken the comparison or filter
  failing features.

## Traceability

PRD G2/G6, R4/R5; `language-04-differential-execution`.
Red commit: `52696f539b99aef57bd53d55ce067b0c97119d34`.
CI run: `34308325332`, retained `language-diagnostics` artefact `10087491235`.
Implementation and verification: `meta/changes/quotation-erasure-regressions/`.
