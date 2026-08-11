---
node: firth.runtime.vm
status: open
created: 2026-08-11
---

# Rust VM reference conformance

Requires: rust-vm-kernel-execution reference-interpreter kernel-metatheory

## Objective

Provide the VM-side deterministic adapter and focused witnesses needed to compare representative Rust execution with the Lean reference contract.

## Acceptance criteria

- The adapter or fixture boundary compares terminal status, residual stack and frames, hidden `World` observation, classified traps, and cost reports for representative canonical cases.
- Tests cover successful execution, malformed input, fuel exhaustion, primitive faults, and the dual-fuel inconclusive classification without duplicating the kernel execution witnesses.
- Fixture and comparison data remain canonical, deterministic, and compatible with the frozen target specification; no host address, timing, or allocator detail is observable.

## Verification

- `cargo test --manifest-path src/runtime/vm/Cargo.toml --locked`
- `cargo fmt --manifest-path src/runtime/vm/Cargo.toml --check`
- `cargo clippy --manifest-path src/runtime/vm/Cargo.toml --all-targets --all-features --locked -- -D warnings`
- `tools/loop/check_kernel_fixtures.sh`
- `git diff --check`

## Non-goals

- Do not change Lean interpreter semantics, compiler lowering, or the frozen fixture format.
- Do not claim a general fuzzing harness when only deterministic witnesses are available.
