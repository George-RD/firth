---
node: firth.runtime.vm
status: done
created: 2026-07-18
---

Requires: host-language-decision vm-target-spec kernel-spec-freeze

# Rust VM bootstrap

## Objective

Create the minimal Rust VM workspace and crate for the frozen Forth-class target, with MIT/Apache-2.0 licensing, pinned direct dependencies, and a working CLI smoke path.

## Acceptance criteria

- Declare a reproducible Cargo workspace and VM crate beneath `src/runtime/vm` with supported Rust toolchain metadata, dual licence notices, minimal dependency surface, and no undeclared network or runtime requirements.
- Provide a CLI with an explicit smoke input and expected output, plus unit tests proving the crate builds and the smoke path executes.
- Record dependency versions, check every dependency against a checked-in MIT/Apache-2.0-only licence policy, and keep the bootstrap implementation free of unsafe blocks; it contains no `todo!`, `unimplemented!`, or placeholder.

## Verification

- `cargo fmt --manifest-path src/runtime/vm/Cargo.toml --check`
- `cargo test --manifest-path src/runtime/vm/Cargo.toml --locked`
- `cargo clippy --manifest-path src/runtime/vm/Cargo.toml --all-targets --all-features --locked -- -D warnings`
- `cargo metadata --manifest-path src/runtime/vm/Cargo.toml --locked --no-deps`
- `cargo tree --manifest-path src/runtime/vm/Cargo.toml --locked`
- `cargo deny --manifest-path src/runtime/vm/Cargo.toml --config src/runtime/vm/deny.toml --locked check licenses`
- `test -f src/runtime/vm/LICENSE-MIT && test -f src/runtime/vm/LICENSE-APACHE`
- `! rg -n '\bunsafe\b' src/runtime/vm`
- `! rg -n 'todo!|unimplemented!|TODO|placeholder' src/runtime/vm`
- `git diff --check`

## Non-goals

- Do not implement target instruction execution, dictionary mutation, image reclamation, or patch admission beyond the bootstrap smoke boundary.
- Do not add speculative crates, a general-purpose CLI, or a compatibility layer for ANS Forth.
