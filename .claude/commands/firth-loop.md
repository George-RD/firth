---
name: "Firth Dev Loop"
description: Run one iteration of firth development, one unit landed as one squash commit, designed for unattended harness loop mode on the Codex CLI harness
category: Workflow
tags: [workflow, cairn, firth, codex]
---

Run ONE iteration of the Firth Dev Loop: a workflow that develops firth using
cairn governance. You are a fresh session inside a harness loop; the harness
re-injects this same message each iteration, so do exactly one unit of work,
land it as one commit on main, and end. Never select a second unit. This
file (plus the reading it names) is the sole normative orchestrator; anything
in `docs/` or `AGENTS.md` that overlaps is descriptive only, never normative.

**Required reading.** This harness (Codex) has no Skill tool: there is no
mechanism to "load" a skill by name. Instead, read the file at the exact
path below IN FULL before the step that needs it. A required file that is
missing or fails to read in full is LOOP HALTED: touch nothing, report which
file failed and why, and end. Never improvise a procedure that lives in one
of these files from memory or by guessing its contents.

| File | When | Declared tokens |
|---|---|---|
| `.claude/skills/firth-loop-recovery/SKILL.md` | Any preflight recovery row (dirty-tree recovery, open-PR recovery, interrupted cleanup, recover-todo branch, surviving-branch adopt/quarantine) | `RECOVERED`, `LOOP HALTED` (terminal tokens come from landing after a hand-off) |
| `.claude/skills/firth-loop-landing/SKILL.md` | Land (publish) and Cleanup (merge); also the open-PR recovery row after CI/review is green, and the quarantine hand-off | `ITERATION COMPLETE`, `LOOP HALTED` |
| `.claude/skills/cairn-propose/SKILL.md` | Substantial-work trigger before proposing a change | procedure-specific |
| `.claude/skills/cairn-apply/SKILL.md` | Substantial-work trigger while applying a change | procedure-specific |

**Input: MISSION.** The harness re-injects one fixed user message per
iteration. Any text in that message beyond the command itself binds MISSION.
It is identical every iteration; there is no per-iteration channel, so work
that must evolve across iterations belongs in the tracker, not in MISSION.
Precedence:

1. The preflight verdict always wins; MISSION never builds on unresolved
   state. (Deferring costs nothing: the next session receives the same
   MISSION.)
2. MISSION names a unit (todo slug, node id, finding code): select exactly
   that. A node id selects within the node deterministically: invoke
   `python3 tools/loop/select_unit.py --node <id>` for the todo branch; its first
   lint Error finding remains first, else use its top eligible open todo (see
   Select ONE unit). Already
   done, or blocked/quarantined: report why and output LOOP EXHAUSTED; the
   message is immutable, so no later iteration of this run can progress
   either.
3. MISSION is a scope filter (e.g. "toolchain only"): apply normal selection
   restricted to that scope. Nothing in scope: report it, output LOOP
   EXHAUSTED. Never select outside the scope.
4. MISSION describes new work: derive the slug canonically so every session
   computes the same one: lowercase the mission text, replace runs of
   non-alphanumerics with single hyphens, take the first 40 characters, then
   append `-` plus the first 6 hex chars of the SHA-256 of the exact raw
   MISSION string (before any canonicalisation), which makes cross-mission
   collisions vanishingly unlikely. If `todo.<slug>` already exists, do not
   re-create it; select it. Otherwise create the branch `loop/todo.<slug>`
   FIRST, then materialise the todo on it with `$CAIRN todo new <slug> --node
   <id>` (`$CAIRN`: the bound cairn binary, defined under Repo bindings
   below); split into sub-todos per the sizing rule if large, and select the
   first open one. Writing a todo while parked detached would strand the
   next session in the fail-closed row. Node id: resolution accepts exactly
   two forms, an exact node id from `cairn.blueprint` (dotted, e.g.
   `firth.language.kernel`), or a file path that falls under exactly one
   node's `path`. Nothing else resolves; never infer a node from meaning.
   Unresolved: report that the mission needs a node, list candidate nodes
   with a ready-to-paste corrected mission, and output LOOP EXHAUSTED. Node
   choice drives Scope, deps, and provenance for every later iteration, so a
   wrong anchor compounds silently. When adopting any surviving branch for a
   MISSION, confirm its slug maps to this MISSION's unit; a mismatched
   branch belongs to the table's generic surviving-branch row.
