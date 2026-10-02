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
| S5. Non-trivial program, verified to a spec, run in a cost bound | Met | Previously "met" by a program that adds 1, 2 and 1. Done is the M1 inventory allocator (or a program of the same weight): it iterates over a bounded collection using arithmetic and comparison, its stated properties (conservation, no over-allocation, the fulfilment policy) are checked by the toolchain, not only by tests, and it runs on the VM with results matching the reference interpreter inside a cost bound stated as a function of input size. "Checked by the toolchain" means Lean proofs, for every valid input, over the kernel program the elaborator emits, run by the reference interpreter and admitted as rechecked evidence bound to the word digests (`language-06b`); the cost bound is proved the same way (`language-06c`). The proofs also show that every value stays within the VM's i64 for every valid input. Two gaps are stated with any such claim: agreement of the compiler's lowering and the VM with the reference interpreter rests on differential testing, not a proof, and the Python host (JSON decoding and encoding, the ID encoding) is tested, not proved (the host gap was narrowed on 2 October 2026; see the end of this row). This definition was decided on 28 September 2026 (by the coordinator, on George's delegation). Until those proofs exist, the fixed independent corpus is the check and that gap is stated. Progress (27 September 2026, #121 and #123): all 53 contract cases pass: 30 run in `examples/inventory/allocator.firth` with the VM and the reference interpreter agreeing, and 23 are rejected by the host's input checks, as the spec assigns them. CI checks every run against the measured bound 165 + 202n + 163n(n−1)/2 kernel steps, taken over the costliest ID shape (the repeated-ID scan uses locals since `pick` and `roll`, #125). The partial to all-or-nothing policy change is demonstrated with changed-word and regression checks (#126). Proved since (28 September 2026, #137): `src/proofs/Inventory/Allocate.lean` proves in Lean, from the exported kernel program run by the reference interpreter, that `allocate-batch` returns the spec's result on every valid input, so the properties proved of that rule in `src/proofs/Inventory/Spec.lean` hold of its output, with every value in i64 and kernel cost at most that same bound (the constant is attained on an empty batch). The proof is recorded as evidence bound to the body digests of `allocate-batch` and the nine words it calls, the registry and the cost table, and all ten words are reported `contract_verified` (`src/proofs/records.json`). The recorded contract assumes only the host's ID encoding (four entries per request, each in [0, 65^8)); it assumes nothing about the stock or the quantities, which the program checks itself. The two stated gaps remain: VM and compiler agreement rests on differential testing (`todo.compiler-vm-agreement-proof`), and the Python host is tested, not proved (`todo.inventory-host-proof`). Met on 28 September 2026 under `AGENTS.md` rule 1, with those two gaps filed as todos. Evidence: #137 (the proofs) and #141 (the digest-bound record). Host gap narrowed (2 October 2026, `todo.inventory-host-proof` done): `src/proofs/Inventory/Host.lean` proves the ID encoding injective on the spec's ID syntax, so the recorded `allocate_batch_host_contract` states the duplicate-ID result on ID strings, and proves results are attached to their requests' IDs in request order; the host runs those Lean definitions (`lake exe inventoryHost`). The remaining trusted host code: Python's JSON parsing and the shape, type, ID-syntax and i64 checks in `run_cases.host_check`, which the spec gives the host, and Python's transport of the input and of the VM's final stack to and from `inventoryHost` (`run_cases.lean_host`); the JSON glue in `HostMain.lean` (`strings`, `ints`, `answerJson`, the four-value stack match) and Lean's JSON parser and printer; and Lean's compilation of the proved definitions into `inventoryHost`. The Python parsing and checks are tested by the corpus, the spec's two host tests (malformed JSON, repeated members) and planted bugs (`tools/loop/test_inventory_host.py`), the glue and transport by the corpus runs and `examples/inventory/check_host.py`; none of it is proved. |
| S6. Third-party VM reimplementation | Open | Needs an outside party. Not a near-term goal. |
| S7. Measured machine authorship | Open | See the next row. Full S7 also needs the same tasks in a mainstream language as the baseline, and a materially higher pass rate in Firth. The baseline is planned under "S7 baseline" below (`todo.s7-python-baseline`, `todo.s7-harder-task-tier`). |
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

## S7 baseline and eval subjects

Added 30 September 2026 following the maintainer's suggestions. This is planned work,
not a status change: no goal above moves because of it.

**Is Firth worth reaching for?** Runs 1 to 4 scored Python on the same
tasks, and it was at the ceiling each time for both Sonnet and Haiku (22 of
22, 9 of 9 on each of three attempts, 20 of 20; `eval/s7/README.md`). Runs 5
to 13 compare Firth with Firth. A result at the ceiling cannot show a
difference in either direction, so it is not a usable baseline for the
harder tasks. The S7 criterion stays as
written: a materially higher pass rate in Firth on equivalent tasks. The
weaker result, correct on the first or second try about as often as in
Python while Firth also proves things Python cannot, is reported too, but it
does not meet S7 and is not called a pass. So the baseline gives a model the
same harder tasks in both languages and measures correct on the first
attempt and correct within two. It then lists the guarantees Firth adds
(checked types, stack effects, linear ownership and declared effects, a
measured cost per run, and a proved cost bound only where a Lean proof is
written for one, as for the allocator) and
says whether the runs showed any of them catching a real error. Measured
and proved stay separate (`AGENTS.md` rule 8). The question
it answers is whether Firth beats Python for agent-written code that a host
runs without anyone reading it. If Firth loses badly, that is the most
useful result the eval could give us. Tracked in `todo.s7-python-baseline`.

**Subject models.** Sonnet 5.5 is planned as the primary subject, following
the maintainer's suggestion: it is the realistic balance of cost and ability, and few people use Haiku for real
work. Haiku 4.5 stays as a secondary check of how learnable the language is
for a small model. A cheap non-Anthropic model (the maintainer named
DeepSeek Flash) is an option only if it can be reached without new
credentials.

**Harder tasks first.** Sonnet scores 19 to 20 of 20 on the current MVP
tasks, and Python scored 20 of 20 for both Sonnet and Haiku (run-4 table,
`eval/s7/README.md`). Neither the
baseline nor a Sonnet-primary run can show a difference at that ceiling, so
both need a harder task tier written before any trial
(`todo.s7-harder-task-tier`).

**Order.** After the current run 14 (the Haiku check-tool A/B, PR #200) has
finished. Nothing here changes what run 14 measures.

## Completion discipline

A specification task can be done when the specification is accepted. An
implementation obligation additionally needs executable behaviour and linked
implementation work. Preserve this distinction when generating the backlog.
Every confirmed review defect is fixed in scope or becomes a linked open task
before ending the session. It must not survive only in a PR comment.

Record these separately: implemented, verified at a commit, merged, and
accepted on main. A branch-local `done` status is not a landed release.
A goal in the table above moves to "Met" only as `AGENTS.md` rule 1 says: a
PR that changes only the goal's status cell, its row's gap text and the gap
todos, whose independent review finds the evidence meets the goal as written,
with every gap stated and filed. The maintainer can reverse it.

The acceptance specification and expected results are not writable targets for
an implementation agent trying to get green tests. Changes require a reviewed
requirement change and retained old cases. For example, conservation alone is
insufficient: allocating nothing can conserve stock but violate fulfilment.

## Deliberately not next

Do not start a language server, package registry, web framework, general I/O
layer or new autonomous orchestration system before the consumer exposes a
need. Do not extend the SMT path to sequences: the chosen route for sequence
properties is Lean proofs (`dec.s5-proof-standard`), which are not written
yet. Do not market runtime hashes as authenticated proofs, finite tests as a
compiler theorem, or kernel cost as a hardware timing guarantee.

The decision after the first pilot is evidence-driven: expand when Firth
reduces failed changes or repair effort. Improve its interface when diagnostics
are the bottleneck. Revisit the authoring surface when stack bookkeeping is the
bottleneck. No assumption that future models will make current weaknesses
irrelevant is required.
