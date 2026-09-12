# Tasks: rust-vm-reference-conformance

- [x] Add the canonical observation, partial reference, verdict, and
      comparison in `src/runtime/vm/src/conformance.rs`.
- [x] Classify a decode failure as a zero-cost malformed-input trap through
      `observe_image_bytes`.
- [x] Return `bounded-fuel-inconclusive` for dual exhaustion and disagree for
      a one-sided exhaustion.
- [x] Add deterministic witnesses covering successful execution with a world
      observation, malformed input, fuel exhaustion, primitive faults, an
      unknown primitive, a classified stack fault, cost breakdown, and
      determinism.
- [x] Route the frozen `fixtures/kernel.tsv` corpus through the same
      comparison and assert its row count.
- [x] Run `cargo fmt --check`, `cargo clippy --all-targets --all-features
      --locked -- -D warnings`, `cargo test --locked`, a
      `--no-default-features` build, `tools/loop/check_kernel_fixtures.sh`,
      the control-plane suites, `cairn scan` and `cairn hook all`.