5. No MISSION: default selection.

**Isolation.** Work only in the persistent worktree `../firth-loop`. After the
preflight fetch, before creating it, require the source ref to contain the
blueprint:

```bash
if ! git cat-file -e origin/main:cairn.blueprint; then
  echo "push main first (git push -u origin main)"
  echo "LOOP HALTED"
  exit 1
fi
```

If this check fails, touch nothing else and halt. Create the worktree once if
absent: `git worktree add --detach ../firth-loop origin/main`; never remove it. Every branch you create is prefixed `loop/`. Never touch the main
checkout, non-loop branches, other sessions' dirty files, or PRs from
non-loop heads. Branch names are derived, never invented: `loop/todo.<slug>`
for a todo, `loop/<finding-code>.<node>` for a lint finding,
`loop/split.<slug>` for a decomposition, and `loop/backlog.<module-id>` for
backlog generation (the exact dotted Module id, lowercased as written in the
blueprint).

**Repo bindings.** One seam; everything else in this file is generic.
`$CAIRN` is a textual placeholder, not a live shell variable: substitute the
bound value when composing every command, and give every executable shell
block its own assignment line; nothing set in one tool call survives into
the next. Two bindings:
- `CAIRN` - the cairn binary. Firth consumes cairn as an installed tool (it
  does not develop cairn itself): `CAIRN="$(command -v cairn)"`, then
  `[ -x "$CAIRN" ]` (POSIX-portable; the -x test rules out alias and
  function resolution), then verify `"$CAIRN" --version` succeeds; absent or
  failing at any step: touch nothing, report, output LOOP HALTED.
- Language gates - staged on repo state, since the Lean project has not
  landed yet:
  - If `lakefile.toml` or `lakefile.lean` exists at the repo root: `lake
    build`, and `lake test` when a test driver is configured by a `test_driver` or
    `lean_test` stanza in either lakefile, or when repository CI config
    invokes `lake test`; plus `$CAIRN scan` (zero Errors) and `$CAIRN hook all` (exit 0).
  - Before the Lean project exists (no lakefile at repo root): cairn gates
    only, `$CAIRN scan` (zero Errors) and `$CAIRN hook all` (exit 0).
  - `$CAIRN scan` "zero Errors" is deliberately not "zero findings":
    `CAIRN_RECONCILE_LANGUAGE_UNKNOWN` warnings on the blueprint's
    declared-but-empty module paths (`src/*`, `spec/*`, `stdlib`, `specs`)
    are the expected baseline until those paths hold real source; a Warning
    never blocks, an Error always does.

**Firth policy.** Constitutional constraints this repo layers on top of the
generic loop; read before Scope and Implement, referenced by name below.

(i) Blueprint extension rule. New files must fall under an existing module
`path` in `cairn.blueprint`. If none fits, the unit itself extends the
blueprint: add the new `path` to an existing Module, or declare a new Module
under the right Container, AND cover every newly declared or reassigned node
in a decision artefact (`meta/decisions/<slug>.md`, its `nodes:` frontmatter
listing every touched node id) landed in the SAME commit as the blueprint
edit. `CAIRN_BLUEPRINT_CHANGE_NO_DECISION` (CA002) is an Error: a structural
blueprint change without a matching decision fails Verify, it is not a
formality to clean up later.

(ii) Decision discipline. Any structural choice or non-obvious tradeoff gets
a decision artefact under `meta/decisions/<slug>.md` (`id: dec.<slug>`,
slug-only filename, typed prefix only in the `id:` frontmatter). Set
`informed_by` to the relevant `research`/`sources` entries when they exist;
never fabricate provenance where none exists. Never contradict an accepted
decision silently: if new evidence changes a prior call, author a new
decision that explicitly supersedes it (reference the superseded decision's
id in the new one) rather than editing the old decision's conclusion in
place.

