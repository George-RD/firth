# First consumer: ordered stock allocation, v1

Status: frozen acceptance specification (v1, 27 September 2026), not an
implemented Firth application.
The calculation will be written in Firth. These fixed cases predate that
implementation and are not replaceable by whatever result it produces.

## Boundary

Input is a JSON object with exactly `available`, `policy` and `requests`.
`available` is an integer from 0 to 1,000,000 inclusive. `policy` is either
`partial` or `all-or-nothing`. `requests` is an array of at most 64 objects,
each containing exactly `id` and `quantity`. An ID matches
`[A-Za-z0-9_-]{1,32}` and is unique within the batch. Quantity is an integer
from 1 to 1,000,000 inclusive. Booleans, floating-point numbers and numeric
strings are not integers; a JSON number written with a fraction or an
exponent (`1.0`, `1e0`) is not an integer even when its value is whole. IDs
are compared exactly, byte for byte, so `a` and `A` are different IDs.
Request-array order is the priority order.

The host decodes and encodes JSON; it does not implement allocation. Malformed
JSON or repeated JSON object member names are rejected before this typed
interface with `invalid-input`; the fixed cases store decoded inputs, so these
two errors are host tests rather than corpus cases. Domain validation and
allocation must remain testable at the component boundary. No network,
database or UI feature is necessary here.

Invalid input produces only `{"status":"error","code":"..."}`, never a
partial allocation. Error precedence is global: malformed shape, field type,
policy or ID syntax => `invalid-input`; then numeric/count bounds =>
`invalid-range`; then repeated request IDs => `duplicate-id`. The value and
count bounds share one level, and every request is checked for shape, type and
ID syntax even when there are more than 64. Unknown or missing members are
malformed shape. An empty request array is valid.

## Host and Firth split

The corpus fixes the observable result of host and component together, so the
split below changes no expected output. It says which side owns each check.

- The host owns JSON decoding and everything that needs JSON or text: object
  shape, JSON types, the policy string and ID syntax. These produce
  `invalid-input`. It then hands the component the policy, `available`, and
  each request's ID and quantity, in order.
- The Firth component owns the rest of validation (the `available`, quantity
  and count bounds, then repeated IDs) and the whole calculation. The host
  passes decoded integers unchanged and does not pre-check their bounds. The
  one exception is an integer the host cannot hold exactly (outside the
  signed 64-bit range): it is out of bounds by definition, so the host
  reports `invalid-range` for it once its own `invalid-input` checks pass.
- Each ID reaches the component in an encoding computed from that ID alone,
  and distinct IDs get distinct encodings. The host must not number IDs by
  first occurrence or otherwise detect repeats for the component.
- The component returns either an error code or `remaining` plus one
  allocated quantity and reason per request; the host attaches IDs and
  encodes the JSON.

If Firth cannot yet represent some part of this interface (for example a
negative integer, or a sequence of requests), that is a language gap to fix,
not a reason to move a check into the host or to drop cases.

## Calculation

Start with remaining stock equal to `available`. Visit every request in the
provided order. Under `partial`, allocate the minimum of remaining stock and
requested quantity. Under `all-or-nothing`, allocate the full quantity only
when it fits; otherwise allocate zero and continue to later requests. Rejecting
an oversized request must not stop a later smaller request from being filled.
Subtract the allocated quantity before handling the next request.

Success has exactly `status`, `remaining` and `allocations`. Status is `ok`;
allocations has one object per input request in the same order, with exactly
`id`, `quantity` (the allocated quantity) and `reason`:

| Condition | Reason |
| --- | --- |
| Full requested quantity allocated | `fulfilled` |
| Positive but incomplete allocation | `partial` |
| No stock remained when the request was visited | `out-of-stock` |
| Positive stock remained but all-or-nothing request did not fit | `insufficient-stock` |

Under `partial`, a request never gets `insufficient-stock`.

## Required properties

Remaining stock and allocations are non-negative integers. No request receives
more than it asked for. Remaining plus the sum allocated equals initial stock.
IDs and order are preserved. Earlier eligible requests have priority; every
allocation follows the chosen policy, not just the conservation equation.
An implementation that always allocates zero must fail the acceptance cases.
The calculation terminates within a bound derived from the batch bound and
its executed word costs; no hardware real-time claim follows from that alone.

## Acceptance and maintenance task

`inventory-allocation-cases.json` contains fixed outputs for valid inputs and
fixed error codes for invalid inputs. When the contract was frozen on 27
September 2026, every expected outcome was re-derived from this text by hand
and again, blind, by a separate reviewer. The cases added then cover error
precedence, the edge of every bound, exact fit and case-sensitive IDs; the
original 19 cases are unchanged. Review of that change added two more: IDs are
checked beyond the 64th request, and a value past the signed 64-bit range is
`invalid-range`. `tools/loop/test_inventory_contract.py`
checks these against an independent mathematical model and invariant checks;
that validates the specification corpus, not Firth execution. The eventual
consumer gate must execute the actual Firth program and compare to these
unchanged expected outputs on both VM and reference interpreter.

The maintenance task changes a partial-fulfilment client to all-or-nothing
while preserving conservation, order, input validation and later fulfilment.
The paired oversize-first cases make the behavioural difference observable.
An implementation agent cannot weaken this specification or edit acceptance
outputs as part of implementing that change.

## Non-goals and assumptions

This is a single-product, ordered batch calculation, not a production inventory
system. A pure proof does not cover stale stock snapshots, concurrent orders,
transaction isolation, retries or authentication. The host owns those concerns.
Money, currencies, replenishment and multi-location stock are outside v1.
No live client data or business transactions are used by these fixtures.
