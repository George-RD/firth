# Runtime ingress verification

Date: 9 September 2026. Scope: bounded direct Rust image/stack admission and
quotation traversal, not authenticated image proofs or baseline acceptance.

## Reproducible candidate

Product base: `c34ffc85989020a5657681d3b5ba5e9751e64b82`.
Validation commit: `018d3c7995d3f083c75261ce85b5473af6d0a5e1`.
Successful validation run:
https://github.com/George-RD/firth/actions/runs/34373202388

The temporary validation branch applies a SHA-256-bound patch to the base,
formats the new integration test with the pinned Rust toolchain, and runs the
same formatted regressions against both the unchanged base runtime and the
candidate. It exports file blobs only after its gates pass and never updates
branch references. Temporary workflows and patch transport files do not land
in the product commit.

Retained artefact: `runtime-ingress-validation`, ID `10112783174`.
ZIP SHA-256: `8dc7e84f337611b641951238634d444f40da761b4a16f54fa0c06da3f335ab65`.
The ZIP contains before/after test output, source, formatted tests, candidate
diff, per-file blob identities and the Rust/Python/governance logs. GitHub's
configured retention expires on 16 September 2026; a conversation copy is
retained too. All 13 exported file identities were matched independently to
the local candidate; the integration-test formatting diff was reviewed.

The product commit reuses the exact validated implementation and test blobs.
Only completion notes and this verification record are added afterwards.
The exact product head must additionally pass ordinary PR CI, including Lean
and source-to-execution gates. Its SHA and CI result belong in the PR handoff.

## Results

| Check | Result |
| --- | --- |
| Selected baseline reproducers | 14 assertion failures and one deep-code validation timeout, all expected and retained |
| Corrected ingress cases, standard VM | 20/20 passed |
| Same cases, no_std VM core | 20/20 passed |
| Complete locked Rust suite | 119 tests passed, including the 20 new integration tests |
| Formatting and strict Clippy | Passed; no_std library Clippy also passed |
| Existing Python regression suites | 309 tests across 16 suites passed |
| Agent input schema, selector and coverage validation | Passed |
| Zero-admit and SMT source bindings | Passed; unchanged source envelope and proof pins |
| Cairn scan and all hooks; whitespace | Passed |

The deep-code case previously exceeded its three-second subprocess deadline.
The corrected case completes within that same deadline. This is a bounded
regression result, not a hardware-independent timing guarantee. The structural
fix removes duplicate traversal, while other validation passes remain separate.

The input cases cover total image bytes, total initial-stack bytes, per-vector
limits, unused helpers and quotations, malformed bitmaps, invalid capture
indices, exact byte/vector boundaries, and quotation depths 32 and 33. Rejected
diagnostic inputs retain zero cost and no frames, trace or World mutation.

## Remaining scope

The parent `language-03-runtime-conformance` stays open. This change does not
authenticate image/patch evidence, fix every comparison surface, bound all
runtime/trace allocation, implement SMT process provenance or accept PR #109
on main. The unchecked construction helpers are explicitly documented as
such. No Lean implementation, theorem, proof pin, fixed application source,
expected output or differential generator recipe changed.
