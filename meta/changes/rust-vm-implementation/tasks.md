# Tasks: rust-vm-implementation

- [x] Publish `body_digest`, `evidence_digest` and `seal_image` so a `WordPatch`
      and an image can be built through the frozen contract alone.
- [x] Reuse those helpers in `fixture_image`/`fixture_word` instead of
      repeating the canonical encoding.
- [x] Add the `run <image-path> [--fuel <n>]` CLI subcommand reporting through
      the conformance boundary, with usage, unreadable-path and trap exits.
- [x] Add `tests/lifecycle.rs`: load, execute, redefine, verify, atomic swap,
      compared with the frozen reference rows.
- [x] Prove a refused patch, a stale patch, and a patch whose body digest does
      not bind all leave the prior image observable.
- [x] Extend `tests/cli.rs` to the new contract.
- [x] Run `cargo fmt --check`, `cargo clippy --all-targets --all-features
      --locked -- -D warnings`, `cargo test --locked`, a
      `--no-default-features` build, and confirm the crate has no dependency,
      no unsafe block, and no `todo!`, `unimplemented!`, `TODO` or
      `placeholder`.
