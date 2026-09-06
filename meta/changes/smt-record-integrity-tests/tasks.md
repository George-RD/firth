# Tasks: smt-record-integrity-tests

- [x] Build the fixture from a real open verification condition, and assert
      that an unmutated record is confirmed before asserting any refusal.
- [x] Cover stale records: another word, body, specification, predicate
      definition, toolchain revision and source span.
- [x] Cover tampered records: an edited solver name, version, formula address
      and script address.
- [x] Cover profile, version, executable-digest and invocation-option drift,
      and request mismatch.
- [x] Cover translation-rule and soundness-proof mismatch at recheck, and
      incomplete proof bindings at promotion.
- [x] Cover an obligation that no longer translates, and every rerun answer
      that is not a promotable `unsat`.
- [x] Cover a solver that is absent, undigestable or not the pinned binary.
- [x] Assert on the refinement-discharge result boundary in every case: no
      record exposed, one Lean escalation, one deferred diagnostic carrying the
      failure's stable code.
- [x] Run `lake build`, `lake test`, the control-plane suites, `cairn scan` and
      `cairn hook all`.
