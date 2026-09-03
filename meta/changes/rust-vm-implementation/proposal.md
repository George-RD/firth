# Proposal: rust-vm-implementation

## Motivation

`todo.rust-vm-implementation` is the integration unit for the VM: the
bootstrap decoder, the execution core, the dictionary image, and the
verified-patch protocol all exist and are individually tested, but nothing
proves they compose into one supported crate that an embedder can drive.

Two concrete gaps stood in the way. The patch contract asks a caller for a
`body_digest` and two evidence digests, yet the canonical encoding and the
hash that define them were private, so no code outside the crate could build a
valid `WordPatch` or seal a valid image. And the CLI accepted only `--smoke`,
a fixed bootstrap image with a fixed answer, so the binary exercised none of
the loading, execution, or reporting the crate provides.

## Scope

- Publish the identity helpers the frozen contract already defines:
  `body_digest`, `evidence_digest`, and `seal_image`.
- Give the CLI a `run` subcommand that loads a canonical image file and
  reports the execution through the conformance boundary.
- Add an end-to-end integration test that drives load, execute, redefine,
  verify, and atomic swap through the public contracts only, and proves a
  rejected patch leaves the prior image observable.

## Out of scope

- The compiler, the differential fuzzer, the LSP, a formal VM proof, or any
  target extension outside the accepted VM specification.
- Broadening the image or patch protocol past the v0.1 compatibility boundary.
  Nothing here changes an admission rule; the change makes the existing rules
  reachable.
