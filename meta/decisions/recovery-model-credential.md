---
id: dec.recovery-model-credential
nodes: [firth.governance.loop]
status: accepted
related: [dec.halt-recovery]
date: 2026-08-08
---
# Recovery Delegate Credential Scope

## Context

dec.halt-recovery clause 1 says the advisor delegate holds "no
credentials: no git write access, no GitHub token, no push key". Read
literally, "no credentials" would also forbid the client token the
delegate's container needs to reach the harness auth broker for model
access, without which no delegate session can run at all. That decision
is accepted and is not edited in place.

## Decision

The credential prohibition in dec.halt-recovery clause 1 is scoped to
repository-facing authority: git write access, GitHub API tokens, SSH
deploy keys, and any secret that can mutate the repository or its
forge state. A model-only credential - the auth-broker client token,
mounted as a single file with nothing else from the secrets directory -
is permitted in the delegate's container. It grants LLM access through
the broker and no repository authority of any kind; the deploy
verification asserts the delegate container has no `/secrets`, no
`/work`, and no `/status` mount.

## Rationale

The delegate's function is judgement, which requires a model; the
threat dec.halt-recovery guards against is unaudited mutation, which
requires repository credentials. Scoping the prohibition to the second
preserves the decision's trust model exactly while making the delegate
implementable.
