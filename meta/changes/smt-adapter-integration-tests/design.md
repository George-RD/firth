# Design: smt-adapter-integration-tests

## Approach

`dec.smt-adapter-integration-tests` records why the suite runs the whole path
and asserts only on its ends, why resource bounds are asserted on the
invocation rather than read back out of the profile, why "unchecked `unsat` is
deferred" is tested as "did not pass the adapter", why unsupported input is
tested where it is refused, and why determinism is asserted by repetition.

The runner is a recording variant of the injected seam: it answers from a queue
of prepared transcripts and keeps the options, script and bound it was given,
so the invocation itself is observable without a process.

## Changes

ADDED:
- `src/elaborator/FirthAdapterIntegrationTest.lean` and the
  `firthAdapterIntegrationTest` executable.
- `meta/decisions/smt-adapter-integration-tests.md`.

MODIFIED:
- `lakefile.toml`: the new executable and its default target.
- `src/agent/FirthAllTest.lean`: the suite runs from `lake test`.
- `AGENTS.md`: the new suite in the command list.
