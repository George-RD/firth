# B4: cross-sample items after the last answer (reported, not voiding)

`context_seen.py --arm-set run11 --arm arm-b --sample haiku-firth-4 --label B4`
exited 1 with five `cross_sample` items:

    CROSS-SAMPLE line 81 attachment:task_status 2026-09-29T21:54:27.190Z  (A6, running)
    CROSS-SAMPLE line 82 attachment:task_status 2026-09-29T21:54:27.190Z  (B5, running)
    CROSS-SAMPLE line 83 attachment:task_status 2026-09-29T21:54:27.190Z  (B6, completed)
    CROSS-SAMPLE line 84 attachment:task_status 2026-09-29T21:54:27.190Z  (A7, completed)
    CROSS-SAMPLE line 85 attachment:task_status 2026-09-29T21:54:27.190Z  (A8, running)

The author's last `Write` of `answer-3.md` is at log line 71,
2026-09-29T21:53:46.104Z. All five items arrived 41 seconds later, during a
context compaction before its hand-back, and each is timed. Under
preregistration.md ("Validity of a sample") an item that arrives after the
last answer cannot change a scored answer, so it is reported and B4 is not
void. The author made no call after that Write other than the hand-back.
