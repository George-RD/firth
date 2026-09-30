# A13: cross-sample items after the last answer (reported, not voiding)

`context_seen.py --arm-set run11 --arm arm-a --sample haiku-firth-13 --label A13`
exited 1 with five `cross_sample` items:

    CROSS-SAMPLE line 85 attachment:task_status 2026-09-29T22:13:50.378Z  (A14, running)
    CROSS-SAMPLE line 86 attachment:task_status 2026-09-29T22:13:50.378Z  (B15, running)
    CROSS-SAMPLE line 87 attachment:task_status 2026-09-29T22:13:50.378Z  (A15, running)
    CROSS-SAMPLE line 88 attachment:task_status 2026-09-29T22:13:50.378Z  (B14, running)
    CROSS-SAMPLE line 89 attachment:task_status 2026-09-29T22:13:50.378Z  (B16, running)

The author's last `Write` of `answer-3.md` is at log line 75,
2026-09-29T22:13:14.395Z. All five items arrived 36 seconds later, during a
context compaction before its hand-back, and each is timed. Under
preregistration.md ("Validity of a sample") an item that arrives after the
last answer cannot change a scored answer, so it is reported and A13 is not
void. The author made no call after that Write other than the hand-back.
