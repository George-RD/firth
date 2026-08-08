---
node: firth.language.kernel
status: open
created: 2026-08-08
---

# Trusted Computing Base Boundary
# Goal
Keep Firth's trusted computing base limited to the Lean kernel, the SMT solver where used, and the VM, while making every other component a checked artefact.

Requires: component-spec-boundaries, kernel-metatheory, pin-lean-toolchain, refinement-discharge-design, vm-target-spec

## Acceptance criteria
- Define a machine-readable inventory of the three permitted trusted components and the conditions under which the SMT solver is included.
- Classify every non-TCB component, including each compiler, elaborator, interpreter, translator, cache, harness, diagnostic, runtime image, patch, agent, standard-library, language-server, and specification component, by the artefact it emits and the check that revalidates that artefact.
- Add an automated boundary check that fails when a component or verification stage is unclassified or when an output can be accepted without Lean, SMT, or VM checking.
- Demonstrate the boundary with the existing zero-admit, Lean, SMT, and VM conformance gates without adding a trusted helper or weakening a check.

## Traceability
Satisfies PRD R8 and obligation `req-r8`.
