# Design: public-source-tests

A `firth.tests.v1` JSON suite names one source file relative to the suite and
1 to 128 ordered cases. Each case supplies a unique display name, an explicit
entry, an input stack and an expected output stack. Unknown or duplicate JSON
members, non-portable values, missing fields and empty suites fail before a
build. Suite bytes and stack lengths are bounded. Names never become paths.
The source must decode as UTF-8 before the build, and it is read once: every
case runs from that snapshot, so edits during a run cannot mix versions.

Build once, then use the existing `mvp_agent_gate.rebuild` in separate scratch
workspaces. It re-elaborates the snapshotted source, independently rechecks
compiler admission, runs the VM and reference interpreter and compares their
observations. The test adds an exact typed expected-stack comparison, so a
Boolean cannot pass as an integer. No generated oracle or expected-output
update command is provided.

A suite returns one ordered JSON report and exits nonzero if any case fails.
Execution failures and inconclusive fuel exhaustion are failures, never passes.
The existing quotation-trace limitation remains visible per case. These finite
examples do not establish source contracts, compiler correctness or agent
usability. Reuse the current CLI, test discovery and documented-example CI gate;
add no dependency, framework or new workflow.
