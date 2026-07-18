---
node: firth.runtime.vm
status: open
created: 2026-07-18
---

Requires: rust-vm-bootstrap rust-vm-kernel-execution rust-vm-dictionary-image rust-vm-patch-protocol

# Rust VM implementation integration

## Objective

Integrate the Rust bootstrap, execution core, dictionary image, and verified-patch protocol into one supported VM crate and CLI with end-to-end conformance coverage.

## Acceptance criteria

- Run a complete load, execute, redefine, verify, and atomically swap scenario using only the frozen target, image, and patch contracts.
- Provide integration tests that compare representative execution with the reference interpreter and prove rejected patches leave the prior image observable.
- Pass formatting, locked build, tests, clippy, licence, and no-stub gates; the implementation contains no `todo!`, `unimplemented!`, placeholder, or unjustified unsafe block.

## Verification

- `cargo fmt --manifest-path src/runtime/vm/Cargo.toml --check`
- `cargo test --manifest-path src/runtime/vm/Cargo.toml --locked`
- `cargo clippy --manifest-path src/runtime/vm/Cargo.toml --all-targets --all-features --locked -- -D warnings`
- `! rg -n 'todo!|unimplemented!|TODO|placeholder' src/runtime/vm`
- `git diff --check`

## Non-goals

- Do not implement the compiler, differential fuzzer, LSP, formal VM proof, or target extensions outside the accepted VM specification.
- Do not broaden the image or patch protocol beyond the v0.1 compatibility boundary.
