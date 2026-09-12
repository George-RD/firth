# Compiler admission verification

Date: 9 September 2026. Scope: M0 compiler-input rechecking and explicit
source binding, not portable proof authentication or language completion.

## Candidate and provenance

Baseline product commit: `302838ee9a4767fe8c175df4d6618b8ab156f153`.
Validation commit: `1f19bdd1ad0f62f25167bc204a4e7bb1f819e88a` on the temporary
`codex/firth-compiler-admission-validation-20260909` branch.
Successful run: https://github.com/George-RD/firth/actions/runs/34359174884

The validation commit contains a checksum-bound patch, not the final product
tree. The job first builds the unchanged baseline, applies the candidate and
its checked syntax correction, then builds and tests the resulting sources.
Only after every gate succeeds does it publish the product file blobs. It
never changes branch references. The product commit reuses those exact blobs
on the original product base; temporary workflows and transport files are not
included. Completion notes and this record are added separately from source.

The retained `compiler-admission-validation` artefact is ID `10107173636`,
ZIP SHA-256
`ceac436ae9e5fccbb1e52ae5df9f32ade6dcff8ab31123c0418d9dd33350c5b3`.
It holds the final patch, exported blob map, compiled manifest and complete
before/after requests, outputs, errors and gate logs. All 18 exported file
hashes were independently matched against the reviewed local product files.
GitHub's configured retention expires on 16 September 2026; a conversation
copy of the same ZIP is also retained.

Selected identities from the actual builds:

| Item | SHA-256 |
| --- | --- |
| Baseline compiler binary | `eaace829f3d0ba7a2c09dc085789002920e5b3eebbe86537bfc8de55c68e68e5` |
| Corrected compiler binary | `66404f250e255aede69a41e30ece00c7721fe4b25fef03da7cb6da9fefa47631` |
| Complete local source envelope, 55 inputs | `4e61a361842d83b7f35d852ce039fb2bffbe2dcb0ab5d80583ec8a961d9b8ea7` |

Governed compiled bindings were derived from the pinned Lean build, then
checked. No kernel typing rule or metatheory theorem body was changed. The
SMT file changes only the source-envelope hash initialisers. Original MVP
source/authoring inputs, generator recipes, seed matrix and expected
observations were not changed to obtain passing results.

## Results

| Check | Result |
| --- | --- |
| Invalid-input reproduction against unchanged baseline | All 15 forged typed/linear requests incorrectly compiled |
| Public compiler admission against corrected candidate | 45/45 passed: 37 rejections, four direct-kernel successes and four source-bound successes |
| Existing differential source campaign | 72/72 successful agreements, unchanged seeds 0, 1 and 20260909 |
| Python regression suites and agent input schema | Passed |
| Lean suites, zero-admit check, source and compiled bindings | Passed |
| Reference fixtures, canonical names and real solver pipes | Passed |
| Rust format, strict Clippy and locked tests | Passed |
| Existing trust boundaries, fixed MVP applications, documented examples and bounded cost witness | Passed |
| Selector/coverage validation and all active pinned gates | No failing or missing gates; `loop_exhausted_valid` remains false |
| Cairn architecture scan and all hooks; whitespace | Passed |

Two earlier validation attempts remain visible: run `34358208482` stopped
because the default Lake build omitted the compiler CLI; run `34358585720`
reproduced all 15 baseline failures but found a source-request constructor
syntax error in the candidate. The successful run adds the explicit CLI build
and the narrow syntax correction without changing the regression cases.

## Scope and landing

Fresh type/ownership checking and source/kernel correspondence are properties
of this compiler invocation. They do not authenticate arbitrary VM image
bytes, discharge source refinements, prove compiler correctness or establish
a minimal TCB. Both success modes expose this scope in verification metadata.
The legacy target digest slots remain content identifiers, not proof tokens.

`language-02-compiler-evidence` is branch-verified for the declared M0
compiler-input boundary. Runtime image/patch authentication, SMT result
provenance and baseline acceptance remain open. A passing finite campaign is
not sustained S2 evidence. The product commit must also pass normal PR CI;
its exact head/run is recorded in the PR handoff. Nothing here claims a merge
or acceptance on main.
