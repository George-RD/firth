# Design

## Modified

The source pipeline refuses every untranslatable refinement before erasure,
with a source-located diagnostic, and refuses empty programs. The compiler
refuses pushed linear quotations it cannot represent. The VM validates capture
and consumed-vector length before encoding or hashing recursively.

The changes add no kernel semantics and modify no governed proof module.
Existing raw evidence claims remain tracked under compiler and SMT admission.
The real-process regression gate includes ordinary positive cases so rejecting
all inputs cannot satisfy it. It checks specific refusal codes and fails on
crashes, timeouts and disabled Python assertions.

## Added

A maintainer-authorised roadmap and active implementation todos make known
work visible to the existing selector. Existing design todos are not falsified
or erased; implementation obligations now require additional real work.
Independent inventory cases define the first consumer without pretending that
a host reference model is a Firth application.

## Verification

Test-only commits precede the fixes. Retain the corrected red run and the final
green run. Require all existing language tests, new trust tests, source and
compiled proof-binding checks, fixture consistency, Cairn and coverage gates.
Full-profile exhaustion is not a CI merge prerequisite while roadmap work is
open; missing or failing executable acceptance gates still fail CI.
