# Tasks: prepared-launch-authority

- [x] Author the accepted `firth.governance.loop` decision amendment that
  places ticketed prepared launch and independent runtime observation before
  normal lease grant.
- [x] Install the exact projection generated from the governed operator policy,
  including `normal.prepared-launch` and its field/predicate contract. The
  installed projection carries the prepared-launch template and the current
  policy/projection digests.
- [x] Add the prepared-launch template field set to the Firth projection
  validator. `prepare_iteration.py` enforces the exact governed normal template
  IDs and request field sets; `landing_gate.py` enforces the pinned projection
  digest/top-level schema and canonical normal-template map without a stale
  subset of IDs.
- [x] Change fresh preparation to request and reconcile prepared launch before
  lease grant, then pass only observed fresh container and cgroup identities to
  the lease request.
- [x] Add focused tests for request order, identity propagation, stale/reused
  runtime rejection, and projection compatibility.
- [x] Run the focused prepare and landing contract tests and record their
  results; do not claim broad repository gates. `test_prepare_iteration.py`
  passes 23 tests and `test_landing_gate.py` passes 17 tests.
