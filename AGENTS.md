# Repository Guidelines

## Project Overview

Firth is a **concatenative programming language** in the Forth tradition whose
programs carry **machine-checked guarantees**. Source is elaborated through
**Lean 4** (where types and proof obligations are discharged), then compiled to
a minimal Forth-class target for execution. Machine authorship is a first-class
design constraint: concatenative programs compose by concatenation, word-level
granularity keeps changes small and independent, and a mechanical checker
(rather than human review) is the arbiter of correctness.

Implementation is under way and machine-checked from the start. The
authoritative design material lives in `files/` as markdown specs, product
source lives under `src/` (Lean components plus the Rust VM crate), and the
architecture is governed by [cairn](https://github.com/cairn-framework/cairn).
`cairn.blueprint` declares the real 22-node architecture: four product
containers (Language, Toolchain, Runtime, Ecosystem) plus the Governance
container for the frozen loop machinery.

## Architecture & Data Flow

Four layers (per `files/firth-prd.md`):

1. **Language:** kernel calculus (~dozen combinators with typing rules and
   small-step operational semantics), Forth-flavoured point-free surface syntax,
   a type system of stack effects with row polymorphism, linearity, and
   refinements, first-class quotations, vocabularies, and specification
   predicates as words.
2. **Toolchain:** elaborator (surface into kernel terms, embedded in Lean 4),
   reference interpreter (executable semantics in Lean), compiler (kernel into
   Forth-class target), differential test harness (compiler-vs-interpreter
   agreement under fuzzing), SMT integration for refinement discharge, and a
   machine-parseable agent interface (structured diagnostics, typed holes,
   signature search by stack effect).
3. **Runtime:** minimal permissively-licensed VM with a word-level
   hot-redefinition image model and a verified-patch protocol.
4. **Ecosystem:** standard library written in Firth, language server, kernel and
   VM specifications.

**Data flow:** `source -> elaborator (type/linearity/proof checking) -> kernel
terms -> compiler -> Forth-class target -> VM`. The reference interpreter
*defines* program behaviour; any compiler divergence is a compiler bug. The
trusted computing base is limited to the Lean kernel, the SMT solver (where
used), and the VM.

**Kernel machine model** (per `files/firth-kernel-spec-draft.md`): a single
value stack `V`, no return stack, no environment, no variables. Execution is a
pure rewrite over configurations `⟨V ∣ p⟩`. Sequencing is composition;
quotations `⟦p⟧` provide all higher-order structure (`call`, `dip`); recursion
comes from the dictionary `D : Name ⇀ (WordType, Program)`, not a fixpoint
combinator. Effects are modelled by a linear `World` base type in the signature
`Σ`, forcing a single ordered effect thread; pure programs never mention
`World`. Cost is a target-specific parameter table `κ`.

## Key Directories

| Path | Purpose |
| --- | --- |
| `files/` | Design specs. `firth-prd.md` (PRD v0.1), `firth-kernel-spec-draft.md` (kernel calculus). |
| `cairn.blueprint` | Declared 22-node architecture: four product containers plus Governance (the frozen loop is under `archive/`). |
| `cairn.config.yaml` | Cairn config (`ignore: [target]`). |
| `meta/` | Cairn artefacts. `todos/` and `contracts/` exist; `decisions/`, `research/`, `sources/`, `changes/` are created on demand. |
| `.cairn/` | Cairn state plus its authoritative guide `.cairn/AGENTS.md`. |
| `.claude/skills/` | Cairn dev-loop skills (see below). |
| `src/` | Lean components (`interpreter`, `elaborator`, `agent`, `smt`) and the Rust VM crate at `src/runtime/vm`. |

## Current focus (read first)

The autonomous loop and its gate machinery are **frozen** as of 27 September
2026 (`archive/loop/README.md`). Do not revive it, extend it, or add new
governance, evidence or attestation tooling unless the maintainer asks.
Work goes to the language itself: see `docs/roadmap.md`, especially
"Goal status", which says which PRD goals are honestly met and which are open.

## Development Commands

```sh
lake build
lake test            # driver: firthAllTest
lake exe firthRecordIntegrityTest   # record drift, staleness and tampering
lake exe firthAdapterIntegrationTest # the SMT slice end to end
( cd src/runtime/vm && cargo fmt --check && cargo clippy && cargo test --locked )
python3 tools/loop/check_zero_admit.py      # no sorry/admit in Lean
python3 tools/loop/update_smt_proof_bindings.py --check  # rerun without --check after any Lean edit
python3 tools/loop/check_smt_attestation.py
python3 tools/loop/firth_run.py check <file.firth>
python3 tools/loop/firth_run.py run <file.firth> --entry <word>
python3 tools/loop/check_language_examples.py
python3 tools/loop/mvp_agent_gate.py
for t in tools/loop/test_*.py; do python3 "$t"; done
git diff --check
```

`tools/loop/` keeps its name for now because `src/` refers to paths in it;
everything left there is a product check or the runner, not loop machinery.
Cairn (`cairn status`, `cairn scan`, `cairn hook all`) still describes the
architecture, but its CI job now runs only on manual dispatch.

## Code Conventions & Common Patterns

- **The graph is the source of truth**, not scratch notes, `docs/`, or memory.
  Query cairn for status and rationale; never infer state from freeform text.
- **Every source file (tests included) must fall under a module `path` in
  `cairn.blueprint`.** If none fits, extend a module's paths or declare a new
  module before writing the file.
- **Artefacts live FLAT** under `meta/decisions/`, `meta/research/`,
  `meta/sources/` (no subfolders). Filenames are slug-only (`<slug>.md`); the
  typed prefix (`dec.`/`res.`/`src.`) lives only in the `id:` frontmatter.
  Namespace by slug in the id (`res.gas-city.analysis` gives
  `gas-city.analysis.md`).
- **Todos are the exception:** `meta/todos/todo.<slug>.md`, scaffolded via
  `cairn todo new <slug> --node <id>`. Decisions scaffold via
  `cairn decision new <slug>`.
- **Non-artefact material** (docs, specs, PDFs) enters provenance only as a
  `source` citation, never inline its content as a typed artefact.
- **British spelling** (artefact, colour, neighbourhood, reconcile); **no
  em-dashes** in user-facing copy.
- **Kernel naming** (from the spec): kernel atoms are lowercase (`dup`, `drop`,
  `swap`, `dip`, `call`, `compose`, `quote`, `if`); primitives are `prim π`;
  dictionary words are opaque names `w`.

## Important Files

- `files/firth-prd.md`: top of the artefact chain: vision, 9 goals, 17
  requirements, 7 success criteria, licensing posture.
- `files/firth-kernel-spec-draft.md`: kernel calculus: atom set, typing
  judgement `D ⊢ p : Σ₁ → Σ₂`, operational semantics `⟨V ∣ p⟩ → ⟨V' ∣ p'⟩`.
- `.cairn/AGENTS.md`: authoritative cairn workflow reference.
- `.claude/skills/cairn-dev/SKILL.md`: dev-loop entry point (full command
  reference, blueprint syntax, artefact schemas, finding codes).
- `cairn.blueprint` / `cairn.config.yaml`: architecture declaration plus config.

## Runtime / Tooling Preferences

- **Stack:** Lean 4 (metatheory plus elaborator, "zero admits") and a
  minimal, permissively-licensed Rust Forth-class VM at `src/runtime/vm`.
- **cairn** is the required governance layer for all architecture changes;
  install its dev-loop skills with `cairn init` if absent.
- Toolchain pins: `lean-toolchain` (`leanprover/lean4:v4.30.0`,
  elan-managed) and `rust-toolchain.toml` (rustup-managed).

## Testing & QA

- **The MVP gate** is `tools/loop/mvp_agent_gate.py`. It verifies the
  provenance manifest, then rebuilds every manifest-listed application in a
  scratch workspace, running elaborate, compile, VM and reference-run and
  comparing the two observations. `tools/loop/test_mvp_agent_gate.py` covers
  its fail-closed behaviour with synthetic trees.
- **Record integrity** is covered by `firthRecordIntegrityTest`, which drives
  every way a discharge record can go stale, drift or be edited through the
  real rerun and the real refinement-discharge result boundary. It uses an
  injected solver runner, so it needs no solver on the host.
- **The SMT slice end to end** is covered by `firthAdapterIntegrationTest`,
  which runs each case from `checkBodyRefinements` through a bounded solver
  invocation to a diagnostic, and asserts the invocation carries the pinned
  options and bounds. It uses an injected runner and needs no solver.
- Product gates are live: `lake build` / `lake test` (driver
  `firthAllTest`) and the VM crate gates from `src/runtime/vm`. The kernel
  metatheory (determinism, preservation, progress, linearity soundness,
  cost invariance) is mechanised with zero admits. The **differential test
  harness** at `src/diffharness/harness.py` executes a bounded pure source
  campaign through the real adapters, with deterministic seeds, retained
  failures, replay and shrinking. See `src/diffharness/README.md`. This is not
  the sustained S2 campaign, effectful equivalence or a compiler theorem.
- **Governed proof modules:** `lake test` authenticates the built
  `.olean` hashes of the seven governed proof modules (see
  `governedProofModules` in `src/elaborator/Firth/Refinement.lean`) against
  `src/elaborator/refinement-proof-module.sha256`. After changing any of
  them, run `lake build && python3 tools/loop/update_proof_manifest.py`
  to regenerate the manifest (`--check` verifies); otherwise the gate
  fails with "refinement proof-module hash is unavailable".
- **Before committing:** run the development commands above. New or moved
  files should stay reachable from a blueprint module `path`.

## The Cairn Development Loop

Orient, scope, propose, implement, verify, record. Skills under
`.claude/skills/`:

- **`cairn-explore`**: navigate the graph, query project state.
- **`cairn-propose`**: capture a change (`cairn change new <name>` scaffolds
  `meta/changes/<name>/` with `proposal.md`, `design.md`, `tasks.md`) before
  writing code.
- **`cairn-apply`**: implement a change's tasks, run gates, then
  `cairn change accept <change-id>`.
- **`cairn-archive`**: `cairn change archive <change-id>` once merged.

If cairn misbehaves, record it with `cairn feedback "<what you expected vs what
happened>"` before moving on.

<!-- cairn:agent-guide-begin -->
## Cairn orientation

This project uses cairn to keep its architecture map in sync with code. Read
`.cairn/AGENTS.md` for full orientation, then follow
`.claude/skills/cairn-dev/SKILL.md` for the development loop.
<!-- cairn:agent-guide-end -->
