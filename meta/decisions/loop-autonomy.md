---
id: dec.loop-autonomy
nodes: [firth.governance, firth.governance.loop]
status: accepted
date: 2026-08-05
---
# Loop Autonomy

## Context

The loop was built for unattended one-unit sessions but retained two
maintainer dependencies. First, a decision-shaped blocker was parked as a
maintainer-blocked todo that the selector never auto-unblocks, and a blocked
obligation makes `LOOP EXHAUSTED` invalid, so a fully unattended run could
reach a state with no eligible unit and no valid terminal token. Second, the
installed cairn series (0.9.0) has an unreachable change-acceptance battery in
this repository: its cargo steps run from the repository root, which has no
manifest (the only crate is `src/runtime/vm`), and its strict-lint step is red
on the accepted warning baseline. Both were verified against a pristine
`origin/main` worktree and recorded in `.cairn/feedback.md` on 2026-08-05.
Operation is moving to unattended runs to project completion with no
maintainer in the loop, driven by the repository's own loop command; the
generic cairn pack's `/cairn-loop` never drives this repository.

## Decision

1. **Completion definition.** The project is complete when
   `python3 tools/loop/coverage.py` reports `loop_exhausted_valid: true`
   (every obligation in `tools/loop/obligations.toml` generated, unblocked,
   and discharged by done todos), the selector reports no eligible or open
   work, and the repository gates pass. `LOOP EXHAUSTED` with no MISSION is
   valid only in that state and means project completion; the coverage
   boolean is the sole authority, and no todo text, gap entry, or prose
   ever substitutes for it. The obligations matrix is the sole operational
   definition of the PRD scope bullets, requirements R1-R17, and success
   criteria S1-S7.

