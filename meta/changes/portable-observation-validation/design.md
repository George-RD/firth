# Design: portable observation validation

Validate complete supported result values before structural equality: an exact
literal envelope, a non-negative signed-64-bit-range integer with Python type
`int`, or a Boolean with Python type `bool`. Do not coerce values or strip extra
fields. In particular, reject both identical unsupported values and unequal
ones. Returned quotations receive an explicit unsupported-comparison error;
normalising away bodies or captures is not an alternative.

The reference pure-world value must be exactly `{"ids": []}`. The VM value
must be exactly `{"bytes": [0]}` with an integer byte, not a Boolean or float.
Keep status, trap, fuel, trace-length and kernel-cost checks distinct. No full
trace-equivalence claim is introduced.

Use the standard JSON decoder with duplicate-key and non-finite-number
rejection at the adapter response boundary. Preserve request-id matching and
existing subprocess bounds. This is transport validation, not authentication
of the compiler's checking/proof markers.

The comparison and test files are mapped to `firth.governance.loop`; VM cost
projection and Rust tests belong to `firth.runtime.vm`. Both are already mapped
in `cairn.blueprint`. No new module or dependency is needed.

## Captured-quotation cost projection

Candidate `9a47ebf35216b76aa3149891293a17c56494a9a3`, CI run 34246577859,
passed 23 of 24 real-host boundary cases. Calling a captured quotation returned
42 on both hosts, but reference cost was 3 and VM kernel cost was 4. The reference
interpreter's existing S-PUSH rule explicitly charges zero for restoring a
capture; the VM must still execute and charge its PUSH_CAPTURE instruction.

Record kernel cost on each VM cost step and derive both observation formats
from the same projection. Capture restoration and administrative word entry
contribute zero to that projection, while target totals, trace lengths and fuel
consumption remain unchanged. Test successful and fuel-exhausted capture calls,
multiple composed captures, both observation formats, and a real source example.
Do not change the governed S-PUSH gap, interpreter semantics, fixed fixture
costs or any proof pin to conceal the discrepancy.
