# Example programs

Small programs that use arithmetic, comparison, conditionals and tail-recursive
loops. `check_programs.py` runs every case in `cases.json` through the checker
and compiler, then on both the VM and the reference interpreter, and fails
unless both hosts agree and produce the expected stack.

```sh
python3 examples/programs/check_programs.py
python3 tools/loop/firth_run.py run examples/programs/factorial.firth --entry fact --stack '[5]'
```

## Primitives

Numbers are naturals; `Int` in a signature never holds a negative value.

```
a b prim +    \ Int Int -- Int
a b prim -    \ Int Int -- Int   (truncates at 0: 3 5 prim - gives 0)
a b prim *    \ Int Int -- Int
a b prim <    \ Int Int -- Bool
a b prim =    \ Int Int -- Bool
flag [ then-branch ] [ else-branch ] if
```

A result that does not fit a signed 64-bit integer traps on the VM.

## Loops

A loop is a word that calls itself as its last action, directly or as the last
action of an `if` branch. The VM runs such a call in the caller's frame, so the
loop is bounded by the step budget (4096 steps per run), not by call depth.
A recursive call followed by more work still nests and traps past 256 frames.

## Limits

- `allocate.firth` is one step of `specs/inventory-allocation.md`. The whole
  batch needs a sequence type, which the language does not have yet.
- The trace comparison reports `unsupported-quotation-values` for these
  programs, because `if` puts quotations on the stack. Final stacks, costs and
  trace lengths are still compared.
