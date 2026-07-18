# Firth

Firth is a concatenative language in the Forth tradition. Programs carry
machine-checked guarantees: Lean 4 elaborates the source, discharges types and
proof obligations, and the result runs on a small Forth-class target.

Concatenation is the main composition rule. Words stay small, so changes can
be local and independent. Correctness is checked mechanically rather than
left to a code reviewer's judgement.

## Status

Firth is in early development. The v0.1 kernel calculus is frozen, and Lean 4
proves its core metatheory (determinism, preservation, and progress) with zero
admits. The Lean reference interpreter is in `src/interpreter`.

The elaborator surface parser and the canonical Rust VM bootstrap have landed.
Elaborator erasure and VM kernel execution are in progress. The compiler,
standard library, and language server are still ahead.

## Architecture

The project has four layers. The detailed design is in `files/firth-prd.md`.

1. **Language**: a kernel calculus of around a dozen combinators, with typing
   rules and small-step operational semantics; a Forth-flavoured point-free
   surface syntax; stack-effect types with row polymorphism, linearity, and
   refinements; plus first-class quotations and vocabularies.
2. **Toolchain**: an elaborator embedded in Lean 4, a reference interpreter,
   a compiler to a Forth-class target, differential tests, SMT support for
   refinement discharge, and a machine-parseable agent interface.
3. **Runtime**: a small permissively licensed VM with word-level
   hot-redefinition and a verified-patch protocol.
4. **Ecosystem**: a standard library written in Firth, a language server, and
   specifications for the kernel and VM.

The intended flow is:

```
source -> elaborator (type, linearity, and proof checking) -> kernel terms
       -> compiler -> Forth-class target -> VM
```

The reference interpreter defines program behaviour. If a compiler disagrees
with it, the compiler is wrong. The trusted computing base is the Lean kernel,
the SMT solver when it is used, and the VM.

## Why a VM?

The VM is not the Firth language, and it is not the product. It is the first
execution target. We are keeping it deliberately small so the trusted base,
Lean kernel plus SMT solver plus VM, stays small enough to audit.

The Lean reference interpreter defines behaviour, and the compiler is
fuzz-checked against it. That comparison needs a deterministic executor.
Word-level hot redefinition and the verified-patch protocol also need a
runtime that mediates the dictionary instead of letting updates bypass it.

This is not a Java-style claim that the platform is the VM. Native and
bare-metal targets, in the classic Forth spirit, are still the intended future.
The kernel's cost table `kappa` is per-target for exactly this reason.

VM here means Firth's small reference execution target, not a development
sandbox. If you want an isolated environment, such as a container or an Apple
VM, to experiment in safely, that is a separate and sensible layer on top. It
does not change the language or its targets.

## Kernel model

There is one value stack: no return stack, environment, or variables. Execution
is a pure rewrite over configurations `⟨V ∣ p⟩`. Sequencing is composition;
quotations `⟦p⟧` provide the higher-order structure; and recursion comes from
the dictionary, not a fixpoint combinator. Effects use a linear `World` base
type, which forces one ordered effect thread. See
`files/firth-kernel-spec-draft.md`.

## Repository layout

| Path | Purpose |
|---|---|
| `files/` | Design specs: PRD and kernel calculus |
| `src/interpreter/` | Lean 4 reference interpreter and metatheory |
| `src/elaborator/` | Lean 4 surface parser and erasure (in progress) |
| `src/runtime/vm/` | Canonical Rust VM (bootstrap landed, execution in progress) |
| `spec/` | Landed component specifications |
| `cairn.blueprint` | Declared architecture, governed by [cairn](https://github.com/cairn-framework/cairn) |
| `meta/` | Cairn artefacts: todos, decisions, research, sources |
| `docs/loop-runbook.md` | Autonomous development loop runbook |

## Building

The Lean toolchain is pinned to `leanprover/lean4:v4.30.0` and installed via
`elan`. From the repository root:

```sh
lake build
lake test
```

Before committing, run the governance checks:

```sh
cairn scan       # target: zero findings
cairn hook all   # strict gate; exit 0 means the commit is safe
```

## Licence

The intended licence for the trusted core and VM is permissive:
MIT/Apache-2.0. See the PRD for the full licensing posture.
