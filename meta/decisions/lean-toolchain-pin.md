---
id: dec.lean-toolchain-pin
nodes: [firth.toolchain.elaborator]
status: accepted
date: 2026-07-17
informed_by: [res.lean-toolchain-selection]
---

# Decision

Pin Firth's Lean host to the exact Elan toolchain
`leanprover/lean4:v4.30.0`. The root `lean-toolchain` file is authoritative.
The compatible Lake package scaffold is `lakefile.toml` with package name
`firth`, version `0.1.0`, and no default targets until Lean source lands.

This is the latest stable Lean release verified against the official Lean 4
release page on 2026-07-17. A stable release is preferred for the elaborator,
reference interpreter, and zero-admit metatheory because Lean minor releases do
not guarantee full backwards compatibility. Local validation is complete: Elan
installed the pin, `lean --version` reported Lean 4.30.0 with commit
`d024af099ca4bf2c86f649261ebf59565dc8c622`, and `lake build` succeeded against
the scaffold. Mathlib is not currently relevant because Firth has no dependency
or Lean source yet. If mathlib becomes necessary, add a tagged mathlib revision
that declares the same Lean toolchain and revalidate the pair before changing
this decision.

# Initial CI gate

CI must run `git diff --check` as the initial formatting/whitespace gate, run
`lake build`, and run a repository-scoped scan that fails on `sorry` or `admit`
in Lean source once source exists. Lean 4.30.0 has no built-in `--fmt` CLI
option, so a source formatter must be selected and pinned separately before a
stronger Lean-format gate is introduced. After a test driver is added, CI also
runs `lake test`; `lake lint` runs only with an explicitly configured Lake
`lintDriver`. The job must install the exact toolchain from
`lean-toolchain`, use Lake from that toolchain, and report the image/toolchain
identity. The current build validation covers toolchain resolution and the
dependency-free package scaffold; product-level library, zero-admit, lint, test,
and CI-image gates will run when their source/dependencies/drivers exist.
