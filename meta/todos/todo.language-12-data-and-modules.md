---
node: firth.ecosystem.stdlib
status: open
created: 2026-09-08
---

Requires: language-11-arithmetic-comparison

## Goal

Make bounded application data and reusable vocabularies practical.

## Acceptance criteria

- Provide the minimum typed records/results/bounded sequence representation needed for the consumer, through existing kernel facilities where possible.
- Support reusable multi-file vocabularies with deterministic imports, explicit exports and stable errors. Do not hide the algorithm in a host-language primitive.
- Define ownership, bounds, termination and serialization at the host boundary; any required frozen-spec extension needs a separate accepted decision and proof gates.
- Add core library examples, malformed-data tests and differential coverage. Do not start a package registry or general framework.

## Progress

- Multi-file vocabularies: `import "path";` and `export name ...;`, with
  deterministic load order and stable `firth.name.*` errors
  (`dec.multi-file-imports`). `examples/inventory/policy-change/` clients
  import `allocator.firth`.
- 13 October 2026: design for typed records and results in
  `dec.typed-records-and-variants`. No kernel change: `record` and `variant`
  types erase to flat stack values, sequences of scalar-flat records to
  columns. Planned PRs: records, variants with `match`, sequences of records,
  then the agent guide and S7 inputs.
- 29 October 2026: the first records PR (declarations, `pack`/`unpack`, field
  read and set, flat word types, the nominal and field diagnostics, the
  structural atoms on records, `examples/programs/records.firth`). Records are
  file-local: the next records PRs add the import and export of types with the
  layer identity and proof-record digests the decision requires. Until then
  `firth.name.export-type-unsupported` refuses those uses; a word whose stack effect names a record is refused at
  `export` too. The scalar-type gap in `pack`/`unpack` is
  `todo.record-scalar-type-tracking`.
- 29 October 2026: record locals (second records PR). `locals { s }` over a
  record binds its flat slots (`s.on-hand`), `s` and `s.f` read the whole record
  or a field, and `examples/programs/record-locals.firth` runs on the VM and
  the reference interpreter. `firth.type.locals-record-unsupported` is gone.
- Still open: typed records and results (the first criterion) and bounded
  sequences of records, both through the planned PRs; the host-boundary
  definition of ownership, bounds, termination and serialization (partly
  `todo.host-record-values`); core library examples; malformed-data tests;
  and differential coverage (VM against reference interpreter). The
  multi-file criterion is met by the import work above.
- Known gap from the design: a record or variant with an imported member type
  cannot be exported, because exports are non-transitive and the design adds
  no type re-export (`firth.name.export-imported-member`). Re-export of types
  is a follow-up once a consumer needs it.

## Traceability

PRD G3/G8/G9; scope-language-vocabulary-layering and scope-ecosystem-stdlib.
