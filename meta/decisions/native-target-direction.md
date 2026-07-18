---
id: dec.native-target-direction
nodes:
  - firth.language.kernel
  - firth.toolchain.interpreter
  - firth.toolchain.compiler
  - firth.toolchain.diffharness
  - firth.runtime.vm
  - firth.runtime.patch
status: accepted
date: 2026-07-18
informed_by: [res.firth-prd.summary]
---
# Accepted native-target direction

## Context

The PRD commits Firth to a minimal, live-patchable VM in G5, includes the VM in
the trusted computing base in R8, and uses execution on the VM as the S5
success criterion. This makes the VM the reference execution target, but it
does not require every future deployment to retain that target.

## Decision

The minimal VM is Firth's reference execution target and remains part of the
trusted computing base. Native and bare-metal compilation targets in the
classic Forth spirit are the intended long-term direction, as ratified by the
owner on 2026-07-18.

The kernel cost table `κ` is per-target so that native and bare-metal targets
can state honest cost models without changing the verified kernel. The VM
remains the compiled side of the differential-testing baseline and the
runtime that arbitrates verified patches. The reference interpreter continues
to define program behaviour.

## Rationale

The VM supplies a small, deterministic, auditable target for compiler
validation and a runtime that can mediate dictionary updates. Keeping it as
the baseline preserves the current verification and live-patch contracts.
Treating it as the first target rather than the language platform preserves
the Forth tradition of compiling close to a native machine and keeps embedded
and bare-metal deployment open.

## Consequences

Future native targets must instantiate their own `κ` table and demonstrate
agreement with the reference interpreter. They do not displace the VM as the
baseline for differential testing or as the arbiter runtime for the verified
patch protocol. This decision records direction only; it does not add a native
target to the current implementation scope.

## Sources

- [Firth PRD, G5, R8, and S5](../../files/firth-prd.md)
- [README, "Why a VM?"](../../README.md#why-a-vm)
