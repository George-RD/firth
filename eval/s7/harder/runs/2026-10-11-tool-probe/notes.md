# Tool-list probes, 11 October 2026

Two probes, neither a sample. The second is the evidence that an
`s7-harder-author` gets exactly Read, Write and the hand-back.

## 1. A built-in type (`statusline-setup`)

When `.claude/agents/s7-harder-author.md` was first written in this
session, the Agent tool answered "Agent type 's7-harder-author' not found":
the session's agent types had been read before the file existed. So the
first probe used the built-in type `statusline-setup`, whose definition
lists Read and Edit, with model `haiku` and a prompt asking it to name its
tools and change nothing.

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

## 2. `s7-harder-author`

A few minutes after #248 was opened (13:47Z), the session reloaded its
agent types and listed "s7-harder-author ... (Tools: Read, Write)". The
second probe was started as that type, with model `haiku` and the prompt
in `probe-prompt.md` (name every tool, write the list, hand back). It
called Read on the prompt, Write on its list and `SubagentHandback`
("done"), and nothing else.

- `agent-aeaa153e26921b4be.meta.json`: agent type `s7-harder-author`,
  model `haiku`.
- Its `prompt_snapshot` tool list is exactly Read, Write and
  `SubagentHandback`. There is no `deferred_tools_delta` and no
  `skill_listing`.
- Every line has `cwd` `/home/user/firth`.
- `tools-seen.txt` is the list the author wrote: Read, Write,
  `SubagentHandback`.

`agent-aeaa153e26921b4be.jsonl` is its log trimmed as above, keeping also
the tool-call names and each hook error's name, event, command, exit code,
stdout and stderr. `tool-probe.txt` is

    python3 eval/s7/harder/author_tools.py \
      --logs eval/s7/harder/runs/2026-10-11-tool-probe \
      --probe aeaa153e26921b4be --cwd /home/user/firth

which prints `ok`. So in this session the `tools:` line was honoured. That
does not show it for the next tier's own session: the protocol's step 3
runs the same probe there before the first sample.

`test_author_tools.py` re-runs both checks and compares their output with
`check-output.txt` and `tool-probe.txt`.

### Context the author still receives

Fixing the tools does not fix everything the author is shown. The
`s7-harder-author` log also has:

- an `mcp_instructions_delta` attachment carrying the instructions of the
  session's MCP servers (Claude_Docs, github, Gmail, Notion, Supabase),
  although the author has none of their tools;
- two `hook_non_blocking_error` items, after its Read and its Write. Both
  are a PostToolUse hook whose command runs
  `/Users/george/.local/share/uv/tools/omega-memory/bin/python` on
  `.../omega-memory/hooks/fast_hook.py surface_memories`, which exits 127
  with "not found" on stderr (the two lines are kept whole, apart from the
  tool-use id and duration, in `agent-aeaa153e26921b4be.jsonl`; they hold
  local paths and no credential);
- `total_tokens_reminder` items, and the session's environment, model,
  instructions, session context, date, credential and session-change
  attachments at the start.

The next tier's pre-registration has to name each of these as a known
injected item or remove it, because the scored run's rule voids any
injected item it does not list.
