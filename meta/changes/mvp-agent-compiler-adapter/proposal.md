# Proposal: mvp-agent-compiler-adapter

## Motivation

`firth.toolchain.compiler` was a declared module with an empty path. The
frozen target specification has carried a total lowering table since §3 was
written, and the MVP gate cannot rebuild an application without an executable
that applies it, so `entry_point.compile` stayed `availability =
"gate-required"` and the `mvp-agent-authoring` obligation could not close.

## Scope

- The compiler component under `src/compiler`: SHA-256, the canonical target
  encoding, the §3 lowering table, canonical erased word-type rendering, and
  target name mangling.
- The `firth.compile.v1` adapter and its `firthCompile` executable.
- Byte-level agreement with the Rust encoder, pinned by test vectors and, at
  run time, by the VM's own recomputation of every `body_digest`.

## Out of scope

- The differential fuzzing harness. This unit provides deterministic
  witnesses and the adapter the harness will call, not the campaign.
- A Lean lowering-preservation proof. `specs/component-spec-boundaries.md`
  records it as required for the G6 proof path and it remains ahead.
- Any change to the frozen target contract, the kernel, or the elaborator's
  checking. The compiler consumes what the elaborator already checked.
