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
```

Every case that reaches Firth runs on the VM and the reference interpreter,
which must agree (`mvp_agent_gate.rebuild`), and the result must equal the
corpus's fixed expected output. The corpus is never rewritten from what the
program produces.

## Result

All 53 cases pass: 30 run in Firth and 23 are rejected by the host's own
checks, as the spec assigns them. Negative integers reach the component
unchanged, and Firth rejects a negative stock or quantity as `invalid-range`,
before it looks for repeated IDs.

## Cost

For a batch of n valid requests with no repeated ID, the kernel cost is at most

    166 + 199·n + 264·n(n−1)/2

which is 545,126 at the 64-request maximum, inside the VM's 1,000,000-step fuel
cap. `measure_cost.py` measures n = 0 to 64 on both hosts. It uses IDs sharing
their first 24 characters, which is the slowest case for the repeated-ID
scan, and one run for each allocation branch. For n ≥ 2 each run's cost is
exactly `82 + b·n + 264·n(n−1)/2`, where b is 169 (out-of-stock), 191
(fulfilled) or 198 (insufficient-stock), plus 30 once for the single partial
request a batch can have. The stated bound is deliberately looser than any one
of those: it uses the largest per-request cost and the n = 0 entry cost, so it
also covers mixed batches and the one partial request. An invalid input stops
earlier and costs less. `run_cases.py` fails any corpus run over the bound, and
CI also runs `measure_cost.py`, because the corpus's IDs never reach the slow
path.

This bound is measured and explained by the program's structure, not proved.
The toolchain does not yet check refinements or cost claims (`language-06`).

## What the language needed

- **Locals were expensive in hot loops.** A local cost tens of kernel steps
  per use, so the first version of the repeated-ID scan, with six locals, ran
  out of the 1,000,000-step fuel at 64 requests. The scan is written with stack
  words, and the IDs arrive as one sequence (four Ints per request) instead of
  four. Since `pick` and `roll` a local costs one step per use, which cut the
  per-request cost from 689 to 766 steps down to 169 to 198; the scan's 264 per
  pair was already hand-written and is unchanged.
- **There is no Boolean `and` or absolute difference.** Both are written with
  nested `if`.
- **Integers were naturals** when this was first written. Since signed `Int`
  landed, the stock's lower bound is an ordinary `-1 available prim <` check.