(iii) Spec-freeze constitutional rule. Once `todo.kernel-spec-freeze` carries
`status: done`, the kernel calculus is normative. Any further change to
`spec/kernel` or `files/firth-kernel-spec-draft.md` is a constitutional
amendment, not routine editing: it requires a decision artefact that
supersedes the freeze decision (or the specific prior decision it revises)
AND re-running the Lean metatheory gates for the frozen calculus before the
change lands. A silent edit to a frozen kernel file without that decision is
never permitted, regardless of how small it looks; treat discovering the
need for one as a Scope violation, stop before touching the file, and follow
the reroute-never-expand rule below.

(v) Edge semantics and architecture helpers. Cairn blueprint edges are
depends-on edges: `A -> B` means A depends on B. `$CAIRN order`,
`$CAIRN frontier`, and `$CAIRN next` operate on module-level architecture
edges and are context helpers only; they NEVER select the unit. The selection
table below, lint errors first and then eligible todos by slug, is the sole
selector.

(iv) Artefact conventions. `meta/decisions/`, `meta/research/`, and
`meta/sources/` are FLAT (no subfolders); filenames are slug-only
(`<slug>.md`), the typed prefix (`dec.`/`res.`/`src.`) lives only in the
`id:` frontmatter field, namespaced by slug (`res.gas-city.analysis` gives
`gas-city.analysis.md`). Todos are the one exception:
`meta/todos/todo.<slug>.md`, scaffolded with `$CAIRN todo new <slug> --node
<id>`. British spelling throughout (artefact, colour, neighbourhood,
reconcile); no em-dashes in any user-facing copy this loop writes.

**Setup.** Runs AFTER the preflight verdict and before the first `$CAIRN`
command (preflight needs only git and gh; on a fail-closed verdict nothing
is touched at all). If the verdict adopted a surviving `loop/*` branch,
check it out NOW (`git checkout loop/<slug>`; clean tree, pure ref move) so
Scope and everything after run against the recovered state, not
origin/main. Then resolve the `CAIRN` binding per Repo bindings above
(`command -v cairn`, the `-x` test, then `--version`); failing at any step:
touch nothing, report, output LOOP HALTED.

**Preflight: observe read-only, then act on the FIRST matching row.**
No checkout, stash, clean, add, or commit during observation. Recovery
procedures live in `.claude/skills/firth-loop-recovery/SKILL.md`; the table
classifies and points. Fail-closed backstops stay here and never move.

```bash
git fetch origin main
git status --porcelain                                    # dirty?
git branch --show-current                                 # branch, or empty = detached
git for-each-ref 'refs/heads/loop/*' --format='%(refname:short) %(objectname)'
gh pr list --state open --json number,headRefName \
  --jq '.[] | select(.headRefName | startswith("loop/"))' # open loop PRs only
```

