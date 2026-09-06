# Tasks: smt-adapter-integration

- [x] Check each of the parent's criteria against the tree rather than against
      the child todos' claims.
- [x] Bind the normaliser's and the VC generator's translation-rule and
      soundness-proof hashes into every request and record, which no child
      todo owned.
- [x] Refuse two rule sets, or two proof sets, that share a name.
- [x] Assert the binding set and its distinctness from the record integrity
      suite.
- [x] Run `lake build`, `lake test`,
      `! rg -n '\b(sorry|admit)\b|TODO|unimplemented|placeholder' src/elaborator src/smt`,
      `git diff --check`, the control-plane suites, `cairn scan` and
      `cairn hook all`.
