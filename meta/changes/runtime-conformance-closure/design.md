# Design: runtime-conformance-closure

## Rendering and the unsupported verdict

The conformance grammar gains `quotation:<usage>:<hex64>{slot,...}` for
values and `word@pc:<hex64>:<cont>{slot,...}` for frames, where `hex64` is
the SHA-256 of the canonical code, a slot is a value or `consumed`, and the
continuation is `halt`, `return` or `restore-dip(<value>)`. Braces occur in
no other alphabet, so a rendering splits unambiguously. A frame whose saved
values do not fit its continuation renders `invalid-frame`; the executor
never produces one and a test asserts it.

`ConformanceVerdict::UnsupportedComparison` is added with `is_agreement()`
true only for `Agree`. A reference stack containing `quotation-many` or
`quotation-linear`, or a reference frame without a `:`, is a projection: the
target is projected the same way, a differing projection disagrees, an equal
one is unsupported. Disagreement wins over unsupported, which wins over
agreement. `fixture_reference` keeps the frozen corpus byte-compatible and
lifts only a single root `main@pc` frame inside the entry body, which is
fully determined, so row `drop-fault` agrees exactly while row `quote` is
asserted unsupported.

## Adapter payloads and the trace comparison

`value_json` reports a quotation's usage, body digest, and its code and
capture slots in the request grammar, so the object minus `usage` and
`body_digest` round-trips through `adapter_operand_value`. Consumed slots and
administrative `World` captures are labelled since they have no request form.
`TraceEvent.cost` becomes the event's own charge and `kernel_cost` is added,
computed once in `charge()`; `trace_json` emits both with `image_version` and
the frames in flight. The response gains the VM-only members `frames`,
`trap_subcode` and `verification` after the shared `firth.observation.v1`
list, declared as `extensions` in the manifest rather than by changing the
shared schema.

`compare_traces` projects the reference onto positively charged events and
the VM onto positively kernel-charged events. One instruction per atom, a
zero-cost `S-PUSH` against a zero-kernel `PUSH_CAPTURE`, no VM event for
`DIP` restoration against a zero-cost push, and `CALL_WORD` carrying the
unfold charge make the projections align index by index; every pinned gate
was run to confirm it. Lengths and per-index charges must match; when no
projected stack holds a quotation, every stack is validated and compared
exactly and the label is `agreed`, otherwise `unsupported-quotation-values`.
Programs, words, instruction pointers and step counts are not compared.
`TraceMismatch` gives the harness its `trace-mismatch` class; the S5 gate
records the label. `compare` consumes the `[comparison]` table and refuses any
table other than the implemented one; `verify_contract` binds the manifest's
language and Gamma versions, the four adapters and that table before
provenance.

## Bounds

`MAX_CALL_DEPTH` is checked at the top of `run_code` and before the word-entry
charge in `CALL_WORD`, trapping `resource-fault/call-depth-exceeded` with the
callers as residual frames. The executor is split into per-opcode step
functions so only the active path occupies native stack: a level cost about
16.5 KiB before and about 4.8 KiB (`CALL_WORD`) to 5.4 KiB (`DIP`) after in
an unoptimised build, which is why the cap is 256 and is pinned by a test
executing exactly that depth on both paths inside a 2 MiB thread.
`MAX_FUEL` equals the default budget; the adapter, the CLI, the gate, the
runner and the harness share it. The per-step checkpoint holds the stack,
world, fuel, cost totals, vector lengths and the current frame's continuation
and saved value, and rollback truncates. Both CLI readers take one byte past
`MAX_INPUT_BYTES`; `vm_run_bytes` refuses oversize input before UTF-8
decoding. Duplicate members use a `BTreeSet`; surrogate pairs decode; the
transport nesting bound is `3 * MAX_NESTING + 8` so the decoder alone decides
quotation depth; consumed bits are refused by decoder, validator and adapter.

## Admission label and S5

`AdmissionLabel`/`VM_ADMISSION` use the compiler's vocabulary and appear on
`ConformanceObservation`, the `run` command and the adapter's
`firth.vm-verification.v1` member. Nothing is refused that was not refused
before: the label states the boundary. The S5 gate proves both branches from
both traces (each host selects on `true` and `false`, and every handler named
in a dispatch quotation runs, matched positionally to its mangled target
name), binds the compiled entry, tracks every specification field as read,
and executes a one-branch session as a negative control that must fail.
