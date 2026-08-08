---
node: firth.language.kernel
status: open
created: 2026-08-08
---

# Kernel Trusted Computing Base Boundary
# Goal
Constrain the trusted computing base to the Lean kernel, the SMT solver when used, and the VM, with every other Firth artefact checked explicitly.

Requires: kernel-metatheory

## Acceptance criteria
- Define the trusted computing base boundary and the checked-artefact obligations for the kernel, elaborator, compiler, interpreter, and VM interfaces.
- Identify the exact assumptions admitted at each boundary and ensure non-trusted artefacts are validated rather than trusted by convention.
- Add executable Lean checks covering representative checked artefacts and rejection of an unchecked assumption.
- Keep the zero-admit check passing with no `sorry`, `admit`, or `axiom`.

## Traceability
Satisfies PRD R8 and obligation `req-r8`.
