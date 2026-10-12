---
node: firth.toolchain.agent
status: open
created: 2026-10-11
---

# S7 sub-agent authors can reach session-messaging tools

In the harder tier's scored run of 11 October 2026, two Haiku authors
called `mcp__claude-code-remote__send_message` after writing their answers
(`haiku-firth-2`, `haiku-python-3`; `runs/2026-10-11-scored/run-notes.md`).
Both calls failed and sent nothing, and the audit flagged both, so both
samples are void. Two of Haiku's four voids in that run came from this. The
author tool set was not changed during the run.

This is the tool-list part of `todo.s7-author-enforced-allowlist`, which
covers enforcing the whole allowlist (files, shell, task outputs). Removing
the tools is the smaller step and can land first.

## Acceptance criteria

- The next tier starts its sub-agent authors with only the tools the
  protocol allows (Read and Write), or at least without any tool that can
  reach another session, and the same set in both language arms.
- The audit still flags any call beyond the allowed tools, with a planted
  call it must flag.
- The run's pre-registration states the tool set the authors had.

## Progress

- 11 October 2026: the agent type `s7-harder-author` (`tools: Read,
  Write`, no hooks), the check `eval/s7/harder/author_tools.py` with its
  planted logs (`test_author_tools.py`), and the next tier's steps
  (`eval/s7/harder/README.md`, "Author tool set"). Still open: no
  `s7-harder-author` has run yet, so nothing shows its tool list is
  honoured; the next tier's probe (step 3 there) is the first that can, and
  its pre-registration must state the tool set.
- 11 October 2026, later (#248 merged): a non-sample `s7-harder-author`
  author's raw log shows exactly Read, Write and `SubagentHandback`, no
  deferred tool and one working directory, and `author_tools.py --probe`
  prints `ok` (`eval/s7/harder/runs/2026-10-11-tool-probe/tool-probe.txt`).
  Still open: no tier has run its authors as this type yet, and its
  pre-registration must state the tool set. It must also list, or remove,
  the context the author still receives: the MCP server instructions and
  the `omega-memory` hook errors (`notes.md` there).
