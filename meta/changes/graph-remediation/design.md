# Design: graph-remediation

## Approach

Use Cairn's actual edge direction, `A -> B` means A depends on B, as the prerequisite graph. Keep unresolved design questions visible as proposed gap decisions and keep host-language defaults proposed until researched and ratified.

## Changes

1. Reversed and re-audited blueprint edges, added the accepted `dec.blueprint-edge-semantics` decision, and corrected the explanatory comment.
2. Added machine-readable `Requires:` lines to all todos, flipped prerequisite-only blocked todos to open, and corrected component-boundary completion wording.
3. Added `patch-compat-prior-art`, `diffharness-fuzz-strategy`, and `host-language-decision` todos.
4. Extended `kernel-spec-freeze` for G3, K1-K5, and D3 holes.
5. Recorded Lean v4.32.0 as a candidate in `pin-lean-toolchain`, requiring release and Lake validation before acceptance.
6. Registered 11 kernel questions with `cairn gap`.
7. Added researched `res.host-language-tradeoffs` and proposed `dec.host-languages`.

No source implementation, `.claude/`, tools, or Governance blueprint nodes are changed by this change.
