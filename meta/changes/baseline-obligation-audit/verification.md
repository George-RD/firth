# Verification, baseline obligation audit

Audit performed 9 September 2026 against base commit
`80a9d41` (PR #109 head, "Preserve runtime observation payloads and
named-entry attribution"); recorded and committed 10 September 2026. This is
a governance and evidence change: no file under `src/`, `examples/`, the
frozen specifications, `.github/workflows/ci.yml`, `todo.language-*.md` or
the `smt-solver` TCB component was modified. Lean and Rust gates were not run
here because nothing they check changed; ordinary PR CI still gates the
candidate.

This change does not mark `language-05-baseline-acceptance` done: its
merged-main criterion cannot be met on a branch. It does not change
`loop_exhausted_valid`, which stays `false` before and after.

## Audit table

Every active (`mvp` profile) row at `80a9d41`. Evidence classes: `mechanised`
(Lean theorem under the zero-admit gate), `implemented` (executable code with
tests under a pinned stage), `executable gate` (row pins a gate script),
`design` (specification, research or prior-art todo only), `in flight`
(an open implementation todo already linked), `stale` (done todos whose
evidence does not establish the requirement as written).

| Obligation | satisfied_by (after) | Class | Citation | Action |
| --- | --- | --- | --- | --- |
| scope-language-kernel-calculus | kernel-spec-freeze, kernel-metatheory | mechanised | `files/firth-kernel-spec-draft.md`; `src/interpreter/Firth/{KernelMetatheory,Progress,Linearity,CostInvariance}.lean` | none |
| scope-language-surface-syntax | surface-syntax-spec, elaborator-parser, elaborator-named-local-erasure | design + implemented | `spec/surface/syntax.md`; parser and `Erasure.lean` suites under `lake test` | linked two done implementation todos |
| scope-language-type-system | type-system, elaborator-stack-effect-inference, req-r3, req-r4, language-06-source-refinement-execution | design + implemented; refinements in flight | `spec/types/type-system.md`; `StackEffect.lean`; source refinements refused by `Pipeline.lean` until language-06 | linked; row now in flight |
| scope-language-quotations | quotation-typing-prior-art, elaborator-stack-effect-inference, quotation-erasure-regressions | design + implemented | quotation rules in `AtomTyping`; exact kernel goldens from the differential campaign | linked |
| scope-language-vocabulary-layering | scope-language-vocabulary-layering, language-12-data-and-modules | design; multi-file vocabularies in flight | `spec/surface/syntax.md` section 2.1; `todo.language-12` | linked; row now in flight |
| scope-language-spec-predicates | specification-predicates, language-06-source-refinement-execution | design; source predicates refused at 80a9d41 | `spec/types/specification-predicates.md`; `unsupportedSourceRefinements` in `Pipeline.lean` | linked; row now in flight |
| scope-language-naming-grammar | surface-syntax-spec, naming-grammar-lint | design only | no lint exists (only `LOCAL_DEPTH`, `STACK_JUGGLE` in `Erasure.lean`); "morpheme" occurs only in the PRD | new todo |
| scope-language-visibility-model | scope-language-visibility-model | design + implemented | `spec/surface/syntax.md` section 2; canonical name resolution in `Pipeline.lean` (`resolveNames`) under `lake test` | none; implementation is carried by the elaborator rows |
| scope-toolchain-elaborator | scope-toolchain-elaborator, language-00-boundary-regressions, language-06-source-refinement-execution | implemented; in flight | `src/elaborator`; `check_trust_boundaries.py` | none |
| scope-toolchain-interpreter | reference-interpreter | implemented | `src/interpreter`; `firthReferenceRunTest`; oracle adapter | none |
| scope-toolchain-compiler | mvp-agent-compiler-adapter, language-02-compiler-evidence, language-11-arithmetic-comparison | implemented; in flight | `firthCompilerTest` under `lake test`; `check_compiler_admission.py` (45 cases) | TCB evidence pinned (below) |
| scope-toolchain-diffharness | diffharness-fuzz-strategy, language-04-differential-execution | implemented | `src/diffharness/harness.py` seeds in CI | none |
| scope-toolchain-smt | refinement-discharge-design, language-01-smt-record-admission, language-06-source-refinement-execution | in flight | `smtBoundaryTest`, `smtSolverTest` | none |
| scope-toolchain-agent-interface | diagnostic-schema, language-20-agent-workflow | implemented; in flight | `firthAgentDiagnosticTest`; `todo.language-20` | none |
| scope-runtime-vm | rust-vm-implementation, language-03-runtime-conformance | implemented; in flight | `cargo test` (vm-conformance); `todo.language-03` | none |
| scope-runtime-image | rust-vm-dictionary-image | implemented | `src/runtime/vm/src/image*.rs` under vm-conformance | TCB status `planned` to `implemented` |
| scope-runtime-patch | rust-vm-patch-protocol, patch-refinement-evidence-admission | stale: VM-side admission only | `image_patch.rs` checks digest shape; `Lowering.lean` digests code and erased type | new todo; TCB status and comment |
| scope-ecosystem-stdlib | scope-ecosystem-stdlib, language-12-data-and-modules | in flight | `stdlib/core.firth` elaborates in `FirthPipelineTest` | TCB comment |
| scope-ecosystem-specs | component-spec-boundaries, kernel-spec-freeze, vm-target-spec | design (specification obligation) | `specs/`, `files/firth-kernel-spec-draft.md`, `src/runtime/vm/target-spec.md` | linked the two specification todos |
| req-r1 | kernel-spec-freeze, kernel-minimality-evidence | stale: minimality is prose | spec section 2 asserts minimality; no non-derivability theorem in `src/interpreter/Firth/` | new todo |
| req-r2 | kernel-spec-freeze, surface-syntax-spec, elaborator-named-local-erasure, quotation-erasure-regressions | design + implemented | erasure suites and exact kernel goldens | linked |
| req-r3 | req-r3 | implemented | `todo.req-r3` integration checks under `lake test` | none |
| req-r4 | req-r4 | implemented | linearity diagnostics under `lake test` | none |
| req-r5 | req-r5 | implemented | reference interpreter is definitional; differential campaign | none |
| req-r6 | rust-vm-patch-protocol, rust-vm-lifecycle-integration, rust-vm-implementation | implemented | vm-conformance | none |
| req-r7 | rust-vm-patch-protocol, elaborator-refinement-discharge, patch-refinement-evidence-admission | stale: compatibility evidence is content hashes | `Lowering.lean` lines 308 to 309; `image_patch.rs` `valid_evidence_digest` | new todo |
| req-r8 | req-r8, language-01-smt-record-admission, language-02-compiler-evidence | in flight | `specs/tcb-boundary.toml`; `check_tcb_boundary.py` | TCB pins |
| req-r9 | req-r9 | mechanised | `KernelWordObligation` and invalidation in `KernelMetatheory.lean` | none |
| req-r10 | kernel-cost-semantics-claims | mechanised + executable gate | `CostInvariance.lean`; `check_s5_envelope.py` | none |
| req-r11 | req-r11 | mechanised | `KernelEffectBoundary` in `KernelMetatheory.lean` | none |
| req-r12 | pin-lean-toolchain, diagnostic-schema, component-spec-boundaries, language-20-agent-workflow | in flight | diagnostic envelope suites | none |
| req-r13 | diagnostic-schema, language-20-agent-workflow | in flight | typed holes in `StackEffect.lean` | none |
| req-r14 | surface-syntax-spec, elaborator-named-local-erasure, stack-depth-lint-threshold | stale: threshold hard-coded | `Erasure.lean` lines 1014 and 1026 (`> 4`); no threshold in `erase`, `PipelineConfig` or the source request | new todo; linked lint implementation |
| req-r15 | kernel-spec-freeze, surface-syntax-spec, refinement-discharge-design, language-06-source-refinement-execution | in flight | `todo.language-06` | none |
| req-r17 | surface-syntax-spec, naming-grammar-lint | design only | as scope-language-naming-grammar | new todo |
| sc-s1 | kernel-spec-freeze, kernel-metatheory | mechanised | `check_zero_admit.py` | none |
| sc-s5 | s5-bounded-cost-envelope | executable gate | `check_s5_envelope.py` | none |
| mvp-agent-authoring | mvp-agent-authoring | executable gate | `mvp_agent_gate.py` | none |
| usable-language-baseline | language-00 to language-05 | executable gate; in flight | `check_trust_boundaries.py`; this change serves the audit criterion of language-05 | none |
| usable-inventory-component | language-06, -10, -11, -12, -13 | in flight | `specs/inventory-allocation*.json` | none |
| agent-maintained-component | language-20, language-21 | in flight | roadmap M2 | none |
| compiler-admission-recheck | language-02-compiler-evidence | executable gate | `check_compiler_admission.py` | pinned as TCB stage `compiler-admission` |

## New todos and premise checks

- `naming-grammar-lint`: premise adjusted. No naming lint exists, as claimed;
  but `spec/surface/syntax.md` defines only the lexical `word-name`
  production, and the morpheme and affix grammar of PRD 4.1 is not specified
  anywhere (the word "morpheme" occurs only in `files/firth-prd.md`). The
  todo therefore requires the normative naming grammar to land in
  `spec/surface` through an accepted decision before the lint, without
  narrowing R17.
- `stack-depth-lint-threshold`: premise holds. `Erasure.lean` hard-codes
  `> 4` for `LOCAL_DEPTH` (line 1014) and `STACK_JUGGLE` (line 1026);
  `erase`, `PipelineConfig` and the `firth.source.v1` request carry no
  threshold.
- `patch-refinement-evidence-admission`: premise holds. `compileWords`
  digests canonical code and the erased type into the evidence slots;
  `image_patch.rs` checks only digest length and non-zero bytes; the only
  `PatchVerifier` implementations are in test modules.
- `kernel-minimality-evidence`: premise holds. Section 2 of the frozen
  specification asserts minimality in prose; the Lean modules contain no
  minimality or non-derivability statement.

The four todos are `open` with the standard frontmatter, `Requires:` line,
Goal, Acceptance criteria and Traceability sections. Selector output after
linking: eligible `kernel-minimality-evidence`,
`language-01-smt-record-admission`, `language-03-runtime-conformance`,
`language-10-inventory-contract`, `naming-grammar-lint`,
`stack-depth-lint-threshold`; `next` is `kernel-minimality-evidence` by the
slug-order rule; `patch-refinement-evidence-admission` is ineligible until
`language-03` and `language-06` are done; no blocked or in-progress todos.

## Coverage before and after

`python3 tools/loop/coverage.py` (plain; `--run-gates` is CI's job and is
unchanged by this change):

| Field | Before (80a9d41) | After |
| --- | --- | --- |
| complete | 29 | 20 |
| in_flight | 13 | 22 |
| blocked | [] | [] |
| ungenerated | [] | [] |
| missing_gates | [] | [] |
| failing_gates | [] | [] |
| next_obligation | null | null |
| loop_exhausted_valid | false | false |

Nine rows moved from complete to in flight because they now carry open
implementation work: `req-r1`, `req-r7`, `req-r14`, `req-r17`,
`scope-language-naming-grammar`, `scope-language-spec-predicates`,
`scope-language-type-system`, `scope-language-vocabulary-layering` and
`scope-runtime-patch`. Nothing was removed from any `satisfied_by`.
`coverage.py --validate` and `select_unit.py --validate` both report
`valid: true`.

## TCB boundary

- `firth.toolchain.compiler` output evidence is now `lean-test-driver`,
  `compiler-admission`, `vm-conformance`, `vm-fixtures`; the translator's is
  `lean-test-driver`, `vm-conformance`. Only the first two execute the Lean
  compiler (`lake test` runs `firthCompilerTest` through `firthAllTest`;
  `check_compiler_admission.py` runs the built `firthCompile` binary over
  45 pinned cases and is CI step "Recheck compiler admission and source
  binding").
- New stage `compiler-admission` is pinned identically in
  `EXPECTED_STAGES`; `EXPECTED_REVALIDATORS` is unchanged.
- `firth.runtime.image` and `firth.runtime.patch` are `implemented`
  (the patch row annotated as VM-side admission with unauthenticated
  digests); `firth.toolchain.elaborator.cache` is `implemented` because
  `smt-discharge-record-recheck` landed the content-addressed
  `DischargeRecord` and `recheckDischargeRecord`, consumed by
  `Refinement.recheckRecord`; no persistent store exists, which the comment
  states. `firth.ecosystem.stdlib` stays `planned` with a comment;
  `firth.toolchain.agent` gains the signature-search comment.
- `python3 tools/loop/check_tcb_boundary.py`: passed, 21 components,
  7 stages. `python3 tools/loop/test_tcb_boundary.py`: 26 tests OK, including
  `test_compiler_evidence_runs_the_compiler` and
  `test_compiler_admission_stage_is_pinned` (both mutations fail closed).
- `tools/loop/check_kernel_fixtures.sh` runs the same test file and then
  `lake exe firthVmFixtures`; the Lean part was not run here.

## Cairn dispositions

`cairn scan --json` before: 0 Errors, 43 warnings, 33 informational
(76 findings). After: 0 Errors, 30 warnings, 33 informational (63 findings).
`cairn hook all` exits 0 before and after.

- `CAIRN_GAP_UNRESOLVED` 12 to 1. The eleven `gap-firth-language-kernel-*`
  decisions are `accepted`, each Resolution citing the frozen specification
  section and the theorem or definition that settles it (`push_program_typing`
  and the `push` case of `preservation`; `usageMeet_*`;
  `finite_trace_at_most_once`, `exact_once_of_terminating_empty_residue`,
  `divergence_may_leave_linear_live`; `step_deterministic` and `progress`
  with their well-formedness premises; `preservation_prim`;
  `preservation_swap`; `preservation_if`; `step_cost_matches_kappa`,
  `seq_cost_composes`). The kappa/`S-PUSH` gap is the least direct: the
  prose does not name the administrative push in section 8, so the
  resolution records that `push` is outside the section 2 atom set and thus
  outside the domain of `κ`, as the mechanisation, the cost-invariance
  theorems and the VM target specification already encode; changing that is
  a clause 2b amendment. The runtime patch gap is genuinely open and
  post-mvp; it stays `proposed` with a status note naming `sc-s3` and the
  separate `patch-refinement-evidence-admission` work.
- `CAIRN_DECISION_UNKNOWN_PROVENANCE` 1 to 0. `dec.refinement-discharge-architecture`
  and `dec.smt-checked-adapter-pipeline` moved from `informed_by` to
  `related` in `dec.smt-serialiser-proof-bindings`; the body is unchanged.
- `CAIRN_SOURCE_ORPHAN` 1 to 0. `src.mvp-agent-example-add-one` is now in
  `dec.mvp-agent-examples`'s `informed_by`, with a dated provenance note
  appended; the decision text is unchanged.
- `CAIRN_SOURCE_UNVERIFIED` 4, retained (informational). The four
  transcripts are pinned byte-for-byte by `transcript_sha256` in
  `tools/loop/mvp_agent_manifest.toml` and checked by
  `mvp_agent_gate.verify_transcript`, so changing their `verification`
  field would require re-pinning original agent inputs, which the baseline
  discipline forbids inside an audit. `unverified` is also the honest value:
  dec.mvp-gate-provenance clause 4 records that the hash pins detect drift
  and cannot prove independent authorship.
- `CAIRN_CONTRACT_LEAF_UNCOVERED` 2, retained. Declaring
  `contract "src/diffharness/README.md"` and
  `contract "tools/loop/obligations.toml"` was tested: `cairn scan` raised
  two `CAIRN_CONTRACT_MISSING_NODE` Errors because a contract file must
  carry `node:` frontmatter, which a TOML file cannot and which the README
  under `src/` may not receive in this change. The blueprint edit was
  reverted; no `CAIRN_BLUEPRINT_CHANGE_NO_DECISION` fired during the test.
- `CAIRN_RECONCILE_LANGUAGE_UNKNOWN` 25, retained: expected baseline per the
  loop command. `CAIRN_MODULE_OVERSIZED` 1 (`adapter.rs`), retained: owned
  by the runtime agent. `CAIRN_PATH_GITIGNORED` 1 (`.claude`), retained:
  pre-existing blueprint declaration. `CAIRN_CHANGE_TASKS_COMPLETE` 29,
  retained: archiving completed changes is outside this audit.

## Gates run on this worktree

| Gate | Result |
| --- | --- |
| `python3 tools/loop/coverage.py --validate` | valid |
| `python3 tools/loop/coverage.py` | as tabulated above; `loop_exhausted_valid` false |
| `python3 tools/loop/select_unit.py --validate` | valid |
| `python3 tools/loop/select_unit.py` | as recorded above |
| all 16 `tools/loop/test_*.py` unittest suites plus `test_review_gate.py` | 311 cases OK (309 at base plus the two new TCB tests); review gate PASS |
| `python3 tools/loop/check_tcb_boundary.py` | passed, 21 components, 7 stages |
| `cairn scan` | 0 Errors, 30 warnings, 33 informational |
| `cairn hook all` | exit 0 |
| `git diff --check` | clean |

Not run: `lake build`, `lake test`, `cargo test`, `check_kernel_fixtures.sh`
(Lean part), `coverage.py --run-gates` and the source-runner gates. None of
their inputs changed in this commit; the exact candidate must pass ordinary
PR CI, which runs all of them, before landing.
