---
node: firth.toolchain.agent
status: open
created: 2026-10-11
---

# Report an unnamed stack-effect item where it is, not at the end of the file

A stack effect with an unnamed item, such as `( a:Int -- Bool )`, is refused
with

```
code: firth.syntax.unexpected-eof
message: The input ends here, expected `:`.
hint: A definition looks like `: name (forall ρ; ρ n:Int^many -- ρ r:Int^many) body;`.
```

at the end of the file, however far away the item is. Reproduce with

```
: f ( a:Int -- b:Int ) drop 0 ;
: g ( a:Int -- Int ) drop 0 ;
: h ( a:Int -- b:Int ) drop 1 ;
```

which `tools/loop/firth_run.py check` refuses at line 4, column 1, after the
last line, with nothing pointing at `g`. Checked at 627a0eb; main (8ce2c8f)
changes nothing under `src/` or `tools/` since.

Found in the harder tier's scored run of 11 October 2026: deepseek-firth-9
wrote a 250-line sokoban answer whose first word is
`: all-goals-loop ( cells:Seq Int boxes:Seq Int i:Int -- Bool )`. Both rounds
got this diagnostic at line 250 and the author never found the cause
(`eval/s7/harder/runs/2026-10-11-scored/deepseek-firth-9/`,
`rescore-pin/deepseek-firth-9/results-1.json`). `todo.paren-in-body-diagnostic`
made "the input ends here" true only where the input ends; here it does end,
but the error is elsewhere.

## Acceptance criteria

- An unnamed item in a stack effect is reported at that item, with a message
  that says every item needs a name (`b:Bool`), checked on the program above
  and on deepseek-firth-9's answer.
- A planted case keeps the old location from passing.
