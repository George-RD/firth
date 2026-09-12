# Verification and handoff, 8 September 2026

## Verified candidate, not merged acceptance

Code and roadmap commit: `296bc85e0fe92c7301b14c98cd3acca701537099`.
Tree: `a0ed96914fd5d71a61443687c64b0616b2c5c225`.
CI: https://github.com/George-RD/firth/actions/runs/34160894897.
All three jobs passed: Python regressions; Lean/Rust/source execution; Cairn.
Retained language and governance diagnostics were downloaded and inspected.

The following tracker-only update records that result; it does not retroactively
claim another commit was tested. The PR remains unmerged and unapproved by this
pass. `language-00-boundary-regressions` is verified on this branch; the broader
`language-05-baseline-acceptance` task remains open.

## Before and after

The corrected test-only commit `ebbddd1bca76828efd718d0c49feb4fa7157b21d`
failed CI run 34159503443 with 2 passing and 18 failing boundary cases. Six
malformed quotation cases crashed the VM with out-of-bounds panics. The first
attempt e601fd7 included six wrongly shaped test envelopes and is not used as
the final red baseline.

At 296bc85e the same 20-case gate passes completely. Tests cover plain typed
source and unrestricted quotations positively, and reject five source-contract
cases, three empty programs, an unsupported linear quotation, and nine malformed
capture-state cases. True but unimplemented source predicates are refused too.
This is safe refusal, not implementation of source refinement proof checking.

An intermediate fix changed a file pinned as an original agent input. The
original corpus correctly rejected that drift. The file was restored verbatim
and the existing validation diagnostic channel reused. No frozen guide,
original authored program, transcript pin, or governed proof hash was changed.

## Gates and observations

Passed: clean Lean build and suites; source and compiled proof bindings;
zero-admit check; canonical-name and real solver-pipe regressions; Rust format,
clippy and tests; reference kernel fixture consistency; the original four
programs; all 20 new boundary cases; 9 successful executable source/input cases,
7 expected refusals and 2 documented CLI invocations; S5 bounded-cost witness.
S5 reported kernel cost 25 and VM cost 31 against envelope 40.

Python CI passed all control-plane suites, including five live roadmap-binding
tests and three consumer-specification tests over 19 fixed cases. The consumer
cases are not execution evidence for a Firth inventory application.

Cairn 0.9.0 was installed from its checksum-pinned official release. Scan and
all hooks passed with **0 errors, 43 warnings and 26 informational findings**.
Warnings were retained, not suppressed. Existing unresolved gaps/provenance
warnings still require disposition in the baseline audit. No tracked evidence
was rewritten by the governance checks.

`coverage.py --run-gates` executed all pinned acceptance gates:
`missing_gates = []`, `failing_gates = []`, `loop_exhausted_valid = false`.
Fourteen obligation rows remain in flight. False exhaustion is the correct
result while the active roadmap is unfinished, not a CI failure to bypass.

## Next session

The selector can now choose `language-01-smt-record-admission`, followed by the
compiler evidence and runtime/conformance tasks and actual differential harness.
Reproduce each review finding through the current public boundary, fix it and
retain a regression. Finish the full acceptance/review task before merging.
The source-refinement implementation, independent consumer-spec review,
arithmetic, data/modules, Firth consumer and fresh-agent trial stay open.

The next session does not need to reconstruct the work from this note:
`meta/todos/` and `tools/loop/obligations.toml` contain the dependencies and
acceptance criteria, and `docs/roadmap.md` explains the product milestones.
