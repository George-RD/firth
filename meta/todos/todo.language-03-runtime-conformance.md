---
node: firth.runtime.vm
status: done
created: 2026-09-08
---

Requires: language-00-boundary-regressions

## Goal

Close runtime and cross-host comparison gaps.

## Acceptance criteria

- Triage every remaining runtime/conformance review finding with a reproducer or evidence-backed disposition.
- Define comparable quotation results without equating different bodies/captures; either compare a justified normal form or reject unsupported comparisons explicitly.
- Validate malformed image/quotation states before encoding and execution across supported public entry points. Trap/fuel/overflow must not count as successful agreement.
- Add negative and differential tests for return values, costs and observations. Do not claim full trace equivalence from final-stack equality.

## Traceability

PR #109 runtime, quotation and conformance reviews; PRD R5/R7/R8.

## Portable comparison sub-slice, 8 September 2026

`meta/changes/portable-observation-validation/` implements strict scalar-result
and pure-world validation, duplicate/non-finite adapter JSON rejection, and
explicit refusal of returned quotations whose bodies/captures lack a shared
comparison format. Regression tests preserve internal quotation execution.
The verification record distinguishes local Python checks from real-host CI.

This parent remains open. These changes do not validate all Rust image entry
points, reconcile all runtime review findings, authenticate compiler evidence,
or establish full trace equivalence. Complete those acceptance criteria and
the baseline audit before marking the parent done.

## Verified sub-slice: direct runtime ingress bounds

`meta/changes/runtime-ingress-bounds/` addresses bounds on caller-created
images and initial stacks, repeated quotation traversal, and captured-value
depth alignment. Public-API regressions distinguish valid boundary inputs
from oversized or malformed inputs, and a subprocess deadline checks the
nested-code validation path. Production solver provenance, image/patch proof
admission and complete conformance remain open; this is not baseline acceptance.

Validation run `34373202388` reproduced 15 selected baseline failures and
passed all 20 new cases in both std and no_std builds. Exact source identities,
logs and limits are recorded in the change's `verification.md`. Ordinary PR
CI still gates the product head; the parent remains open.

Remaining comparison target from static review: the Rust
`src/runtime/vm/src/conformance.rs` display renderer collapses quotation
bodies/captures, while frame rendering omits resume state. Add public
reproducers and either a justified shared normal form or explicit
unsupported-comparison results. Python's existing portable refusal must not
be treated as closure of the separate Rust comparison surface.

## Verified sub-slice: scalar observation payloads and named reports

`meta/changes/runtime-observation-payloads/` fixes byte/primitive payload
collisions in the Rust stack renderer and incorrect `main` labels in named
report execution. Public-API regressions retain exact scalar representations,
real false-agreement reproducers and report/diagnostic parity. This does not
close quotation/frame projection losses, full trace comparison, image/patch
proof admission, process provenance or baseline acceptance.

Validation run `34378902545` reproduced exactly 13 failures on the unchanged
runtime in both std and no_std configurations, with the positive controls
passing. The candidate passed all 15 std / 14 no_std observation tests, the
full 134-test Rust suite, 309 Python unit tests plus the review-gate script,
and Cairn's strict gate. Exact source identities and limitations are in the
change's `verification.md`. Product-head CI and merged-main acceptance remain
separate; this parent is still open.

## Implementation slice: conformance comparison closure

`meta/changes/runtime-conformance-closure/` closes the comparison and
bounding gaps that remained after the two earlier sub-slices. The Rust
conformance renderer now renders quotations (usage, canonical body digest,
capture slots) and residual frames (word, code digest, instruction pointer,
continuation, saved `DIP` value, capture state) in full. A reference stated
only as `quotation-many`, `quotation-linear` or `word@pc` is a projection:
the comparison is `UnsupportedComparison`, never `Agree`, and the frozen
corpus row `quote` is asserted as exactly that while the other fourteen rows
agree in full (a single root `main@pc` frame is lifted, so row `drop-fault`
agrees exactly). `firth.vm-run.v1` reports per-event charges and kernel
charges, per-event and residual frames, full quotation payloads that
round-trip through the request grammar, the trap subcode, and an explicit
admission label in the compiler's vocabulary; `firth-vm run` prints the same
label. The MVP gate, the differential harness and the S5 witness compare the
two traces event by event after projecting both onto kernel-charged steps;
scalar traces must agree stack for stack (`agreed`) and traces whose
intermediate stacks hold quotations are labelled `unsupported-quotation-values`,
which is neither failure nor agreement. Recursion traps deterministically at
`MAX_CALL_DEPTH` (256 administrative frames, pinned inside a 2 MiB thread)
with `resource-fault/call-depth-exceeded` instead of aborting the process;
adapter and CLI fuel are bounded to 4096 and Python shares the bound. The
per-step machine clone, the quadratic duplicate-member scan, the transport
nesting bound, escaped surrogate pairs, both unbounded CLI reads, unchecked
`push-quote` envelopes and pre-consumed capture bitmaps are fixed, with
subprocess-deadline reproducers in `tools/loop/check_runtime_bounds.py`. The
S5 gate proves both branches from both traces and refuses a one-branch
control, and the MVP gate binds the manifest's declared contract before
provenance.

## Residual limitations

- There is no cross-host quotation normal form: the reference reports a
  kernel body and the VM a lowered body with captures, so quotation-valued
  stacks and traces are labelled unsupported rather than compared.
- Residual programs and frames are not compared across hosts, and trace
  step counts, words and instruction pointers are not compared.
- The depth cap is a hosted-VM bound the reference interpreter lacks; a
  deeper program is a one-sided trap that disagrees by design. The iterative
  executor that would lift the cap is future work.
- Evidence digests remain unauthenticated content identifiers and
  verified-patch admission remains delegated to the caller's verifier; every
  observation surface now says so. Authenticated admission is tracked by
  `patch-refinement-evidence-admission`.
- This is branch verification under bounded tests, not baseline acceptance
  on `main`.
