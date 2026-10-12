# Scored run analysis

Results read from `rescore-pin`. Produced by `analyse.py`.

## Voids and crashes

- haiku-firth-2: audit flag
- haiku-python-3: audit flag
- haiku-firth-3: audit flag
- haiku-firth-5: context
- sonnet-firth-8: context
- deepseek-firth-1: transport
- deepseek-firth-2: transport
- deepseek-python-1: transport
- sonnet python: kept 8 of 8 planned; voids and crashes 0 {}
- sonnet firth: kept 8 of 8 planned; voids and crashes 1 {'context': 1}
- deepseek python: kept 8 of 8 planned; voids and crashes 1 {'transport': 1}
- deepseek firth: kept 8 of 8 planned; voids and crashes 2 {'transport': 2}
- haiku python: kept 5 of 5 planned; voids and crashes 1 {'audit flag': 1}
- haiku firth: kept 2 of 5 planned; voids and crashes 3 {'audit flag': 2, 'context': 1}

## sonnet

### python (8 kept), in run order

Run order is by `time`: a sub-agent's start, or for DeepSeek its round-1 reply's `created_at` (the request's start is not recorded).

| sample | model | time | round 1 | within two | lengths | per task, round 1 | per task, round 2 |
| --- | --- | --- | --- | --- | --- | --- | --- |
| sonnet-python-1 | claude-sonnet-5-5 | 2026-10-11T03:37:05 | 6 | 6 | [13816] | sokoban: passed; checkers: passed; regex: passed; swiss: passed; warehouse: passed; cache-sim: passed | no round 2 (every example passed) |
| sonnet-python-2 | claude-sonnet-5-5 | 2026-10-11T04:59:45 | 6 | 6 | [13927] | sokoban: passed; checkers: passed; regex: passed; swiss: passed; warehouse: passed; cache-sim: passed | no round 2 (every example passed) |
| sonnet-python-3 | claude-sonnet-5-5 | 2026-10-11T05:46:15 | 6 | 6 | [14115] | sokoban: passed; checkers: passed; regex: passed; swiss: passed; warehouse: passed; cache-sim: passed | no round 2 (every example passed) |
| sonnet-python-4 | claude-sonnet-5-5 | 2026-10-11T07:29:48 | 6 | 6 | [14675] | sokoban: passed; checkers: passed; regex: passed; swiss: passed; warehouse: passed; cache-sim: passed | no round 2 (every example passed) |
| sonnet-python-5 | claude-sonnet-5-5 | 2026-10-11T07:47:29 | 6 | 6 | [14552] | sokoban: passed; checkers: passed; regex: passed; swiss: passed; warehouse: passed; cache-sim: passed | no round 2 (every example passed) |
| sonnet-python-6 | claude-sonnet-5-5 | 2026-10-11T09:10:26 | 5 | 6 | [14836, 1450] | sokoban: wrong result {"wrong result": 3}; checkers: passed; regex: passed; swiss: passed; warehouse: passed; cache-sim: passed | sokoban: passed; checkers: passed; regex: passed; swiss: passed; warehouse: passed; cache-sim: passed |
| sonnet-python-7 | claude-sonnet-5-5 | 2026-10-11T09:12:40 | 5 | 6 | [13904, 3675] | sokoban: passed; checkers: wrong result {"wrong result": 7}; regex: passed; swiss: passed; warehouse: passed; cache-sim: passed | sokoban: passed; checkers: passed; regex: passed; swiss: passed; warehouse: passed; cache-sim: passed |
| sonnet-python-8 | claude-sonnet-5-5 | 2026-10-11T10:16:43 | 6 | 6 | [13482] | sokoban: passed; checkers: passed; regex: passed; swiss: passed; warehouse: passed; cache-sim: passed | no round 2 (every example passed) |

Total: round 1 46, within two 48.

### firth (8 kept), in run order

Run order is by `time`: a sub-agent's start, or for DeepSeek its round-1 reply's `created_at` (the request's start is not recorded).

| sample | model | time | round 1 | within two | lengths | per task, round 1 | per task, round 2 |
| --- | --- | --- | --- | --- | --- | --- | --- |
| sonnet-firth-1 | claude-sonnet-5-5 | 2026-10-11T03:41:29 | 4 | 4 | [36722] | sokoban: passed; checkers: passed; regex: out of steps {"out of steps": 1}; swiss: runtime error {"runtime error": 1}; warehouse: passed; cache-sim: passed | no round 2 (every example passed) |
| sonnet-firth-2 | claude-sonnet-5-5 | 2026-10-11T04:28:08 | 4 | 5 | [40340, 8030] | sokoban: passed; checkers: passed; regex: refusal {"refusal": 26}; swiss: runtime error {"runtime error": 1}; warehouse: passed; cache-sim: passed | sokoban: passed; checkers: passed; regex: passed; swiss: runtime error {"runtime error": 1}; warehouse: passed; cache-sim: passed |
| sonnet-firth-3 | claude-sonnet-5-5 | 2026-10-11T05:48:24 | 5 | 6 | [34647, 7090] | sokoban: passed; checkers: passed; regex: passed; swiss: passed; warehouse: refusal {"refusal": 16}; cache-sim: passed | sokoban: passed; checkers: passed; regex: passed; swiss: passed; warehouse: passed; cache-sim: passed |
| sonnet-firth-4 | claude-sonnet-5-5 | 2026-10-11T07:15:25 | 6 | 6 | [44446] | sokoban: passed; checkers: passed; regex: passed; swiss: passed; warehouse: passed; cache-sim: passed | no round 2 (every example passed) |
| sonnet-firth-5 | claude-sonnet-5-5 | 2026-10-11T07:49:10 | 3 | 6 | [43826, 21909] | sokoban: passed; checkers: refusal {"refusal": 19}; regex: passed; swiss: passed; warehouse: refusal {"refusal": 16}; cache-sim: refusal {"refusal": 16} | sokoban: passed; checkers: passed; regex: passed; swiss: passed; warehouse: passed; cache-sim: passed |
| sonnet-firth-6 | claude-sonnet-5-5 | 2026-10-11T08:36:09 | 4 | 5 | [43614, 13842] | sokoban: refusal {"refusal": 16}; checkers: passed; regex: refusal {"refusal": 26}; swiss: passed; warehouse: passed; cache-sim: passed | sokoban: passed; checkers: passed; regex: wrong result {"wrong result": 17}; swiss: passed; warehouse: passed; cache-sim: passed |
| sonnet-firth-7 | claude-sonnet-5-5 | 2026-10-11T09:15:26 | 5 | 6 | [37434, 7909] | sokoban: passed; checkers: refusal {"refusal": 19}; regex: passed; swiss: passed; warehouse: passed; cache-sim: passed | sokoban: passed; checkers: passed; regex: passed; swiss: passed; warehouse: passed; cache-sim: passed |
| sonnet-firth-9 | claude-sonnet-5-5 | 2026-10-11T10:22:08 | 4 | 6 | [43316, 17432] | sokoban: passed; checkers: refusal {"refusal": 19}; regex: refusal {"refusal": 26}; swiss: passed; warehouse: passed; cache-sim: passed | sokoban: passed; checkers: passed; regex: passed; swiss: passed; warehouse: passed; cache-sim: passed |

Total: round 1 35, within two 44.

**Primary, within two rounds:** Firth 5.500, Python 6.000, difference -0.500, exact two-sided p 0.2000, 95% bootstrap interval [-1.000, -0.125]: parity at the ceiling.

**Secondary, round 1:** Firth 4.375, Python 5.750, difference -1.375, exact two-sided p 0.0078, 95% bootstrap interval [-2.000, -0.750]: materially higher in Python.

Readings: every failed hidden test is traced; no sentence was ruled to admit another reading.

### sonnet Firth guarantees

| row | diagnostics | refusals (round 1, visible) | round 2 differs on a hidden test | of those, round 2 ran |
| --- | --- | --- | --- | --- |
| stack effects | 2 | 2 | 2 | 2 |
| checked types | 5 | 4 | 4 | 4 |
| linear ownership | 0 | 0 | 0 | 0 |
| other refusal | 4 | 4 | never a catch | never a catch |
| declared effects | not exercised | | | |

Out of steps (1,000,000-step budget used up): 1 ['sonnet-firth-1 r1 regex hidden']

Runtime refusals on hidden inputs: 2 ['sonnet-firth-1 r1 swiss trap primitive-fault', 'sonnet-firth-2 r1 swiss trap primitive-fault']

Measured kernel steps (reference interpreter), every case that ran to completion, per round (round 2: the tasks it took). Measured, not a bound; no task has a Lean cost contract, so no proved bound applies.

| round | task | passed cases | passed steps | wrong cases | wrong steps | total steps |
| --- | --- | --- | --- | --- | --- | --- |
| 1 | sokoban | 112 | 1861796 | 0 | 0 | 1861796 |
| 1 | checkers | 95 | 9442743 | 0 | 0 | 9442743 |
| 1 | regex | 129 | 4526312 | 0 | 0 | 4526312 |
| 1 | swiss | 134 | 4069940 | 0 | 0 | 4069940 |
| 1 | warehouse | 96 | 8769032 | 0 | 0 | 8769032 |
| 1 | cache-sim | 112 | 8597295 | 0 | 0 | 8597295 |
| 2 | sokoban | 16 | 433135 | 0 | 0 | 433135 |
| 2 | checkers | 57 | 5185356 | 0 | 0 | 5185356 |
| 2 | regex | 61 | 2213604 | 17 | 252691 | 2466295 |
| 2 | swiss | 0 | 0 | 0 | 0 | 0 |
| 2 | warehouse | 32 | 2842791 | 0 | 0 | 2842791 |
| 2 | cache-sim | 16 | 1147784 | 0 | 0 | 1147784 |

Cases with no measured cost, by cause: {'out of steps': 1, 'runtime error': 2, 'refusal': 199}

## deepseek

### python (8 kept), in run order

Run order is by `time`: a sub-agent's start, or for DeepSeek its round-1 reply's `created_at` (the request's start is not recorded).

| sample | model | time | round 1 | within two | lengths | per task, round 1 | per task, round 2 |
| --- | --- | --- | --- | --- | --- | --- | --- |
| deepseek-python-2 | deepseek-v4.1-flash | 2026-10-11T06:24:38 | 6 | 6 | [20307] | sokoban: passed; checkers: passed; regex: passed; swiss: passed; warehouse: passed; cache-sim: passed | no round 2 (every example passed) |
| deepseek-python-3 | deepseek-v4.1-flash | 2026-10-11T06:28:00 | 6 | 6 | [20709] | sokoban: passed; checkers: passed; regex: passed; swiss: passed; warehouse: passed; cache-sim: passed | no round 2 (every example passed) |
| deepseek-python-4 | deepseek-v4.1-flash | 2026-10-11T06:33:14 | 6 | 6 | [19323] | sokoban: passed; checkers: passed; regex: passed; swiss: passed; warehouse: passed; cache-sim: passed | no round 2 (every example passed) |
| deepseek-python-5 | deepseek-v4.1-flash | 2026-10-11T06:35:25 | 4 | 6 | [18575, 8930] | sokoban: passed; checkers: wrong result {"wrong result": 14}; regex: runtime error {"runtime error": 18}; swiss: passed; warehouse: passed; cache-sim: passed | sokoban: passed; checkers: passed; regex: passed; swiss: passed; warehouse: passed; cache-sim: passed |
| deepseek-python-6 | deepseek-v4.1-flash | 2026-10-11T06:41:13 | 4 | 6 | [18502, 7821] | sokoban: passed; checkers: wrong result {"wrong result": 2}; regex: passed; swiss: passed; warehouse: passed; cache-sim: no answer | sokoban: passed; checkers: passed; regex: passed; swiss: passed; warehouse: passed; cache-sim: passed |
| deepseek-python-7 | deepseek-v4.1-flash | 2026-10-11T06:44:38 | 6 | 6 | [20001] | sokoban: passed; checkers: passed; regex: passed; swiss: passed; warehouse: passed; cache-sim: passed | no round 2 (every example passed) |
| deepseek-python-8 | deepseek-v4.1-flash | 2026-10-11T06:49:52 | 6 | 6 | [20130] | sokoban: passed; checkers: passed; regex: passed; swiss: passed; warehouse: passed; cache-sim: passed | no round 2 (every example passed) |
| deepseek-python-9 | deepseek-v4.1-flash | 2026-10-11T06:52:08 | 5 | 6 | [19548, 4151] | sokoban: passed; checkers: passed; regex: runtime error {"runtime error": 12, "wrong result": 1}; swiss: passed; warehouse: passed; cache-sim: passed | sokoban: passed; checkers: passed; regex: passed; swiss: passed; warehouse: passed; cache-sim: passed |

Total: round 1 43, within two 48.

DeepSeek rounds (prompt_eval_count, done_reason): deepseek-python-2 r1 4634 stop; deepseek-python-3 r1 4634 stop; deepseek-python-4 r1 4634 stop; deepseek-python-5 r1 4634 stop, r2 13737 stop; deepseek-python-6 r1 4634 stop, r2 12591 stop; deepseek-python-7 r1 4634 stop; deepseek-python-8 r1 4634 stop; deepseek-python-9 r1 4634 stop, r2 11834 stop

### firth (8 kept), in run order

Run order is by `time`: a sub-agent's start, or for DeepSeek its round-1 reply's `created_at` (the request's start is not recorded).

| sample | model | time | round 1 | within two | lengths | per task, round 1 | per task, round 2 |
| --- | --- | --- | --- | --- | --- | --- | --- |
| deepseek-firth-3 | deepseek-v4.1-flash | 2026-10-11T06:28:31 | 0 | 0 | [1687, 918] | sokoban: wrong result {"wrong result": 15}; checkers: refusal {"refusal": 19}; regex: wrong result {"wrong result": 25}; swiss: wrong result {"wrong result": 16}; warehouse: refusal {"refusal": 16}; cache-sim: refusal {"refusal": 16} | sokoban: wrong result {"wrong result": 15}; checkers: wrong result {"wrong result": 18}; regex: wrong result {"wrong result": 25}; swiss: wrong result {"wrong result": 16}; warehouse: wrong result {"wrong result": 15}; cache-sim: wrong result {"wrong result": 15} |
| deepseek-firth-4 | deepseek-v4.1-flash | 2026-10-11T06:30:44 | 0 | 0 | [2174, 1154] | sokoban: wrong result {"wrong result": 15}; checkers: refusal {"refusal": 19}; regex: wrong result {"wrong result": 25}; swiss: wrong result {"wrong result": 16}; warehouse: refusal {"refusal": 16}; cache-sim: refusal {"refusal": 16} | sokoban: wrong result {"wrong result": 15}; checkers: wrong result {"wrong result": 18}; regex: wrong result {"wrong result": 25}; swiss: wrong result {"wrong result": 16}; warehouse: wrong result {"wrong result": 15}; cache-sim: wrong result {"wrong result": 15} |
| deepseek-firth-5 | deepseek-v4.1-flash | 2026-10-11T06:36:56 | 0 | 0 | [2080, 1127] | sokoban: wrong result {"wrong result": 15}; checkers: refusal {"refusal": 19}; regex: wrong result {"wrong result": 25}; swiss: wrong result {"wrong result": 16}; warehouse: refusal {"refusal": 16}; cache-sim: refusal {"refusal": 16} | sokoban: wrong result {"wrong result": 15}; checkers: wrong result {"wrong result": 18}; regex: wrong result {"wrong result": 25}; swiss: wrong result {"wrong result": 16}; warehouse: wrong result {"wrong result": 15}; cache-sim: wrong result {"wrong result": 15} |
| deepseek-firth-6 | deepseek-v4.1-flash | 2026-10-11T06:38:27 | 0 | 0 | [1791, 972] | sokoban: wrong result {"wrong result": 15}; checkers: refusal {"refusal": 19}; regex: wrong result {"wrong result": 25}; swiss: wrong result {"wrong result": 16}; warehouse: refusal {"refusal": 16}; cache-sim: refusal {"refusal": 16} | sokoban: wrong result {"wrong result": 15}; checkers: wrong result {"wrong result": 18}; regex: wrong result {"wrong result": 25}; swiss: wrong result {"wrong result": 16}; warehouse: wrong result {"wrong result": 15}; cache-sim: wrong result {"wrong result": 15} |
| deepseek-firth-7 | deepseek-v4.1-flash | 2026-10-11T06:45:06 | 0 | 0 | [1719, 922] | sokoban: wrong result {"wrong result": 15}; checkers: refusal {"refusal": 19}; regex: wrong result {"wrong result": 25}; swiss: wrong result {"wrong result": 16}; warehouse: refusal {"refusal": 16}; cache-sim: refusal {"refusal": 16} | sokoban: wrong result {"wrong result": 15}; checkers: wrong result {"wrong result": 18}; regex: wrong result {"wrong result": 25}; swiss: wrong result {"wrong result": 16}; warehouse: wrong result {"wrong result": 15}; cache-sim: wrong result {"wrong result": 15} |
| deepseek-firth-8 | deepseek-v4.1-flash | 2026-10-11T06:47:13 | 0 | 0 | [2032, 1112] | sokoban: wrong result {"wrong result": 15}; checkers: refusal {"refusal": 19}; regex: wrong result {"wrong result": 25}; swiss: wrong result {"wrong result": 16}; warehouse: refusal {"refusal": 16}; cache-sim: refusal {"refusal": 16} | sokoban: wrong result {"wrong result": 15}; checkers: wrong result {"wrong result": 18}; regex: wrong result {"wrong result": 25}; swiss: wrong result {"wrong result": 16}; warehouse: wrong result {"wrong result": 15}; cache-sim: wrong result {"wrong result": 15} |
| deepseek-firth-9 | deepseek-v4.1-flash | 2026-10-11T06:54:25 | 0 | 0 | [6376, 6575] | sokoban: refusal {"refusal": 16}; checkers: no answer; regex: no answer; swiss: no answer; warehouse: no answer; cache-sim: no answer | sokoban: refusal {"refusal": 16}; checkers: no answer; regex: no answer; swiss: no answer; warehouse: no answer; cache-sim: no answer |
| deepseek-firth-10 | deepseek-v4.1-flash | 2026-10-11T06:57:46 | 0 | 0 | [2074, 1138] | sokoban: wrong result {"wrong result": 15}; checkers: refusal {"refusal": 19}; regex: wrong result {"wrong result": 25}; swiss: wrong result {"wrong result": 16}; warehouse: refusal {"refusal": 16}; cache-sim: refusal {"refusal": 16} | sokoban: wrong result {"wrong result": 15}; checkers: wrong result {"wrong result": 18}; regex: wrong result {"wrong result": 25}; swiss: wrong result {"wrong result": 16}; warehouse: wrong result {"wrong result": 15}; cache-sim: wrong result {"wrong result": 15} |

Total: round 1 0, within two 0.

DeepSeek rounds (prompt_eval_count, done_reason): deepseek-firth-3 r1 16670 stop, r2 20364 stop; deepseek-firth-4 r1 16670 stop, r2 20646 stop; deepseek-firth-5 r1 16670 stop, r2 20610 stop; deepseek-firth-6 r1 16670 stop, r2 20442 stop; deepseek-firth-7 r1 16670 stop, r2 20397 stop; deepseek-firth-8 r1 16670 stop, r2 20597 stop; deepseek-firth-9 r1 16670 stop, r2 24544 stop; deepseek-firth-10 r1 16670 stop, r2 20608 stop

**Primary, within two rounds:** Firth 0.000, Python 6.000, difference -6.000, exact two-sided p 0.0002, 95% bootstrap interval [-6.000, -6.000]: materially higher in Python.

**Secondary, round 1:** Firth 0.000, Python 5.375, difference -5.375, exact two-sided p 0.0002, 95% bootstrap interval [-5.875, -4.750]: materially higher in Python.

**Declared deviation, not as pre-registered:** the pinned driver sent non-streamed requests (`"stream": false`); after its three requests failed with HTTP 502, #246 (8ce2c8f) streamed the reply and changed nothing else. Requests by `stream`: kept 27 True; void 3 False. Counted with this deviation under the coordinator's ruling (a) (`run-notes.md`); the independent reviewer may overrule it.

Readings: every failed hidden test is traced; no sentence was ruled to admit another reading.

### deepseek Firth guarantees

| row | diagnostics | refusals (round 1, visible) | round 2 differs on a hidden test | of those, round 2 ran |
| --- | --- | --- | --- | --- |
| stack effects | 0 | 0 | 0 | 0 |
| checked types | 0 | 0 | 0 | 0 |
| linear ownership | 0 | 0 | 0 | 0 |
| other refusal | 22 | 22 | never a catch | never a catch |
| declared effects | not exercised | | | |

Out of steps (1,000,000-step budget used up): 0 []

Runtime refusals on hidden inputs: 0 []

Measured kernel steps (reference interpreter), every case that ran to completion, per round (round 2: the tasks it took). Measured, not a bound; no task has a Lean cost contract, so no proved bound applies.

| round | task | passed cases | passed steps | wrong cases | wrong steps | total steps |
| --- | --- | --- | --- | --- | --- | --- |
| 1 | sokoban | 7 | 111 | 105 | 1665 | 1776 |
| 1 | checkers | 0 | 0 | 0 | 0 | 0 |
| 1 | regex | 7 | 52 | 175 | 1300 | 1352 |
| 1 | swiss | 7 | 59 | 112 | 944 | 1003 |
| 1 | warehouse | 0 | 0 | 0 | 0 | 0 |
| 1 | cache-sim | 0 | 0 | 0 | 0 | 0 |
| 2 | sokoban | 0 | 0 | 0 | 0 | 0 |
| 2 | checkers | 7 | 66 | 126 | 1188 | 1254 |
| 2 | regex | 0 | 0 | 0 | 0 | 0 |
| 2 | swiss | 0 | 0 | 0 | 0 | 0 |
| 2 | warehouse | 7 | 137 | 105 | 2055 | 2192 |
| 2 | cache-sim | 7 | 104 | 105 | 1560 | 1664 |

Cases with no measured cost, by cause: {'refusal': 389}

## haiku

### python (5 kept), in run order

Run order is by `time`: a sub-agent's start, or for DeepSeek its round-1 reply's `created_at` (the request's start is not recorded).

| sample | model | time | round 1 | within two | lengths | per task, round 1 | per task, round 2 |
| --- | --- | --- | --- | --- | --- | --- | --- |
| haiku-python-1 | claude-haiku-5-5 | 2026-10-11T04:13:10 | 6 | 6 | [14243] | sokoban: passed; checkers: passed; regex: passed; swiss: passed; warehouse: passed; cache-sim: passed | no round 2 (every example passed) |
| haiku-python-2 | claude-haiku-5-5 | 2026-10-11T05:42:14 | 6 | 6 | [13935] | sokoban: passed; checkers: passed; regex: passed; swiss: passed; warehouse: passed; cache-sim: passed | no round 2 (every example passed) |
| haiku-python-4 | claude-haiku-5-5 | 2026-10-11T07:43:49 | 6 | 6 | [13920] | sokoban: passed; checkers: passed; regex: passed; swiss: passed; warehouse: passed; cache-sim: passed | no round 2 (every example passed) |
| haiku-python-5 | claude-haiku-5-5 | 2026-10-11T08:21:12 | 6 | 6 | [13596] | sokoban: passed; checkers: passed; regex: passed; swiss: passed; warehouse: passed; cache-sim: passed | no round 2 (every example passed) |
| haiku-python-6 | claude-haiku-5-5 | 2026-10-11T10:18:36 | 6 | 6 | [14889] | sokoban: passed; checkers: passed; regex: passed; swiss: passed; warehouse: passed; cache-sim: passed | no round 2 (every example passed) |

Total: round 1 30, within two 30.

### firth (2 kept), in run order

Run order is by `time`: a sub-agent's start, or for DeepSeek its round-1 reply's `created_at` (the request's start is not recorded).

| sample | model | time | round 1 | within two | lengths | per task, round 1 | per task, round 2 |
| --- | --- | --- | --- | --- | --- | --- | --- |
| haiku-firth-1 | claude-haiku-5-5 | 2026-10-11T04:16:50 | 0 | 0 | [739, 2855] | sokoban: no answer; checkers: no answer; regex: no answer; swiss: no answer; warehouse: no answer; cache-sim: no answer | sokoban: refusal {"refusal": 16}; checkers: refusal {"refusal": 19}; regex: wrong result {"wrong result": 26}; swiss: refusal {"refusal": 17}; warehouse: refusal {"refusal": 16}; cache-sim: refusal {"refusal": 16} |
| haiku-firth-4 | claude-haiku-5-5 | 2026-10-11T07:31:22 | 0 | 0 | [3347, 3260] | sokoban: refusal {"refusal": 16}; checkers: refusal {"refusal": 19}; regex: refusal {"refusal": 26}; swiss: refusal {"refusal": 17}; warehouse: refusal {"refusal": 16}; cache-sim: refusal {"refusal": 16} | sokoban: wrong result {"wrong result": 15}; checkers: wrong result {"wrong result": 19}; regex: wrong result {"wrong result": 26}; swiss: wrong result {"wrong result": 17}; warehouse: wrong result {"wrong result": 16}; cache-sim: wrong result {"wrong result": 15} |

Total: round 1 0, within two 0.

**Primary, within two rounds:** Firth 0.000, Python 6.000, difference -6.000, exact two-sided p 0.0476, 95% bootstrap interval [-6.000, -6.000]: incomplete: reported, not a result.

**Secondary, round 1:** Firth 0.000, Python 6.000, difference -6.000, exact two-sided p 0.0476, 95% bootstrap interval [-6.000, -6.000]: incomplete: reported, not a result.

Readings: every failed hidden test is traced; no sentence was ruled to admit another reading.

Voids and crashes differ between arms by 2 (Firth 3, Python 1): the surviving samples may differ between arms.

A cell has fewer than its planned samples: this comparison is incomplete, not a result.

### haiku Firth guarantees

| row | diagnostics | refusals (round 1, visible) | round 2 differs on a hidden test | of those, round 2 ran |
| --- | --- | --- | --- | --- |
| stack effects | 2 | 2 | 2 | 2 |
| checked types | 0 | 0 | 0 | 0 |
| linear ownership | 0 | 0 | 0 | 0 |
| other refusal | 3 | 4 | never a catch | never a catch |
| declared effects | not exercised | | | |

Refusals with no `code:` line (other refusal): haiku-firth-4 sokoban: {"error": "entry main: initial stack type mismatch; expected {'kind': 'base', 'name': 'Seq', 'usage': 'many'}, got Seq I

Out of steps (1,000,000-step budget used up): 0 []

Runtime refusals on hidden inputs: 0 []

Measured kernel steps (reference interpreter), every case that ran to completion, per round (round 2: the tasks it took). Measured, not a bound; no task has a Lean cost contract, so no proved bound applies.

| round | task | passed cases | passed steps | wrong cases | wrong steps | total steps |
| --- | --- | --- | --- | --- | --- | --- |
| 1 | sokoban | 0 | 0 | 0 | 0 | 0 |
| 1 | checkers | 0 | 0 | 0 | 0 | 0 |
| 1 | regex | 0 | 0 | 0 | 0 | 0 |
| 1 | swiss | 0 | 0 | 0 | 0 | 0 |
| 1 | warehouse | 0 | 0 | 0 | 0 | 0 |
| 1 | cache-sim | 0 | 0 | 0 | 0 | 0 |
| 2 | sokoban | 1 | 17 | 15 | 255 | 272 |
| 2 | checkers | 0 | 0 | 19 | 190 | 190 |
| 2 | regex | 0 | 0 | 52 | 1144 | 1144 |
| 2 | swiss | 0 | 0 | 17 | 595 | 595 |
| 2 | warehouse | 0 | 0 | 16 | 816 | 816 |
| 2 | cache-sim | 1 | 20 | 15 | 300 | 320 |

Cases with no measured cost, by cause: {'refusal': 194}

