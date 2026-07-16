---
id: dec.agent-diagnostic-envelope
nodes: [firth.toolchain.agent]
status: accepted
date: 2026-07-17
informed_by: [res.firth-prd.summary]
---

# Decision

Define the agent interface as a versioned JSON envelope. Diagnostics, typed-hole
reports, and signature-search messages use the same top-level identity and
version fields, while their kind-specific bodies remain separate. This is an
interface contract for elaborator and editor boundaries, not a representation
of kernel terms or elaborator internals.

The first envelope version is `1.0`. Implementations shall emit
`schema_version` on every payload. Version `1.x` permits additive optional
fields, new diagnostic codes, and new enum values with their documented
meanings only. A breaking change requires a new major version. Consumers shall
ignore unknown optional fields and preserve unknown values when forwarding a
payload. Required fields cannot be removed, renamed, or have their meaning
changed within a major version.

## Common envelope

Every payload is a JSON object with these fields:

```json
{
  "schema_version": "1.0",
  "payload_kind": "diagnostic",
  "payload_id": "diag-01JEXAMPLE",
  "request_id": "req-01JEXAMPLE",
  "body": {}
}
```

`schema_version`, `payload_kind`, `payload_id`, `request_id`, and `body` are
required. IDs are opaque strings, stable within the request, and must not
encode source locations or array positions. `request_id` links all messages
from one tool request. A producer may add `producer` and `capabilities` as
optional metadata, but these are not used for semantic interpretation.

## Locations and linkage

Locations use one-based line and column numbers and half-open ranges. A URI is
preferred over a machine-local path, but a path is permitted when no URI is
available.

```json
{
  "uri": "file:///workspace/main.fth",
  "path": "main.fth",
  "range": {
    "start": {"line": 4, "column": 9},
    "end": {"line": 4, "column": 12}
  }
}
```

`uri` or `path` and `range` are required. Lines and columns are positive
integers; the end position must not precede the start. A diagnostic has one
required `location` and may have `related` entries. Each related entry has a
`relation` enum, a location, and an optional stable `payload_id`. The initial
relation vocabulary is `definition`, `origin`, `related`, `supersedes`, and
`requires-review`. New relation values are additive and must be documented
before use. `group_id` optionally groups diagnostics from one failed
operation. Group and related identifiers are links only; they do not alter
ordering or severity.

## Diagnostics

The diagnostic body is:

```json
{
  "code": "firth.type.stack-mismatch",
  "severity": "error",
  "message_key": "diagnostic.stack_mismatch",
  "message_params": {"word": "add"},
  "location": {"path": "main.fth", "range": {
    "start": {"line": 1, "column": 1},
    "end": {"line": 1, "column": 2}
  }},
  "cause": {"kind": "type-checking", "data": {}},
  "expected_stack": {"encoding": "opaque", "value": {}},
  "actual_stack": {"encoding": "opaque", "value": {}},
  "obligations": [],
  "proposed_fixes": [],
  "related": [],
  "group_id": "typecheck-01"
}
```

`code` is a permanent machine contract. It has the form
`firth.<namespace>.<condition>`. Codes are never removed or repurposed. A
replacement condition receives a new code, and an old code may be deprecated
but remains recognisable. The initial taxonomy reserves `type`, `linearity`,
`refinement`, `elaboration`, `syntax`, `name`, `search`, and `protocol`
namespaces. Code registries may add conditions without changing existing ones.

`severity` is one of `error`, `warning`, `info`, or `hint`. `message_key` and
`message_params` are localisation inputs. They keep user-facing strings out of
the contract and allow editors and agents to render their own view.

`cause` is required and has a stable `kind` plus an optional opaque `data`
object. `expected_stack` and `actual_stack` are required and may be `null` when
a diagnostic is not a stack-state comparison. `obligations` is required and
may be an empty array. When stack states are non-null, they use an opaque
encoding envelope:

```json
{"encoding": "opaque", "value": {}, "display_hint": "optional-key"}
```

The producer owns the value. Consumers must not depend on its fields. This
preserves the exact inferred state needed by an agent while the kernel and
elaborator representations are still changing.

An obligation has `obligation_id`, `kind`, `status`, and an opaque `data`
object. Status is `open`, `discharged`, `failed`, or `deferred`. An optional
`proposed_fixes` array contains `fix_id`, `kind`, `title_key`, `applicability`,
and `edits`. Each edit has a location and replacement text. Applicability is
`safe`, `needs-review`, or `stale`; edits are suggestions, never instructions
to mutate source automatically.

## Typed holes

Typed holes are a distinct payload so an editor can request completion without
parsing diagnostics. Its body requires `hole_id`, `location`,
`inferred_stack_state`, and `obligations`; the obligation list may be empty.
`expected_stack` and `actual_stack` may be included when known. The stack state
and obligation data use the same opaque envelopes as diagnostics.

