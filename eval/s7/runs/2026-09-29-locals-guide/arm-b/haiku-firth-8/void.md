# B8: void

`audit_subagent.py --rounds 2 --lang firth` exited 1 after round 2 (answer-2.md):

```
FLAGGED /home/user/firth-r11/eval/s7/runs/2026-09-29-locals-guide/arm-b/haiku-firth-8/answer-2.md: not what the author wrote
FLAGGED Edit: {"replace_all": false, "file_path": "/home/user/firth-r11/eval/s7/runs/2026-09-29-locals-guide/arm-b/haiku-firth-8/answer-2.md", "old_string": "                [ stock item-idx curr-stock prim seq-int
FLAGGED Edit: {"replace_all": false, "file_path": "/home/user/firth-r11/eval/s7/runs/2026-09-29-locals-guide/arm-b/haiku-firth-8/answer-2.md", "old_string": ": allocate\n  (forall \u03c1; \u03c1 stock:Seq Int^many 
FLAGGED Edit: {"replace_all": false, "file_path": "/home/user/firth-r11/eval/s7/runs/2026-09-29-locals-guide/arm-b/haiku-firth-8/answer-2.md", "old_string": "```\n\nNOTE: For allocate-batch, I used \"locally\" inst
FLAGGED Edit: {"replace_all": false, "file_path": "/home/user/firth-r11/eval/s7/runs/2026-09-29-locals-guide/arm-b/haiku-firth-8/answer-2.md", "old_string": "### task: longest-run\n```firth\n: main\n  (forall \u03c
```

After writing answer-2.md (log line 47, 2026-09-29T22:01:09.473Z), the author
called `Edit` on it four times (log lines 52, 59, 65, 70). `Edit` is not an
allowed call (preregistration.md, "Validity of a sample"), and the scored file
is not what its `Write` produced. Void under the audit rule, as run 10's B9 was.
Scores so far, reported only: round 1 2/20, round 2 13/20 (with the edits).
Its replacement is B10, the next number in arm B. No round-2 feedback was sent.
