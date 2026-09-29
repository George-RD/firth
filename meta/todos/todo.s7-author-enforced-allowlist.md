---
node: firth.toolchain.agent
status: open
created: 2026-09-29
---

# Enforce the S7 author allowlist instead of only auditing it

S7 authors run as sub-agents of the eval session (no API key, so not
`isolate.py run`). They are told to use only Read on their prompt and
feedback and Write on their own answer, but nothing stops another call:
they share the session's shell, files and task outputs. The transcript
audit (`audit_subagent.py`) catches a forbidden call after the fact, and a
flagged sample is void, but it cannot keep the author from seeing
something.

Run 9 showed this is not hypothetical. Sample 4, after writing its last
answer, ran 14 Bash commands and read sample 3's sub-agent output file
under `/tmp`. The audit flagged it and the sample is void, but an author
doing the same before its answer would have seen another sample's work.

Close it with one of:

- Run each author in its own container or sandbox, with only its prompt,
  its feedback and its answer directory visible (the `isolate.py` model,
  without needing an API key in the sandbox).
- Or restrict the sub-agent's tools mechanically: a tool allowlist or
  permission rule that permits Read of exactly the prompt and its own
  `repair-*.md` and Write of exactly its own `answer-*.md`, and refuses
  everything else, with a planted forbidden call shown to be refused.

Not a blocker for run 9: the audit's allowlist is the prompt plus the
sample's own directory, and every counted sample's transcript is clean.