```json
{
  "schema_version": "1.0",
  "payload_kind": "typed_hole",
  "payload_id": "hole-report-01",
  "request_id": "req-01",
  "body": {
    "hole_id": "hole-7",
    "location": {"uri": "file:///workspace/main.fth", "range": {
      "start": {"line": 8, "column": 5},
      "end": {"line": 8, "column": 6}
    }},
    "inferred_stack_state": {"encoding": "opaque", "value": {}},
    "obligations": [{"obligation_id": "ob-7", "kind": "refinement",
      "status": "open", "data": {}}]
  }
}
```

## Signature search

A search request body requires `query`, `page_size`, and `page`. `query` has
`stack_effect` and optional `refinements`, both opaque values supplied by the
caller or a previous tool response. `page` is a non-negative integer and
`page_size` is a positive integer no greater than 1000. An optional `cursor` is preferred
for continuation because it is opaque and cannot expose dictionary internals.

```json
{
  "schema_version": "1.0", "payload_kind": "signature_search_request",
  "payload_id": "search-req-01", "request_id": "req-02", "body": {
    "query": {"stack_effect": {"encoding": "opaque", "value": {}},
      "refinements": {"encoding": "opaque", "value": {}}},
    "page_size": 20, "page": 0
  }
}
```

A response body requires `matches`, `page`, and `page_size`, and may include
`next_cursor`. Each match has opaque `word_id`, `signature`, optional opaque
`refinements`, and a deterministic `rank`. Results are ordered by ascending
rank, then a stable lexical ordering of opaque `word_id`; ties are forbidden.
The response must report `match_kind` as `exact`, `subsumes`, or `compatible`.

```json
{
  "schema_version": "1.0", "payload_kind": "signature_search_response",
  "payload_id": "search-res-01", "request_id": "req-02", "body": {
    "page": 0, "page_size": 20, "next_cursor": null,
    "matches": [{"word_id": "math.add", "signature": {
      "encoding": "opaque", "value": {}}, "refinements": null,
      "match_kind": "compatible", "rank": 10}]
  }
}
```

## Ordering and validation

Diagnostics are deterministic for the same source, environment, and request.
Sort by the lexically ordered location source key (`uri`, otherwise `path`),
primary location start, primary location end, stable code, then
`payload_id`. Do not sort by rendered message, hash, or discovery timing.
Within a diagnostic, obligations and fixes use their stable IDs as the tie
breaker. Pagination uses the response ordering and an opaque cursor; a client
must not assume that page numbers remain valid after the dictionary changes.

Payloads are rejected when required fields are absent, `schema_version` is not
supported, IDs are duplicated within a request, a code violates the namespace
form, a location is invalid, `payload_kind` is unknown, or a page constraint
is violated. Unknown optional fields are accepted. Extensible enum values, such
as `severity`, `status`, `relation`, and `match_kind`, are accepted and
preserved so additive values remain forward-compatible. Consumers may render
an unknown enum value generically. Unknown required fields from a new major
version produce a protocol diagnostic rather than being guessed at.

The contract deliberately excludes elaborator-internal ASTs, unification
variables, kernel constructors, solver traces, and rendered prose. Such data
may be carried under an explicitly opaque optional field and can be added
without changing the envelope semantics.

## JSON diagnostic examples

The following compact examples exercise the required categories. Their
`message_key` values are illustrative localisation keys, not user-facing text.

```json
{"schema_version":"1.0","payload_kind":"diagnostic","payload_id":"d1","request_id":"r1","body":{"code":"firth.type.stack-mismatch","severity":"error","message_key":"diagnostic.stack_mismatch","message_params":{},"location":{"path":"main.fth","range":{"start":{"line":2,"column":1},"end":{"line":2,"column":4}}},"cause":{"kind":"type-checking","data":{}},"expected_stack":{"encoding":"opaque","value":{}},"actual_stack":{"encoding":"opaque","value":{}},"obligations":[],"proposed_fixes":[]}}
{"schema_version":"1.0","payload_kind":"diagnostic","payload_id":"d2","request_id":"r1","body":{"code":"firth.linearity.unconsumed-resource","severity":"error","message_key":"diagnostic.unconsumed_resource","message_params":{},"location":{"path":"main.fth","range":{"start":{"line":3,"column":1},"end":{"line":3,"column":5}}},"cause":{"kind":"linearity","data":{}},"expected_stack":null,"actual_stack":null,"obligations":[],"proposed_fixes":[]}}
{"schema_version":"1.0","payload_kind":"typed_hole","payload_id":"h1","request_id":"r2","body":{"hole_id":"h-1","location":{"path":"main.fth","range":{"start":{"line":4,"column":1},"end":{"line":4,"column":2}}},"inferred_stack_state":{"encoding":"opaque","value":{}},"obligations":[]}}
{"schema_version":"1.0","payload_kind":"signature_search_response","payload_id":"s1","request_id":"r3","body":{"page":0,"page_size":10,"next_cursor":null,"matches":[{"word_id":"math.add","signature":{"encoding":"opaque","value":{}},"refinements":null,"match_kind":"exact","rank":0}]}}
```

This envelope fulfils R12, R13, and R16 and supports G8 and S7. It remains
reversible because implementation-specific detail is behind opaque fields and
all future additions are optional and additive.