2. **Typed decision authority.** Decisions are tiered by what ratifies them:

   - **(a) Goal layer: immutable to the loop.** PRD goals, non-goals,
     scope, requirements, and success criteria (`files/firth-prd.md`
     sections 2 through 6), the scope of
     the obligations matrix (removing obligations or thinning
     `satisfied_by`), and the licensing posture are never amended by an
     autonomous iteration. The goal layer also never blocks work: if
     evidence says an entry is wrong, the iteration authors a decision left
     at `status: proposed` plus a cairn gap on the affected node for the
     record, and continues discharging the obligation as written under its
     most conservative reading. Only a maintainer-authored decision landed
     outside the loop may amend this layer.
   - **(b) Frozen specifications: evidence-ratified.** Amendments to frozen
     normative content (the kernel calculus per Firth policy iii, and any
     spec frozen later by the same pattern) require a superseding decision
     AND a green re-run of that spec's full binding gates in the same
     change. The mechanical re-verification is the ratifying authority; no
     prose approval substitutes for it.
   - **(c) Implementation layer: loop-accepted.** Every other design
     question, structural choice, or open gap is resolved by the iteration
     that hits it: author the research (`meta/research/`, `meta/sources/`
     as needed) and a decision artefact with `status: accepted` whose
     Context carries the line `Autonomous author: loop/<branch>`, choose
     the most conservative option that satisfies the PRD when alternatives
     are otherwise equivalent, and proceed under it. Such a decision exists
     only via the standard Land path, so it always carries the two-lens
     pre-submit review. The supersede rule is unchanged: an accepted
     decision binds later iterations until a superseding decision cites new
     evidence.

   Tier (c) deliberately diverges from the generic cairn pack's local-tier
   receipt protocol (subject-hash-bound lens receipts with a
   `ratified_by: machine` marker, per the pack's `cairn-loop-reconcile`).
   That protocol belongs to the generic `/cairn-loop` contract, which never
   drives this repository and whose skills are excluded from loop sessions.
   Nothing in this repository claims receipt-protocol compliance; should
   the generic pack ever become this repository's loop, a superseding
   decision must adopt its receipt protocol first.

3. **Maintainer-blocking is reserved for environment, authority, and
   external-evidence dependencies**: credentials, remote infrastructure,
   licensing posture, third-party outages, or evidence only an independent
   external actor can produce. The todo body must name the failing check
   or, for external evidence, carry a line beginning `External-evidence:`
   naming exactly what is outstanding. Any other maintainer-blocked todo is
   a defect of the iteration that parked it.

4. **Starved-selector rule: fail closed.** If selection finds no lint Error
   and no eligible todo, and coverage reports no `next_obligation`, but
   blocked obligations or blocked todos remain, the iteration touches
   nothing, classifies every slug in the selector's and coverage's sorted
   `blocked` lists (environment or authority blocker whose named check
   still reproduces: environment incident; todo carrying an
   `External-evidence:` line: legitimate external dependency; anything
   else: clause 3 defect left by a prior iteration), and outputs
   `LOOP HALTED` with that classification report. When every remaining
   blocker is external-evidence class and nothing else is incomplete, the
   report's first line is `implementation complete; external success
   criteria outstanding` followed by the outstanding evidence; the token is
   still `LOOP HALTED`, because `LOOP EXHAUSTED` belongs to the coverage
   boolean alone. No selection among blocked items exists:
   `select_unit.py` deliberately never surfaces a blocked todo as `next`,
   and this decision adds no prose selection rule beside that contract.

5. **Acceptance-gate substitution.** While the installed cairn's
   `change accept` battery is unreachable here (see Context), a change under
   `meta/changes/` is accepted when all its tasks are complete and the
   repository gates pass (control-plane tests, `cairn scan` with zero
   Errors, `cairn hook all` exit 0, plus the staged language gates); archive
   it with `cairn change apply` or `cairn change archive`. This clause is
   superseded the moment an installed cairn release makes the battery pass
   on a clean checkout.

6. **Anti-shortcut charter.** Never permitted, and no MISSION, review
   comment, or convenience overrides them:
   - amending the goal layer (clause 2a) from inside the loop, including
     weakening or descoping any PRD requirement or success criterion and
     shrinking the obligations matrix;
   - `sorry`, `admit`, or any axiom beyond the audited `propext` baseline;
   - weakening or deleting tests, fixtures, or gates; landing with a
     `cairn scan` Error; bypassing `cairn hook`;
   - discharging an external-actor criterion by proxy. Enabling work lands
     as its own todos, but the obligation's terminal todo stays blocked
     with an `External-evidence:` line until the named evidence exists,
     holding `loop_exhausted_valid` false. Worked classification: S6 (a
     third party reimplements the VM from the specification alone) is
     external-evidence class, because the loop cannot instantiate an
     independent party; S7 (a measured machine-authorship pass rate
     materially higher than a mainstream-language baseline) is not, because
     the loop can run the measurement, and an unfavourable result leaves
     the obligation incomplete rather than blocked. General rule: a
     criterion is external-evidence class iff its satisfaction requires an
     act by a party the loop cannot instantiate.

7. **Halts stay fail-closed.** Unclassifiable states still end in
   `LOOP HALTED`; autonomy never licenses heuristic recovery. Repeated
   identical halts are the operational signal that manual attention is
   required; that is an incident, not a decision.

## Rationale

The blocked-todo/invalid-exhaustion combination was the one state where the
loop had no defined outcome. Clauses 2 and 3 make it unreachable in normal
operation, because decision blockers are resolved by the iteration that hits
them and never parked, and clause 4 defines the outcome when it is reached
anyway: a typed halt whose report separates incidents and defects from the
one honest end state where only external evidence remains, a state that
genuinely requires a human to bring the evidence. Completion claims rest
solely on the coverage boolean, which external-evidence blockers hold
false, so no proxy, gap entry, or prose can ever surface a false project
completion. Typing the authority keeps `status: accepted` from becoming the
shortcut door: the goal cannot drift because the loop cannot touch it,
frozen specs cannot rot because only their own gates ratify amendments, and
implementation choices stay reversible by record. Tier (c) ratification
evidence is the firth loop's own contract, already exercised by every
landed unit: the two-lens pre-submit review on the landing path plus the
`Autonomous author` marker, which makes the autonomy audit a text search.
It is not claimed to satisfy the generic pack's receipt protocol. The
conservative-default rule biases ties toward options that preserve
guarantees. Clause 5 removes no protection this repository actually has:
the battery's cargo steps target a manifest that does not exist here and
its strict step fails on the accepted baseline, while every binding gate
the loop runs is retained.

Trade-off accepted: autonomous implementation decisions will sometimes be
worse than a maintainer's, and a run that finishes everything
machine-reachable while S6-class evidence is outstanding ends in a
`LOOP HALTED` carrying the qualified implementation-complete report rather
than a clean completion. Termination and honest reporting are bought with
that; the correction path is a superseding decision citing evidence, not
silent rework.

## Consequences

- `.claude/commands/firth-loop.md` is amended: the maintainer-decision
  parking rule is replaced by clauses 2-4, Firth policy gains the
  acceptance-gate substitution (vi), backlog generation gains the
  fail-closed starved-selector row with the qualified
  implementation-complete report, and `LOOP EXHAUSTED` is bound to
  `loop_exhausted_valid`.
- `docs/loop-runbook.md` states the cairn prerequisite as verified behaviour
  rather than a version pin, documents the omp launch with the generic-pack
  exclusion, and defines the terminal semantics of both tokens.
- No selector or coverage code changes: `select_unit.py` still never
  surfaces a blocked todo, external-evidence blockers hold
  `loop_exhausted_valid` false through the existing blocked
  classification, and clause 4 keeps starvation typed rather than adding a
  second selection rule beside the tool. A future governed unit MAY extend
  `coverage.py` and its tests to classify the external-only state
  machine-checkably and, via a superseding decision, promote that state
  from a qualified halt to a validated terminal form.
- Tier (c) decisions are grep-able via `Autonomous author:`;
  external-evidence blockers via `External-evidence:`.
- When a cairn release restores the acceptance battery, a superseding
  decision retires clause 5.
