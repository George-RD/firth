# Design: smt-proof-region-validation

## Approach

Reserve line comments beginning with `-- firth:` for exact region delimiters.
Treat malformed marker-like lines as errors even outside an open region.
Continue hashing region bodies in file/position order, without changing bytes
or the generated layout for valid current sources.

Require `encoder`, `serialiser`, `normaliser` and `vc-generator` rule regions.
Require each rule to have a same-name soundness region. Permit new paired
stages, but permit only `adapter` and `normaliser-validity` as proof-only
regions; both remain mandatory. This preserves the real four-rule/six-proof
layout rather than incorrectly demanding equal rule and proof sets.

Use strict argument parsing and require one unambiguous bindings declaration.
Validate the complete input before writing. Tests construct isolated source
trees and copy the real sources for the write-mode fixed-point check.

## Delta

MODIFIED:
- `tools/loop/update_smt_proof_bindings.py`
- `tools/loop/test_smt_proof_bindings.py`

These files already belong to `firth.governance.loop`; no blueprint change is
needed. SMT admission remains owned by `firth.toolchain.smt`.

## Verification

First run the new regression tests against the original generator and retain
failing cases. Then rerun the full Python suites and the read-only source
proof-binding checks. The final candidate must also pass the existing Lean,
Rust and Cairn CI. Do not mark the parent admission task complete or merge
PR #109 on the strength of this narrower check.
