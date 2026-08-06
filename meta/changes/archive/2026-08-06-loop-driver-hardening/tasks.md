# Tasks: loop-driver-hardening

- [x] Record the accumulated driver contract as dec.loop-driver-contract.
- [x] Acknowledge merged PRs #39-#46 with their smoke evidence in the decision's Rationale.
- [x] Land per-iteration prompt freshness (fetch + git show from origin/main) in the driver.
- [x] Verify: prompt-freshness happy path injects origin/main's command bytes, fetch-failure path stops rc 3 with its message, full stop-path matrix re-run green, cairn scan zero Errors, cairn hook all exit 0.
