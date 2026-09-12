# Tasks: mvp-agent-vm-adapter

- [x] Add a bounded, dependency-free JSON reader and writer to the VM crate.
- [x] Decode `firth.vm-execution.v1` and re-decode the sealed target program
      through the trusted decoder so every contract rule is enforced there.
- [x] Execute a named entry word so cost agrees with the reference
      interpreter without a synthetic administrative call.
- [x] Emit `firth.observation.v1` with the reference adapter's value encoding.
- [x] Classify malformed images, unknown words, unknown primitives, invalid
      primitives, stack faults and fuel exhaustion as traps, never success.
- [x] Refuse the unit literal, a kernel quotation, and World in the initial
      stack rather than approximating them.
- [x] Add the `vm-run` CLI subcommand reading one request from stdin.
- [x] Run `cargo fmt --check`, `cargo clippy --all-targets --all-features
      --locked -- -D warnings`, `cargo test --locked`, and a
      `--no-default-features` build.
