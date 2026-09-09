---
id: dec.diffharness-portable-driver
nodes:
  - firth.toolchain.diffharness
status: accepted
date: 2026-09-09
refines:
  - dec.diffharness-fuzz-strategy
---
# Portable differential driver

Implement the initial pure source-level driver in Python rather than adding a
second Lean executable for process orchestration. Reuse the checked public
adapters and strict portable observation rules already used by the executable
MVP gate. Lean remains the reference semantics and every generated or reduced
source is elaborated by the actual Lean checker before execution.

This is a derived implementation choice under the authorised M0 roadmap. It
changes neither the kernel nor the original acceptance corpus, obligations or
success criteria. It avoids moving a process driver into governed proof code
and can exercise its failure handling without a Lean installation.

Retain deterministic source, inputs and binary identities, explicit exhaustion,
separate kernel/VM costs, bounded shrinking and real-host CI from the original
strategy. The small portable campaign covers no linear World effects or
returned quotation equivalence and is not sustained S2 evidence. A later
kernel-level or effectful generator remains governed by the original strategy.
