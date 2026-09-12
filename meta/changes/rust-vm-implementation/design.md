# Design: rust-vm-implementation

## Approach

The integration is proved from outside the crate. `tests/lifecycle.rs` is an
integration test, not a unit test, so it can only touch the public surface;
if the lifecycle needed a private helper, the test would not compile. That
makes "an embedder can drive the whole lifecycle" a mechanical claim rather
than a reading of the source.

Driving it that way exposed the missing public surface. `target-spec.md` §7
defines `body_digest` as SHA-256 over a word body's canonical encoding and the
evidence digests as SHA-256 over externally owned bytes, and `WordPatch`
requires all three from its caller, but `canonical_code` and `sha256` were
private. `body_digest`, `evidence_digest` and `seal_image` publish exactly
those definitions and nothing more; `fixture_image` and the crate's own test
image builder now go through `seal_image` instead of repeating it.

The CLI reports through `conformance.rs` rather than formatting its own view
of a run. That is deliberate: the boundary already excludes anything a host
address, clock, or allocator could leak, so the CLI cannot report something
the contract does not fix, and a malformed image is reported as the same
zero-cost `malformed-instruction` trap the differential comparison sees.

The reference comparison in the lifecycle test reuses the frozen corpus rows
`dictionary-before-redefinition` and `dictionary-after-redefinition`, which
exist precisely because the Lean interpreter models the same before-and-after
dictionary. Redefining `value` under the patch protocol and then agreeing with
those two rows is the end-to-end statement that the swap changed meaning in
the way the reference says it should.

## Changes

ADDED:
- `body_digest`, `evidence_digest`, `seal_image` in
  `src/runtime/vm/src/image_encoding.rs`.
- `render_conformance_cost` in `src/runtime/vm/src/conformance.rs`, and
  `render_conformance_bytes`/`render_conformance_trap` promoted to public.
- `src/runtime/vm/tests/lifecycle.rs`: the end-to-end scenario, a refused
  patch, a stale patch, a patch whose body digest does not bind, rollback, and
  the administrative word-entry cost charge.

MODIFIED:
- `src/runtime/vm/src/main.rs`: subcommand dispatch, `run <image-path>
  [--fuel <n>]`, canonical observation report, exit 0 terminal / 1 trap / 2
  usage.
- `src/runtime/vm/tests/cli.rs`: the new usage contract plus coverage of a
  successful run, a malformed image, an explicit fuel budget, an unreadable
  path, and an unknown subcommand.
- `src/runtime/vm/src/fixtures.rs`: `fixture_image` and `fixture_word` reuse
  the published helpers.
