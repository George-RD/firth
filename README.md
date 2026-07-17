# Firth

Firth is a concatenative programming language in the Forth tradition whose
programs carry machine-checked guarantees. Source is elaborated through
Lean 4, where types and proof obligations are discharged, then compiled to a
minimal Forth-class target for execution.

Machine authorship is a first-class design constraint: concatenative programs
compose by concatenation, word-level granularity keeps changes small and
independent, and a mechanical checker, rather than human review, is the
arbiter of correctness.

## Status

Early development. The v0.1 kernel calculus is frozen and its core metatheory
(determinism, preservation, progress, and sequence cost invariance) is
mechanised in Lean 4 with zero admits. A reference interpreter lives under
`src/interpreter`. The elaborator,
compiler, Rust VM, and standard library are not yet implemented.

## Architecture

Four layers, specified in `files/firth-prd.md`:

1. **Language**: a kernel calculus of around a dozen combinators with typing
   rules and small-step operational semantics; a Forth-flavoured point-free
   surface syntax; a type system of stack effects with row polymorphism,
   linearity, and refinements; first-class quotations and vocabularies.
2. **Toolchain**: an elaborator embedded in Lean 4, a reference interpreter
   (the executable semantics), a compiler to a Forth-class target, a
   differential test harness, SMT integration for refinement discharge, and a
   machine-parseable agent interface.
3. **Runtime**: a minimal permissively-licensed VM with word-level
   hot-redefinition and a verified-patch protocol.
4. **Ecosystem**: a standard library written in Firth, a language server, and
   kernel and VM specifications.

Data flow:

```
source -> elaborator (type/linearity/proof checking) -> kernel terms
       -> compiler -> Forth-class target -> VM
```

The reference interpreter defines program behaviour; any compiler divergence
is a compiler bug. The trusted computing base is the Lean kernel, the SMT
solver where used, and the VM.

## Kernel model

A single value stack, no return stack, no environment, no variables.
Execution is a pure rewrite over configurations `⟨V ∣ p⟩`. Sequencing is
composition; quotations `⟦p⟧` provide all higher-order structure; recursion
comes from the dictionary, not a fixpoint combinator. Effects are modelled by
a linear `World` base type, forcing a single ordered effect thread. See
`files/firth-kernel-spec-draft.md`.

## Repository layout

| Path | Purpose |
|---|---|
| `files/` | Design specs: PRD and kernel calculus |
| `src/interpreter/` | Lean 4 reference interpreter and metatheory |
| `spec/` | Landed component specifications |
| `cairn.blueprint` | Declared architecture, governed by [cairn](https://github.com/cairn-framework/cairn) |
| `meta/` | Cairn artefacts: todos, decisions, research, sources |
| `docs/loop-runbook.md` | Autonomous development loop runbook |

## Building

The Lean toolchain is pinned to `leanprover/lean4:v4.30.0` (installed via
`elan`). From the repository root:

```sh
lake build
lake test
```

Governance checks before committing:

```sh
cairn scan       # target: zero findings
cairn hook all   # strict gate; exit 0 means the commit is safe
```

## Licence

Intended licensing is permissive (MIT/Apache-2.0) for the trusted core and
the VM. See the PRD for the licensing posture.
