# Design: compiler admission recheck

`Lowering.compileWords` rechecks every submitted word, including unused
helpers, against the complete submitted dictionary and the elaborator's real
Gamma. Resolved type conversion preserves row binders, ordering, quotations
and usage. Canonical type validation precedes checking. The lower-level
instruction encoder remains an explicitly unchecked representation helper,
not an admission API. Errors return no target program.

An optional `source` member carries exact source bytes, a diagnostic path and
the language version. When supplied, the compiler re-elaborates it, compares
word names, every kernel body and every declared type, and refuses mismatch.
The source runner, fixed MVP gate and differential driver always supply it.
No file path in this member is opened. A changed but self-consistent source is
a new checked input, not impersonation of an earlier source.

Successful responses distinguish source-bound checking from kernel-only
checking. Neither mode claims discharged refinements, authenticated target
images, a compiler-correctness theorem or exact machine-time cost. Existing
`proof_state` input markers remain compatibility assertions only; rechecking
is unconditional. Legacy evidence digest slots remain content identifiers,
not portable proof capabilities, pending the separately tracked runtime
admission work.

Verification includes a failing-before public-input corpus, direct lowering
regressions, source/body/type substitution, helper and quotation tampering,
row and linearity failures, schema failures, and the unchanged real-source
campaign. The pinned Lean build derives new proof manifests after the source
change; no proof statement or original authored acceptance input is changed.
