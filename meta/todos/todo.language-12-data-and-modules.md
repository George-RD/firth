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

## Traceability

PRD G3/G8/G9; scope-language-vocabulary-layering and scope-ecosystem-stdlib.
