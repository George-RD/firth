# First consumer: ordered stock allocation, v1

Status: acceptance specification, not an implemented Firth application.
The calculation will be written in Firth. These fixed cases predate that
implementation and are not replaceable by whatever result it produces.

## Boundary

Input is a JSON object with exactly `available`, `policy` and `requests`.
`available` is an integer from 0 to 1,000,000 inclusive. `policy` is either
`partial` or `all-or-nothing`. `requests` is an array of at most 64 objects,
each containing exactly `id` and `quantity`. An ID matches
`[A-Za-z0-9_-]{1,32}` and is unique within the batch. Quantity is an integer
from 1 to 1,000,000 inclusive. Booleans, floating-point numbers and numeric
strings are not integers. Request-array order is the priority order.

The host decodes and encodes JSON; it does not implement allocation. Malformed
JSON or repeated JSON object member names are rejected before this typed
interface. Domain validation and allocation must remain testable at the
component boundary. No network, database or UI feature is necessary here.

Invalid input produces only `{"status":"error","code":"..."}`, never a
partial allocation. Error precedence is global: malformed shape, field type,
policy or ID syntax => `invalid-input`; then numeric/count bounds =>
`invalid-range`; then repeated request IDs => `duplicate-id`. Unknown or
missing members are malformed shape. An empty request array is valid.

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
fixed error codes for invalid inputs. `tools/loop/test_inventory_contract.py`
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
