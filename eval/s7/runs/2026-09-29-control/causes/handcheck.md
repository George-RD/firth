# Hand check of the Jev cause labels

`handcheck_sample.py` draws 15 failing first answers and 15 failing final
answers from `units.json` with a fixed seed and prints each as Jev saw it,
without Jev's label. The labels below were written from that output before
`jev.json` was opened for these rows. Each names the mistake behind the first
failure the author was shown, using the labels in `jev_causes.py`.
`python3 runs/2026-09-29-control/causes/handcheck_sample.py --compare` reads
this table and prints the agreement with Jev.

| # | Sample | Round | Task | Hand label | Note |
|---|---|---|---|---|---|
| 1 | B1 | 1 | seq-max | locals-form | `xs` used in a word that binds no locals |
| 2 | B4 | 1 | ledger | other-syntax | parentheses around a condition |
| 3 | B14 | 1 | merge-sorted | stale-local-state | recursive call given only the changed arguments |
| 4 | A10 | 1 | digits | locals-form | `n` used without a `locals` block |
| 5 | B12 | 1 | histogram | argument-order | `seq-int.set` operands in the wrong order |
| 6 | B3 | 1 | keep-positive | wrong-algorithm | `<` where `<=` was meant |
| 7 | A6 | 1 | histogram | locals-form | `k` used without a `locals` block |
| 8 | B2 | 1 | longest-run | stale-local-state | recursive call given only the changed arguments |
| 9 | A9 | 1 | is-sorted | locals-form | `xs` used without a `locals` block |
| 10 | B11 | 1 | count-below | quoted-condition | condition written after the two quotations |
| 11 | A12 | 1 | merge-sorted | stale-local-state | recursive call given `i j result` but not `xs ys` |
| 12 | B3 | 1 | allocate-batch | stack-juggling | `seq-int.set` given two values, the index missing |
| 13 | A2 | 1 | digits | other-syntax | parentheses in a body |
| 14 | B4 | 1 | count-distinct | other-syntax | parentheses around a condition |
| 15 | A1 | 1 | reverse | locals-form | `locals { ... }` without a braced body |
| 16 | B2 | 3 | all-true | argument-order | `len i <` where `i len <` was meant; runs, wrong result |
| 17 | B12 | 3 | allocate-batch | stale-local-state | computed values left, recursive call given old `allocated reasons` and no `stock` |
| 18 | B7 | 3 | primes-up-to | stack-juggling | `isprime prim and` with one Bool |
| 19 | B11 | 3 | histogram | stale-local-state | recursive call given only the changed arguments (condition is also after the quotations) |
| 20 | B11 | 3 | is-sorted | quoted-condition | condition after the quotations |
| 21 | B11 | 3 | longest-run | quoted-condition | condition after the quotations |
| 22 | A8 | 3 | seq-sum | unknown-word | `rot` |
| 23 | A3 | 3 | prefix-sums | stack-juggling | `swap` after `seq-int.push` with one value |
| 24 | A10 | 3 | prefix-sums | stale-local-state | new `result` pushed, old `result` passed to the recursive call |
| 25 | B12 | 3 | has-pair-sum | argument-order | computed `need` pushed first instead of last |
| 26 | B11 | 3 | count-below | quoted-condition | condition after the quotations |
| 27 | A7 | 3 | histogram | argument-order | `seq-int.at` given index before sequence |
| 28 | A12 | 3 | longest-run | wrong-algorithm | run length starts at 1 and counts the first element again |
| 29 | B2 | 3 | has-pair-sum | argument-order | `len j <` where `j len <` was meant; runs, wrong result |
| 30 | B12 | 3 | primes-up-to | argument-order | recursive call's arguments in another order |

## Result

`handcheck_sample.py --compare` on this table: 22 of 30 agree, 11 of 15 in
each round. By the family of the first thing the author was shown
(`rank.py`): syntax 4 of 4, unknown-name 4 of 5, input-mismatch 7 of 8,
branch-mismatch 6 of 9, wrong-result 1 of 4.

So Jev's labels are used only to split checker failures. Wrong results are
kept as one group: on three of the four sampled, Jev said stale-local-state
where the hand label was a reversed comparison (two) or an off-by-one start,
which is also why Jev puts 27 of the 40 final wrong results under
stale-local-state. Within branch mismatches the split between
stack-juggling and stale-local-state is rough (of the three disagreements
there, two are those two labels swapped and one is an argument-order
mistake Jev called stack-juggling), so the write-up gives the
branch-mismatch total first and the split as approximate. Across the
branch-mismatch and input-mismatch rows, on the three labels the splits use
(stack-juggling, stale-local-state, argument-order), Jev matched 9 of 13 and
every miss (rows 5, 11, 12 and 27) was a swap among those three, so every
such sub-row is approximate.
