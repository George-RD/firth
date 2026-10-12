---
node: firth.toolchain.elaborator
status: done
created: 2026-10-02
---

# A self-call inside a nested `locals` block is not a tail call

A word that calls itself as the last item of a `locals` block nested inside
its own `locals` block nests a frame on every call: the outer block's
locals are dropped after the inner block, so the call is not the word's
last action. Past 256 frames the VM traps with `resource-fault`. The
checker accepts the program and says nothing, and the docs ("a word that
calls itself as its last action, directly or as the last action of an `if`
branch", `examples/programs/README.md`) give an author no way to tell.

Found in the harder S7 tier's calibration (`eval/s7/harder/README.md`):
Sonnet's `tiny-vm` answer (sonnet-firth-2) passed 15 of 16 hidden tests and
trapped on the one that runs 300 instructions. Minimal case, which traps at
300 and succeeds at 200:

```firth
: count
  (forall ρ; ρ n:Int acc:Int -- ρ r:Int)
  locals { n acc } {
    n 0 prim =
    [ acc ]
    [ n 1 prim - locals { m } { m acc 1 prim + count } ]
    if };
```

The same word without the inner block runs at 300.

## Acceptance criteria

- Either the call in that position runs in the caller's frame (the outer
  locals are dropped before it, with the erasure still proved or tested
  against direct locals semantics), or the checker reports the non-tail
  self-call with a hint naming the fix. Which one is decided on the merits,
  taking the harder option if it avoids later pain (`AGENTS.md` rule 4).
- The minimal case above is a test, with its expected result written
  independently, on both hosts.

## Resolution

The call now runs in the caller's frame. Erasure counts a `many` local of an
enclosing block as used by what follows the inner block only when that
block's body really uses it after (`useCount` in
`src/elaborator/Firth/Erasure.lean`), so an outer local the rest of the word
never reads is moved into the inner block, not copied and dropped after it.
The minimal case is `count` in `examples/programs/nested-loop.firth`, with
expected results in `examples/programs/cases.json` (300 and 3000 iterations)
that `check_programs.py` runs on the reference interpreter and the VM. The
erasure is still tested against direct locals semantics by
`src/diffharness/check_locals_erasure.py`, which generates nested blocks.
