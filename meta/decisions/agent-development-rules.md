---
id: dec.agent-development-rules
nodes: [firth.governance]
status: accepted
related: [dec.loop-freeze, dec.review-mandatory, dec.usable-language-milestones, dec.kernel-indexed-shuffles]
date: 2026-09-28
---
# Rules for agents developing Firth

## Context

The maintainer wants Firth to be developed and refined by AI agents until it
is complete, with written rules that let agents keep going without the
shortcuts earlier runs took. The assessment of `main` at c6b1a19 (27 September
2026, `dec.loop-freeze`) found these:

- milestones were recorded as met while `prim +` was the only executable
  primitive;
- S5 was "discharged" by a program that adds 1, 2 and 1, after its goal was
  read downward;
- about 21,000 lines went into loop and gate tooling against about 2,000 for
  the compiler;
- tests could not fail: differential checks were built from the same source
  as the thing they checked, and refusals were counted as passes;
- agreement between the VM and the reference interpreter was treated as
  correctness, although it cannot catch a bug they share, such as one in
  erasure.

On 28 September 2026 the maintainer added a principle for choosing between
approaches: take the one that is harder now when the easier one would cause
pain later.

## Decision

1. The rules live in one place, the "Rules for agents" section at the top of
   `AGENTS.md`. `CLAUDE.md` imports that file so every agent tool reads the
   same text. There is no separate rules document and no tooling that
   enforces them: each rule names what a reviewer checks, and the independent
   review of each PR is where they are enforced.
2. The rules cover what done means (the roadmap's "Goal status", never
   narrowed; see point 4 for who moves a goal), how to choose an approach
   (harder now beats painful later; language before machinery; report gaps
   instead of working around them; the kernel is frozen), evidence (claims
   name evidence; a new check comes with a planted bug it rejects; tests use
   independently written expected results; proofs have no escape hatches;
   the VM and the reference interpreter agree) and changes (one coherent
   change per PR; approval of the exact head; defects become todos, not
   comments; one owner per area at a time).
3. The cairn change workflow (`meta/changes/`) is optional. It was part of the
   process machinery that the freeze retired from the default path.
4. Amended later on 28 September 2026 at the maintainer's request ("I would
   like to not be the constraint as much as possible"): agents may change a
   goal's status without the maintainer. The change goes in a PR that names
   the evidence and touches only the goal's status cell, the gap text in its
   row and the gap todos. The independent reviewer approves it only
   if the evidence meets the goal as written in the PRD and the roadmap row,
   with no narrowed reading, and every remaining gap is stated in the row and
   filed as a todo. The maintainer can reverse any status change. Earlier
   runs failed by redefining goals downward, not by marking them without
   permission, so the guard is the unchanged goal wording plus a review that
   sees nothing but the claim and its evidence.
5. Amended on 29 September 2026. The maintainer approved four wording
   additions, drawn from Anthropic's published prompting guidance for its
   Claude 5 models ("Go with recomendation", project thread, 09:32 UTC):
   - rule 8: check each progress claim against a tool result from the same
     session, and say what was not run;
   - rule 10: tests check correctness, they do not define the solution;
   - rule 13: say so when an ask looks wrong, rather than quietly narrowing
     or widening it;
   - rule 14: the reviewer flags only what affects correctness, the
     requirements or a rule.
   The same approval covered trimming `AGENTS.md` to what an agent cannot
   derive from the repository, following Anthropic's guidance to keep a
   `CLAUDE.md` under 200 lines. Rule 11's check was shortened without
   changing what it requires.

## Consequences

- A rule is added only when a real shortcut shows it is needed, and it must
  say how a reviewer checks it. Rules that cannot be checked are not added.
- Examples of choices made under the "harder now" principle on 28 September
  2026: `pick n` and `roll n` entered the kernel
  (`dec.kernel-indexed-shuffles`, #125) rather than leaving every program to
  hand-written stack shuffles, and
  S5 is proved in Lean over the reference interpreter
  (`dec.s5-proof-standard`) rather than resting on tests.
- Honest limit: review is done by agents too. The rules make shortcuts
  visible and checkable; they do not make them impossible.
