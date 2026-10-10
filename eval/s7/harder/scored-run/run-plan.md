# Harder tier, scored run: run plan

The order the scored run's samples run in, fixed before any of them starts
(`preregistration.md`). It will be pinned with the prompts, and is not
changed after that.

- One sample runs at a time, with no other author or worker running in the
  session.
- In rounds 1 to 5, every subject runs both language arms one after the
  other, and the subjects take turns. Sonnet, the primary subject, runs 8
  per arm (`preregistration.md`, "Sample size"), so rounds 6 to 8 run
  Sonnet only.
- The arm that goes first alternates: Python first for odd numbers, Firth
  first for even ones. So each arm goes first for each subject in about
  half its rounds (four of eight for Sonnet, two or three of five for
  DeepSeek and Haiku), which balances which arm runs first. The two
  arms of a subject also run back to back, so a long slow period touches
  both, though a brief outage can still void a single sample; voids are
  counted per arm (`preregistration.md`).
- A void or crashed sample's replacement takes the next unused number for
  its subject and language, and runs after sample 36, in the order the
  voids happened (`preregistration.md`, "Voids, crashes and
  replacement").

1. `sonnet-python-1`
2. `sonnet-firth-1`
3. `deepseek-python-1`
4. `deepseek-firth-1`
5. `haiku-python-1`
6. `haiku-firth-1`
7. `sonnet-firth-2`
8. `sonnet-python-2`
9. `deepseek-firth-2`
10. `deepseek-python-2`
11. `haiku-firth-2`
12. `haiku-python-2`
13. `sonnet-python-3`
14. `sonnet-firth-3`
15. `deepseek-python-3`
16. `deepseek-firth-3`
17. `haiku-python-3`
18. `haiku-firth-3`
19. `sonnet-firth-4`
20. `sonnet-python-4`
21. `deepseek-firth-4`
22. `deepseek-python-4`
23. `haiku-firth-4`
24. `haiku-python-4`
25. `sonnet-python-5`
26. `sonnet-firth-5`
27. `deepseek-python-5`
28. `deepseek-firth-5`
29. `haiku-python-5`
30. `haiku-firth-5`
31. `sonnet-firth-6`
32. `sonnet-python-6`
33. `sonnet-python-7`
34. `sonnet-firth-7`
35. `sonnet-firth-8`
36. `sonnet-python-8`
