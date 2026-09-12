# Verification: pr109-baseline-acceptance

Date: 10 September 2026. Parent: `todo.language-05-baseline-acceptance`.
This is candidate verification on a branch. It is not acceptance on main.

## Candidate identity

Base: PR #109 head `80a9d41f3895b25793c7c4c37f1ec60bb29f10ef`, itself 42
commits above `main` at `bba6ed748dc548bad1c11797f2d23a1eea3b55d3`.

| Commit | Unit |
| --- | --- |
| `f60232e` | Audit baseline obligation evidence and pin compiler gate evidence |
| `142fac3` | Attest SMT solver provenance before admitting discharge records |
| `7d4e9b6` | Fix compiler bounds, name diagnostics and documentation review findings |
| `b7abe56` | Regenerate governed proof pins after integrating the review fixes |
| `1206a01` | Close runtime conformance comparison gaps and bound VM execution |

Final candidate head: `1206a01a959be430862adfaa20279a3413996daa`, plus this
record. Final candidate CI run: (recorded by the integrator on the exact head
that carries this file).

## Criterion 1: review reconciliation

All 82 review threads were triaged against `80a9d41` by locating the cited
code, checking later commits and maintainer replies, and re-deriving the
finding rather than trusting it. At the base commit: 31 were already fixed, 43
were valid and unfixed, 5 were partly fixed, and 3 did not hold.

On this branch: 43 are fixed here, 31 remain fixed from before, 2 are partly
fixed with the remainder carried by an open todo, 3 are tracked by a linked
open todo, and 3 are dismissed with source evidence. No finding is closed by
assertion, and none survives only in a PR comment.

Seven findings were trust-boundary or crash defects rather than hygiene. All
seven are fixed here:

| Finding | Where | Fixed by |
| --- | --- | --- |
| A fabricated raw result published a discharge record with no solver run | `src/elaborator/Firth/Refinement.lean` | `142fac3` |
| Self-recursive words aborted the process instead of trapping | `src/runtime/vm/src/execute.rs` | `1206a01` |
| `vm-run` buffered unbounded stdin before its limit applied | `src/runtime/vm/src/main.rs` | `1206a01` |
| Residual frames rendered as word and program counter only, so different resumable states compared as agreement | `src/runtime/vm/src/conformance.rs` | `1206a01` |
| The S5 gate never enforced its own both-branches witness | `tools/loop/check_s5_envelope.py` | `1206a01` |

The full table follows. Line numbers are those of the review comment, not of
the current tree.

