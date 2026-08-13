# Proposal: resolver-skill-registry

## Motivation

The autonomous loop currently creates its unit branch inside the model session
and spreads halted-recovery authority across prompt instructions, an
in-container executor, a host healer, and several JSONL ledgers. A model can
therefore write before branch identity is deterministically established, and
the recovery plane has no single transactional record that can distinguish an
intent, an effect, a reconciled consequence, and project completion.

The operator control plane is being rebuilt around issuer-bound, single-effect
tickets and least-privileged adapters. Firth must first publish the dormant
authority contract that this control plane is allowed to enforce. The existing
landing and healer paths remain active until explicit one-way cutover markers
are installed.

## Outcome

Firth exposes a deterministic preflight and iteration-preparation contract in
which the unit branch, linked worktree, and lease are prepared before OMP
starts. A terminal no-argument finaliser seals only that prepared unit.
Recovery inside OMP is validation-only. Installed policy, external exact-object
review receipts, and the selected todo's sanctioned final state gate later
publication and merge.

The authority decision defines separate normal, halted-recovery, and local
operator ticket namespaces. It preserves the existing review, autonomy, model
credential, and completion decisions. Nothing added by this change can emit,
infer, or proxy `LOOP EXHAUSTED`.

## Acceptance boundary

The boundary is the Firth loop command and its deterministic helpers when run
against fixture repositories and prepared envelopes. A model session must be
unlaunchable before branch/worktree/lease preparation, unable to mutate Git
metadata, and terminal after `firth_finalize`. Recovery must refuse every
mutation. Landing must reject missing or stale policy, review, finaliser, and
selected-todo evidence.

## Evidence

- `test_preflight_state.py` covers every closed verdict, precedence, complete
  forge pagination, observation failures, and byte-for-byte non-mutation.
- `test_prepare_iteration.py` proves ordered state-issued mirror, branch,
  worktree, and lease transitions before launch, plus the stop, ACL, lease, and
  stable-snapshot finalisation chain.
- The driver, review, and TCB boundary suites prove exact-object receipts,
  policy-digest binding, terminal-token separation, and exclusive completion
  authority.
- The repository's full Python, Lean, Rust, Cairn scan, and Cairn hook gates
  pass from the fresh change checkout.

## Scope

- The accepted resolver authority decision and dormant cutover contract.
- Pure preflight classification and deterministic iteration preparation.
- Prepared-envelope, finaliser, recovery, landing, policy-projection, and
  selected-todo final-state contracts.
- Runbook and recovery-mandate updates.

## Out of scope

- Activating the normal finaliser before the scoped operator services pass
  their own release gates.
- Activating halted recovery or disabling the healer. That requires the later
  authenticated `activate-recovery` transaction.
- Installing services, credentials, GitHub Apps, rulesets, or root policy.
- Changing the Firth language, its MVP profile, obligations, or the exclusive
  `coverage.py --run-gates` completion authority.
