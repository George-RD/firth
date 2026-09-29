# A14: void

`audit_subagent.py --rounds 2 --lang firth` exited 1 on the complete log:

```
FLAGGED Read: {"file_path": "/tmp/claude-0/-home-user/8303955b-b8e6-5ad0-99b0-7583acb11fc5/tasks/a239488f895ed4037.output"}
FLAGGED Bash: {"command": "tail -100 /tmp/claude-0/-home-user/8303955b-b8e6-5ad0-99b0-7583acb11fc5/tasks/a239488f895ed4037.output"}
```

`context_seen.py --arm-set run11 --arm arm-a --sample haiku-firth-14 --label A14`
also exited 1:

```
CROSS-SAMPLE line 77 attachment:task_status 2026-09-29T22:17:42.014Z
CROSS-SAMPLE line 78 attachment:task_status 2026-09-29T22:17:42.014Z
CROSS-SAMPLE line 79 attachment:task_status 2026-09-29T22:17:42.014Z
CROSS-SAMPLE line 80 attachment:task_status 2026-09-29T22:17:42.014Z
CROSS-SAMPLE line 81 attachment:task_status 2026-09-29T22:17:42.014Z
CROSS-SAMPLE line 102 tool_result 2026-09-29T22:17:58.018Z
```

Sequence: the author wrote answer-3.md (log line 67, 22:17:02.675Z). At
22:17:42 the harness injected task_status attachments naming A15 (completed),
A16, B16, B17 and B18 (lines 77-81). The author then read A15's raw output log
(line 95, a Read) and ran `tail` on it (line 101, a Bash call), before its
hand-back.

Everything happened after the last answer, so under the context rule alone the
items would be reported, not voiding. The audit rule has no timing exception:
any flagged call voids the sample (preregistration.md, "Validity of a
sample"), so A14 is void, applied as written. Scores, reported only: round 1
0/20, round 2 4/20, round 3 4/20. Its replacement is A18, the next number in
arm A.

This is the first sample in which a harness task_status attachment led an
author to open another author's log. It is recorded for the write-up and
todo.s7-author-enforced-allowlist.
