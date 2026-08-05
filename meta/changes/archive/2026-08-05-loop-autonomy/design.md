# Design: loop-autonomy

## Approach

Close the one undefined state instead of softening any guard. The loop
already fails closed everywhere except one corner: blocked todos plus
blocked obligations plus an empty eligible set had no defined outcome. The
decision makes that corner unreachable in normal operation (decision
blockers are resolved by the iteration that hits them, never parked) and
fail-closed when reached anyway, devolves decision authority to the loop
through typed tiers with a conservative-default rule, and binds completion
to the machine-checkable `loop_exhausted_valid` field coverage already
emits. Halts, gates, review, zero-admit, and the supersede rule are
untouched; autonomy is added by removing the maintainer from the
implementation-decision path, not by weakening any check. The goal layer
(PRD requirements and success criteria, obligation scope, licensing) stays
immutable to the loop so `status: accepted` cannot become a shortcut door,
and the generic cairn pack's receipt protocol is explicitly not claimed:
the firth loop is the sole runner, with the pack's skills excluded from
loop sessions.

The cairn acceptance battery is substituted, not bypassed: its cargo steps
target a manifest that does not exist in this repository and its strict step
is red on the accepted baseline (verified on pristine `origin/main`), so
tasks-complete plus the repository gates carry the same protection. The
clause self-retires when a cairn release fixes the battery.

## Changes

ADDED:
- `meta/decisions/loop-autonomy.md` (dec.loop-autonomy, accepted, nodes
  `firth.governance` and `firth.governance.loop`).
- `meta/changes/loop-autonomy/` (this change).

MODIFIED:
- `.claude/commands/firth-loop.md`: maintainer-decision paragraph replaced
  by typed in-loop resolution per clauses 2-3; Firth policy (vi)
  acceptance-gate substitution; Backlog generation fail-closed
  starved-selector row (clause 4) with the qualified
  implementation-complete report; `LOOP EXHAUSTED` bullet bound to
  `loop_exhausted_valid`; selection section's maintainer-blocked sentence
  points at the decision; language-gates binding fixed for the real tree
  (camel-case `testDriver`, VM crate gates from `src/runtime/vm`, generic
  root-cargo skill lists never override the binding).
- `docs/loop-runbook.md`: cairn prerequisite restated as verified behaviour
  (0.9.x verified; battery exception per clause 5); Lean and Rust toolchain
  prerequisites (elan 4.2.3, cargo 1.93.0 verified); omp launch example
  with flags verified against omp 17.2.9 and a print-mode token check,
  plus the generic `/cairn-loop` exclusion; a driver with a typed exit
  status (0 exhausted, 2 halted, 3 unknown token or harness failure, 4
  fuse) that ignores any token from a nonzero harness exit; guidance that
  completion runs use no MISSION and a large iteration fuse; token table
  terminal semantics; dry-run expected results refreshed to the current
  selector/coverage snapshot plus `lake build`/`lake test` and the VM
  crate gates.
- `AGENTS.md`: stale state claims corrected (`src/` components and live
  product gates) and the dec.loop-autonomy pointer added.

REMOVED:
- The maintainer-decision parking rule (author recommendation, block the
  todo, wait for the maintainer) and the `cairn 0.3.x` version pin.

RENAMED:
- None.
