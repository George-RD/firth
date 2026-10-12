---
node: firth.toolchain.agent
status: open
created: 2026-10-02
---

# Fold the harder tier's scorer back into the S7 harness

`eval/s7/harder/tier.py` copies `harness.run_firth` (to keep the runner's
measured `kernel_cost` and `vm_cost`) and builds its own prompt and repair,
because changing `eval/s7/harness.py` while S7 run 14 was pending would have
changed files that run scores with. Two copies of the runner call can drift.

## Acceptance criteria

- Once no pinned S7 run depends on the current `harness.py`, the harness
  takes task sets and step budgets as parameters and returns measured cost,
  and `tier.py` calls it instead of copying it.
- `test_mvp.py` and `test_harder.py` still pass, with the planted cases in
  each still failing.