| Thread | File (review line) | Finding | At 80a9d41 | Disposition | Evidence |
| --- | --- | --- | --- | --- | --- |
| `DM6fqazH` (50) | `.github/workflows/ci.yml`:42 | 'Check whitespace' step was a no-op (git diff --check on a clean tree) | fixed before | Fixed at 80a9d41 by `b84760b685ae` | Fixed by b84760b (fix: synchronize compiler entry schema and retain all gate diagnostics). At HEAD .github/workflows/ci.yml:48-56 the step is 'Check changed-line whitespace': env BASE_SHA is `${{ github.event.pull_request.base.sha // github.event.before }}`; the run script validates `[[ "$BASE_SHA" =~ ^[0-9a-f]{40}$ ]] && [[ "$BASE_SHA" != 0000...0 ]]` then runs `git diff --check "$BASE_SHA" HEAD`, else falls back to `git... |
| `DM6fqr3d` (58) | `.github/workflows/ci.yml`:68 | tee pipelines mask non-zero exit status (no pipefail) | fixed before | Fixed at 80a9d41 by `67e0414f2513` | Fixed by 67e0414 (fix: register name resolver and make CI pipelines fail on errors, 2026-09-06 09:37Z, six minutes after the 09:31Z comment), which added the workflow-level block at .github/workflows/ci.yml:13-15: `defaults:\n  run:\n    shell: bash`. GitHub Actions semantics: an unspecified shell on Linux is `bash -e {0}` (no pipefail), but an explicitly declared `shell: bash` runs `bash --noprofile --norc -eo pipefail... |
| `DM6gBXUf` (69) | `.github/workflows/ci.yml`:94 | 'Reject unchecked claims' step allegedly cannot fail because tee masks exit | invalid | Dismissed | The premise is false: the workflow sets bash as the default shell, which carries pipefail, so the step does propagate a non-zero exit. The comment was posted after that default landed. |
| `DM6fJhZl` (41) | `meta/changes/mvp-agent-elaborate-adapter/proposal.md`:10 | Uncaught-exception claim misattributed to the manifest | valid | Fixed on this branch in pr109-review-fixes (7d4e9b6) | The proposal now attributes the uncaught-exception claim to the CLI rather than to the manifest. |
| `DM6fJhZZ` (38) | `meta/changes/smt-bounded-solver-results/proposal.md`:20 | Out-of-scope section claims no checked-unsat constructor exists | valid | Fixed on this branch in pr109-review-fixes (7d4e9b6) | The out-of-scope note now says that the checked-unsat constructor, record and recheck are delivered by the sibling units and that this unit only keeps promotion out of the solver module. |
| `DM6fJhZx` (44) | `meta/changes/smt-lean-adapter-proofs/design.md`:44 | 'five generated hashes' does not match the ten hashes in defaultSmtProofBindings | valid | Fixed on this branch in pr109-review-fixes (7d4e9b6) | The design note now reads as a stage count rather than a hash count and records the later growth to ten hashes. |
| `DM6fJhZO` (35) | `meta/decisions/smt-adapter-soundness-bridge.md`:71 | ADR states 2 rule / 3 soundness regions; code has 4 / 6 | valid | Fixed on this branch in pr109-review-fixes (7d4e9b6) | The decision record now states the four translation-rule and six soundness regions the generator actually covers, with a test deriving the counts from the generator. |
| `DM6fJhZU` (37) | `specs/tcb-boundary.toml`:141 | Compiler 'implemented' status not backed by an evidence stage that runs the compiler | valid | Fixed on this branch in baseline-obligation-audit (f60232e) | The compiler and translator outputs now cite lean-test-driver and a new pinned compiler-admission stage, since the VM stages never run the Lean compiler; the checker pins the identical stage tuple and two tests cover the positive case and the mutations. |
| `DM6fJhYp` (24) | `src/agent/Firth/Agent/ElaborateAdapter.lean`:269 | Empty checked program reported as successful elaboration | fixed before | Fixed at 80a9d41 by `5984147, 747` | Fixed in src/elaborator/Firth/Pipeline.lean:166-168 at HEAD: `if words.isEmpty then .failure [.parse { code := "firth.elaboration.empty-program", primary := file.span, cause := .validation }]` runs after resolveNames and before erasure, so ElaborateAdapter.lean:269-271 takes the `.failure` branch (failureJson, no checked_words/kernel_programs) instead of successJson. Introduced by 5984147 (`emptyProgram` constructor) and... |
| `DM6fqzI2` (61) | `src/agent/Firth/Agent/ElaborateAdapter.lean`:267 | Source refinements silently dropped while word published as checked/available | fixed before | Fixed at 80a9d41 by `5984147, 747` | The false-agreement path is closed at HEAD by src/elaborator/Firth/Pipeline.lean:147-157 `unsupportedSourceRefinements` (scans `word.effect.input ++ word.effect.output`, emits `firth.refinement.unsupported-source` for every `type.refinements` entry) and Pipeline.lean:170-171 (`if !unsupported.isEmpty then .failure unsupported`) which runs before erasure and before `finishWords`/`config.refinementBuilder`... |
| `DM6fJbBe` (0) | `src/compiler/Firth/Compile.lean`:316 | Entry word inferred from last definition instead of explicit request member | fixed before | Fixed at 80a9d41 by `639042a` | HEAD src/compiler/Firth/Compile.lean:187 adds optional members ["entry","source"]; :208-213 `let entry ← match field "entry" values with / some value => nonempty ... / none => match words with / [word] => pure word.name / _ => err "request.entry: required for multiple checked words"` then `if !names.any (· == entry) then err`; :382-385 selects by source name `(request.words.zip entries).find? (fun pair => pair.1.name ==... |
| `DM6fJhX7` (6) | `src/compiler/Firth/Compile.lean`:316 | compileRequest publishes wrong word as target_program.entry when entry is not last | fixed before | Fixed at 80a9d41 by `639042a` | Same fix as thread 0 (cubic marked it addressed in 639042a; confirmed at HEAD). src/compiler/Firth/Compile.lean:208-213 decodes/validates an explicit `entry` (required for multiword requests) and :382-385 looks the entry up by source name rather than `entries.getLast?`. Tests: src/compiler/FirthCompilerTest.lean:126-154 `entrySelectionTests` (both definition orders assert `"entry":"main"`, and 'explicit source entry is... |
| `DM6fJhYs` (25) | `src/compiler/Firth/Compile.lean`:277 | debugLocationsJson emits no locations for instructions nested inside quotations | valid | Fixed on this branch in pr109-review-fixes (7d4e9b6) | Debug locations are emitted recursively with a path and kernel path at every nesting level, and the one-instruction-per-atom invariant is checked structurally at every level. Covered by debugLocationTests. |
| `DM6fqau4` (47) | `src/compiler/Firth/Compile.lean`:315 | Compiler does not enforce VM instruction-count (4096) or nesting (32) bounds | valid | Fixed on this branch in pr109-review-fixes (7d4e9b6) | The compiler refuses programs that exceed the VM instruction count or nesting depth with the stable code firth.compile.target-bound-exceeded, with public reproducers in the admission corpus. |
| `DM6fqau8` (49) | `src/compiler/Firth/Compile.lean`:279 | Debug metadata lacks nested instruction paths and source spans required by §5 | valid | Fixed on this branch in pr109-review-fixes (7d4e9b6) | Nested instruction paths are emitted as above, and source spans now travel as an optional spans member from the elaborate adapter, shape-validated and re-elaboration-checked, reported with the source path on source-bound entries. |
| `DM6fJhYh` (22) | `src/compiler/Firth/Lowering.lean`:243 | kernel/refinement evidence digests are synthesized from code and erased type | partly fixed | Tracked by `todo.patch-refinement-evidence-admission` | Evidence digests remain content identifiers of code and erased type. They are explicitly labelled unauthenticated on every observation surface, and binding them to elaborator-owned evidence is tracked as a linked todo under obligations req-r7 and scope-runtime-patch. |
| `DM6fJhZF` (33) | `src/compiler/Firth/Lowering.lean`:171 | Lowering dropped the .linear usage marker of a pushed quotation | fixed before | Fixed at 80a9d41 by `5984147` | HEAD src/compiler/Firth/Lowering.lean:175-177 `/ .quotation _ .linear => .error (.unsupportedValue context.word "linear quotation ownership has no capture-free target representation")`, with the `.many` branch at :178-180 (`git show 5984147 -- src/compiler/Firth/Lowering.lean` shows the wildcard `/ .quotation body _` replaced). The path is wire-reachable: src/interpreter/FirthReferenceRun.lean:81,93 decode a `push` atom... |
| `DM6fqau2` (45) | `src/compiler/Firth/Lowering.lean`:244 | Evidence digests not bound to actual proof artefacts | partly fixed | Tracked by `todo.patch-refinement-evidence-admission` | Same disposition as the companion evidence-digest finding. |
| `DM6fJhYQ` (16) | `src/compiler/Firth/Target.lean`:64 | Target encoder admits arbitrary-precision Int though the wire domain is i64 | valid | Fixed on this branch in pr109-review-fixes (7d4e9b6) | Target.isInt64 bounds literal lowering to the wire domain, with boundary witnesses and request tests. |
| `DM6fJhYv` (26) | `src/compiler/Firth/Target.lean`:91 | captureBitmap silently drops consumed flags beyond the capture count | valid | Fixed on this branch in pr109-review-fixes (7d4e9b6) | Target.wellFormedCode refuses a quotation whose consumed list does not match its captures, so malformed capture state cannot reach canonical encoding. |
| `DM6fJhY7` (31) | `src/compiler/Firth/WordType.lean`:147 | Valid schemes with 25+ row binders are refused by a compiler-only 24-name table | valid | Fixed on this branch in pr109-review-fixes (7d4e9b6) | Row binder names are generated beyond the fixed table, keeping the existing 24 names and all digests stable, with 25 and 200 binder witnesses and a corpus row. |
| `DM6fJhZh` (40) | `src/compiler/Firth/WordType.lean`:84 | isRowName is unused dead code that already drifts from the VM predicate | valid | Fixed on this branch in pr109-review-fixes (7d4e9b6) | isRowName is now VM-faithful and used by the renderer, with a guard over the canonical table and predicate witnesses. |
| `DM6gVPtN` (75) | `src/elaborator/Firth/Names.lean`:56 | Unresolved word references emit firth.name.unresolved-effect instead of normative firth.n... | valid | Fixed on this branch in pr109-review-fixes (7d4e9b6) | The resolver emits the normative firth.name.unresolved for unknown words, qualified names and alias prefixes; the effect code is kept for what it actually means. Covered by the names suite and five new public gate cases. |
| `DM6gsCL4` (80) | `src/elaborator/Firth/Names.lean`:9 | Name diagnostics carry no related spans for colliding declarations or ambiguous candidates | valid | Tracked by `todo.name-diagnostic-related-spans` | The diagnostic envelope has a related field, but the wiring lives in a manifest-pinned frozen interface file, so the change is tracked rather than made inside a frozen input. |
| `DM6gWrCh` (76) | `src/elaborator/Firth/Refinement.lean`:1485 | recordExternalOutcome publishes a discharge record from a fabricated raw .uncheckedUnsat ... | valid | Fixed on this branch in smt-attested-provenance (142fac3) | A fabricated raw result can no longer produce a discharge record: results and rerun verdicts leave the solver module wrapped in Attested, whose constructor is private to that module, and recordExternalOutcome and recordRerunVerdict publish a record only for pinnedProcess provenance, deferring anything else with firth.smt.unattested-provenance. The fabricated-admission regression fails on the unchanged head. |
| `DM6fqrTz` (57) | `src/elaborator/FirthNamesTest.lean`:1 | FirthNamesTest not registered as a Lean executable nor in the lake test driver | partly fixed | Fixed on this branch in pr109-review-fixes (7d4e9b6) | FirthNamesTest is registered as a Lean executable, a default target and a suite in the aggregate driver, so lake test runs it. |
| `DM6fJhYP` (15) | `src/runtime/vm/src/adapter.rs`:209 | Require consumed.len() == captures.len() before constructing the quotation | fixed before | Fixed at 80a9d41 by `59841474af3f` | Resolved thread; fix confirmed at HEAD: adapter.rs:209-217 rejects `captures.len() != consumed.len()` with invalid-request 'capture state length must match captures' before sealing (adapter.rs:512-513), introduced by 59841474af3fab73968e1a9f2fcc061b73c01094 (git show 5984147 -- src/runtime/vm/src/adapter.rs). Tests: tools/loop/check_trust_boundaries.py:126-147 malformed_capture_state ('extra state', 'missing state',... |
| `DM6fJhYV` (18) | `src/runtime/vm/src/adapter.rs`:590 | trace_json drops TraceEvent.frames so bounded observations are not replayable | valid | Fixed on this branch in runtime-conformance-closure (1206a01) | Trace events now carry frames, and the response carries the residual frame stack and trap subcode, so a bounded observation is replayable. |
| `DM6fJhYX` (19) | `src/runtime/vm/src/adapter.rs`:550 | Returned quotations serialise only kind+usage, dropping body and captures | valid | Fixed on this branch in runtime-conformance-closure (1206a01) | value_json emits the full quotation: usage, body digest, code and captures, round-tripping through the request grammar. Cross-host comparison of a quotation-valued stack is explicitly UnsupportedComparison rather than a false agreement. |
| `DM6fJhZB` (32) | `src/runtime/vm/src/adapter.rs`:593 | Trace events report the running cost total instead of each step's charge | valid | Fixed on this branch in runtime-conformance-closure (1206a01) | Trace events report each step charge plus its kernel charge instead of the running total; the invariants are pinned by tests in src/tests_adapter_payloads.rs. |
| `DM6fqzI5` (62) | `src/runtime/vm/src/adapter.rs`:213 | Mismatched consumed/captures lengths could panic during sealing | fixed before | Fixed at 80a9d41 by `59841474af3f` | Fixed by 59841474af3fab73968e1a9f2fcc061b73c01094: HEAD adapter.rs:209-217 `if captures.len() != consumed.len() { return Err(AdapterError::field("invalid-request", context, "capture state length must match captures")) }` runs before seal_image/encode_image (adapter.rs:512-513); validation.rs:456 rejects the same shape on the direct API. Tests: tools/loop/check_trust_boundaries.py:126-147 `malformed_capture_state` with... |
| `DM6gUkUq` (73) | `src/runtime/vm/src/adapter.rs`:191 | push-quote quotation envelope is not schema-validated | valid | Fixed on this branch in runtime-conformance-closure (1206a01) | push-quote operands are validated against the same envelope as quotation values, including the kind member and unknown members. |
| `DM6gaZ-N` (78) | `src/runtime/vm/src/adapter.rs`:452 | Recursive call-word overflows the native stack instead of reporting fuel-exhausted | valid | Fixed on this branch in runtime-conformance-closure (1206a01) | Recursion is bounded: the executor was split into per-opcode step functions and refuses to enter a frame past MAX_CALL_DEPTH with resource-fault/call-depth-exceeded, so a self-recursive word traps deterministically instead of aborting the process. The unchanged head aborts under the new bounds gate. |
| `DM6fJhYB` (8) | `src/runtime/vm/src/conformance.rs`:189 | Bytes/PrimitiveValue rendered as type-only labels, allowing false stack agreement | fixed before | Fixed at 80a9d41 by `80a9d41f3895` | HEAD src/runtime/vm/src/conformance.rs:192-201 now renders `Value::Bytes(bytes)` as "bytes:" + render_hex(bytes) and `Value::PrimitiveValue { tag, bytes }` as "primitive:" + tag.to_string() + ":" + render_hex(bytes); pre-fix (0e9f5ac) lines were `Value::Bytes(_) => rendered.push_str("bytes")` / `Value::PrimitiveValue { .. } => rendered.push_str("primitive")` (git show 80a9d41 -- src/runtime/vm/src/conformance.rs).... |
| `DM6fJhYI` (12) | `src/runtime/vm/src/conformance.rs`:216 | Residual frame rendering is `word@pc` only; different captures/continuations/DIP saved va... | valid | Fixed on this branch in runtime-conformance-closure (1206a01) | Frames now render word@pc:<code digest>:<continuation>{capture state}, with restore-dip carrying its saved value, so residual configurations that differ in captures, continuation or saved DIP value no longer compare as agreement. Covered by tests/projections.rs. |
| `DM6gWrCo` (77) | `src/runtime/vm/src/conformance.rs`:190 | Preserve payloads in canonical stack observations (Codex duplicate of thread 8) | fixed before | Fixed at 80a9d41 by `80a9d41f3895` | Same defect as thread 8. HEAD src/runtime/vm/src/conformance.rs:192-201 renders `bytes:<lowercase hex>` and `primitive:<u64 tag>:<lowercase hex>` using render_hex (src/runtime/vm/src/adapter.rs:137-146); the 0e9f5ac version emitted the constant strings "bytes"/"primitive" (git show 80a9d41 -- src/runtime/vm/src/conformance.rs). compare_conformance (conformance.rs:436-442) therefore now flags distinct byte payloads or... |
| `DM6fJhYH` (11) | `src/runtime/vm/src/decode.rs`:211 | execute_report_entry labels non-main entry cost/trace/frames as `main` | fixed before | Fixed at 80a9d41 by `80a9d41f3895` | HEAD src/runtime/vm/src/decode.rs:269-277: `run_code(&word.code, &mut [], &mut [], image, &environment, &mut state, &word.name)`; pre-fix line 276 was the literal `"main"` (git show 80a9d41 -- src/runtime/vm/src/decode.rs, a one-token diff). `word` comes from `resolved.parts()` (src/runtime/vm/src/word_resolver.rs:11-17) and StaticWordResolver::resolve matches by exact name `word.name == name` (word_resolver.rs:34-45), so... |
| `DM6fqr3g` (60) | `src/runtime/vm/src/decode.rs`:205 | execute_report_resolved passes literal "main" to run_code for named entries (Codex duplic... | fixed before | Fixed at 80a9d41 by `80a9d41f3895` | Same defect as thread 11. HEAD src/runtime/vm/src/decode.rs:269-277 passes `&word.name` (resolved WordEntry from ResolvedWord::parts, word_resolver.rs:11-17, exact-name match at word_resolver.rs:39) where 0e9f5ac passed the literal "main" (git show 80a9d41 -- src/runtime/vm/src/decode.rs). Every root TraceEvent/CostStep/FrameTrace label originates from run_code's current_word (src/runtime/vm/src/execute.rs:167-189). Tests:... |
| `DM6fJhYT` (17) | `src/runtime/vm/src/json.rs`:196 | Duplicate-member scan is quadratic in object size | valid | Fixed on this branch in runtime-conformance-closure (1206a01) | Duplicate member detection uses a BTreeSet instead of a linear rescan, so object parsing is no longer quadratic. The deadline is enforced by the new tools/loop/check_runtime_bounds.py gate, which reproduces the unchanged head exceeding it. |
| `DM6fJhYx` (27) | `src/runtime/vm/src/json.rs`:241 | Escaped UTF-16 surrogate pairs are rejected as malformed | valid | Fixed on this branch in runtime-conformance-closure (1206a01) | parse_escape decodes a high surrogate together with the following low surrogate into one scalar and still refuses unpaired halves. |
| `DM6fqr3f` (59) | `src/runtime/vm/src/json.rs`:241 | Decode surrogate pairs in JSON strings (duplicate of thread 27) | valid | Fixed on this branch in runtime-conformance-closure (1206a01) | Same fix as the duplicate surrogate finding. |
| `DM6gBkHS` (70) | `src/runtime/vm/src/json.rs`:142 | Transport depth limit refuses quotation nesting the VM admits | valid | Fixed on this branch in runtime-conformance-closure (1206a01) | The transport depth bound is now separate from the VM nesting bound and a quotation costs one level, so code the decoder admits is no longer refused by the transport. |
| `DM6fJhZo` (42) | `src/runtime/vm/src/lib.rs`:31 | Writer emits /
 instead of the documented minimal \b/\f escapes | valid | Fixed on this branch in runtime-conformance-closure (1206a01) | write_json_string emits the documented short escapes for backspace and form feed. |
| `DM6fJhYa` (20) | `src/runtime/vm/src/main.rs`:91 | vm-run buffers unbounded stdin before the 1 MiB JSON limit applies | valid | Fixed on this branch in runtime-conformance-closure (1206a01) | vm-run reads at most the documented limit plus one byte before parsing, so an oversized stdin stream is refused with input-too-large instead of being buffered. Covered by tests/cli.rs. |
| `DM6fJhYk` (23) | `src/runtime/vm/src/main.rs`:58 | `run` loads the whole image file before the decoder's size check | valid | Fixed on this branch in runtime-conformance-closure (1206a01) | firth-vm run bounds the image file read to the limit plus one byte, so an unbounded source is classified rather than buffered. Covered by tests/cli.rs. |
| `DM6fqjyJ` (55) | `src/runtime/vm/src/main.rs`:91 | Bound stdin before buffering adapter requests (duplicate of thread 20) | valid | Fixed on this branch in runtime-conformance-closure (1206a01) | Same fix as the duplicate stdin finding: the transport bound is applied before buffering. |
| `DM6gUkUs` (74) | `src/runtime/vm/src/main.rs`:58 | Bound image files before reading them (duplicate of thread 23) | valid | Fixed on this branch in runtime-conformance-closure (1206a01) | Same fix as the duplicate image-read finding. |
| `DM6fJhZL` (34) | `src/runtime/vm/src/tests_adapter.rs`:88 | No test protects the JSON byte-size bound | valid | Fixed on this branch in runtime-conformance-closure (1206a01) | The adapter suite now asserts the byte bound: a document of exactly the limit parses and one byte more is refused with the stable code. |
| `DM6fJhZu` (43) | `src/runtime/vm/tests/cli.rs`:44 | run_* CLI tests share a fixed temp directory and never clean up | valid | Fixed on this branch in runtime-conformance-closure (1206a01) | The CLI tests use per-process unique scratch directories that are removed after each test. |
| `DM6fJhX-` (7) | `src/smt/Firth/SmtBoundary.lean`:1267 | Public ExternalOutcome.checkedUnsat let callers bypass checkUnsat when building records | fixed before | Fixed at 80a9d41 by `2e8b1c4e4bd0` | Fixed by 2e8b1c4 ("fix: own SMT record promotion and recheck current rerun bindings"). At HEAD src/smt/Firth/SmtBoundary.lean:1257-1277 `makeDischargeRecord` performs the promotion itself (`let checked ← checkUnsat request result`, :1259) and `checkUnsat` (:1218-1235) matches only `.uncheckedUnsat`, returning `.error .notUnsat` for everything else (:1235), so a caller-constructed `.checkedUnsat` ,  or one returned by a... |
| `DM6fJbBo` (4) | `src/smt/Firth/SmtSolver.lean`:273 | Solver pipes not drained while child runs (stdout > pipe capacity -> false timeout) | fixed before | Fixed at 80a9d41 by `307842ac598e` | Fixed by 307842a ("fix: preserve vocabulary identity and drain solver pipes"). At HEAD src/smt/Firth/SmtSolver.lean:239-251 `readBoundedText` is a chunked `handle.read 4096` loop that keeps draining after the limit (`read bytes true`), and :275-277 start `stdout`, `stderr` and `input` readers/writer as `IO.asTask ... Task.Priority.dedicated` BEFORE the `wait` loop (:278-289); results are joined only after exit (:294-296)... |
| `DM6fJhX4` (5) | `src/smt/Firth/SmtSolver.lean`:276 | processRunner blocks in wait when a pipe fills (cubic duplicate of thread 4) | fixed before | Fixed at 80a9d41 by `307842ac598e` | Same defect as thread 4; marked resolved by the maintainer with 307842a and confirmed at HEAD: src/smt/Firth/SmtSolver.lean:275-277 spawn bounded stdout/stderr readers and the stdin writer on dedicated tasks before `wait` (:278-289); `readBoundedText` (:239-251) consumes each stream until EOF (`chunk.isEmpty`) even after the bound is exceeded. Exercised by src/smt/FirthSmtProcessTest.lean:31-40 (`large`, `overflow`) and... |
| `DM6fJhYF` (10) | `src/smt/Firth/SmtSolver.lean`:103 | solve accepts a parseable model from a model run that exited non-zero as .sat | valid | Fixed on this branch in smt-attested-provenance (142fac3) | solve classifies the model run with classifyTranscript before parsing it; a crashed or resource-exhausted model run can no longer become a counterexample. Covered by solveTests in src/smt/FirthSmtSolverTest.lean and the deferred-outcome table in src/elaborator/FirthAdapterIntegrationTest.lean. |
| `DM6fJhYe` (21) | `src/smt/Firth/SmtSolver.lean`:249 | No production path constructs processRunner; the real solver is never invoked | valid | Partly fixed here in smt-attested-provenance (142fac3) | solvePinned and rerunPinned are the production entry points: they resolve the pinned executable, verify its digest and spawn it through processRunner, and are the only producers of pinnedProcess provenance. The arm64 CI job runs the positive path against the digest-verified z3 5.0.0. Draining the elaborator pipeline queue into that entry point remains language-06 work, and the pipeline still fails closed on a non-empty SMT... |
| `DM6fJhY0` (28) | `src/smt/Firth/SmtSolver.lean`:203 | parseModel skips bare delimiters/`model` tokens, accepting malformed or duplicate model l... | valid | Fixed on this branch in smt-attested-provenance (142fac3) | parseModel now parses one explicit wrapper grammar: exactly one outer list, the model keyword only immediately after the opening paren, no bare delimiters, no trailing tokens, and a symbol defined twice is an error. Covered by parseModelTests. |
| `DM6fqau6` (48) | `src/smt/Firth/SmtSolver.lean`:326 | Model invocation exit code / resource diagnostics ignored before parsing (codex duplicate... | valid | Fixed on this branch in smt-attested-provenance (142fac3) | Same fix as the duplicate finding on the model invocation: the second run is classified by the same total rule as the decision run before its output is parsed. |
| `DM6fqrTw` (56) | `src/smt/Firth/SmtSolver.lean`:257 | Claim: writeInput never closes stdin so an EOF-waiting solver times out; suggests `handle... | invalid | Dismissed | The suggested handle close does not exist in Lean 4.30.0. EOF is delivered when the writer task drops the handle, and the real-process regression in src/smt/FirthSmtProcessTest.lean covers a child that waits for EOF before answering. |
| `DM6fJhYE` (9) | `tools/loop/check_s5_envelope.py`:162 | S5 gate never enforces structure.both_branches_taken | valid | Fixed on this branch in runtime-conformance-closure (1206a01) | The S5 gate now proves from both traces that each dispatch handler executed, tracks unread specification fields, and has a one-branch negative control that must fail. Covered by the new tools/loop/test_s5_envelope.py. |
| `DM6fqau3` (46) | `tools/loop/check_s5_envelope.py`:167 | Both-branches witness not enforced (duplicate of thread 9) | valid | Fixed on this branch in runtime-conformance-closure (1206a01) | Same fix as the duplicate both-branches finding. |
| `DM6fqjFL` (52) | `tools/loop/check_s5_envelope.py`:300 | Compiled entry is printed but never compared with the specification | valid | Fixed on this branch in runtime-conformance-closure (1206a01) | The gate now asserts that the compiled entry matches the specification entry rather than only printing it. |
| `DM6gBXUS` (64) | `tools/loop/check_trust_boundaries.py`:79 | Instruction-placement fixture used the wrong push-quote shape | fixed before | Fixed at 80a9d41 by `ebbddd1` | Fixed in ebbddd1 (2026-09-07T20:27Z, two minutes before the 20:29Z review; thread is marked outdated). HEAD tools/loop/check_trust_boundaries.py:129 is exactly the suggested `instruction = {"op": "push-quote", "quotation": quotation}` and the nested placement (:133-134) wraps under `quotation` too; the adapter requires members ["op","quotation"] at src/runtime/vm/src/adapter.rs:254-262. Test: the gate itself runs in CI... |
| `DM6gBXUW` (65) | `tools/loop/check_trust_boundaries.py`:115 | firth.elaboration.empty-program diagnostic did not exist | fixed before | Fixed at 80a9d41 by `74703e9` | Fixed in 74703e9 (2026-09-07T20:38Z, nine minutes after the review; `git log -S'firth.elaboration.empty-program'` names only this commit). HEAD src/elaborator/Firth/Pipeline.lean:166-168: `if words.isEmpty then .failure [.parse { code := "firth.elaboration.empty-program", primary := file.span, cause := .validation }]` after resolveNames. Gate assertion source_refusal (check_trust_boundaries.py:37-43) checks... |
| `DM6gBXUZ` (66) | `tools/loop/check_trust_boundaries.py`:112 | firth.refinement.unsupported-source was not emitted by any path | fixed before | Fixed at 80a9d41 by `5984147, 747` | Introduced in 5984147 (2026-09-07T20:32Z, as a dedicated PipelineDiagnostic constructor) and finalised in 74703e9 (2026-09-07T20:38Z) as HEAD src/elaborator/Firth/Pipeline.lean:147-158 `unsupportedSourceRefinements` emitting `.parse { code := "firth.refinement.unsupported-source", primary := refinement.span, actual := some word.name, cause := .validation }` for every refinement on any declared value type, invoked before... |
| `DM6gBXUb` (67) | `tools/loop/check_trust_boundaries.py`:71 | Compiler accepted linear quotation ownership | fixed before | Fixed at 80a9d41 by `5984147` | Fixed in 5984147 (`git log -S'.quotation _ .linear'`). HEAD src/compiler/Firth/Lowering.lean:175-177: `/ .quotation _ .linear => .error (.unsupportedValue context.word "linear quotation ownership has no capture-free target representation")`, and :178 only lowers `.quotation body .many`; the wire code is `firth.compile.unsupported-value` (Lowering.lean:60). Gate case 'linear quotation ownership'... |
| `DM6gBXUd` (68) | `tools/loop/check_trust_boundaries.py`:93 | VM did not validate capture/consumed length before sealing | fixed before | Fixed at 80a9d41 by `5984147` | Fixed in 5984147 (`git log -S'capture state length must match captures'`). HEAD src/runtime/vm/src/adapter.rs:209-217 in adapter_quotation: `if captures.len() != consumed.len() { return Err(AdapterError::field("invalid-request", context, "capture state length must match captures")) }`, reached from push-quote (:254-262), push-literal via adapter_operand_value kind "quotation" (:173-175) and nested captures (:193-194), so... |
| `DM6gvL1i` (81) | `tools/loop/firth_run.py`:35 | Deeply nested or oversized --stack JSON yields a traceback instead of the documented JSON... | valid | Fixed on this branch in runtime-conformance-closure (1206a01) | The source runner catches RecursionError and ValueError at the input boundary and reports the documented structured JSON error. |
| `DM6fJbBh` (1) | `tools/loop/mvp_agent_gate.py`:182 | Transcript contents not verified (only path existence + manifest hash) | fixed before | Fixed at 80a9d41 by `639042a` | Trust-boundary defect (forgeable evidence), fixed by 639042a. HEAD tools/loop/mvp_agent_gate.py:108-145 `verify_transcript`: :117-118 hashes the transcript bytes against `transcript_sha256`; :120-130 parses frontmatter and requires `type: model-authorship-transcript`; :131 `file` must equal `entry["source_path"]`; :133 transcript's own `output_sha256` must equal `source_sha256`; :138-140 recorded inputs must equal... |
| `DM6fJbBk` (2) | `tools/loop/mvp_agent_gate.py`:404 | Reference request sent an empty dictionary so multiword entries were refused | fixed before | Fixed at 80a9d41 by `639042a` | Correctness defect (gate could not pass any valid multiword application), fixed by 639042a. HEAD tools/loop/mvp_agent_gate.py:470-484 `checked_dictionary` builds `{name: {checking_state, proof_state, program}}` from `elaboration["checked_words"]`, refusing duplicates (:477-478) and any word without `checking_state == "checked"` and `proof_state == "available"` (:479-480); :540-542 the entry word must be in that dictionary;... |
| `DM6fJbBm` (3) | `tools/loop/mvp_agent_gate.py`:322 | Compared VM cost.total (includes word-entry charge) against reference total | fixed before | Fixed at 80a9d41 by `639042a, 5c2` | Fail-closed correctness defect (false mismatch for any CALL_WORD program), fixed by 639042a in the gate, with the VM side finished by 5c2e504. HEAD tools/loop/mvp_agent_gate.py:438-443 requires reference cost {total, steps} and target cost {total, kernel, steps} to be non-negative ints; :444-445 refuses kernel > total; :446-450 compares `reference_cost["total"] != target_cost["kernel"]` and reports it as "(target kernel... |
| `DM6fJhYL` (13) | `tools/loop/mvp_agent_gate.py`:182 | Edited transcript with unchanged source still passed provenance | fixed before | Fixed at 80a9d41 by `639042a` | Same defect as thread 1 (cubic rated P2; re-assessed P1 because it is forgeable evidence at a trust boundary). Fixed by 639042a as the resolver comment says. HEAD tools/loop/mvp_agent_gate.py:117-118 refuses any byte drift against `transcript_sha256`; :129-145 parse and validate the transcript's recorded type, source path, `output_sha256`, recorded inputs and the model-output block bytes, so even a re-pinned transcript... |
| `DM6fJhYO` (14) | `tools/loop/mvp_agent_gate.py`:322 | VM total vs reference total rejects semantically matching word-calling hosts | fixed before | Fixed at 80a9d41 by `639042a, 5c2` | Duplicate of thread 3; fixed by 639042a as the resolver comment says. HEAD tools/loop/mvp_agent_gate.py:446-450 compares reference `cost.total` with target `cost.kernel`; :444-445 additionally refuses kernel > total. Tests: tools/loop/test_mvp_agent_gate.py:271 `test_word_entry_overhead_is_not_a_kernel_mismatch`, :274 `test_changed_kernel_cost_is_refused`; src/runtime/vm/src/tests_adapter.rs:334... |
| `DM6fJhZR` (36) | `tools/loop/mvp_agent_gate.py`:297 | [comparison] manifest table is not consumed or validated by the gate; docs claimed config... | partly fixed | Fixed on this branch in runtime-conformance-closure (1206a01) | The comparison table is now read and bound by verify_contract, so a toggled flag is a gate failure rather than a silent no-op. |
| `DM6fqjyH` (54) | `tools/loop/mvp_agent_gate.py`:388 | Source runner rejects negative Int inputs | invalid | Dismissed | Negative integers are not representable anywhere in the pure portable profile at this milestone, so refusing them at the input boundary is the correct front-line refusal rather than a gate defect. The supported profile is documented in the getting-started guide. |
| `DM6fqzI8` (63) | `tools/loop/mvp_agent_gate.py`:345 | Quotation results always compared as divergent (reference emits body, VM omits it) | partly fixed | Partly fixed here in runtime-conformance-closure (1206a01) | The VM side is fixed: quotation results are serialised in full and rendered unambiguously. There is still no shared cross-host quotation normal form, so a quotation-valued result is reported as unsupported-quotation-values, which is neither agreement nor failure, rather than compared. The remaining work is recorded in the runtime todo. |
| `DM6gBrjc` (72) | `tools/loop/mvp_agent_gate.py`:355 | Traces are only length-bounded; intermediate stack states are not compared | valid | Fixed on this branch in runtime-conformance-closure (1206a01) | Traces are now compared event by event after projecting both sides onto kernel-charged events, with per-index charge and stack equality, so a reordered instruction sequence reaching the same final stack no longer passes. |
| `DM6ggGUK` (79) | `tools/loop/mvp_agent_gate.py`:153 | Gate ignores manifest language_version/[gamma]/[schema]/[entry_point]/[comparison]; execu... | valid | Fixed on this branch in runtime-conformance-closure (1206a01) | verify_contract binds the gate to the manifest: language version, gamma, every entry point adapter, transport and schema name, and the comparison table must match what the gate implements, failing closed on any drift. |
| `DM6fqjFJ` (51) | `tools/loop/mvp_agent_manifest.toml`:103 | Adding entry:string to firth.checked-kernel.v1 broke check_mvp_agent_inputs.py | fixed before | Fixed at 80a9d41 by `b84760b, 67e` | CI-breaking schema mismatch (correctness of the CI gate), fixed by b84760b ("fix: synchronize compiler entry schema and retain all gate diagnostics", +1 line). HEAD tools/loop/check_mvp_agent_inputs.py:247-258 `expected_schemas["firth.checked-kernel.v1"].fields` now includes `"entry:string (required for multiword requests)"` at :252, byte-identical to tools/loop/mvp_agent_manifest.toml:103. Reproduced at HEAD: `python3... |
| `DM6gBrF1` (71) | `tools/loop/test_language_roadmap.py`:54 | test_open_work_prevents_completion never checks the positive direction | valid | Fixed on this branch in pr109-review-fixes (7d4e9b6) | The roadmap test now checks both directions against a temporary copy of the live matrix, so completion actually flipping exhaustion is asserted. |
| `DM6fJhZc` (39) | `tools/loop/test_smt_proof_bindings.py`:51 | Idempotence test rewrote the tracked Lean source in place | fixed before | Fixed at 80a9d41 by `faf2ba7` | Fixed in faf2ba7 (diff renames test_the_generator_is_idempotent -> test_the_generator_is_idempotent_without_writing_tracked_sources and introduces source_tree). HEAD tools/loop/test_smt_proof_bindings.py:43-69 `source_tree(real_sources=True)` copies the script, src/**/*.lean and the build inputs into a TemporaryDirectory; :210-219 runs write, write, `--check` inside that copy, asserts the copy is byte-stable, and finally... |
| `DM6fJhY3` (29) | `tools/loop/update_smt_proof_bindings.py`:135 | Helpers outside markers did not affect proof hashes | fixed before | Fixed at 80a9d41 by `3b4bb6b` | Fixed in 3b4bb6b (maintainer reply confirms). HEAD tools/loop/update_smt_proof_bindings.py:138-175 `source_snapshot()` reads every `.lean` under src/ plus lean-toolchain, lakefile.toml, lake-manifest.json (fail-closed on symlinks, foreign roots, third-party packages); :178-188 `source_envelope()` hashes all of them, masking only the two literal pin lists (:95-99, :182-185); :191-194 `region_hash()` binds the envelope into... |
| `DM6fJhY4` (30) | `tools/loop/update_smt_proof_bindings.py`:54 | Misspelled or whitespace-padded region markers were silently ignored | fixed before | Fixed at 80a9d41 by `faf2ba7` | Fixed in faf2ba7. HEAD tools/loop/update_smt_proof_bindings.py:74-78: BEGIN/END are anchored `^…$` regexes (trailing whitespace cannot match) and `MARKER_LIKE = re.compile(r"^\s*--\s*firth\s*:", re.IGNORECASE)`; regions() :207-208 raises `SystemExit(f"{source}:{number}: malformed SMT region marker")` for any marker-like line that is not an exact BEGIN/END, inside or outside a region. Tests in... |
| `DM6fqjyD` (53) | `tools/loop/update_smt_proof_bindings.py`:121 | Rule region without a matching soundness region was accepted | fixed before | Fixed at 80a9d41 by `faf2ba7` | Fixed in faf2ba7 (maintainer reply 2026-09-08). HEAD tools/loop/update_smt_proof_bindings.py:260-274: missing REQUIRED_RULE_REGIONS -> exit; rule named after a proof-only bridge -> exit; missing REQUIRED_PROOF_ONLY_REGIONS -> exit; `unproved_rules = ruleNames - proofNames` -> exit 'translation-rule regions without soundness regions'; `unexpected_proofs = proofNames - ruleNames - REQUIRED_PROOF_ONLY_REGIONS` -> exit. The... |

## Criterion 2: obligation audit

`meta/changes/baseline-obligation-audit/` carries the audit. Every
active-profile obligation whose `satisfied_by` todos were all `done` was
classified as executable, specification-only or stale, with the evidence
cited. Four rows were discharged by design documents alone and now carry an
implementation todo: `naming-grammar-lint` (R17), `stack-depth-lint-threshold`
(R14), `patch-refinement-evidence-admission` (R7 and the patch scope row) and
`kernel-minimality-evidence` (R1). The review fixes added a fifth,
`name-diagnostic-related-spans`, for work that belongs inside a frozen
manifest-pinned interface.

Existing implementation todos were linked into the rows they already served;
no slug was ever removed. Coverage therefore moves from 29 complete and 13 in
flight to 20 and 22, which is the honest direction: rows that were resting on
a specification are now visibly in flight.

`specs/tcb-boundary.toml` now cites `lean-test-driver` and a new pinned
`compiler-admission` stage for the compiler outputs, because the two VM stages
it previously named never run the Lean compiler. `tools/loop/check_tcb_boundary.py`
pins the identical stage tuple and two new tests cover the positive case and
the mutations. The stale `planned` statuses for the runtime image, the patch
protocol and the elaborator cache are corrected, with the patch row annotated
that its admission is VM-side only while evidence digests stay unauthenticated.

Eleven kernel gap decisions that the frozen specification and the mechanised
metatheory already answer are resolved with their citations. The effectful
verified-patch gap stays `proposed`: it is genuinely open and post-mvp.

## Criterion 3: full gates on the exact candidate

Every step of `.github/workflows/ci.yml` was reproduced locally on the
candidate tree with the pinned toolchains (Lean 4.30.0, cargo 1.93.0, Cairn
0.9.0). All 34 steps pass.

| Gate | Result on `1206a01` | On `80a9d41` |
| --- | --- | --- |
| Python regression suites | pass, 18 suites | pass, 16 suites |
| Agent input schema, changed-line whitespace | pass | pass |
| `lake build`, `lake test` | pass | pass |
| Zero admits, SMT source bindings, compiled proof manifest | pass, 7 governed modules | pass, 6 |
| SMT attestation lint | pass, one sealed constructor, two gated record sites | not present |
| Kernel fixtures, canonical names, real solver pipes | pass | pass |
| Pinned solver refusals, unset and named | pass | not present |
| Runtime ingress, standard and core | 20/20 each | 20/20 each |
| Runtime execution and transport bounds, standard and core | 3/3 each | not present |
| `cargo fmt`, strict clippy, `cargo test --locked` | pass, 162 tests | pass, 134 tests |
| Public trust boundaries | 29/29 | 24/24 |
| Compiler admission | 50/50 | 45/45 |
| MVP applications | pass, 4 rebuilt and compared | pass |
| Documented source programs | pass | pass |
| Differential campaign, 3 seeds, 24 cases | 72/72 agreement | 72/72 |
| Replay and bounded shrinking | pass | pass |
| Bounded cost witness | result 4, kernel cost 25, target cost 31, envelope 40, both branches proven | same costs, witness not enforced |
| Coverage validation and every pinned gate | no failing or missing gates | same |
| `loop_exhausted_valid` | false | false |
| Cairn scan and hooks | 0 errors, 30 warnings, hooks exit 0 | 0 errors, 43 warnings |
| Checks did not rewrite tracked evidence | pass | pass |

The differential campaign reports all 72 cases as
`unsupported-quotation-values` for the new per-event trace comparison, because
the generator emits a quotation in every case. Terminal results, kernel costs,
world observations and traps are still compared exactly on all 72; the label
is the honest statement that intermediate quotation-valued stacks have no
shared cross-host form, not a pass.

## CI evidence

- Run `34505980035` on `142fac3`: all four jobs succeeded. The new
  `smt-pinned-solver` job on `ubuntu-24.04-arm` fetched z3 5.0.0, verified the
  release zip and the binary against the pinned digest, and ran the positive
  path: a discharge record from the pinned process and a `sat` reported as a
  failed refinement with its countermodel. Diagnostics artefact `10163842969`,
  zip SHA-256 `85d03938eabdf698c34aba629cf1fa436b2c46b369f40239469cc3d7fc5f9723`.
- Run `34507227788` on `b7abe56`: all four jobs succeeded.
- The final candidate head needs its own run; the integrator records it above.

## What remains open

Criterion 4 is not met and cannot be met here. After the merge, acceptance
must be rerun on `main` and recorded separately, citing the merged commit id.
`todo.language-05-baseline-acceptance` therefore stays `open`, even though its
`Requires` are now all `done` and the selector may surface it.

Carried limitations, each recorded in its own change record:

- The pinned solver's `unsat` is trusted; no certificate is checked. The
  binary is identified by the host digest tool, with a window between the
  digest check and the spawn. The pin is `linux-arm64`, so the positive path
  runs only on the arm64 job while other hosts can only refuse.
- Lean `private` is a naming discipline. In-repository routes around the seal
  are refused by a lint, the source envelope and the compiled manifest;
  out-of-repository Lean callers are outside the trusted computing base.
- There is no cross-host quotation normal form, so quotation-valued results
  and intermediate stacks are explicitly unsupported rather than compared.
  Residual programs, frames and step counts are not compared across hosts.
- The call-depth cap is a hosted-VM bound the kernel reference does not have,
  so a deeper program is a one-sided trap and disagrees by design.
- Image and patch evidence digests remain unauthenticated content identifiers,
  labelled as such on every observation surface; binding them is tracked.
- No production consumer drains the SMT queue yet; the pipeline fails closed.

M1 and M2 obligations are untouched and in flight, which is why
`loop_exhausted_valid` is false and must stay false.

## Landing requirements still owned by the merger

Green gates on a branch are not a licence to merge. Whoever lands this must
still fast-forward the PR head to this candidate, publish the two-lens
correctness and simplicity review bound to the exact head, have CI green on
that head, resolve the review threads, and then record merged-main acceptance.
