# Inventory allocator (M1)

`allocator.firth` implements [specs/inventory-allocation.md](../../specs/inventory-allocation.md)
in Firth: the value and count bounds, repeated IDs, and the ordered
partial or all-or-nothing allocation with its reasons. `run_cases.py` is the
host. It does only what the spec's host/Firth split gives the host: JSON
shape, types, ID syntax, integers a 64-bit host cannot hold, encoding each ID
as four Ints, and turning the result codes back into JSON.

```sh
python3 examples/inventory/run_cases.py          # the 53 fixed cases
python3 examples/inventory/measure_cost.py       # cost against batch size
python3 examples/inventory/policy_change.py      # the partial to all-or-nothing change
python3 examples/inventory/check_scan.py         # the repeated-ID scan, part by part
```

Every case that reaches Firth runs on the VM and the reference interpreter,
which must agree (`mvp_agent_gate.rebuild`), and the result must equal the
corpus's fixed expected output. The corpus is never rewritten from what the
program produces.

The corpus never has two IDs that agree on some of their four encoded parts
and differ in another, so a scan that skipped a part would still pass it.
`check_scan.py` covers that: 20 batches whose IDs differ in only one part, with
and without a repeat at the first, middle or last pair, each checked against
the independently tested model in `tools/loop/test_inventory_contract.py`.

## Result

All 53 cases pass: 30 run in Firth and 23 are rejected by the host's own
checks, as the spec assigns them. Negative integers reach the component
unchanged, and Firth rejects a negative stock or quantity as `invalid-range`,
before it looks for repeated IDs.

## Cost

For a batch of n valid requests with no repeated ID, the kernel cost is at most

    165 + 202·n + 157·n(n−1)/2

which is 329,605 at the 64-request maximum, inside the VM's 1,000,000-step fuel
cap. `measure_cost.py` measures n = 0 to 64 on both hosts. It uses IDs sharing
their first 24 characters, which is the slowest case for the repeated-ID
scan, and one run for each allocation branch. For n ≥ 2 each run's cost is
exactly `75 + b·n + 157·n(n−1)/2`, where b is 172 (out-of-stock), 194
(fulfilled) or 201 (insufficient-stock), plus 30 once for the single partial
request a batch can have. The stated bound is deliberately looser than any one
of those: it uses the largest per-request cost and the n = 0 entry cost, so it
also covers mixed batches and the one partial request. An invalid input stops
earlier and costs less. `run_cases.py` fails any corpus run over the bound, and
CI also runs `measure_cost.py`, because the corpus's IDs never reach the slow
path.

This bound is measured and explained by the program's structure, not proved.
The toolchain does not yet check the allocator's properties or prove its cost
bound; that work is `language-06b` and `language-06c`.

## Changing the policy

The spec's maintenance task changes a partial-fulfilment client to
all-or-nothing while preserving conservation, order, input validation and
later fulfilment. `policy-change/partial.firth` is that client before the
change and `policy-change/all-or-nothing.firth` after it. Each defines one word,
`reserve`, which supplies the policy and calls `allocate-batch`. The change is
one token, `false` to `true`, because the spec makes the policy an input to the
component; nothing in `allocator.firth` changes.

`policy_change.py` checks that claim, and the behaviour, with what the
toolchain produces:

- **Changed words and dependents.** It elaborates and compiles both programs,
  compares every word's body digest and erased type from the compiler, and
  follows `call-word` edges in the compiled program. It fails unless `reserve`
  is the only changed word and no word depends on it; the 10 allocator words
  keep their digests. Both programs share `allocator.firth`, so that
  comparison alone cannot see an allocator edit; an allocator change is its
  own change, gated by `run_cases.py` and `measure_cost.py`. To show the check
  is not vacuous, the script also compiles a mutant whose `allocate-one` gains
  a no-op, and fails unless it reports `allocate-one` changed with
  `allocate-from` and `allocate-batch` as dependents.
- **Regression.** Each of the 30 cases that reach Firth runs through both
  clients on the VM and the reference interpreter, 60 runs in all. Where the
  case's policy is the client's, the result must equal the corpus's fixed
  output. Otherwise it must equal the independently tested model in
  `tools/loop/test_inventory_contract.py` and keep the spec's properties
  (conservation, IDs and order, no request over its quantity, the policy's own
  rule). Validation errors come out the same under both clients, and the
  paired `partial-oversize-first` and `whole-oversize-first` cases show the
  behaviour change. Every run stays within the cost bound plus the 6 steps
  `reserve` adds.

## What the language needed

- **Locals were expensive in hot loops.** A local cost tens of kernel steps
  per use, so the first version of the repeated-ID scan, with six locals, ran
  out of the 1,000,000-step fuel at 64 requests, and the scan was rewritten by
  hand with stack-shuffling words (264 steps per pair). The IDs also arrive as
  one sequence (four Ints per request) instead of four. Since `pick` and `roll`
  (#125) a local costs one step per use. The per-request cost fell from 689 to
  766 steps to 169 to 198, and the scan is back to plain locals, now cheaper
  than the hand-written version: 157 steps per pair.
- **There is no Boolean `and` or absolute difference.** Both are written with
  nested `if`.
- **There are no imports.** `vocab` groups words inside one file, but a
  client cannot name `allocator.firth` from another file, so `policy_change.py` builds each program by putting the allocator's
  source before the client's.
- **Integers were naturals** when this was first written. Since signed `Int`
  landed, the stock's lower bound is an ordinary `-1 available prim <` check.
