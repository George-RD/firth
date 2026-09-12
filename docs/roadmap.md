# Firth: roadmap to a useful language

Revised 8 September 2026 following the maintainer's request. The current
portable subset is an experimental baseline, not a completed application
language. PR #109 is not accepted merely because its previous tests passed.

## What success means

A fresh agent can build, run and modify a useful component from public
documentation, with declared guarantees actually checked and failures reported
honestly. This is a testable interpretation of PRD G8/G9, not a new syntax or
orchestration project. The first consumer is a pure inventory allocator inside
an ordinary host application.

The obligations matrix and `meta/todos/` remain the work authority. This page
explains their order. `coverage.py --run-gates` reports the active work and
executable gates; an empty queue alone never establishes product acceptance.

## Milestones and acceptance

| Milestone | Deliverable | Acceptance evidence |
| --- | --- | --- |
| M0. Trustworthy experimental baseline | Close false checking claims, evidence-admission and runtime defects; implement differential testing; land the baseline | Negative tests through public boundaries, seeded compiler/reference tests, all required gates and resolved review blockers on the exact candidate, then verification on merged main |
| M1. Useful component | Stock allocation written in Firth, called through a small host interface | Independent fixed acceptance corpus, invalid inputs, checked conservation/policy properties, matching VM/reference execution, and a policy change that preserves other requirements |
| M2. Agent-usable release | Reproducible install and check/run/test workflow, executable docs and local contract/diagnostic discovery | A clean environment follows the docs; fresh-context agents implement, change and repair the consumer without inspecting language internals |
| M3. Expand only on evidence | Verified live-patch demonstration, broader libraries/targets and measured comparative authorship | Relevant original S3/S4/S7 criteria, retained authentic results and explicit limitations; never inferred from closing tasks |

M0 does not promise source-level refinement execution. Until M1's real
source-to-obligation path is implemented, annotations must be rejected rather
than reported as proved. The kernel metatheory, a type-checked source program,
a discharged contract and a successful test run are different evidence.

## Work order

| Work | Tracker task(s) |
| --- | --- |
| Current boundary fixes and their full acceptance | `language-00-boundary-regressions` |
| SMT record and compiler evidence admission | `language-01-smt-record-admission`, `language-02-compiler-evidence` |
| Runtime comparison and validation | `language-03-runtime-conformance` |
| Actual differential generator, replay and shrinking | `language-04-differential-execution` |
| Review, requirement-evidence audit, full gates and landing | `language-05-baseline-acceptance` |
| Real source contract checking | `language-06-source-refinement-execution` |
| Independent consumer specification and cases | `language-10-inventory-contract` |
| Arithmetic/comparison; bounded data and reusable modules | `language-11-arithmetic-comparison`, `language-12-data-and-modules` |
| Firth consumer and maintenance demonstration | `language-13-inventory-component` |
| Reproducible tooling/docs; fresh-agent change pilot | `language-20-agent-workflow`, `language-21-docs-only-change-trial` |

Each task contains dependencies and acceptance criteria. Split an oversized
task before implementation, preserving the parent obligation and open work.
The first implementation targets are trust failures, not more primitives.
The current source-boundary refusal is a safety fix, not implementation of
source refinement proofs. A strategy document is not the differential harness.

## First consumer

[Inventory allocation contract](../specs/inventory-allocation.md) and its
[fixed cases](../specs/inventory-allocation-cases.json) define the calculation.
The host owns JSON decoding, storage, transactions and the UI; Firth owns the
allocation logic. The host must not conceal the algorithm in a primitive.
There is no live customer integration or production inventory mutation in this
milestone. Database concurrency remains outside a pure calculation proof.

Choose language additions from this workload: arithmetic and comparisons,
structured values, explicit results/errors, bounded collections and reusable
vocabularies. Preserve the verified kernel; a necessary semantic extension
requires its own accepted decision and metatheory checks, not a silent patch.

## Completion discipline

A specification task can be done when the specification is accepted. An
implementation obligation additionally needs executable behaviour and linked
implementation work. Preserve this distinction when generating the backlog.
Every confirmed review defect is fixed in scope or becomes a linked open task
before ending the session. It must not survive only in a PR comment.

Record these separately: implemented, verified at a commit, merged, and
accepted on main. A branch-local `done` status is not a landed release.
The existing `mvp` profile remains active, with the concrete consumer and agent
pilot added by the maintainer-authorised milestone decision. Original
post-mvp rows remain visible; do not switch to `full` just to grow the queue.

The acceptance specification and expected results are not writable targets for
an implementation agent trying to get green tests. Changes require a reviewed
requirement change and retained old cases. For example, conservation alone is
insufficient: allocating nothing can conserve stock but violate fulfilment.

## Deliberately not next

Do not start a language server, package registry, web framework, general I/O
layer or new autonomous orchestration system before the consumer exposes a
need. Do not market runtime hashes as authenticated proofs, finite tests as a
compiler theorem, or kernel cost as a hardware timing guarantee.

The decision after the first pilot is evidence-driven: expand when Firth
reduces failed changes or repair effort. Improve its interface when diagnostics
are the bottleneck. Revisit the authoring surface when stack bookkeeping is the
bottleneck. No assumption that future models will make current weaknesses
irrelevant is required.
