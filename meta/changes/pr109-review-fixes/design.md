# Design: pr109-review-fixes

## Compiler

Threads 25 and 49, nested paths. `debug_locations` entries now carry `path`
and `kernel_path`, index lists through every enclosing quotation body
(`[1]` for top-level instruction 1, `[1,0]` for instruction 0 inside the
quotation at index 1). `Compile.debugEntries` walks `PUSH_QUOTE` bodies and
quotation literals recursively. The invariant is checked structurally rather
than by counting: `Compile.correspond` pairs the kernel program with the
lowered code at every depth, requiring one instruction per atom and the body
of a `PUSH_QUOTE` for every quotation atom, and any mismatch is an internal
error rather than a response. The `atoms`/`atomCounts` plumbing that only
counted top-level atoms is gone.

Thread 49, source spans. The elaborate adapter emits an optional `spans`
member on every `checked_word`: one `{start, end}` per atom with a `body`
per quotation atom, taken from `LocatedKernel.span` and `children`. The
compile adapter accepts the member (`decodeCheckedWord` optional list),
validates its shape against the program (`spansMatch`) and, for a
source-bound request, requires any supplied tree to equal the one from its
own re-elaboration; every debug entry then carries `source_path` and the
re-elaborated `span`. A kernel-only request has no source to attribute a span
to, so it reports none. The pinned schemas type `checked_words` and
`debug_locations` as opaque arrays, and the gate and harness copy only the
known members into reference-run dictionaries, so no pinned schema, frozen
input or reference-run request changes.

Thread 47. `Target.maxInstructions = 4096` and `Target.maxNesting = 32`
mirror `src/runtime/vm/src/lib.rs`. `Target.boundViolation` walks lowered
code the way `resource_bounds.rs` does (depth 0 at a word body, one deeper
per quotation body or captured quotation, code and capture vectors bounded at
every level) and `Lowering.compileWords` refuses a violation as
`CompileError.targetBoundExceeded`, code
`firth.compile.target-bound-exceeded`, before rendering or rechecking. Depth
32 is admitted and 33 refused, matching `validation.rs` and `decode.rs`.

Thread 16. `Target.isInt64` states the `i64` domain once; `lowerLiteral`
uses it instead of an inline constant, and `Value.int` documents that callers
must respect it because the encoder is total.

Thread 26, lighter alternative. `Target.wellFormedCode` /
`wellFormedQuotation` require equal capture and consumed lengths at every
depth; `compileWords` refuses a mismatch as `unsupportedValue`. The
`captureBitmap` shape is unchanged so no digest moves.

Threads 31 and 40. `WordType.isRowName` is the VM's `row_name` predicate
(one scalar, not Unicode `White_Space`, not a delimiter) restricted further
to non-ASCII so a row name can never read as a `Name`. `canonicalRowName`
keeps the frozen 24-name Greek table for binders 0 to 23 and continues with
CJK Unified Ideographs from `U+4E00`; `render` checks every emitted name with
`isRowName` and a `#guard` pins the table. Schemes beyond the block (21016
binders) are still refused rather than wrapped into another block.

## Elaborator

Thread 75. `resolveNames` takes an `external : String -> Bool` (default
none). A qualified reference is resolved only when its expanded canonical
key is a dictionary key or external; an unqualified reference with no
candidate is refused unless external. Both refusals are
`firth.name.unresolved` from the resolver. `Pipeline.elaborateWith` passes
`config.erasureEnv.word`, so configured external words keep resolving.
`firth.name.unresolved-effect` now means exactly what erasure reports: a
primitive the environment does not declare.

Thread 57. `firthNamesTest` is a `lean_exe` in `lakefile.toml`, in
`defaultTargets`, and run by `src/agent/FirthAllTest.lean`; the CI step is
left in place.

Thread 80. The envelope already has `related`, but attaching per-diagnostic
related spans requires editing `parserEnvelope` in
`src/agent/Firth/Agent/ElaboratorDiagnostics.lean`, a frozen model-facing
input pinned by SHA-256 in the manifest. Recorded as
`meta/todos/todo.name-diagnostic-related-spans.md`.

## Documentation

Threads 35, 38, 41 and 44 are wording corrections in the cited documents.
Thread 35 additionally gains `test_decision_record_states_current_region_counts`
in `tools/loop/test_smt_proof_bindings.py`, which derives the expected counts
from the generator's required regions. `docs/compiler-admission.md` documents
the new admission bounds and the separate `vm-run` JSON nesting limit, and the
compiler-adapter design records the path-based debug metadata.

## Control plane

Thread 71. `test_completion_flips_loop_exhaustion_only_when_every_language_task_is_done`
copies `coverage.py`, `select_unit.py`, `obligations.toml`, the blueprint,
every todo and a passing stub for every pinned gate into a temporary root,
asserts exhaustion is invalid while a language todo is open, marks every
todo done and asserts it flips to valid with nothing ungenerated or missing,
then reopens one language todo and asserts it flips back. The live-tree
negative check is kept.

## Public gates

`tools/loop/check_compiler_admission.py` gains `bounds:` cases at and above
both bounds and a `rows:` 25-binder success case, none under the `kernel:`
prefix the `--baseline` mode filters on. `tools/loop/check_trust_boundaries.py`
pins `firth.name.unresolved` for unqualified, qualified and unknown-prefix
references, `firth.name.unresolved-effect` for an undeclared primitive, and
runs a 25-binder word through `vm-run` so the VM parser's agreement with the
generated row names is checked in CI.