| State | Action |
|---|---|
| Dirty tree, on a `loop/*` branch whose slug maps to a known unit (todo or finding) | Finishing that unit IS this iteration. Read `firth-loop-recovery` §1 (recover in place). No checkout of any kind until the tree is clean. On `RECOVERED`, continue at Verify. |
| Dirty tree, anything else (detached, unknown branch, unexplained files, intent unclear) | FAIL CLOSED. Touch nothing: no stage, stash, clean, commit, checkout, and no file writes either, the dirty tree is evidence. Report the state (`git status --short`, branch/HEAD, why unclassifiable) and output LOOP HALTED. Next sessions land in this row and re-report until the maintainer resolves it; that repeating halt IS the durable signal. |
| Clean; exactly ONE open `loop/*` PR exists | Recovery unit. Read `firth-loop-recovery` §2, then `firth-loop-landing` at Cleanup. On `ITERATION COMPLETE` from landing, end. |
| Clean; MORE than one open `loop/*` PR | FAIL CLOSED. A prior run violated one-PR-per-iteration and the right merge order is a judgment call. Report all of them, output LOOP HALTED. |
| Clean; a `loop/*` branch whose tip matches a MERGED PR's headRefOid (`gh pr list --state merged --head <branch> --json headRefOid,mergedAt`) | Interrupted cleanup, not work. Read `firth-loop-recovery` §3. Preflight deletes branches ONLY here and in the discard-note case (§4). On `RECOVERED`, continue preflight. |
| Clean; a `loop/*` branch covered by an existing `todo.recover-<slug>` on main | Read `firth-loop-recovery` §4 (status-branched: discard-authorised cleanup, ambiguous, or quarantined). Never delete or commit to a quarantined branch; if the worktree has it checked out, park off it (clean tree, pure ref move). On `RECOVERED`, continue preflight as if the branch were absent. |
| Clean; any other surviving `loop/*` branch (closed PR, no PR, or tip differs from merged PR) | Read `firth-loop-recovery` §5. Adopt (open todo/finding → `RECOVERED`, continue at Scope) or quarantine (author `todo.recover-<slug>`, hand off to `firth-loop-landing`; landing emits the terminal token). A local branch ref is the only thing keeping those commits alive: never delete without a MERGED PR at the same tip or an explicit maintainer discard note in the todo. |
| Clean, parked detached, no unquarantined `loop/*` branches or PRs | Select fresh work (below). |

**Select ONE unit** (after MISSION precedence): the first lint Error from `$CAIRN lint --json`; sort Errors by file path,
line, then code. If there is no lint Error, run
`python3 tools/loop/select_unit.py` from the repository root and parse its
JSON output. This tool is authoritative for the todo branch of selection; do
not re-derive Requires eligibility from prose. Tool exit 2, a non-zero exit,
unparseable output, a missing schema value, or an output that violates the
selector contract is FAIL CLOSED: report it and output LOOP HALTED. Never
fall back to `$CAIRN status`, `$CAIRN todos`, or hand parsing.

The tool's rule is deterministic: an `in_progress` todo is surfaced first as
`next`, because a fresh session must finish it rather than start new work.
Otherwise `next` is the first eligible open slug sorted lexicographically.
Eligible means status open and every Requires slug done. The JSON also lists
`ineligible_open` with sorted missing slugs, plus sorted `blocked` and
`in_progress` lists. A blocked todo with no Requires line is
maintainer-blocked and is never auto-unblocked; a blocked todo with
"blocked on sub-todos: <ids>" follows the split rule. The tool validates
unknown slugs, cycles, filename/slug mismatches, duplicate slugs, and invalid
status before selection. The tool's stable ordering is the contract.

If no lint Error and the tool reports no eligible next unit, run
`python3 tools/loop/coverage.py` and continue to **Backlog generation** below
before permitting LOOP EXHAUSTED. Architecture helpers such as `$CAIRN order`,
`$CAIRN frontier`, and `$CAIRN next` operate on module-level depends-on edges
and never select the unit.


Sizing rule: the unit must fit one small reviewable PR. Too big: this
iteration IS the decomposition. Create the branch `loop/split.<slug>` first,
then on it create sub-todos with `$CAIRN todo new` and set the parent to
`blocked` with body line "blocked on sub-todos: <ids>" (the iteration
completing the last child flips the parent to `done`), and land that
decomposition as this iteration's single commit.

Artefact rule: every todo or `meta/` artefact this loop creates is written
ON the unit's `loop/*` branch (never while parked detached) and reaches main
only through the Land path, inside the iteration's single commit. If a state
forbids landing (the fail-closed row), it also forbids writing: report
instead. Nothing is ever left uncommitted in the loop worktree.

