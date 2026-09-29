# A22: void

`audit_subagent.py --rounds 2 --lang firth` exited 1 after round 1:

```
FLAGGED /home/user/firth-r11/eval/s7/runs/2026-09-29-locals-guide/arm-a/haiku-firth-22/answer-1.md: not what the author wrote
FLAGGED /home/user/firth-r11/eval/s7/runs/2026-09-29-locals-guide/arm-a/haiku-firth-22/answer-1.md: not what the author wrote
FLAGGED Read: {"file_path": "/home/user/firth-r11/eval/s7/runs/2026-09-29-locals-guide/arm-a/haiku-firth-22/answer-1.md", "limit": 100}
```

The author wrote answer-1.md three times (log lines 26, 32 and 38,
2026-09-29T22:31:47.110Z, 22:32:29.533Z and 22:33:14.004Z), then read it
back (line 44, 22:33:16.263Z). Void under the audit rule, as A1 and B23
were. Score, reported only: round 1 0/20. No feedback was sent. Its
replacement is A24, the next number in arm A.
