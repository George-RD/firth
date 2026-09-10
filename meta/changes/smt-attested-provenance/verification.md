# Verification: SMT attested provenance

Baseline: `80a9d41f3895b25793c7c4c37f1ec60bb29f10ef` (head of PR #109). All
work was done in a worktree on that commit with the pinned Lean 4.30.0
toolchain, on an x86_64 host that cannot run the pinned linux-arm64 solver.

## Failing before, passing after

A regression-only patch (sha256
`dd1b7ecc0998f426c0ca22c4d219bedf1281f912b5c3570c659e5465ba47cec5`, retained
in the agent scratch area and not committed) added only assertions written
against the baseline signatures, was built on the unchanged baseline, and
produced these failures, one per suite, in this order:

- `lake exe firthRefinementTest` (R1): `a hand-built unsat for a refutable
  obligation creates no discharge record / actual: 1 / expected: 0`. The
  baseline published a record for `x = 1 ⊢ x < 0` from a hand-built
  `uncheckedUnsat` without any solver.
- `lake exe firthAdapterIntegrationTest` (R8): `a model run that exited
  non-zero after answering: Lean escalation reason / actual: ...invalidCountermodel
  / expected: ...externalCrash`. The baseline parsed the model from a crashed
  model run.
- `lake exe smtSolverTest` (R10): `an entry without the outer list was
  accepted as a model: { integers := [("x", 5)], booleans := [] }`.
- `lake exe smtSolverTest` with `solveTests` moved ahead of `parseModelTests`
  (R9): `a model run that exits non-zero is a crash, not a counterexample /
  actual: ...sat { integers := [("x", 5)], booleans := [] } / expected:
  ...crashed "model run: exit 1"`.

The patch was reverted with `git checkout` before implementation. The same
assertions, migrated to the attested signatures, pass after.

## Gates run on the final tree, in the plan's order

Regeneration, after every Lean edit was final:

1. `python3 tools/loop/update_smt_proof_bindings.py`: all ten hashes in
   `defaultSmtProofBindings` changed (zero of the baseline's ten survive),
   envelope `8e94b2538dcebb97fdcb3ff252e1f1b733d7a38ca5cdfabe99e072d82f4de566`
   over 57 inputs. The four rule and six soundness region bodies were
   extracted from the baseline and from the final sources with the same
   script and are byte-identical (`diff -r` over the ten bodies is empty).
2. `lake build`: 98 jobs, success.
3. `python3 tools/loop/update_proof_manifest.py`: seven entries. Against the
   baseline, Refinement changed (`cebcfa7e...` to `8e16d0ba...`),
   SmtBoundary changed (`6e98c13d...` to `faf883e1...`), SmtSolver appeared
   (`c842cec0...`); StackEffect, Erasure, Parser and Firth/Interpreter are
   unchanged. The chain was run twice, because the first pass tripped
   `check_zero_admit.py` on the bare word "admit" in a new doc comment; the
   comment was reworded and the whole chain rerun.
4. `update_smt_proof_bindings.py --check`, `update_proof_manifest.py --check`,
   `check_zero_admit.py`, `check_smt_attestation.py`: all pass.

Then:

- `lake test` (driver `firthAllTest`, all fourteen suites): exit 0.
- `lake env lean --run src/smt/FirthSmtProcessTest.lean`: pass.
- `src/smt/FirthSmtPinnedRefusalTest.lean` with `FIRTH_SMT_SOLVER` unset:
  refuses an absent explicit path, a relative path and the unset variable as
  `executableMissing`, and a `#!/bin/sh` script that answers `unsat` (checked
  by running it through `processRunner` first) as
  `executableDigestMismatch`, for `solvePinned` and `rerunPinned`. With
  `FIRTH_SMT_SOLVER=/usr/bin/python3`: the same, plus the named executable
  refused as digest mismatch. Both runs were made through `lake env lean --run`
  before the final regeneration and through the toolchain's `lean` binary
  with Lake's `LEAN_PATH` after it; all four passed.
- Every `python3 tools/loop/test_*.py` (18 suites, including the new
  `test_smt_attestation.py` with 17 cases and `test_tcb_boundary.py`): pass.
- `check_tcb_boundary.py` (21 components, 6 stages), `check_mvp_agent_inputs.py`,
  `check_trust_boundaries.py` (24 cases), `check_compiler_admission.py --no-build`
  (45 cases): pass.
- `cairn scan`: zero errors (43 warnings and 33 infos, all pre-existing
  categories). `cairn hook all`: blocked once with
  `CAIRN_SOURCE_SHA256_MISMATCH` because the plan's sentences in
  `spec/smt/refinement-discharge-architecture.md` changed the digest the
  citation `src.refinement-discharge-architecture` pins; the citation's
  `sha256` and `date` were updated to the new content and the hooks then
  pass with `Decision: pass`.
- `git diff --check`: clean.

Not run here: the Rust VM gates, the MVP application gate, the documented
examples, the differential campaign and the cost witness. Nothing under
`src/runtime`, `examples` or `src/diffharness` changed; those remain the
responsibility of the integrating PR's complete CI.

## x64 solver evidence for transcript handling only

`z3-5.0.0-x64-glibc-2.39.zip` (sha256
`d4922cebc9f0a55629231ec0c62f0bbedf8006eddaed4e68199ad19626b697f6`) from the
z3-5.0.0 release, containing `bin/z3` with sha256
`e15df59f37c9d939af8370cf57cadb4928551e349e10b14eeb5d4859bdc663c3`
("Z3 version 5.0.0 - 64 bit"), was run on this host by a scratch program that
is not committed:

- `solve (processRunner path)` and `solvePinned ... (some path)` refuse it
  with `executableDigestMismatch`, expected
  `sha256:6457d932...` and actual `sha256:e15df59f...`, for both a provable
  and a refutable request built through `checkBodyRefinements`. The pin
  authenticates the binary.
- Raw transcripts through `processRunner.run` under the pinned options: the
  provable decision script answers `"unsat\n"` with exit 0 and classifies as
  `uncheckedUnsat "unsat"`; the refutable decision script answers `"sat\n"`;
  its model script answers `"sat\n(\n  (define-fun i0 () Int\n    1)\n)\n"`,
  which classifies as `sat`, parses under the new grammar to
  `{ integers := [("x", 1)] }`, and validates as a countermodel.
- `src/smt/FirthSmtPinnedSolverTest.lean` run on this host with
  `FIRTH_SMT_SOLVER` naming that binary fails immediately with
  `the pinned solver was refused: ...executableDigestMismatch`, which is the
  expected outcome off the pinned platform.

This is evidence for the classification and parsing code, not for provenance.

## The arm64 job has not run

The `smt-pinned-solver` job (`ubuntu-24.04-arm`) is defined in
`.github/workflows/ci.yml` and has NOT yet run: no arm64 runner was available
to this worktree. It downloads the pinned acquisition URL, checks the zip
(`c9437ff7...`) and `bin/z3` (`6457d932...`) with `sha256sum --check`, and
runs `src/smt/FirthSmtPinnedSolverTest.lean`, which is the only positive,
record-producing exercise of `solvePinned`, `rerunPinned` and the two
boundary sites. The integrator must record that job's run id on the PR
before treating the positive branch as verified.

## Deviations from the plan, recorded rather than dropped

- `solvePinned` and `rerunPinned` do not return `executableMissing` early when
  the executable cannot be resolved; they run the shared path with a runner
  that reports no executable, so `verifyPin` refuses at the same point and
  after the same profile and request checks as for an injected runner, and a
  drifted record in `rerunPinned` reports its drift first. The observable
  refusal is the one the plan requires; the ordering is the same as the seam.
- The two CI refusal steps do not write `set -o pipefail`: the existing steps
  do not either, and rely on the workflow's `defaults.run.shell: bash`, which
  GitHub runs as `bash -eo pipefail`. Matching them exactly meant not adding
  it.
- The pinned solver zip is unpacked into `$RUNNER_TEMP` rather than the
  checkout, and the zip digest is checked before the binary digest.
- Structure-instance patterns on `Attested` are also refused outside the
  module ("constructor is marked as private"), so the suites read fields
  through projections; this is stronger than the plan assumed, not weaker.
- The citation `src.refinement-discharge-architecture` was re-verified against
  the edited spec, as described above; no other source changed.
- `AGENTS.md` and the manifest tool's docstring now say seven governed
  modules.
