# Verification: public-source-tests

## Local checks, 14 September 2026

The workspace was reconstructed from main commit
`c6b1a19c5a94eacf13d2b9679b2bbbf1eba33ff7` using its checksum-verified CI source
archive. The imported Git tree matched `02b63845f454800c11f3589332447c916176b24b`.

- `python3 tools/loop/test_firth_run.py`: 28 tests passed. These use mocked
  build/rebuild boundaries and exercise the real suite loader and CLI reporting.
- Python compilation of the modified CLI and language-example gate passed.
- `python3 tools/loop/check_mvp_agent_inputs.py`: passed; frozen authoring and
  interface inputs are unchanged.
- `select_unit.py --validate` and `coverage.py --validate`: passed.
- `git diff --check`: passed.

The broader Python sweep was interrupted by local process deadlines. Do not
count it as a completed suite. Lean, Cargo and Cairn are unavailable locally;
no local full-language or governance pass is claimed.

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
