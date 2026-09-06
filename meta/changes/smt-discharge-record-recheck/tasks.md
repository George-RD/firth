# Tasks: smt-discharge-record-recheck

- [x] Add `ExternalOutcome.checkedUnsat` and make `checkUnsat` its only
      producer, refusing an unpinned profile, an unpinned request, an unbound
      result, stale proof bindings and an unsupported fragment.
- [x] Record every field `spec/smt/refinement-discharge-architecture.md` §3
      names, split into the elaborator-owned `ObligationBinding` and the
      solver-owned `DischargeRecord`.
- [x] Recompute every derived field in `makeDischargeRecord` rather than
      accepting a caller's claim about it.
- [x] Recheck by rebuilding the formula from the typed IR, revalidating every
      binding, recomputing every derived field, and returning the request to
      run rather than a verdict.
- [x] Rerun the pinned checker over a rechecked request and require the
      rebuilt record to agree with the recorded one on every input, evidence
      excepted because it is an output.
- [x] Give a record its own content address, and record the whole source
      location and the whole solver profile.
- [x] Promote at the boundary rather than believing a caller's tag, and refuse
      a result that arrives already promoted.
- [x] Expose a validated `unsat` through `PipelineResult.dischargeRecords`, and
      report a rerun through the same boundary, keeping every other outcome
      deferred.
- [x] Cover promotion, construction, drift and rerun with an injected runner so
      `lake test` needs no solver.
- [x] Regenerate both manifests and run `lake build`, `lake test`, the
      control-plane suites, `cairn scan` and `cairn hook all`.
