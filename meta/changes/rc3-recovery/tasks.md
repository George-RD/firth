# Tasks: rc3-recovery

- [x] Author dec.rc3-recovery.
- [x] supervisor.sh: rc 3 ok-verdict delegation; refresh_for_relaunch
      on all relaunch paths.
- [x] recovery.py: accept rc {2, 3}; docstring.
- [x] Amend docs/loop-recovery-mandate.md and the launcher clause in
      docs/loop-runbook.md.
- [x] Supervisor scenarios: granted rc 3 relaunches once; denied stays
      down; exhausted and unreadable quota never call the delegate.
- [x] Executor tests: rc 3 ledgered and bounded; other rcs refused.
- [x] Deploy the rebuilt image and observe a live iteration.
