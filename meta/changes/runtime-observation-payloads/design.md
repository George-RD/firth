# Design: runtime-observation-payloads

Keep the existing bottom-to-top comma-separated stack form for integers,
Booleans and World. Encode bytes as `bytes:<lowercase-hex>` and primitive
values as `primitive:<unsigned-decimal-tag>:<lowercase-hex>`, using the VM's
existing hexadecimal encoder. Two hex digits per byte preserve length and
leading zeros; tags use all 64 bits, without a signed conversion. Neither
payload alphabet contains commas or colons, so type and value boundaries
remain explicit. Empty payloads are represented by empty hex suffixes.

These forms describe the Rust conformance API, not additions to the portable
source or JSON result profile. Primitive tags do not authenticate a value or
change its ownership. Unknown tags remain subject to the existing execution
admission rules. The default registry's linear primitive value is tested in
a retained trap stack rather than being misreported as a terminal value.

The report helper already owns a resolved `WordEntry`; pass `word.name` to
`run_code` instead of adding a second caller-supplied name. This also preserves
normal `main` and retained-image execution. Diagnostic execution already uses
the explicit entry and supplies an independent report-parity check.

The new integration suite uses public crate APIs only. It covers exact scalar
spellings, all 256 single-byte values, tag/length/type boundaries, real
execution mismatches, named root and helper events, quotation frame names,
and equality with diagnostic execution. Run it unchanged on the original
runtime and the candidate in both std and no_std configurations. Existing
15-row reference fixtures must remain byte-for-byte unchanged and pass.

No quotation or residual-frame equivalence claim is added. The renderer's
comments explicitly identify those remaining projections instead of claiming
that code or capture values follow from a word name and program counter.
