# B23: void

`audit_subagent.py --rounds 2 --lang firth` exited 1 after round 1:

```
FLAGGED /home/user/firth-r11/eval/s7/runs/2026-09-29-locals-guide/arm-b/haiku-firth-23/answer-1.md: not what the author wrote
FLAGGED /home/user/firth-r11/eval/s7/runs/2026-09-29-locals-guide/arm-b/haiku-firth-23/answer-1.md: not what the author wrote
```

The author wrote answer-1.md three times (log lines 44, 51 and 57,
2026-09-29T22:30:29.282Z, 22:31:28.232Z and 22:32:26.112Z). Void under the
audit rule, as A1 and B12 were. Score, reported only: round 1 8/20. No
feedback was sent. Its replacement is B25, the next number in arm B.
