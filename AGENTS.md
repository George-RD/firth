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
container for loop machinery.

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
| `cairn.blueprint` | Declared 22-node architecture: four product containers plus Governance and loop paths. |
| `cairn.config.yaml` | Cairn config (`ignore: [target]`). |
| `meta/` | Cairn artefacts. `todos/` and `contracts/` exist; `decisions/`, `research/`, `sources/`, `changes/` are created on demand. |
| `.cairn/` | Cairn state plus its authoritative guide `.cairn/AGENTS.md`. |
| `.claude/skills/` | Cairn dev-loop skills (see below). |
| `src/` | Lean components (`interpreter`, `elaborator`, `agent`, `smt`) and the Rust VM crate at `src/runtime/vm`. |

## Development Commands

The root Lake package builds the Lean components (`testDriver` is
`firthAllTest`), the Rust VM crate lives at `src/runtime/vm`, and the
control-plane tooling is operational:

```sh
cairn status          # project summary: nodes, findings, backlog. Start here.
cairn context         # structural overview of nodes/edges/findings
cairn change list     # active change proposals
cairn get <id>        # inspect a module (IDs are dotted, see cairn.blueprint)
cairn neighbourhood <id>
cairn decisions / cairn research / cairn sources <id>   # provenance chain
cairn scan            # run before committing; zero findings is the target
cairn hook all        # strict gate; exit 0 means the commit is safe
python3 tools/loop/test_select_unit.py
python3 tools/loop/test_coverage.py
python3 tools/loop/test_driver_tokens.py
python3 tools/loop/test_review_gate.py
python3 tools/loop/test_mvp_agent_gate.py
python3 tools/loop/test_mvp_agent_coverage.py
python3 tools/loop/mvp_agent_gate.py
python3 tools/loop/select_unit.py --validate
python3 tools/loop/coverage.py --validate

lake build
lake test            # driver: firthAllTest
( cd src/runtime/vm && cargo fmt --check && cargo clippy && cargo test --locked )
! rg -n '\b(sorry|admit)\b' src
git diff --check
```

For the autonomous loop launch contract and maintainer preflight, read
[`docs/loop-runbook.md`](docs/loop-runbook.md). It defines the required
`origin/main` publication, invocation, terminal tokens, and smoke checks.
Unattended operation and in-loop decision authority are governed by
`meta/decisions/loop-autonomy.md` (dec.loop-autonomy): decisions are typed,
the goal layer is immutable to the loop, and `LOOP EXHAUSTED` with
`tools/loop/coverage.py` reporting `loop_exhausted_valid: true` is completion
of the active profile in `tools/loop/obligations.toml` (dec.mvp-completion:
`mvp` = a working language an AI can use, via the agent guide, to build and
run basic applications; post-mvp rows stay visible as roadmap).

`--json` is accepted by every command for machine-readable output. The
product gates are live: `lake build` and `lake test` at the root, and the
VM crate gates (`cargo fmt --check`, `cargo clippy`, `cargo test --locked`)
from `src/runtime/vm` (no root Cargo manifest exists), alongside Cairn scan
and hook checks.

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

- Control-plane tests live in `tools/loop/test_select_unit.py`,
  `tools/loop/test_coverage.py` and `tools/loop/test_mvp_agent_gate.py`; all
  use temporary synthetic trees and never read the real tracker in fixtures.
  `tools/loop/test_mvp_agent_coverage.py` is the exception by design: it pins
  the live bindings between the obligations matrix, the manifest and the
  pinned gate, and catches a stale acceptance hash without a toolchain.
- **The pinned MVP gate** is `tools/loop/mvp_agent_gate.py`. It verifies the
  provenance manifest before executing anything, then rebuilds every
  manifest-listed application in a scratch workspace holding only that
  application's source, running elaborate, compile, VM and reference-run and
  comparing the two observations. `python3 tools/loop/coverage.py --run-gates`
  invokes it, and a failure holds `loop_exhausted_valid` false.
- Product gates are live: `lake build` / `lake test` (driver
  `firthAllTest`) and the VM crate gates from `src/runtime/vm`. The kernel
  metatheory (determinism, preservation, progress, linearity soundness,
  cost invariance) is mechanised with zero admits; the **differential test
  harness** (fuzzed compiler-vs-interpreter agreement) is specified and not
  yet implemented.
- **Governed proof modules:** `lake test` authenticates the built
  `.olean` hashes of the six governed proof modules (see
  `governedProofModules` in `src/elaborator/Firth/Refinement.lean`) against
  `src/elaborator/refinement-proof-module.sha256`. After changing any of
  them, run `lake build && python3 tools/loop/update_proof_manifest.py`
  to regenerate the manifest (`--check` verifies); otherwise the gate
  fails with "refinement proof-module hash is unavailable".
- **Before committing:** run `cairn scan` (target: zero findings) and
  `cairn hook all` (strict gate; exit 0 means safe). New/moved files must be
  reachable from a blueprint module `path` or cairn will flag them.

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
