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

50 of the 53 cases pass: 27 run in Firth and 23 are rejected by the host's own
checks, as the spec assigns them. 3 are **blocked**: `negative-stock`,
`negative-quantity` and `range-before-duplicate` need a negative integer to
reach the component, and Firth integers are naturals until signed `Int`
lands. The spec forbids moving that bound check into the host, so the runner
reports them as blocked instead of passing them.

## Cost

For a batch of n valid requests with no repeated ID, the kernel cost is at most

    391 + 767·n + 297·n(n−1)/2

which is 648,231 at the 64-request maximum, inside the VM's 1,000,000-step fuel
cap. `measure_cost.py` measures n = 0 to 64 on both hosts. It uses IDs sharing
their first 24 characters, which is the slowest case for the repeated-ID
scan, and one run for each allocation branch. For n ≥ 2 each run's cost is
exactly `307 + b·n + 297·n(n−1)/2`, where b is 689 (out-of-stock), 756
(fulfilled) or 766 (insufficient-stock), plus 78 once for the single partial
request a batch can have. An invalid input stops earlier and costs less.
`run_cases.py` fails any corpus run over the bound.

This bound is measured and explained by the program's structure, not proved.
The toolchain does not yet check refinements or cost claims (`language-06`).

## What the language needed

- **Locals are expensive in hot loops.** A local costs tens of kernel steps per
  use. The first version of the repeated-ID scan used six locals and ran out of
  the 1,000,000-step fuel at 64 requests. The scan is now written with stack
  words, and the IDs arrive as one sequence (four Ints per request) instead of
  four. The rest of the program uses locals.
- **There is no Boolean `and` or absolute difference.** Both are written with
  nested `if` or with `prim -`, which stops at 0.
- **There are no negative integers** (see above).
