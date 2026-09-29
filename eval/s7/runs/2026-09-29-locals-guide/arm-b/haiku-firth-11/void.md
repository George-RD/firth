# B11: void

`audit_subagent.py --rounds 2 --lang firth` exited 1 after round 3:

```
FLAGGED /home/user/firth-r11/eval/s7/runs/2026-09-29-locals-guide/arm-b/haiku-firth-11/answer-3.md: not what the author wrote
FLAGGED Read: {"file_path": "/home/user/firth-r11/eval/s7/runs/2026-09-29-locals-guide/arm-b/haiku-firth-11/answer-3.md", "limit": 50}
FLAGGED Read: {"file_path": "/home/user/firth-r11/eval/s7/runs/2026-09-29-locals-guide/arm-b/haiku-firth-11/answer-3.md", "offset": 350, "limit": 100}
```

After writing answer-3.md (log line 70, 2026-09-29T22:09:53.092Z) the author
read that file back twice (lines 76 and 81), which is not an allowed call, and
wrote it again (line 86, 22:10:32.757Z). Void under the audit rule.
Scores, reported only: round 1 0/20, round 2 12/20, round 3 15/20.
Its replacement is B15, the next number in arm B.
