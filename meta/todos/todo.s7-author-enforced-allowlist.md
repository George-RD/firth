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
hand-back named another author ("Control author B10"). Its raw log
shows the harness injected a `task_status` attachment for B10's task,
including the path of B10's output log, into its context
(`eval/s7/runs/2026-09-29-control/8ea4a1d/haiku-firth-8/handback.txt`).
It made no call on that path, but an author that did would read another
sample's work; the allowlist has to block that path too. Until it does,
`eval/s7/context_seen.py` lists what each author was shown and flags any
item naming another sample. It also found that the harness names both
worktrees to every author (a skill listing scoped to `firth-r8/` and
`firth-v9/`, and for two arm B authors a working directory in arm A's
worktree); an enforced sandbox should show each author only its own
arm's tree. The
audit also flags an author that writes its own answer file more than
once, because it compares every write with the kept file, which is
stricter than the allowlist below; an enforced allowlist should settle
whether rewriting one's own answer is allowed, and the audit should then
match it.

Run 11 (`eval/s7/runs/2026-09-29-locals-guide/`) was the first time an
author acted on the harness's `task_status` channel. Forty seconds after
its last answer, A14 was shown `task_status` items naming five other
authors. It then read A15's raw output log and ran `tail` on it (log
lines 95 and 101 of its log, `arm-a/haiku-firth-14/void.md`). The audit
voided it. Had the compaction that injects these items come before its
last answer, it could have read another sample's work first. A13 and B4
were shown the same kind of item after their last answers and made no
call. Eight of run 11's nine voids were authors rewriting, editing or
re-reading their own answer file, which the allowlist below would permit
and the audit flags, so settling that rule matters for the void rate.

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
