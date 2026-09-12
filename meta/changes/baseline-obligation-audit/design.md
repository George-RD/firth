# Design

## Audit rule

An obligation whose `satisfied_by` names only specification, research or
prior-art todos is design-evidenced, not implementation-evidenced
(dec.usable-language-milestones clause 2). For each such row the audit either
links the existing implementation todo that already serves it, or opens a new
implementation todo whose premise is verified in the code at `80a9d41`. A
premise that does not hold is adjusted and recorded, never papered over.

## Modified

`tools/loop/obligations.toml` gains links only. `specs/tcb-boundary.toml`
gains the `compiler-admission` stage and pins `lean-test-driver` and
`compiler-admission` as compiler evidence, because `vm-conformance` and
`vm-fixtures` exercise emitted target code and never the Lean compiler.
`tools/loop/check_tcb_boundary.py` pins the identical stage tuple so an
unpinned or missing stage fails closed; `tools/loop/test_tcb_boundary.py`
adds the positive and mutation tests. `firth.runtime.image` and
`firth.runtime.patch` move from `planned` to `implemented`, the patch row
annotated that its digests are unauthenticated content identifiers;
`firth.toolchain.elaborator.cache` records the landed record recheck. The
`smt-solver` component and its excluded results are not touched.

The eleven `gap-firth-language-kernel-*` decisions become `accepted` with a
Resolution citing the frozen specification section and the Lean theorem that
settles each question. The runtime patch gap stays `proposed` with a note
naming its post-mvp owner. Two decisions get their provenance frontmatter
corrected; one gains a dated provenance note, and neither has its decision
text changed.

## Added

`todo.naming-grammar-lint`, `todo.stack-depth-lint-threshold`,
`todo.patch-refinement-evidence-admission` and
`todo.kernel-minimality-evidence`, each with a verified premise, acceptance
criteria that add evidence rather than reinterpret the requirement, and a
Traceability section naming the PRD requirement and matrix rows.

## Verification

Coverage must keep `loop_exhausted_valid` false with no missing, failing or
blocked gates and no ungenerated rows; the selector must still validate; all
Python suites, the TCB checker, Cairn scan (zero Errors) and hooks must pass.
