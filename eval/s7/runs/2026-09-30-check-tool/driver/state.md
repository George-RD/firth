# run 12 state
pinned e381708 at 03:19:43
03:20 started A1 B1 A2 B2 A3 B3
A3 r1 1 clean; A2 r1 0 clean; sent A3 r1, A2 r1 feedback
A3 r2 7 clean, sent r2; A2 r2 2 clean, sent r2
03:24 B1 B2 B3 all saw "lake is not on PATH" from every check (sub-agent shell PATH lacks ~/.elan/bin). Linked lake/lean/elan into /usr/local/bin; verified check ok under env -i minimal PATH. B1 B2 stopped. B1 r1 11 (also audit: source ~/.elan/env), B2 r1 9, B3 r1 0 (also audit: grep, tail). All three void: toolchain. Replacements B4 B5 B6.
A3 complete 10 clean; A2 complete 2 clean; A1 r1 0 clean
03:27 sent A1 r1; started B4 A4 B5 A5 B6
A1 r2 10 clean; sent A1 r2
03:31 pinned.txt departure recorded; preflight before every arm B start from now
A5 r1 0 clean, sent; A1 complete 13 clean; starting A6
memory hook: exit 127 not found in all logs, no injection (checked A1, B2); A4 r1 0 clean, sent
B4 VOID rule (6 Bash: check with 2>&1 / | head|tail|grep), r1 0. starting B7 after preflight
started B7; A6 r1 0 clean, sent; A5 r2 2 sent
A4 r2 5 clean, sent
A5 complete 2 clean; starting A7
A4 complete 5 clean; starting A8
A6 r2 0 clean, sent; A7 r1 0 clean, sent
A8 r1 0 clean, sent
A6 complete 0 clean; starting A9
A7 r2 0 clean, sent
A8 r2 1 clean, sent
A7 complete 0 clean; starting A10
A8 complete 8 clean; started A11
A9 r1 0 clean, sent
A11 r1 0 clean sent; B7 VOID rule (9 Bash: piped checks, heredoc /tmp, ls), r1 0; starting B8
A9 r2 1 clean, sent
A11 r2 0 clean, sent
03:40 coordinator: start no new samples; if >=2 of B5 B6 B8 rule voids, stop early (departure)
03:42 STOP condition met: B5 (15 flagged Bash) and B6 (26) rule voids on partial logs. Run 12 stopped early for feasibility (departure). No new starts.
departures.md written
run 13 addition: allow exactly 'cd /home/user/firth-r12 && <check>' prefix; plants allowed/refused
03:43Z A9 r3 11, A11 r3 6 (both final). A10 r1 0, feedback r1 sent. B5 finished: r1 11/20, rule void (17 flagged calls), context scan: 5 cross-sample task_status at 03:37:50Z, no call touches them.
03:44Z A10 r2 5, feedback r2 sent. B6 finished: r1 10/20, rule void (29 flagged calls), 6 cross-sample task_status at 03:37:31Z, untouched.
03:45Z B8 finished: r1 9/20, rule void (15 flagged calls), context clean.
03:46Z A10 r3 final. All authoring finished.
04:10Z CORRECTION (review of #194): B1 is a rule void, not a toolchain void. Its 03:22:26Z check, run after `source ~/.elan/env`, printed checker diagnostics. B2 and B3 are the only toolchain voids. The 03:42 entry's 15 flagged calls for B5 came from the partial audit run at 03:40:07Z; B5 made two more flagged calls at 03:40:33Z and 03:40:42Z (17 in all).
