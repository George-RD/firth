# Example programs

Small programs that use arithmetic, comparison, conditionals, tail-recursive
loops and sequences. `check_programs.py` runs every case in `cases.json` through the checker
and compiler, then on both the VM and the reference interpreter, and fails
unless both hosts agree and produce the expected stack.

```sh
python3 examples/programs/check_programs.py
python3 tools/loop/firth_run.py run examples/programs/factorial.firth --entry fact --stack '[5]'
```

## Primitives

Integers are signed 64-bit values; a literal may be negative (`-3`).

```
a b prim +    \ Int Int -- Int
a b prim -    \ Int Int -- Int   (3 5 prim - gives -2)
a b prim *    \ Int Int -- Int
a b prim div  \ Int Int -- Int   (Euclidean quotient: -7 2 prim div gives -4)
a b prim mod  \ Int Int -- Int   (Euclidean remainder, never negative: -7 2 prim mod gives 1)
a b prim <    \ Int Int -- Bool
a b prim =    \ Int Int -- Bool
p q prim and  \ Bool Bool -- Bool
p q prim or   \ Bool Bool -- Bool
p prim not    \ Bool -- Bool
flag [ then-branch ] [ else-branch ] if
```

A result that does not fit a signed 64-bit integer traps on the VM.

`div` and `mod` satisfy `a = b*q + r` with `0 <= r < |b|`, as Lean's `Int./`
and `Int.%`. A zero divisor traps with `primitive-fault` on both hosts.
`division.firth` has a quotient-and-remainder word, a decimal digit sum and
Euclid's greatest common divisor.

## Loops

A loop is a word that calls itself as its last action, directly or as the last
action of an `if` branch. The VM runs such a call in the caller's frame, so the
loop is bounded by the step budget (100,000 steps per run by default, up to
1,000,000 with `--fuel`), not by call depth. `sum-to` at 7000 takes about
91,000 kernel steps. Its trace comparison is `unsupported-quotation-values`
(every loop runs `if` on quotation branches), so it does not exercise the
`agreed-prefix` path, which the gate's unit tests cover.
A recursive call followed by more work still nests and traps past 256 frames.

## Locals

`locals { a b } { ... }` names the top values. Inside the block a name can be
used any number of times, inside `if` branches, and inside quotations (the
value is captured when the quotation is built). `locals.firth` has factorial,
Fibonacci and an allocation step written this way. A `locals` block nested
inside a quotation can use the outer block's names too.

A block takes its values off the stack: in `locals { a } { swap }` the
`swap` exchanges the two values below `a` (`swap-below`).

A local can't be used after `call`, `dip` or `if` runs a quotation whose stack
effect isn't known at that point: a quotation passed in as a value, one
returned by another quotation, or `[ call ]` itself. The checker can't tell
where the local sits afterwards, so it refuses the program with
`firth.elaboration.untracked-local` rather than guess. Quotations written
inline, like `[ 1 prim + ] call` or `[ 1 prim + ] [ ] compose call`, are fine
(`quotations.firth`). An `if` whose two branches leave different numbers of
values is a type error, reported as `firth.type.branch-mismatch` at that
`if`, however deeply it is nested and whatever follows it
(`refused/if-branch-shape.firth`). The
programs under `refused/` must be rejected.

## Sequences

`Seq Int` and `Seq Bool` hold any number of integers or Booleans. They are
ordinary values: a sequence can be used any number of times, and `push` and
`set` return a new one. `sequences.firth` sums, counts, builds a range and
indexes. `sieve.firth` finds primes with a sieve of Eratosthenes that clears
entries in place, and `sort.firth` sorts by insertion, swapping neighbours
with `set`.

```
{ 1 2 3 }                  \ -- Seq Int      (a literal; { true false } is a Seq Bool)
prim seq-int.empty         \ -- Seq Int
xs prim seq-int.len        \ Seq Int -- Int
xs i prim seq-int.at       \ Seq Int Int -- Int
xs x prim seq-int.push     \ Seq Int Int -- Seq Int
xs i x prim seq-int.set    \ Seq Int Int Int -- Seq Int   (element i becomes x)
```

`seq-bool.empty`, `.len`, `.at`, `.push` and `.set` are the same for
`Seq Bool`. A negative index, or one at or past the length, traps with
`primitive-fault` on both hosts; `at` never returns a default and `set`
never grows the sequence. A case with `expect_trap` checks that: both hosts
must stop with that trap at the same stack and kernel cost. `{ }` is refused
because it has no element type; write `prim seq-int.empty`. On the command
line and in `cases.json` a sequence is a JSON array, and `[]` takes its type
from the word's signature:

```sh
python3 tools/loop/firth_run.py run examples/programs/sequences.firth --entry sum --stack '[[4, 5, 6]]'
```

## Limits

- `allocate.firth` is one step of `specs/inventory-allocation.md`; the whole
  batch is `examples/inventory/`.
- The trace comparison reports `unsupported-quotation-values` for these
  programs, because `if` puts quotations on the stack. Final stacks, costs and
  trace lengths are still compared.
