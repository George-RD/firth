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
- Still open: typed records/results and the other criteria above.

## Traceability

PRD G3/G8/G9; scope-language-vocabulary-layering and scope-ecosystem-stdlib.
