---
node: firth.toolchain.agent
status: open
created: 2026-09-28
---

Requires: compiler-vm-agreement-proof

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
- Whatever stays in the host is listed, with the spec section that assigns
  it to the host, and is covered by the corpus and by planted-bug tests.
- The S5 claim is updated to name the remaining trusted host code, if any.
