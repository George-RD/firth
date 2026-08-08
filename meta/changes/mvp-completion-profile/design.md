# Design: mvp-completion-profile

Authority and boundary rationale live in `meta/decisions/mvp-completion.md`
(dec.mvp-completion, accepted, maintainer-authored outside the loop per
dec.loop-autonomy clause 2a). This file records the mechanism.

## Matrix

`[completion] profile = "mvp" | "full"`; per-row `milestone = "mvp"`
(default) or `"post-mvp"`. Eight rows are tagged post-mvp:
`scope-toolchain-signature-search`, `scope-ecosystem-lsp`, `req-r16`,
`sc-s2`, `sc-s3`, `sc-s4`, `sc-s6`, `sc-s7`. One row is added:
`mvp-agent-authoring` (node `firth.toolchain.agent`), the executable
guide-plus-apps acceptance gate defined by dec.mvp-completion clause 4.

## coverage.py

- Classification lists, `first_incomplete`, `next_obligation`, and
  `loop_exhausted_valid` are computed over the active profile's rows;
  excluded rows are reported under `outside_profile`.
- Dependency gating is active-scoped: a node whose matrix rows are all
  outside the profile is gate-neutral (`complete`), so the inactive
  horizon cannot deadlock active dependants; a node with no matrix rows at
  all stays `ungenerated`, as before.
- The todo gate excludes todos whose every matrix reference is inactive
  (roadmap); unmapped todos still gate, conservatively.
- Validation rejects unknown `milestone` values and unknown profiles.

## select_unit.py

- Todos whose every matrix reference is inactive are never selected and
  are reported under `outside_profile`.
- A live todo inside the profile that `Requires:` such a todo is a
  validation error (fail closed), so an active unit can never be starved
  by an inactive prerequisite. `rust-vm-patch-protocol` therefore stays
  MVP: `rust-vm-implementation` structurally requires it.
- A missing matrix means no filtering (fixtures, fresh checkouts); a
  malformed matrix is a validation error.

## Tests

`test_coverage.py`: mvp scoping of termination and generation, full-profile
regression, inactive-only todo exclusion, unmapped-todo conservatism,
inactive-node gate neutrality, invalid profile/milestone validation.
`test_select_unit.py`: outside-profile filtering, cross-profile Requires
failure, malformed-matrix failure, missing-matrix behaviour.
