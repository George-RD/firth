---
node: firth.runtime.patch
status: open
created: 2026-07-18
---

Requires: rust-vm-dictionary-image patch-compat-prior-art elaborator-implementation

# Rust VM verified patch protocol

## Objective

Implement VM-side admission and atomic application of verified word patches, binding elaborator and kernel compatibility evidence to the target image version.

## Acceptance criteria

- Verify exact erased `WordType` equality, dictionary well-formedness evidence, refinement-spec subsumption evidence, body and image hashes, and expected image version before a swap.
- Reject stale, malformed, mismatched, effectful-v0.1, or incomplete patches without changing the live image, and make accepted replacement atomic for readers and in-flight calls.
- Add positive and negative protocol fixtures plus crash/rollback and concurrency tests; the implementation contains no `todo!`, `unimplemented!`, placeholder, or unjustified unsafe block.

## Verification

- `cargo fmt --manifest-path src/runtime/vm/Cargo.toml --check`
- `cargo test --manifest-path src/runtime/vm/Cargo.toml --locked`
- `cargo clippy --manifest-path src/runtime/vm/Cargo.toml --all-targets --all-features --locked -- -D warnings`
- `! rg -n 'todo!|unimplemented!|TODO|placeholder' src/runtime/patch src/runtime/vm`
- `git diff --check`

## Non-goals

- Do not implement elaborator proof generation, effectful compatibility, distributed consensus, or a new patch contract.
- Do not weaken evidence validation to make a patch admissible.
