# Tasks: mvp-agent-elaborate-adapter

- [x] Author `todo.mvp-agent-elaborate-adapter` and append it to
      `todo.mvp-agent-gate`'s `Requires` rather than widening another unit.
- [x] Decode `firth.source.v1`, failing closed on malformed JSON, a duplicate
      member, an unknown or missing member, an empty identifier, and an
      unsupported language or gamma version.
- [x] Resolve the manifest `[gamma]` primitives into the erasure and typing
      environments so `prim +` and `prim send` elaborate.
- [x] Emit `checked_words` and `erased_word_types` byte-compatible with the
      compile adapter's request, and `kernel_programs` for the reference run.
- [x] Refuse an unresolved row, type or usage variable rather than defaulting.
- [x] Emit failures as versioned diagnostic envelopes.
- [x] Add `firthElaborateTest` and run it from `lake test`.
- [x] Run `lake build`, `lake test`, the control-plane suites, both
      validators, `cairn scan` and `cairn hook all`.
