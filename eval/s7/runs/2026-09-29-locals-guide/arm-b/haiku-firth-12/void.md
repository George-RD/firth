# B12: void

`audit_subagent.py --rounds 2 --lang firth` exited 1 after round 1:

```
FLAGGED /home/user/firth-r11/eval/s7/runs/2026-09-29-locals-guide/arm-b/haiku-firth-12/answer-1.md: not what the author wrote
```

The author wrote answer-1.md twice (log lines 32 and 38,
2026-09-29T22:05:29.612Z and 22:06:20.682Z), so the scored file is not the one
the audit ties to a single `Write`. Void under the audit rule, as A1 was.
Score so far, reported only: round 1 0/20. No feedback was sent.
Its replacement is B13, the next number in arm B.
