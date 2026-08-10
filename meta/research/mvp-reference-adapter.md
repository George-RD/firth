---
id: res.mvp-reference-adapter
nodes: [firth.toolchain.interpreter, firth.toolchain.agent]
sources: [src.firth-kernel-spec-draft, src.firth-prd]
date: 2026-08-10
---
# MVP Reference Adapter Research

## Question

What process boundary can expose the existing Lean reference semantics to the
MVP gate without creating a second interpreter or trusting unchecked input?

## Evidence

- `Firth.Interpreter.run` is the executable semantics and already reports
  terminal, stuck, and fuel-exhausted outcomes with step and cost totals.
- `OracleResult` preserves the residual stack and program and derives World
  observations from both, while `runOracleAdapter` supplies the stable
  in-process boundary.
- `tools/loop/mvp_agent_manifest.toml` pins `firth.reference-run.v1` to
  structured JSON with request correlation, checked kernel input, initial
  stack, dictionary, Gamma version, fuel, and an observation response.
- The agent guide requires deterministic terminal status, stack, trace, cost,
  fuel, and World comparisons, and says malformed or unavailable checking
  state is a non-success state.

## Finding

A Lean executable in `src/interpreter` is the smallest trusted boundary. It can
reuse `step` directly, reject unchecked or unsupported JSON before execution,
and encode one canonical response. A host-language reimplementation would
silently create a second semantic authority and is rejected.
