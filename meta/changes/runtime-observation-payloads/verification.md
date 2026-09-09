# Verification: runtime-observation-payloads

Date: 9 September 2026. Parent: `todo.language-03-runtime-conformance`.

## Candidate identity

- Base: `0e9f5acb46402031fe1df5a9855b9cbb05fa4ad7`.
- Validation commit: `349ee36883cd0403d0ed17d2e6a6c7b19c9bfe2f`.
- Validation run: `34378902545` (success).
- Candidate tree: `734cb7e7bab6c82e364963c48a70d6aaf6bf2733`.
- Artifact: `runtime-observation-validation`, id `10115032519`.
- Artifact ZIP SHA-256: `b8cd6535e536764ef9a3004ebbee45e3531a52aec502ce5a63ec0231c1e67d61`.

The temporary workflow applies a SHA-256-bound patch to the exact base, fixes
only the new probes' identifier spellings to the existing ASCII grammar, and
formats that integration test using Rust 1.93.0. The same formatted test is
copied unchanged to the original runtime and the candidate. The first attempt
(run `34378562994`) stopped because dotted test word names are invalid, not
because the production identifier grammar needed changing. No existing corpus
or expected output was altered to accommodate that test-fixture correction.

Only after all targeted checks pass does the workflow export immutable Git
blobs. It never updates a branch reference. The product commit reuses the
verified code/test blobs, with completion notes added separately. The temporary
workflow and compressed patch are not part of the product change.

| Product source | Verified Git blob |
| --- | --- |
| `src/runtime/vm/src/conformance.rs` | `418f481150471957ef889740bd55b1db02d6d745` |
| `src/runtime/vm/src/decode.rs` | `f149a8123ec8a4a06e8fe24c07e61fae01c4903e` |
| `src/runtime/vm/tests/observations.rs` | `072fd774651f25203cd127c3f9354bed36ce8092` |

The downloaded archive's SHA-256, every exported file's Git/SHA-256 identity,
and the reconstructed candidate tree were independently checked in the chat
container. Rust and Cairn execution took place in the GitHub runner, not in
the container, which has no installed Rust or Cairn toolchain.

## Before and after

The original runtime fails exactly 13 named assertions in each configuration.
These reproduce lost byte content, primitive tags/payloads, value boundaries,
real false-agreement cases and root trace/cost/frame attribution. Two std
controls and one no_std control pass on the original runtime. Compilation
errors or unexpected test failures do not count as valid reproductions.

The corrected candidate passes:

- All 15 std observation cases and all 14 no_std observation cases.
- All 134 Rust tests across the library, binary and integration targets.
- `cargo fmt --check`, all-target std Clippy and no_std library Clippy, with
  warnings denied.
- All 309 Python unit tests across 16 suites, plus the separate review-gate
  script. The shell loop runs all 17 `tools/loop/test_*.py` files.
- Zero-admit, source-envelope/proof-binding, agent-input, unit-selection and
  coverage validation checks.
- `cairn scan` and `cairn hook all`; the strict gate passes. Existing warnings
  are retained rather than described as zero findings.
- Changed-line whitespace checks.

The frozen 15-row Lean reference corpus is unchanged and its Rust comparison
test passes. No Lean source, proof pin, authoring input or expected application
output changes in this slice. Full Lean and source-to-execution acceptance is
run separately by ordinary PR CI on the product head, not inferred from the
runtime-only validation above.

## Review scope and remaining work

This addresses PR #109 comments `3930474588` and `3960819759` (byte/primitive
payload collapse), plus `3930474598` and `3943552665` (named-entry report
attribution). Independent golden strings accompany execution-based mismatch
checks, so two identically broken renderings cannot make the suite pass.

Quotation bodies/captures and residual continuation state still need a shared
comparison form or explicit refusal on the Rust conformance surface. Python's
portable quotation refusal does not close that separate API. Per-event trace
comparison, process-produced SMT provenance, runtime image/patch proof
admission and baseline acceptance also remain open. These tests demonstrate
the bounded corrections only; they do not certify arbitrary program equality,
prove admission soundness, or justify merging the complete baseline to main.
