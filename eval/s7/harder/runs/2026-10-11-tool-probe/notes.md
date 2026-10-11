# Tool-list probe, 11 October 2026

Not a sample, and not evidence that `s7-harder-author` gets only Read and
Write. It shows where a sub-agent's tool list is recorded and that
`author_tools.py` reads it from a real log.

The definition `.claude/agents/s7-harder-author.md` was added in this
session, and agent types are read when a session starts, so this session
could not start one: the Agent tool answered "Agent type
's7-harder-author' not found". The probe used the built-in type
`statusline-setup` instead, whose definition lists Read and Edit, with
model `haiku` and a prompt asking it to name its tools and change nothing.

What its raw log (`~/.claude/projects/<project>/<session>/subagents/`)
shows:

- `agent-<id>.meta.json` names the agent type and the model the driver asked
  for.
- A `prompt_snapshot` attachment carries the tool list the model was given:
  Read, Edit and `SubagentHandback`. So the type's tool list is what the
  sub-agent got, and the harness adds the hand-back to it. The author named
  the same three in its hand-back.
- There is no `deferred_tools_delta` and no `skill_listing`: with no
  ToolSearch, no deferred tool can be loaded. Every author in the scored run
  had both (`../2026-10-11-scored/toollist.txt`).
- Every line carries the session's working directory as `cwd`. In this
  session's own log it changes whenever a command `cd`s, which is how a
  driver's move to another checkout reaches the authors started after it.

`agent-a973715484d11fd44.jsonl` is that log trimmed to each line's type,
time and `cwd`, and each attachment's type, with tool lists cut to their
names (the full log holds the session's instructions). `check-output.txt` is

    python3 eval/s7/harder/author_tools.py \
      --logs eval/s7/harder/runs/2026-10-11-tool-probe \
      --probe a973715484d11fd44 --cwd /home/user

which refuses it for its type and its Edit, as it should.
`test_author_tools.py` re-runs it and compares.

The probe the protocol needs, an `s7-harder-author` whose log shows exactly
Read, Write and the hand-back, has not been run. It is the first step of the
next tier's run (`../../README.md`, "Author tool set"), in a session that
starts with the definition on its checkout.