**Scope.** For the unit's node: `$CAIRN neighbourhood <node> --include-todos
--include-changes`, `$CAIRN rationale <node>`, `$CAIRN deps <node> --direction
in --transitive`. Respect accepted decisions. Write one verifiable success
criterion. If the unit would touch `spec/kernel` or
`files/firth-kernel-spec-draft.md` after the freeze todo is done, apply
Firth policy §iii before doing anything else. Scope may reroute, never
expand: if orientation reveals a prerequisite that must land first
(including "the spec-freeze decision this touch requires does not yet
exist"), stop before touching code; author the prerequisite todo, set this
unit's todo `blocked` on it (the body names the prerequisite todo slug,
`todo.<slug>`, and node id where relevant), land those tracker edits as this
iteration's single commit, and end. The prerequisite is then an open todo,
eligible for normal selection while the blocked unit is skipped; selection
order is unchanged.

**Implement + test.** The unit's branch is `loop/<tail>` where `<tail>` is
the derived form from Isolation (`todo.<slug>`, `<finding-code>.<node>`, or
`split.<slug>`, or `backlog.<module-id>`); every later step (push, PR, Cleanup) uses this exact name.
If it is already checked out, adopted at verdict time or created earlier
this session during MISSION materialisation or decomposition, continue on
it. Otherwise create it, always from fresh origin/main:
`git checkout --detach origin/main && git checkout -b loop/<tail>`. (If the
derived name exists but was NOT adopted by the verdict and NOT created this
session, you missed a preflight row; go back, the table owns it.) Make the
smallest change satisfying the criterion. New files: apply Firth policy §i
(blueprint extension rule); new cross-module calls get a blueprint edge.
Changed behaviour gets a test once a test harness exists (`lake test` per
the staged gates); in the spec-only phase, "changed behaviour" mostly means
a spec or decision revision, which is proven by the metatheory/differential
gates once they exist, not a unit test today. For a bug fix once code
exists, write the test first, red then green. Substantial work goes through
`.claude/skills/cairn-propose/SKILL.md` and
`.claude/skills/cairn-apply/SKILL.md`, read in full under Required reading.

**Verify: the gate.** Run `python3 tools/loop/test_select_unit.py`,
`python3 tools/loop/test_coverage.py`, then `python3 tools/loop/select_unit.py
--validate` and `python3 tools/loop/coverage.py --validate`; a non-zero exit or malformed
JSON is a gate failure. Then run the staged
language gates from Repo bindings: if `lakefile.toml`/`lakefile.lean` exists
at the repo root, `lake build` (and `lake test` when the same lakefile-or-CI
test-driver rule is configured); before the Lean project exists, skip straight
to the remaining cairn gates. Always: `$CAIRN scan` (zero Errors;
`CAIRN_RECONCILE_LANGUAGE_UNKNOWN` warnings on declared-but-empty paths are
expected and non-blocking) and `$CAIRN hook all` (exit 0). Fix the cause of
any failure. Never bypass hooks.

When the VM fixture corpus exists, run
`tools/loop/check_kernel_fixtures.sh` after the Lean gate. It must compare the
committed corpus byte-for-byte with `lake exe firthVmFixtures` output.

**Record.** If structure changed or a non-obvious tradeoff was made, write a
decision artefact in `meta/decisions/` per Firth policy §ii. If the
blueprint's shape changed, the decision is not optional: §i makes it a Verify
failure (`CAIRN_BLUEPRINT_CHANGE_NO_DECISION`) to skip it.

**Backlog generation.** The obligations matrix is the coverage authority. This
section runs when there is no lint Error and no eligible todo, before
`LOOP EXHAUSTED` is allowed. Run `python3 tools/loop/coverage.py`; it validates
`tools/loop/obligations.toml` and reports stable obligation classifications.
When `next_obligation` is non-null, this iteration IS backlog generation: choose
that first ungenerated obligation, create `loop/backlog.<module-id>` first,
author todos for the obligation's node, and update that obligation's
`satisfied_by` list in `obligations.toml` in the same commit. Use the existing
Goal, Acceptance, Traceability, and Requires format, and keep the todo set
small enough for one reviewable PR. Dependency gating uses the blueprint's
depends-on edges: a candidate node is ready only when each dependency node is
complete or in-flight in the matrix. Keep the matrix current whenever the loop
authors a todo. Only when no ungenerated obligation remains and all todos are
done is `LOOP EXHAUSTED` valid. An obligation classified `blocked` is neither
complete nor ungenerated and also prevents exhaustion.

**Cairn gaps.** An unresolved design question discovered during a unit that
does not block its success criterion is registered with
`$CAIRN gap <node> --question "..."` so it remains graph-visible, rather
than left as a prose marker. A question that blocks the unit follows the
scope reroute rule and becomes a prerequisite todo.

**Done and decision pairing.** When a todo delivers a spec revision or design
note that changes normative content, it is done only when the artefact lands
and a companion decision artefact with `status: accepted` covers it.
`accepted` is decision vocabulary, never a todo status.

**Land + Cleanup.** Read `.claude/skills/firth-loop-landing/SKILL.md` in
full. It owns: stage explicit paths (no `git add -A` / `git add .`), tracker
completion for todo units (`$CAIRN todo set <slug> done`), leaving
backlog-generated todos open and making no todo change for lint units, one
logical commit, push, one PR,
the two-lens pre-submit review, and the fail-closed squash-merge with
re-verification (the Cleanup script). Always pass `slug` and `CAIRN`. On the
normal Land path do **not** pass `pr`: the file's procedure creates the PR
and binds `pr` itself before Cleanup. On the open-PR recovery row, pass the
existing `pr` and enter the procedure at Cleanup (the diff is already
published). It returns exactly one of its declared tokens; pass it through
as this iteration's final line. If the file fails to read in full, output
LOOP HALTED.

**End.** Summarize: the unit, success criterion, nodes touched, test added,
final scan finding count, PR and merge status. Output exactly one token
(from this file's fail-closed rows, from selection exhaustion, or from a
required file's declared tokens):

- ITERATION COMPLETE: unit landed, or safely deferred with a blocked todo.
- LOOP EXHAUSTED: no eligible todo exists and Backlog generation found no
  uncovered-ready Module, or the immutable MISSION can never progress in this
  run (named unit done or blocked, scope empty).
- LOOP HALTED: fail-closed state needs the maintainer; do not continue.

The token is the FINAL line of output, alone, verbatim; the summary comes
before it. Tooling and the maintainer read loop health from that line.

If blocked on a decision only the maintainer can make: author the researched
recommendation as a `meta/` artefact plus a blocked todo, land them through
the Land path (`firth-loop-landing`) as this iteration's single commit,
report, output ITERATION COMPLETE. Never wait for an answer mid-loop.

**Guardrails.**

- Zero `cairn scan` Errors is the target state (Warnings for
  declared-but-empty language targets are the expected baseline
  pre-implementation); an Error blocks the iteration, it is not a
  formality.
- Behaviour without a test is not done, once a test harness exists; in the
  spec-only phase this maps to the metatheory/differential gates, not a
  fabricated unit test.
- New files that don't fall under an existing module path get a Module or
  path edge in `cairn.blueprint` AND a decision artefact in the same commit
  (Firth policy §i); `CAIRN_BLUEPRINT_CHANGE_NO_DECISION` is an Error.
- Changes to `spec/kernel` or `files/firth-kernel-spec-draft.md` after
  `todo.kernel-spec-freeze` is done require a superseding decision and a
  re-run of the metatheory gates (Firth policy §iii); never a silent edit.
- Never contradict an accepted decision without writing a superseding one.
- One iteration, one unit, one squash commit on main. A growing PR means
  stop and split.
- Branch deletion requires merged evidence: a MERGED PR at the same tip, or
  an explicit maintainer discard note. Nothing else, nowhere else.
- Fail closed: any state you cannot classify is preserved untouched and
  reported, never staged, cleaned, pushed, or "fixed" by heuristic.
- A required file that cannot be read in full is LOOP HALTED, never a free
  hand to improvise the procedure it would have named.
