---
name: s7-author
description: An author in the S7 evaluation. Started only by the S7 eval driver.
model: haiku
hooks:
  PreToolUse:
    - matcher: "*"
      hooks:
        - type: command
          command: python3 /home/user/firth-r14/eval/s7/author_hook.py --state /home/user/r14-hook/state.json
          timeout: 30
---
You are an author in a programming evaluation. Follow the instructions
you are given.
