---
node: firth.toolchain.agent
status: open
created: 2026-10-11
---

# context_seen.py compares Haiku sample numbers, not whole names

`eval/s7/context_seen.py` finds another Haiku author in a log with
`SAMPLE = haiku-(?:firth|python)-([0-9]+)` and compares only the number
(`crossing`, around line 173). So `haiku-python-1` named in
`haiku-firth-1`'s log is not marked `cross_sample`. The harder tier's
pre-registration says the scan "compares whole sample names (#230)". Sonnet
and DeepSeek names are already compared whole (`SAMPLE_NAME`).

Found by cubic on #245 during the scored run of 11 October 2026 and
confirmed by reading the code. In that run the second search,
`runs/2026-10-11-scored/scan.sh`, matches every other planned sample's whole
name, and found none in any author's log (`scan-output.txt`, "others: 0").

## Acceptance criteria

- `context_seen.py` compares whole Haiku sample names, as it does for the
  other subjects.
- Its self-test has a planted case it must flag: another Haiku author with
  the same number in the other language (`haiku-python-1` in
  `haiku-firth-1`'s log).
