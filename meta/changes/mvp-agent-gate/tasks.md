# Tasks: mvp-agent-gate

- [x] Verify the manifest, guide, interface files, application sources and
      transcripts before executing anything, failing closed on a missing file,
      a stale hash, a malformed entry, an escaping path, a duplicate name, a
      lowered minimum, and invalid TOML.
- [x] Rebuild each application in a scratch workspace, checking that the
      workspace holds only that application's source.
- [x] Run elaborate, compile, VM and reference-run, joining each adapter's
      output into the next request.
- [x] Compare terminal status, trap classification, the bottom-to-top stack,
      trace boundedness, the cost report, and the world projection; refuse a
      dual fuel exhaustion as inconclusive.
- [x] Add a fourth application exercising the Gamma primitive profile, with
      its transcript and manifest entry.
- [x] Add seventeen fail-closed tests over synthetic trees, including one that
      pins the provenance-before-execution ordering.
- [x] Confirm `python3 tools/loop/coverage.py --run-gates` reports the gate
      passing and no longer lists it under `missing_gates`.
