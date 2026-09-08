# Design: smt-record-promotion

`makeDischargeRecord` takes an unpromoted result and calls `checkUnsat` itself.
It cannot be reached successfully using a public `checkedUnsat` marker, even
one previously returned by `checkUnsat`. The constructor derives the record
from the same request that passed profile, identity, fragment and proof-binding
validation. Callers no longer split promotion from record construction.

The refinement rerun result boundary rechecks a record against the current
canonical obligation before exposing it. Changed obligation identities,
formulae, profiles, scripts and proof bindings fail closed with existing stable
deferred diagnostics. This recheck is necessary but is not proof of a rerun.

No translation rule or theorem is changed. Source-region hashes must stay
unchanged. The six-module compiled manifest is regenerated only from the
intentional source changes using the pinned Lean build, with the resulting
diff retained for review. No original source corpus or authoring input changes.
