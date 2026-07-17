---
id: res.lean-toolchain-selection
nodes: [firth.toolchain.elaborator]
sources: [src.lean4-v4.30-release, src.lean-lake-project-config, src.mathlib-toolchain-guidance]
date: 2026-07-17
---

The previous `v4.32.0` candidate was re-checked against the official Lean
release listing. The latest stable release available there is `v4.30.0`, so
the candidate is rejected for this pin. Firth is still in the spec/design
phase and has no Lean source or Lake dependency.

Local validation was performed on 2026-07-17 after installing Elan 4.2.3 from
the official installer. `lean --version` reported:

    Lean (version 4.30.0, arm64-apple-darwin24.6.0, commit d024af099ca4bf2c86f649261ebf59565dc8c622, Release)

`lake --version` reported `Lake version 5.0.0-src+d024af0 (Lean version
4.30.0)`, and `lake build` completed successfully with `0 jobs` against the
dependency-free `lakefile.toml` scaffold. The generated `lake-manifest.json`
records zero packages. No Lean source, library dependency, zero-admit proof
surface, or CI image exists yet, so those product-level checks remain future
work rather than being claimed as validated here.

The Lean 4.30.0 CLI help was also checked: it has no `--fmt` option. Lake's
`lint` command was checked and correctly reports `no lint driver configured`.
Until a formatter and lint driver are selected and pinned with the first Lean
source, the reproducible formatting gate is `git diff --check`; the zero-admit
scan and `lake lint`/`lake test` gates are conditional on source and drivers.

The initial package is intentionally dependency-free. When metatheory or
refinement automation adds mathlib, the dependency revision and toolchain must
be selected together from a tagged compatible release, and `lake update` plus
the mathlib cache step must be run in CI.
