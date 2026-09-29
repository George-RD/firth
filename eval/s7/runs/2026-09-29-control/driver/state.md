# control state
DONE: A1 0/2/3, A2 0/5/9, B1 1/7/8, B2 0/0/0 (all audits+agents clean)
A3 0/0, round2 msg sent
A4 0/0, round2 msg sent
B3 6/8, round2 msg sent
B4 0, round1 msg sent
next: A5 B5 A6 B6 ... (start A5/A6 when A3/A4 finish authoring; B5 when B3 finishes)
18:34 container restart. A3 finished 0/0/10 (clean). B4 r1 0 (clean), round 2 sent after restart.
VOID (restart, not all three answers): A4 (0/0 so far), A5, B5 (no answers). Replacements A11, B11, A12.
A11 r0 0 (clean), round1 sent. B4 answer-3 written. A12 answer-1 written. B6 started.
B4 DONE 0/0/0 clean. A12 r0 0 clean, round1 sent.
A11 r1 0 clean, round2 sent.
A12 r1 8 clean, round2 sent. B11 r0 2 clean (multi 10), round1 sent. A6 started. A11 answer-3 written (6 tool uses in last turn; check audit).
A11 DONE 0/0/0 clean (9 calls).
B6 r0 1 clean (multi 7), round1 sent.
A12 answer-3 written, scoring. A7 started.
A12 DONE 0/8/8 clean. A8 started. B11 answer-2 written, scoring.
B11 r1 2 clean, round2 sent.
B6 r1 10 clean, round2 sent.
B7 started; B11 answer-3 written.
A8 r0 0 clean, round1 sent. A7 r0 5 clean, round1 sent.
DEPARTURE: A8 started while A6 and A7 were running (3 in arm A, 5 authors total) - my scheduling slip; noted for write-up.
B11 DONE 2/2/2 clean. A6 answer-1 written.
A6 r0 1 clean, round1 sent. B6 answer-3 written. B7 answer-1 written.
B6 DONE 1/10/13 clean. B7 r0 0 clean, round1 sent. Holding B8 until arm A drops to 2 in progress (total <=4).
A8 r1 0 clean, round2 sent.
A6 r1 1 clean, round2 sent.
A7 r1 9 clean, round2 sent. B7 answer-2 written.
B7 r1 0 clean, round2 sent.
A8 answer-3 written, scoring. B8 started (now A6,A7,B7,B8 in progress).
A8 DONE 0/0/3/20
A6 answer-3 written, scoring. A9 started.
A6 DONE 1/1/1/20. B9 started. B7 answer-3 written.
B7 DONE 0/0/7/20
A10 started. A7 answer-3 written, scoring.
A7 DONE 5/9/10/20
A10 r0 0 clean, round1 sent. A9 r0 0 clean, round1 sent.
B8 r0 0 clean (multi 19), round1 sent.
B9 r0 7 clean, round1 sent.
A10 r1 1 clean, round2 sent.
A9 r1 7 clean, round2 sent. B8 answer-2 written.
B8 r1 0 clean, round2 sent.
A10 DONE 0/1/6/20
A9 DONE 0/7/12/20. ARM A COMPLETE.
B9 VOID: Edit tool x5 on own answer-2.md in round 1 (audit flagged). Scores 7/11 reported, not counted. Replacement B12.
B10 started.
B8 VOID: Bash ls x2 of own dir after answer-3 (audit flagged). Scores 0/0/0. Replacement B13. Its hand-back named 'Control author B10' (harness leak, not file).
B10 r0 0 clean, round1 sent. B12 started.
B12 r0 0 clean (multi 14), round1 sent.
B10 VOID: wrote answer-2 three times; audit flags earlier writes. Scores 0/5. Replacement B14.
B13 started. B12 r1 1 clean, round2 sent.
B14 started. B12 answer-3 written.
B12 DONE 0/1/2/20
B13 r0 1 clean, round1 sent.
B14 r0 0 clean (multi 14), round1 sent. B13 r1 6 clean, round2 sent.
B13 DONE 1/6/8/20
B14 r1 0 clean, round2 sent.
B14 DONE 0/0/0. ALL 20 COUNTED.
