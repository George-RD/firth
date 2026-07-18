---
node: firth.runtime.image
status: done
created: 2026-07-18
---

Requires: rust-vm-kernel-execution vm-target-spec host-language-decision

# Rust VM dictionary image

## Objective

Implement the VM image and dictionary layer for word-level hot redefinition, preserving atomic bindings and the lifecycle guarantees required by the target specification.

## Acceptance criteria

- Represent immutable word bodies and versioned dictionary bindings with atomic replacement, stable lookup, and explicit handling for readers and in-flight calls.
- Define allocation, reclamation, quiescence, failure rollback, and image serialisation behaviours and test them under concurrent lookup/redefinition scenarios.
- Add deterministic image and concurrency tests, including stale-version and missing-word errors; the implementation contains no `todo!`, `unimplemented!`, placeholder, or unjustified unsafe block.

## Verification

- `cargo fmt --manifest-path src/runtime/vm/Cargo.toml --check`
- `cargo test --manifest-path src/runtime/vm/Cargo.toml --locked`
- `cargo clippy --manifest-path src/runtime/vm/Cargo.toml --all-targets --all-features --locked -- -D warnings`
- `! rg -n 'todo!|unimplemented!|TODO|placeholder' src/runtime/image src/runtime/vm`
- `git diff --check`

## Non-goals

- Do not admit verified patches, define refinement subsumption, or alter instruction semantics.
- Do not promise lock-free behaviour, distributed images, garbage collection, or an image format beyond the frozen VM boundary.
