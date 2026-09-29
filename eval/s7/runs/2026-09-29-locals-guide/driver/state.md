# run 11 state
started 21:39: A1 B1 A2 B2 A3 B3
A3 r1(answer-1) scored, clean; round1 sent 21:40:18
21:43:22 A2 r1 0 sent; A3 r2 0 sent; B2 r1 0 sent; B1 r1 0 sent; B3 r1 5 sent
21:43:37 A1 VOID (answer-1 written twice, audit flag), r1 4. B3 r2 10 sent. starting A4
21:44:22 B2 r2 sent
21:44:28 A3 DONE clean. B1 r2 sent. starting A5
21:46:03 A2 r2 sent. B3 scored r3; starting B4
A2 complete 12 clean; A5 r1 0 clean
sent A4 r1, A5 r1 feedback; started B5 A6 B6
A4 r2 0 clean; B6 r1 0 clean
A5 r2 5 clean
B4 r1 0 clean
A6 r1 6 clean; sent A4 r2, A5 r2, B6 r1, B4 r1, A6 r1 feedback
A5 complete 7 clean
A4 complete 8 clean; B5 r1 4; B6 r2 8; B4 r2 0 all clean; sent B5 r1, B6 r2, B4 r2
A6 r2 13 clean; sent A6 r2; started A7 A8
B5 r2 14 clean; sent B5 r2
B6 complete 11 clean
A7 r1 0 clean; A6 complete 15 clean
B4 complete 7; context exit 1 = 5 task_status items at 21:54:27, after last Write 21:53:46 -> reported not voiding (late-context.md)
B5 complete 17 clean
A8 r1 6 clean; sent A7 r1, A8 r1; started B7 A9 B8 B9
A7 r2 0 clean
B9 r1 0; B7 r1 7; B8 r1 2 all clean; sent A7 r2, B9 r1, B7 r1, B8 r1
A9 r1 0; A8 r2 9 clean; sent A9 r1, A8 r2
B7 r2 10 clean; sent B7 r2
B9 r2 7 clean; sent B9 r2
A8 complete 9 clean
A7 complete 7 clean
B8 VOID (Edit x4 on answer-2.md, audit exit 1); replacement B10
B9 complete 9 clean
A9 r2 6 clean; sent A9 r2; started B10 B11
A10 r1 5 clean; sent A10 r1
B7 complete 13 clean
A11 r1 0 clean; sent A11 r1; started B12
A9 complete 9 clean; B10 r1 6 clean; sent B10 r1; starting A12
A11 r2 6 clean; sent A11 r2
B10 r2 11 clean; sent B10 r2
B11 r1 0 clean; sent B11 r1
A10 r2 6 clean; sent A10 r2
A11 complete 12 clean
B12 VOID (answer-1 written twice); replacement B13
B10 complete 14 clean; sent A12 r1; started B13
B11 r2 12 clean; sent B11 r2; started B14
A10 complete 11 clean; started A14
B13 r1 0 clean; sent B13 r1
A12 r2 5 clean; sent A12 r2
A13 r1 0 clean; sent A13 r1
B11 VOID (read answer-3 back, wrote it twice); replacement B15
A12 complete 9 clean; B13 r2 0 clean; sent B13 r2; started B15
B14 r1 11; A13 r2 0 clean; sent B14 r1, A13 r2; started A15
B13 complete 10 clean
A14 r1 0; B15 r1 0 clean; sent A14 r1, B15 r1; started B16
B14 r2 12 clean; sent B14 r2
A15 r1 1 clean; sent A15 r1
A13 complete 1; context exit 1 = 5 task_status at 22:13:50 after last Write 22:13:14 -> reported (late-context.md)
B16 r1 4 clean; sent B16 r1; started A16
B14 complete 14 clean
A14 r2 4; B15 r2 0 clean; sent A14 r2, B15 r2; started B17
B16 r2 12 clean; sent B16 r2
B15 complete 4 clean
B17 r1 0 clean; sent B17 r1; started B18
A16 r1 3 clean; sent A16 r1
A15 VOID (answer-2 written twice); replacement A17
started A17
A14 VOID (after last answer, read A15's log + Bash tail, prompted by task_status); replacement A18
B16 complete 15 clean; B17 r2 0 clean; sent B17 r2; started A18
B18 r1 0 clean; sent B18 r1; started B19
A16 r2 9 clean; sent A16 r2
A17 r1 7 clean; sent A17 r1
B17 complete 6 clean
B19 r1 0; B18 r2 0; A17 r2 9 all clean; sent B19 r1, B18 r2, A17 r2; started B20
A18 r1 7 clean; sent A18 r1
B20 r1 0 clean; sent B20 r1
A16 complete 13 clean
A17 complete 11; B18 complete 7 clean
A18 r2 12 clean; sent A18 r2; started A19 B21 A20
B19 r2 0; B20 r2 11 clean; sent B19 r2, B20 r2
A19 r1 0 clean; sent A19 r1
B21 r1 0 clean; sent B21 r1
A20 r1 5 clean; sent A20 r1
B19 complete 0 clean; started B22
A18 complete 15 clean
B21 r2 0 clean; sent B21 r2
B22 r1 0 clean; sent B22 r1
A19 r2 0 clean; sent A19 r2
A20 r2 8 clean; B20 VOID (answer-3 written twice); replacement B23
22:29:19 B20 void (answer-3 twice), B21 complete, A20 round-2 fb sent, B23/B24 launched
22:31:02 A19,A20 complete; arm A has 17 non-void -> starting A21-A23
22:31:26 A21-A23 launched; B22 complete; B24 r1 fb sent; B23 writing answer-1 (note: earlier count of A non-void starts was wrong: 17 not 20)
22:33:06 B23 void (answer-1 written 3x) -> B25; A23 r1 fb sent; A21 answer-1 done
22:33:58 A22 void (answer-1 3x + read back) -> A24; B24 answer-3 done; A23 r2 fb
22:37:02 A21,A23 complete; B25 & A24 r2 fb sent
