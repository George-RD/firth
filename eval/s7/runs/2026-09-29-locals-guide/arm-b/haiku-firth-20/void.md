# B20: void

`audit_subagent.py --rounds 2 --lang firth` exited 1 after round 3:

```
FLAGGED /home/user/firth-r11/eval/s7/runs/2026-09-29-locals-guide/arm-b/haiku-firth-20/answer-3.md: not what the author wrote
```

The author wrote answer-3.md twice (log lines 64 and 70,
2026-09-29T22:26:38.829Z and 22:27:19.199Z). Void under the audit rule, as
A1, A15 and B12 were. Scores, reported only: round 1 0/20, round 2 11/20,
round 3 16/20. Its replacement is B23, the next number in arm B.
