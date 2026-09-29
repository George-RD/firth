# A15: void

`audit_subagent.py --rounds 2 --lang firth` exited 1 after round 2:

```
FLAGGED /home/user/firth-r11/eval/s7/runs/2026-09-29-locals-guide/arm-a/haiku-firth-15/answer-2.md: not what the author wrote
```

The author wrote answer-2.md twice (log lines 44 and 50,
2026-09-29T22:16:19.380Z and 22:17:16.939Z). Void under the audit rule, as A1
and B12 were. Scores so far, reported only: round 1 1/20, round 2 8/20.
No round-2 feedback was sent. Its replacement is A17, the next number in arm A.
