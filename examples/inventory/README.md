# Inventory allocator (M1)

`allocator.firth` implements [specs/inventory-allocation.md](../../specs/inventory-allocation.md)
in Firth: the value and count bounds, repeated IDs, and the ordered
partial or all-or-nothing allocation with its reasons. `run_cases.py` is the
host. It does only what the spec's host/Firth split gives the host: JSON
shape, types, ID syntax and integers a 64-bit host cannot hold. Encoding each
ID as four Ints and turning the result codes back into an answer are proved
Lean definitions that it runs through `lake exe inventoryHost` (see below).

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

    165 + 202·n + 163·n(n−1)/2

which is 341,701 at the 64-request maximum, inside the VM's 1,000,000-step fuel
cap. What a pair of IDs costs the repeated-ID scan depends only on how their
four parts compare (equal, ascending or descending), so `measure_cost.py`
first measures all 80 shapes and fails unless the costliest is the one it
sweeps with: part 0 shared (the slow path in `same-id`) and parts 1 to 3
ascending (the negating branch of `distance` three times). It then measures
n = 0 to 64 on both hosts with those IDs, one run for each allocation branch.
For n ≥ 2 each run's cost is
exactly `75 + b·n + 163·n(n−1)/2`, where b is 172 (out-of-stock), 194
(fulfilled) or 201 (insufficient-stock), plus 30 once for the single partial
request a batch can have. The stated bound is deliberately looser than any one
of those: it uses the largest per-request cost and the n = 0 entry cost, so it
also covers mixed batches and the one partial request. An invalid input stops
earlier and costs less. `run_cases.py` fails any corpus run over the bound, and
CI also runs `measure_cost.py`, because the corpus's IDs never reach the
costliest pairs. An earlier version swept IDs sharing their first 24
characters, which take the negating branch once per pair, and stated a bound
that the costliest shape exceeds: before this rewrite, 545,126 was stated for
n = 64 and those IDs cost 555,248.

The bound is also proved. `src/proofs/Inventory/Allocate.lean` proves, from
the exported kernel program run by the reference interpreter, that
`allocate-batch` returns the spec's result on every valid input (so the
properties proved in `src/proofs/Inventory/Spec.lean` hold of its output) at a
kernel cost of at most this bound, with every value in i64. The proof is
recorded as toolchain evidence (`src/proofs/records.json`) bound to the body
digests of `allocate-batch` and every word it calls, so all ten words are
reported `contract_verified`, and a change to any of them withdraws it.
Agreement of the VM with the reference interpreter rests on differential
testing.

The host's ID encoding and its answer are proved as well
(`src/proofs/Inventory/Host.lean`): the encoding is injective on the spec's ID
syntax, so the duplicate-ID result means two equal ID strings, and every
allocation and reason is attached to its own request's ID in request order.
`run_cases.py` runs those Lean definitions through `lake exe inventoryHost`;
`check_host.py` checks that executable against values written by hand. Python
keeps the JSON shape, type, ID-syntax and i64 checks the spec gives the host,
which are tested by the corpus and by planted bugs
(`tools/loop/test_inventory_host.py`), not proved. JSON parsing and printing
(Python's on the way in, Lean's inside `inventoryHost`) and the transport
between them are tested, not proved, too.

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
  766 steps to 172 to 201, and the scan is back to plain locals, now cheaper
  than the hand-written version: 163 steps per pair at most.
- **There is no Boolean `and` or absolute difference.** Both are written with
  nested `if`.
- **There are no imports.** `vocab` groups words inside one file, but a
  client cannot name `allocator.firth` from another file, so `policy_change.py` builds each program by putting the allocator's
  source before the client's.
- **Integers were naturals** when this was first written. Since signed `Int`
  landed, the stock's lower bound is an ordinary `-1 available prim <` check.
