# Tasks: mvp-agent-compiler-adapter

- [x] Implement SHA-256 in Lean and check it against the FIPS 180-4 vectors.
- [x] Implement the canonical target encoding of `target-spec.md` §7 and pin
      it against the Rust encoder with byte vectors.
- [x] Render the canonical erased word type, with positional item labels,
      positional row renaming, and a refusal for unresolved inference
      variables.
- [x] Mangle source names into the target `Name` grammar injectively, and
      refuse a collision.
- [x] Apply the §3 lowering table, refusing `unit`, a pushed `World`, and
      `send` as having no v0.1 target representation.
- [x] Add the `firth.compile.v1` adapter and the `firthCompile` executable,
      sharing the reference interpreter's program decoder and the agent's
      duplicate-member scan.
- [x] Check the one-instruction-per-atom invariant before emitting
      `debug_locations`.
- [x] Record `dec.compiler-target-lowering` and the two blueprint edges it
      covers, in the same commit.
- [x] Add `firthCompilerTest` and run it from `lake test`.
- [x] Run `lake build`, `lake test`, the control-plane suites, both
      validators, `cairn scan` and `cairn hook all`.
