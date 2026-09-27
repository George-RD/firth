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

This page and the maintainer are the work authority. The autonomous loop,
its obligations matrix and its completion check were frozen on 27 September
2026 (`dec.loop-freeze`, `archive/loop/README.md`). `meta/todos/` is a record
of tasks, not a definition of done.

## Goal status

Checked on 27 September 2026 against `main` at c6b1a19. "Met" means the PRD's
own wording is satisfied, not a narrowed reading of it.

| Goal | Status | What honestly done looks like |
| --- | --- | --- |
| S1. Kernel metatheory, zero admits | Met | Preservation, progress and determinism are proved in Lean with no `sorry` or `admit` (`check_zero_admit.py`). This covers the kernel calculus, not the surface elaborator. |
| S2. No compiler/reference divergence under sustained fuzzing | Open | The harness exists but runs 24 seeded cases, and its generator still emits only `prim +`, although `-`, `*`, `<`, `=` and tail calls now run (#113). Done is a retained campaign over the whole executable language (arithmetic, comparison, recursion, data) at a stated scale with zero divergences. |
| S3. Verified live patch end to end | Open | Not demonstrated. Deliberately after M1. |
| S4. Self-hosted standard library | Open | `stdlib/core.firth` is 21 lines. Done is a library written in Firth that the M1 component actually uses, checked by the toolchain. |
| S5. Non-trivial program, verified to a spec, run in a cost bound | **Reopened** | Previously "met" by a program that adds 1, 2 and 1. Done is the M1 inventory allocator (or a program of the same weight): it iterates over a bounded collection using arithmetic and comparison, its stated properties (conservation, no over-allocation, the fulfilment policy) are checked by the toolchain, not only by tests, and it runs on the VM with results matching the reference interpreter inside a cost bound stated as a function of input size. "Checked by the toolchain" means Lean proofs, for every valid input, over the kernel program the elaborator emits, run by the reference interpreter and admitted as rechecked evidence bound to the word digests (`language-06b`); the cost bound is proved the same way (`language-06c`). The proofs also show that every value stays within the VM's i64 for every valid input. Two gaps are stated with any such claim: agreement of the compiler's lowering and the VM with the reference interpreter rests on differential testing, not a proof, and the Python host (JSON decoding and encoding, the ID encoding) is tested, not proved. This definition is proposed, pending George's decision. Until then, the fixed independent corpus is the check and that gap is stated. Progress (27 September 2026, #121 and #123): all 53 contract cases pass: 30 run in `examples/inventory/allocator.firth` with the VM and the reference interpreter agreeing, and 23 are rejected by the host's input checks, as the spec assigns them. CI checks every run against the measured bound 417 + 767n + 264n(n−1)/2 kernel steps. The partial to all-or-nothing policy change is demonstrated with changed-word and regression checks (#126). Still missing: the properties are checked only by the corpus (`language-06b`) and the bound is measured, not proved (`language-06c`). |
| S6. Third-party VM reimplementation | Open | Needs an outside party. Not a near-term goal. |
| S7. Measured machine authorship | Open | See the next row. Full S7 also needs the same tasks in a mainstream language as the baseline, and a materially higher pass rate in Firth. |
| MVP agent authoring | **Reopened** | Previously "met" by four three-line programs with unverified transcripts. Done is a fixed task set written before any trial (about 20 tasks, several at allocator weight), attempted by a fresh-context model given only the guide and the diagnostics loop, several attempts per task. A pass means check, run and expected outputs all agree. Report the pass rate with retained transcripts naming the model and date. A low rate is an acceptable result; an unmeasured one is not. |

The MVP gate (`tools/loop/mvp_agent_gate.py`) stays as a regression check that
the example corpus still builds and runs. It is not evidence for S5 or S7.

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
| Real source contract checking (arithmetic, SMT) | `language-06-source-refinement-execution` |
| Lean proofs of program properties; proved cost bounds | `language-06b-program-property-proofs`, `language-06c-proved-cost-bound` |
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
Only the maintainer moves a goal in the table above to "Met".

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
