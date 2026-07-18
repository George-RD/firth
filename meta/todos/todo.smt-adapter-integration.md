---
node: firth.toolchain.smt
status: open
created: 2026-07-18
---

# SMT adapter integration

Requires: elaborator-refinement-discharge

## Objective

Complete the external SMT slice of the accepted refinement-discharge
architecture behind the conservative typed queue landed by
`elaborator-refinement-discharge`.

## Acceptance criteria

- Select and pin a permissively licensed, reproducible SMT solver. Bind its
  identity, version, executable digest, invocation options, resource bounds,
  and supported theory profile to every request and result.
- Implement checked adapters from the typed, normalised predicate IR through
  theory selection and SMT-LIB serialisation to bounded solver invocation and
  strict result parsing. Unsupported theories or translations must be rejected
  before invocation.
- Provide Lean-checked semantics-preservation proofs for the normaliser, VC
  generator, sort and theory encoder, every registered predicate translation,
  and the final SMT-LIB serialiser. Bind the translation-rule and proof hashes
  to the request and record.
- Create a content-addressed SMT `DischargeRecord` only for a checked adapter's
  validated `unsat` result. The record must carry every field required by
  `spec/smt/refinement-discharge-architecture.md`, and recheck must reconstruct
  the formula, validate all bindings, and rerun the selected checker.
- Treat `unknown`, timeout, resource exhaustion, malformed output, crashes,
  unsupported input, stale or mismatched evidence, and unchecked `unsat` as
  deferred non-success. Treat only a complete validated `sat` model as a
  failed refinement with a deterministic counterexample diagnostic.
- Add mutation-resistant integration tests covering checked `unsat`, validated
  `sat`, every deferred outcome, solver/profile/version drift, stale or
  tampered records, translation-proof mismatch, and enforced resource bounds.
  No unchecked solver result may become proof evidence.

## Verification

- `lake build`
- `lake test`
- `! rg -n '\b(sorry|admit)\b|TODO|unimplemented|placeholder' src/elaborator src/smt`
- `git diff --check`

## Non-goals

- Do not add a new predicate language, change refinement typing premises, or
  move refinements into the frozen kernel.
- Do not treat unsat cores as proof certificates or enlarge the trusted
  computing base beyond the pinned solver allowed by the accepted architecture.
