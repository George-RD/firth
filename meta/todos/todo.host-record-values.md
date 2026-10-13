---
node: firth.toolchain.agent
status: open
created: 2026-10-13
---

## Goal

Let a host (the runners and the eval harness) give and read record and
variant values by field and case name instead of as the flat stack that
`dec.typed-records-and-variants` defines for the boundary.

## Acceptance criteria

- `firth_run.py run` accepts a JSON object for a record argument and reads one
  back, using the declaration's field order, and does the same for variants
  and sequences of records, with the column-length check the contract names.
- Malformed shapes (missing or extra field, wrong type, unequal columns) are
  refused with stable errors, each with a malformed-data test.
- Host code only converts shape; it contains no allocation logic
  (`AGENTS.md` rule 6).

## Traceability

Split out of `dec.typed-records-and-variants` (Host boundary). The language
works without it; the flat stack is the stable interface.
