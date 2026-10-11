---
node: firth.toolchain.agent
status: open
created: 2026-10-11
---

# Say that a name cannot contain `_`

A stack-effect name with an underscore, such as `white_took:Int`, is refused
with

```
code: firth.syntax.unexpected-token
message: Unexpected `_`, expected `:`.
hint: A definition looks like `: name (forall ρ; ρ n:Int^many -- ρ r:Int^many) body;`.
```

The location is right, but neither line says that `_` is not allowed in a
name or what to write instead (`white-took`). Checked at 627a0eb with
`: f ( a:Int -- b_c:Int ) drop 0 ;` (line 1, column 17).

Found in the harder tier's scored run of 11 October 2026. Three of its tasks
(checkers, warehouse, cache-sim) name their outputs with underscores, as
in `white_took`, and authors of all three subjects copied the names into
their stack effects: 30 task refusals in round 1 or 2 across sonnet-firth-5,
seven DeepSeek authors and both kept Haiku authors
(`eval/s7/harder/runs/2026-10-11-scored/results.md`, "Ruling out a harness
fault"). Every author who had a next round fixed it there; haiku-firth-1
first wrote these words in round 2, the last. Python
accepts the same names, so the task text costs Firth a round that it does
not cost Python; a later task set should say so or use names valid in both.

## Acceptance criteria

- A `_` in a name gets a diagnostic that says names use `-`, not `_`, and
  shows the name rewritten, checked on the 30 refused answers above.
- A planted case keeps the old message from passing.
