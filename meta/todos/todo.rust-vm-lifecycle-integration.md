---
node: firth.runtime.vm
status: open
created: 2026-08-11
---
Requires: rust-vm-bootstrap rust-vm-kernel-execution rust-vm-dictionary-image rust-vm-patch-protocol

# Rust VM lifecycle integration

## Objective

Compose the existing decoder, executor, immutable image store, and verified patch admission into one supported end-to-end VM lifecycle.

## Acceptance criteria

- A deterministic integration scenario loads a canonical image, executes the active `main` word, verifies and atomically applies one replacement, executes the new binding, and rolls back to the prior contents under a fresh monotonically increasing image version.
- Integration coverage proves a rejected stale or unproven patch leaves the previously observable image and execution result unchanged, while in-flight word handles retain their resolved body.
- The composition reuses the frozen image, patch, and execution contracts without adding target instructions, weakening validation, or introducing stubs or unjustified unsafe code.

## Verification

- `cargo test --manifest-path src/runtime/vm/Cargo.toml --locked`
- `cargo fmt --manifest-path src/runtime/vm/Cargo.toml --check`
- `cargo clippy --manifest-path src/runtime/vm/Cargo.toml --all-targets --all-features --locked -- -D warnings`
- `git diff --check`

## Non-goals

- Do not reimplement decoder, execution, image lifecycle, or patch validation unit semantics.
- Do not add compiler integration, effectful patch compatibility, or a new image format.
