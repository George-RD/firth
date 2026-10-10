# Harder tier, scored run: run plan

The order the scored run's samples run in, fixed before any of them starts
(`preregistration.md`). It will be pinned with the prompts, and is not
changed after that.

- One sample runs at a time, with no other author or worker running in the
  session.
- In rounds 1 to 5, every subject runs both language arms one after the
  other, and the subjects take turns. Sonnet and DeepSeek run 8 per arm
  (`preregistration.md`, "Sample size"), so rounds 6 to 8 run those two
  only.
- The arm that goes first alternates: Python first for odd numbers, Firth
  first for even ones. So each arm goes first for each subject in about
  half its rounds (four of eight for Sonnet and DeepSeek, two or three
  of five for Haiku), which balances which arm runs first. The two
  arms of a subject also run back to back, so a long slow period touches
  both, though a brief outage can still void a single sample; voids are
  counted per arm (`preregistration.md`).
- A void or crashed sample's replacement takes the next unused number for
  its subject and language, and runs after sample 42, in the order the
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
33. `deepseek-firth-6`
34. `deepseek-python-6`
35. `sonnet-python-7`
36. `sonnet-firth-7`
37. `deepseek-python-7`
38. `deepseek-firth-7`
39. `sonnet-firth-8`
40. `sonnet-python-8`
41. `deepseek-firth-8`
42. `deepseek-python-8`
