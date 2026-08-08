---
id: dec.mvp-completion
nodes: [firth.governance, firth.governance.loop]
status: accepted
related: [dec.loop-autonomy]
date: 2026-08-08
---
# MVP Completion Profile

## Context

dec.loop-autonomy clause 1 defined project completion as the whole
obligations matrix discharged: every PRD section-4 scope bullet, R1-R17,
and S1-S7. That definition drives an unattended run through work that lies
beyond the maintainer's stated endpoint for this phase: a working Firth
language that an AI, given the language guide and the agent interface, can
use to build basic applications. Under the full-matrix definition the loop
would continue through editor tooling (LSP), dictionary signature search,
a sustained fuzzing campaign, stdlib self-hosting, and a measured
machine-authorship study, and could never emit `LOOP EXHAUSTED` at all
while S6 awaits evidence only a third party can produce.

Maintainer instruction, 2026-08-08: the loop needs a deterministic stop at
that endpoint. This decision is maintainer-authored and landed outside the
loop, as clause 2a requires for goal-layer changes.

## Decision

1. **Completion profiles.** `tools/loop/obligations.toml` gains a
   `[completion]` table naming the active profile (`mvp` or `full`) and a
   per-row `milestone` key (`mvp`, the default, or `post-mvp`).
   `coverage.py` computes `loop_exhausted_valid`, `next_obligation`,
   `first_incomplete`, and its classification lists over the active
   profile's rows only, and reports the excluded rows as
   `outside_profile`. This supersedes dec.loop-autonomy in exactly two
   respects, with that decision's text left untouched per the supersede
   rule: clause 1's "every obligation" now means "every obligation in the
   active completion profile", and clause 6's external-evidence rule is
   scoped by the same profile: an external-actor criterion holds
   `loop_exhausted_valid` false only while its obligation is inside the
   active profile. Exclusion is not proxy discharge: an excluded row stays
   undischarged and visible under `outside_profile`, so S6's worked
   classification binds under `full` and is simply out of horizon under
   `mvp`. The coverage boolean remains the sole completion authority, and
   clauses 2-5 and 7 bind unchanged.

2. **The MVP boundary.** Post-mvp rows, and why each is outside the
   endpoint rather than inside it:
   - `scope-toolchain-signature-search`, `req-r16`: dictionary search by
     stack effect is authoring ergonomics; the MVP guide and structured
     diagnostics carry the agent-usability load.
   - `scope-ecosystem-lsp`: editor tooling for humans.
   - `sc-s2`: the differential harness itself stays MVP
     (`scope-toolchain-diffharness`); the sustained large-scale fuzzing
     campaign is post-mvp evidence.
   - `sc-s3`: the verified-patch machinery stays MVP (`scope-runtime-patch`,
     `req-r6`, `req-r7` are untagged), because `rust-vm-implementation`
     structurally requires `rust-vm-patch-protocol`; only the end-to-end
     live-demo criterion is post-mvp.
   - `sc-s4`: a standard library usable from Firth stays MVP
     (`scope-ecosystem-stdlib`); self-hosting with a verified subset is
     post-mvp.
   - `sc-s6`: external-evidence class by dec.loop-autonomy clause 6; a
     third party cannot be instantiated by the loop.
   - `sc-s7`: the measured pass-rate study is post-mvp; its MVP reading is
     `mvp-agent-authoring` below.
   Everything untagged is MVP, including the whole kernel, type system,
   elaborator, interpreter, compiler, SMT/refinement chain, VM, image
   model, and patch protocol.

3. **Selection respects the profile.** A todo whose every matrix reference
   is post-mvp is roadmap: `select_unit.py` never selects it and reports it
   under `outside_profile`. A live todo inside the profile that `Requires:`
   such a todo is a validation error, fail closed, so an active unit can
   never be starved by an inactive prerequisite. Unmapped todos are never
   filtered and still gate exhaustion: the loop finishes what it opened.

4. **MVP acceptance gate.** The new `mvp-agent-authoring` obligation
   (node `firth.toolchain.agent`) is discharged only when all of the
   following exist on `main` and pass as a repeatable executable gate:
   - an agent-facing language guide (the instructions an AI needs to write
     Firth: surface syntax, stack effects, refinements, the diagnostic
     loop, and worked examples), kept under the blueprint's documentation
     paths;
   - at least three basic example applications authored by a code model
     given only the guide and the agent interface, each of which
     elaborates, type/linearity-checks, compiles, and runs on the VM with
     compiler/interpreter agreement;
   - a gate script or test target that rebuilds and re-runs those apps so
     the criterion is re-checkable by machine, wired into the loop's
     verification gates.
   Backlog generation authors the todos for this row like any other; the
   row's discharge is the loop's own `LOOP EXHAUSTED` precondition.

5. **Authority.** Milestone tags, the active profile, and this boundary are
   goal layer under dec.loop-autonomy clause 2a: never amended by an
   autonomous iteration. Moving to the `full` profile later is one
   maintainer-authored line, and the post-mvp rows are already staged for
   it.

## Rationale

The endpoint is now a machine-checkable predicate the loop itself
evaluates, so the run terminates by token rather than by a human watching
a dashboard. Scoping generation and selection, not just the boolean, is
what makes the stop real: coverage alone would still leave the selector
feeding post-mvp todos to iterations. Keeping unmapped todos in the
exhaustion gate preserves the existing conservative invariant. The S3
split follows the dependency evidence rather than taste: the patch
machinery is load-bearing for the MVP VM, the public demo is not.

Trade-off accepted: `LOOP EXHAUSTED` no longer means the PRD is fully
discharged; it means the MVP profile is. The full horizon stays visible in
the matrix (`outside_profile` in every coverage report) and the dashboard,
so the narrowing is explicit, reversible, and never silent.

## Consequences

- `tools/loop/obligations.toml`: `[completion] profile = "mvp"`, eight
  post-mvp tags, one new MVP acceptance row.
- `tools/loop/coverage.py` and `tools/loop/select_unit.py`: profile-aware,
  with boundary tests in both suites.
- `meta/decisions/loop-autonomy.md` is left byte-untouched and stays
  `status: accepted`: it binds in full except for the two respects named
  in clause 1. The frontmatter relation is `related`, not `supersedes`,
  because cairn's `supersedes` asserts the target is retired
  (`CAIRN_DECISION_SUPERSEDES_STATUS` enforces the status flip), and
  retiring dec.loop-autonomy would be false.
- `.claude/commands/firth-loop.md`, `docs/loop-runbook.md`, and `AGENTS.md`
  state completion against the active profile.
