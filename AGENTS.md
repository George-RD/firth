# Repository Guidelines

## Project Overview

Firth is a **concatenative programming language** in the Forth tradition whose
programs carry **machine-checked guarantees**. Source is elaborated through
**Lean 4** (where types and proof obligations are discharged), then compiled to
a minimal Forth-class target for execution. Machine authorship is a first-class
design constraint: concatenative programs compose by concatenation, word-level
granularity keeps changes small and independent, and a mechanical checker
(rather than human review) is the arbiter of correctness.

The repo is currently in a **spec/design phase, with no source code yet.**
The authoritative material lives in `files/` as markdown specs, and the
architecture is governed by [cairn](https://github.com/cairn-framework/cairn).
`cairn.blueprint` declares the real 22-node architecture: four product
containers (Language, Toolchain, Runtime, Ecosystem) plus the Governance
container for loop machinery. The repository remains in the no-`src/`
spec/design phase.

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
| `src/` | Referenced by the blueprint but **does not exist yet.** |

## Development Commands

There is no product source or Lake project yet, but the control-plane tooling is
operational. The current commands are selector, coverage, and Cairn governance
checks; Lean gates are staged for when a root `lakefile.toml` or
`lakefile.lean` lands:

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
python3 tools/loop/select_unit.py --validate
python3 tools/loop/coverage.py --validate
```

For the autonomous Codex loop launch contract and maintainer preflight, read
[`docs/loop-runbook.md`](docs/loop-runbook.md). It defines the required
`origin/main` publication, invocation, terminal tokens, and smoke checks.

`--json` is accepted by every command for machine-readable output. Once a Lake
project lands, the staged gates are `lake build` and `lake test` when a test
driver is configured, alongside Cairn scan and hook checks.

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

- **Intended stack:** Lean 4 (metatheory plus elaborator, "zero admits"), plus a
  minimal, permissively-licensed Forth-class VM. Not yet implemented.
- **cairn** is the required governance layer for all architecture changes;
  install its dev-loop skills with `cairn init` if absent.
- No package manager or runtime is pinned yet. Set this once code lands.

## Testing & QA

- Control-plane tests live in `tools/loop/test_select_unit.py` and
  `tools/loop/test_coverage.py`; both use temporary synthetic todo trees and
  never read the real tracker in fixtures.
- Product source is not present yet. The kernel spec calls for a **differential test
  harness** (fuzzed programs checked for compiler-vs-interpreter agreement) and
  **Lean metatheory obligations** (determinism, preservation, progress,
  linearity soundness, cost invariance) mechanised with zero admits.
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
