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
answer, made 16 calls outside its allowlist: 2 Reads and 4 Bash commands
on sample 3's sub-agent output file under `/tmp` (its task id maps to
`haiku-firth-3` in the run's id list), a read of a file of the eval
session's own saved tool output (`tool-results/bulg7e94h.txt`), and `ls`
and `find` over its own directory and the whole run directory, which
lists every sample's answer and feedback files. The audit flagged it and
the sample is void, but an author doing the same before its answer would
have seen another sample's work.

Run 10 (the control) added three more cases. One author ran `ls` on its
own directory, one used `Edit` on its own answer, and one author's final
hand-back named another author ("Control author B10") although none of
its calls could have read that name, so (inferred) sub-agents can see
something of their siblings through the session they share. The
audit also flags an author that writes its own answer file more than
once, because it compares every write with the kept file, which is
stricter than the allowlist below; an enforced allowlist should settle
whether rewriting one's own answer is allowed, and the audit should then
match it.

Close it with one of:

- Run each author in its own container or sandbox, with only its prompt,
  its feedback and its answer directory visible (the `isolate.py` model,
  without needing an API key in the sandbox).
- Or restrict the sub-agent's tools mechanically: a tool allowlist or
  permission rule that permits Read of exactly the prompt and its own
  `repair-*.md` and Write of exactly its own `answer-*.md`, and refuses
  everything else, with a planted forbidden call shown to be refused.

Not a blocker for runs 9 and 10: the audit allows exactly a Read of the
prompt and of the sample's own `repair-N.md` with N at most the number
of rounds, a Write of its own `answer-N.md` with N at most rounds + 1,
and the hand-back, and every counted sample's transcript is clean.
