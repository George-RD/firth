---
node: firth.toolchain.agent
status: done
created: 2026-09-28
---

## Goal

Close the second gap stated with S5 (met 28 September 2026). The allocator's
Python host (`examples/inventory/run_cases.py`) decodes and checks the JSON
input, encodes each request ID as four base-65 Ints and encodes the result.
It is tested against the frozen corpus, not proved. The proved contract
(#141) assumes the host's ID encoding (`IdParts`) and nothing else, so its
claim reads "two requests' four-part ID blocks are equal", not "two IDs are
equal". That is sound only if the encoding is injective, which is tested,
not proved.

## Acceptance criteria

- The ID encoding is proved injective on the spec's ID syntax, in Lean or by
  moving it into Firth where the existing program logic applies. Moving host
  work into Firth needs the language features it uses (string or byte
  handling); name the gaps it hits as todos rather than working around them.
- Attaching each allocation and reason to its request's ID by position
  (`host_encode`) is proved to preserve IDs and order, which closes the last
  open part of `todo.language-06b-program-property-proofs`.
- Whatever stays in the host is listed, with the spec section that assigns
  it to the host, and is covered by the corpus and by planted-bug tests.
- The S5 claim is updated to name the remaining trusted host code, if any.

## Completion, 2 October 2026

Each acceptance criterion and its evidence:

- The ID encoding is proved injective on the spec's ID syntax, in Lean:
  `encodeId_inj` in `src/proofs/Inventory/Host.lean`. `encodeIds_idParts`
  proves every part is in `[0, 65^8)`, the old contract's precondition, and
  `hasRepeat_encodeIds` proves a repeated four-part block is exactly a
  repeated ID string. `allocate_batch_host_contract` restates the allocator's
  contract on ID strings (code 2 when two requests have the same ID) and is
  recorded in `src/proofs/records.json`. The Firth route was not taken: Firth
  has no string or byte values (`todo.language-text-values`).
- Attaching results to IDs by position is proved: `hostEncode_ok` shows a
  successful answer lists the request IDs in request order, each with its own
  quantity and reason name, and `hostEncode_error` shows an error answer is
  only ever one of the spec's two component codes.
- The proved definitions are the ones that run. `run_cases.py` no longer
  encodes IDs or builds answers; it calls `lake exe inventoryHost`
  (`HostMain.lean`), which evaluates `encodeIds` and `hostEncode` and refuses
  any ID outside `validId` (proved equal to the syntax, `validId_iff`) and any
  stack the spec does not allow. `examples/inventory/check_host.py` checks
  that executable against hand-written encodings and refusals, and
  `HostMutants.lean` plants wrong expectations that `#guard` must reject.
  The spec corpus guards (`SpecCorpus.lean`) now evaluate `hostSpec` on the
  corpus's ID strings.
- What stays in the host, with the spec section ("Host and Firth split") that
  gives it there: JSON parsing; the object shape, JSON types, policy string
  and ID syntax checks that answer `invalid-input`; the check that answers
  `invalid-range` for integers outside i64; and moving JSON to and from
  `inventoryHost`. The checks are in `run_cases.host_check`, covered by the
  23 host-rejected corpus cases and by `tools/loop/test_inventory_host.py`,
  which plants a bug in each check and requires an outcome to change. JSON
  parsing is `host_parse`, which answers `invalid-input` for malformed JSON
  and repeated member names (the spec's two host tests, in the same test
  file, with a planted parser that keeps the last member). The transport is
  in `lean_host`, `host_decode` and `host_encode`, and the JSON glue in `HostMain.lean` (`strings`, `ints`,
  `answerJson`) with Lean's JSON parser and printer, covered by the corpus
  runs and `check_host.py`. Lean's compilation of the proved definitions into
  `inventoryHost` is trusted as `#guard` evaluation is. None of it is proved.
- The S5 row in `docs/roadmap.md` names that remaining host code.
