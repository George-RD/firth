# Tasks: runtime-conformance-closure

- [x] Render quotations and frames in full; add the unsupported verdict and
      the legacy projection rule; lift the single root frame of the corpus.
- [x] Report per-event charges, frames, trap subcodes, full quotation payloads
      and the admission label from the adapter and the CLI.
- [x] Compare traces event by event in the gate, harness and S5 witness;
      bind the manifest contract; prove both S5 branches from the traces.
- [x] Cap call depth and fuel, bound the checkpoint and both readers, fix the
      transport, refuse consumed bits and unchecked envelopes.
- [x] Add the subprocess-deadline bounds gate, pin it in CI, and reproduce
      every defect on the unchanged head.
- [x] Update the target contract, docs, todo and this record.

Branch verification only; merged-main acceptance and the authenticated
evidence admission tracked by `patch-refinement-evidence-admission` remain
separate claims.
