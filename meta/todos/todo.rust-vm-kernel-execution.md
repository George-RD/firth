---
node: firth.runtime.vm
status: open
created: 2026-07-18
---

Requires: rust-vm-bootstrap vm-target-spec reference-interpreter kernel-metatheory

# Rust VM kernel execution

## Objective

Implement the frozen VM target encoding and deterministic execution core in Rust, with conformance observables aligned to the kernel interpreter.

## Acceptance criteria

- Encode every target instruction, value, error, dictionary call, cost hook, and effect representation required by the VM target specification.
- Execute valid programs deterministically and reject malformed stacks, values, instructions, and primitive results with stable errors; cover representative traces against the reference interpreter.
- Add unit and conformance tests for sequencing, quotations, calls, conditionals, primitives, costs, and terminal/error states; the implementation contains no `todo!`, `unimplemented!`, placeholder, or unjustified unsafe block.

## Verification

- `cargo fmt --manifest-path src/runtime/vm/Cargo.toml --check`
- `cargo test --manifest-path src/runtime/vm/Cargo.toml --locked`
- `cargo clippy --manifest-path src/runtime/vm/Cargo.toml --all-targets --all-features --locked -- -D warnings`
- `! rg -n 'todo!|unimplemented!|TODO|placeholder' src/runtime/vm`
- `git diff --check`

## Non-goals

- Do not implement hot redefinition, image lifecycle, verified patches, compiler code generation, or new target instructions.
- Do not claim formal VM verification or replace the Lean reference interpreter as the semantic authority.
