# Proposal: smt-proof-region-validation

## Motivation

The proof-binding generator accepts an unpaired translation-rule region and
silently ignores malformed marker comments. Its existing idempotence test
also rewrites the tracked Lean source in place. A green drift check therefore
does not establish complete declared region coverage, and a test interruption
can leave the source modified.

This is a bounded prerequisite slice of `language-01-smt-record-admission`.
It addresses PR #109 discussions 3943502779, 3930474659 and 3930474706.

## Scope

- Reject malformed reserved marker comments and empty regions.
- Require the four established rule regions and a same-name soundness region
  for every rule, while retaining the two explicit proof-only bridge regions.
- Reject missing, duplicate and unexpected coverage before producing hashes.
- Reject unknown command-line arguments rather than entering write mode.
- Exercise write/idempotence and mutation tests only in temporary copies.

## Out of scope

The checked-result/record constructor admission redesign, transitive Lean
helper coverage, solver authentication and compiled proof admission are not
solved by this change. Marked-region hashes identify declared bytes; neither
names nor hashes establish a theorem's semantic applicability. No Lean source,
proof pin, original application corpus or acceptance threshold is changed.
