# Verification: public-source-tests

## Correction to the 14 September record

The first record said the 28 tests ran in a workspace reconstructed from main
commit `c6b1a19c5a94eacf13d2b9679b2bbbf1eba33ff7` (tree
`02b63845f454800c11f3589332447c916176b24b`). That tree does not contain
`tools/loop/test_firth_run.py`, so those results cannot be attributed to it.
They are withdrawn and replaced by the checks below.

## Local checks, 27 September 2026

Run from a checkout of candidate commit
`0f3901ff06d553dca7ab2b95c34125332ffbad7d` (tree
`fb9f902f74be6a7a2517d0c479f1f234fdee5044`) with Python 3.11.15, first as
published and then with the review fixes in the commit that adds this record.

- At `0f3901f`: `python3 tools/loop/test_firth_run.py` ran 28 tests, all
  passing, with mocked build/rebuild boundaries.
- At `0f3901f`: every `tools/loop/test_*.py` suite, run as CI runs them (20
  suites), passed. This replaces the earlier interrupted broader sweep.
- At `0f3901f`: Python compilation of the CLI and language-example gate,
  `check_mvp_agent_inputs.py`, `select_unit.py --validate`,
  `coverage.py --validate` and `git diff --check c6b1a19 HEAD` passed.
- With the review fixes: 30 tests pass. The two new tests (non-UTF-8 source
  refused before build; every case runs the pre-build snapshot) and the
  updated rebuild-entry assertion fail against the unfixed runner.

Lean, Cargo and Cairn are not available in this container, so no local
language or governance pass is claimed. CI run
[34786322525](https://github.com/George-RD/firth/actions/runs/34786322525)
passed all four gates on `0f3901f`, including `check_language_examples.py`
with the real toolchains; it does not verify the review-fix commit.

## Required candidate checks

The existing CI runs all Python suites, including the 28 new cases, and invokes
`check_language_examples.py` with the real Lean and Rust toolchains. The added
integration checks require three passing saved cases and a mixed suite with
an expected-stack mismatch, fuel exhaustion and a final passing case. They
also require the documented command's exit status and ordered JSON report.

Full CI and review evidence must be bound to the published candidate before
merge. The prior baseline's successful run is not verification of this code.
No kernel, proof pin, source contract, frozen corpus or acceptance oracle is
changed. The wider agent-workflow task remains open.
