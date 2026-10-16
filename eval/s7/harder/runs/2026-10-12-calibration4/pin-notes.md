# Calibration pin: notes

Pinned at main `814b61fd0020ec9c75cf61cc5519a8a3cd219156` (`commit.txt`), which
holds the checker changes the maintainer's calibrate-first choice waited on:
#254 (value to remove for a call given one too many), #241 (`core.min-int`,
`core.max-int`), #257 (roadmap wording), #205 (run 14 author-hook skill) and
#255 (name the operation in an inner `if`). `prompt-firth.md` and
`prompt-python.md` are `tier.py prompt --set candidates --lang LANG` at that
commit, rounds 1, with no sentence appended (the 11 October no-imports sentence
does not apply: a Firth answer runs beside a copy of `stdlib/`, `README.md`,
"Files").

Against the first draft built at f02c355, only the Firth prompt changed, by
#241: the "Core vocabulary" row of `docs/getting-started.md`, the new
"Standard library" section of `examples/programs/README.md`, and the contents
of `stdlib/core.firth` (the `diff` of the two Firth prompts is those three
hunks). The Python prompt is byte-identical.

SHA-256 of the inputs an author's prompt or session draws on, at the pin:

```
40253eda9c637dacccd0eb54aae253f26c843117cfa7b8785c253de276f68d68  AGENTS.md
336cc4fbf19beaada7ccf9986414fa91851a8d7a07dfb3ccbe800a69eed0ab49  CLAUDE.md
25382a315b8e7bd46a1781b311b9fdbcab6b96275c2328df2c3b4111fa203ce1  docs/getting-started.md
f3586eb9d2ef63a60a8c3449de3179ef914806e04888ac0b3856ba88e2359215  docs/firth-agent-guide.md
590f3c5c351c1868fa167e4c4b38162fc2faf5e6f2d5227c4c9867d7d868b972  examples/programs/README.md
0f4c8d0d17c0df58bf8ab7b65111e90d925912c5b3c4d1807b3807bbc41f06c5  .claude/agents/s7-harder-author.md
df18e4642c05b857d27047bdf01b4c01b296b21afd1630c23ae3291040f05fb5  stdlib/core.firth
```

Not in the prompt, but in a sub-agent author's session: #205 added the skill
`.claude/skills/s7-author-hook/SKILL.md`, so the session's skill listing now
names it. The authors' tool set is unchanged (Read, Write and the hand-back,
checked by `author_tools.py`). The 11 October run's inputs were pinned at
627a0eb; this tier does not compare with it across subjects.
