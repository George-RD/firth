---
id: dec.halt-recovery
nodes: [firth.governance.loop]
status: accepted
related: [dec.loop-autonomy, dec.loop-driver-contract, dec.driver-token-tail]
date: 2026-08-08
---
# Bounded Halt Recovery: Advisor Delegate, Deterministic Executor

## Context

dec.loop-autonomy holds halts fail-closed: `LOOP HALTED` stops the run,
and the launch contract left every exit code other than a
machine-verified quota rc 3 as a human decision. Two production halts on
2026-08-08 showed the cost: one spurious (a test suite clobbering the
live driver's log), one real but mechanically resolvable (a stale
`loop/*` ref from an interrupted run rejecting a non-fast-forward push).
Both sat down waiting for an operator while the loop's own sanctioned
recovery procedures could classify the state on the next run. The
project's intent is unattended operation to completion; the maintainer
directed that halts be recoverable without widening what any
probabilistic agent is trusted to do. This decision is
maintainer-authored, landed outside the loop, and supersedes in part the
launch contract's "every other exit code is a human decision" clause.
dec.loop-autonomy clause 7's core is retained: heuristic recovery is
still never licensed, and repeated identical halts still stay down. The
recovery skill's branch guardrail is retained verbatim: no surviving
branch is deleted without a merged PR at the same tip or an explicit
maintainer discard note.

## Decision

1. **Two roles, strictly split.** Recovery is performed by a
   probabilistic **advisor delegate** and a deterministic **executor**.
   The delegate is a fresh harness session on a different model family
   from the authoring loop (Sol by default), given read-only evidence
   and no credentials: no git write access, no GitHub token, no push
   key. It reasons freely under guidelines and emits a typed proposal.
   The executor is a non-AI script that validates each proposed action
   against machine-checked preconditions and performs only allowlisted
   mutations. Nothing the delegate says can cause a mutation the
   executor cannot independently verify as safe.

2. **Trigger and evidence.** On driver exit rc 2 (`LOOP HALTED`), the
   launcher assembles an evidence bundle: the driver's terminal report,
   the last iteration log tail, `git status` of the loop worktree, local
   and remote tips of the current `loop/*` branch, open `loop/*` pull
   requests, and origin/main's tip. The delegate receives the bundle,
   the mandate at `docs/loop-recovery-mandate.md` (read from the landed
   checkout), and the full record of prior interventions.

3. **Incident signature.** sha256 over stable facts only: rc, current
   branch name, local tip sha, remote tip sha of that branch (or
   "absent"), and the sorted set of open `loop/*` PR head shas. Report
   prose, timestamps, and session identifiers are excluded so retries
   cannot mint fresh signatures for the same incident.

4. **Executor allowlist.** The primary recovery instrument is the loop
   itself: its preflight already classifies orphaned branches, open loop
   PRs, and interrupted cleanup under the recovery skill, with
   provenance. The executor therefore implements only:
   - `delete-remote-loop-ref <branch>`: ref matches `refs/heads/loop/*`,
     and either a MERGED pull request's head sha equals the remote tip,
     or the tip is an ancestor of origin/main. This is the recovery
     skill's own deletion guardrail, machine-checked; no weaker evidence
     (todo status, tree similarity, quarantine-first) authorises
     deletion. Tips failing it are left untouched for the loop or a
     human.
   - `push-loop-branch <branch>`: pushes `refs/heads/loop/*` from the
     registered worktree without force; the server rejects any
     non-fast-forward, so this can create or advance a loop ref, never
     rewrite one. Never `main`.
   - `relaunch`: granted only when the ledger entry is durably written,
     per-signature attempts are within bound, and origin/main's
     pre-intervention mark is an ancestor of its current tip (no history
     rewrite happened during the intervention). Unclassifiable-to-the-
     delegate but classifiable-to-preflight states (orphan adoption,
     quarantine, PR recovery) are recovered by relaunching into the
     loop's own governed procedures, not by novel launcher mutations.
   - `escalate <reason>`: stay down; always safe, and the default for
     any malformed, unparseable, or out-of-allowlist proposal.
   Force-push, merge, reset, deletion without the guardrail evidence,
   and every mutation outside this list are structurally unavailable:
   the delegate holds no credentials and the executor implements
   nothing else.

5. **Bounds.** At most 2 interventions per signature; a third identical
   halt stays down (dec.loop-autonomy clause 7's "repeated identical
   halts" rule, now machine-enforced). At most 2 consecutive
   interventions without origin/main advancing, regardless of signature.
   Quota handling for rc 3 is unchanged; every other exit code remains a
   human decision.

6. **Ledger.** Every intervention appends one record to the launcher's
   `interventions.jsonl` before any relaunch: timestamp, signature,
   evidence bundle, prompt hash, model, the delegate's full output, the
   parsed proposal, each executed action with its precondition evidence
   and result, the verdict, and origin/main before and after. The status
   dashboard renders the ledger. The record is the audit trail that
   makes every intervention reviewable after the fact.

## Rationale

The delegate/executor split keeps the trust model of dec.loop-autonomy
intact: probabilistic judgement classifies and proposes under
guidelines rather than a rigid decision tree, but every mutation is
gated by a deterministic check that would hold even if the delegate
were adversarial. Keeping the allowlist to the recovery skill's own
guardrail evidence means the launcher never holds a power the loop's
procedures do not already sanction; the delegate's real leverage is the
relaunch verdict, which hands ambiguous states to the governed preflight
instead of resolving them ad hoc. Signatures over stable facts make the
retry bound meaningful across relaunches.

## Consequences

- The launch contract in `docs/loop-runbook.md` names this decision and
  the second automated operator action it licenses.
- The delegate's mandate lives at `docs/loop-recovery-mandate.md`,
  goal-layer governed like the rest of the launch contract.
- The launcher implementation and its tests live in the maintainer's
  infrastructure repository beside the supervisor; the harness treats a
  recovery session like any other session (transcripts retained).
- An intervention that lands repository changes is still subject to the
  loop's own gates on the next run; the executor never touches `main`.
