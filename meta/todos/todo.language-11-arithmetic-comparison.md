---
node: firth.toolchain.compiler
status: open
created: 2026-09-08
---

Requires: language-05-baseline-acceptance language-10-inventory-contract

## Goal

Deliver the portable arithmetic and comparisons required by allocation.

## Acceptance criteria

- Support subtraction, minimum and comparison through defined primitives or checked words, with consistent parser/type/refinement/reference/compiler/VM behaviour.
- State numeric ranges, underflow and overflow exactly. Resolve the current Int name versus non-negative execution mismatch without silently changing frozen semantics.
- Test boundary values and invalid operands on both hosts, and add generated differential cases.
- Publish runnable examples and a capability table backed by tests. No untested signed/floating-point or general I/O promise.

## Progress

- 10 October 2026: audit against the criteria. Subtraction (since
  #122; `runs_sub` in `interpreter/Firth/ProgramLogic.lean`) and the
  comparisons `<=`, `>`, `>=` (`dec.comparison-primitives`) are Gamma
  primitives on every host; minimum is not, and each example defines its
  own, so a shared `min`/`max` waits for multi-file imports
  (`todo.language-12-data-and-modules`). `dec.int64-arithmetic` (proposed)
  records the integer range, overflow and `MIN div -1` semantics and the two
  divergences left, both from the reference's unbounded integers: overflow,
  and the length of a sequence of 2^63 or more elements, where the VM traps
  and the reference does not. It recommends running the reference under
  `int64Gamma` with `seq-int.len` and `seq-bool.len` checked too. Still open: that
  decision and its change, a hand-written VM overflow trap and a Bool-for-Int
  refusal among the example cases, and a capability table whose rows name
  their tests (`docs/getting-started.md`, held while an S7 authoring window
  is open).

## Traceability

Consumer-derived slice of PRD G2/G6/G9; supersedes adding arithmetic merely to fill a checklist.
