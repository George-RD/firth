---
name: s7-author-hook
description: Registers S7 run 14's author hook for the rest of this session. Invoke only when an S7 run 14 runbook step says to.
hooks:
  PreToolUse:
    - matcher: "*"
      hooks:
        - type: command
          command: "[ -f /home/user/firth-r14/eval/s7/author_hook.py ] && python3 /home/user/firth-r14/eval/s7/author_hook.py --state /home/user/r14-hook/state.json --only s7-author"
          timeout: 30
---
The S7 run 14 author hook is now registered for the rest of this session.
It decides only for `s7-author` sub-agents' tool calls and lets every other
call run. Go on with the next step of the runbook.
