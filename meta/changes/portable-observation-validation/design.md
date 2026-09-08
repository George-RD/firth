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

Modify existing governance-owned files and add a test under `tools/loop`,
already mapped in `cairn.blueprint`. No new module or dependency is needed.
