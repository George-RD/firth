---
id: dec.source-type-names
nodes: [firth.language.surface, firth.toolchain.elaborator, firth.toolchain.agent]
status: accepted
related: [dec.top-level-words-in-vocabularies]
date: 2026-10-11
---
# A stack effect may name only the types a program can make

## Context

The checker accepted any name as a base type in a stack effect: `Seq` with
no element type, a made-up `Foo`, or the target spelling `SeqInt`. A word
declared over such a type checked, and the error surfaced later and
elsewhere: a primitive given the value said it got `Seq` where it takes
`Seq Int`, the compiler refused `SeqInt` with `firth.compile.invalid-word-type`,
and the runner refused a `Seq` entry input with no code and a raw record
(`todo.unknown-base-type`). In the harder tier's scored run of 11 October
2026, haiku-firth-4's round-1 sokoban declared `cells:Seq^many`, checked, and
was refused that way on every case.

## Decision

The checker refuses a stack effect that names a base type outside a fixed
list with `firth.type.unknown-type`, reported at that type and naming the
word. The list is `sourceTypes` in
`src/agent/Firth/Agent/ElaboratorDiagnostics.lean`:

- `Int`, `Bool`, `Seq Int` and `Seq Bool`: the types a literal or a
  surface primitive gives a value of (`surfacePrimitives`, the table the
  elaborator, the reference and the compiler share, and
  `defaultLiteralType`);
- `World`, `Handle` and `Bytes`: taken from `worldPrimitiveSchemes`, the
  schemes of the world primitives (`send` threads all three), not written
  out by hand, so a new world primitive's types join the list with it.

The kernel's `Unit` is not on the list. `defaultLiteralType` types the
kernel's unit literal, but no source syntax produces that literal (the
erasure never emits it) and no primitive takes or leaves a `Unit`, so a
word declared over `Unit` could never be given or return a value. Refusing it
says so at the declaration instead of at a call that cannot be written.

`runSourceTypeTests` (`ElaboratorDiagnosticsTest.lean`) checks that the list
is exactly the base types in every language primitive's scheme and every
literal kind a program can write, in both directions, with planted lists one
short of `Handle` and one with `Unit` that the check rejects. The check runs
in the agent's typing environment (`gammaTyping`), which every checker,
runner and eval path uses; an environment built without a list
(`types := none`) still accepts any name, as before.

The compiler keeps its own guard (`isReservedTargetTypeName`): a word type
built some other way than from checked source, over `SeqInt` or `SeqBool`,
is still refused there, so the mapping from source to target type names
stays injective. `FirthCompilerTest` checks that the guard still fires on a
`SeqInt` word type built directly, and that it is the only check that does.

`examples/programs/cases.json`'s `reserved-type-name` case now expects
`firth.type.unknown-type` in place of `firth.compile.invalid-word-type`:
the same program is still refused, earlier and with a code that says why.
This changes an expected output, so this record is its authority (rule 2).
It is not a narrowing: nothing accepted before by the whole pipeline
(check, compile and run) is refused now, as the evidence below shows.

## Rejected options

- Accepting `SeqInt` and `SeqBool` as source spellings of `Seq Int` and
  `Seq Bool`: no reports would change for the two names, but every program
  would then have two spellings of one type, the compiler's injectivity
  guard would have to become a normalisation, and the guide would teach
  both. It also does nothing for `Seq` or `Foo`.
- Refusing only `Seq` with no element type: it fixes the case seen in the
  run but leaves every other unknown name to fail later and elsewhere.

## Evidence that nothing on main declares a type outside the list

Run on 11 October 2026 over 6,959 unique sources: every `solutions-*.json`
answer under `eval/s7` (MVP and harder tiers, every kept run, including the
scored run and its rescore pins), every `.firth` file under `examples/` and
`stdlib/`. Each was checked by main's checker (ff6e72a) and this branch's,
through `firthElaborate`, and the results compared.

Of the 6,959 sources, 284 get a different first report and two change
between accepted and refused. Every source the branch refuses with
`firth.type.unknown-type` is one of four, each already refused on main by
the checker, the compiler or the runner:

| Source | Main | Branch |
| --- | --- | --- |
| `eval/s7/harder/runs/2026-10-11-scored/haiku-firth-4/solutions-1.json`, sokoban | checks; the runner refuses every case ("initial stack type mismatch", `todo.unknown-base-type`) | `Seq` needs its element type |
| the same file, regex | `firth.type.declared-effect-mismatch` | `Seq` needs its element type |
| the same file, swiss | `firth.type.declared-effect-mismatch` | `Seq` needs its element type |
| `examples/programs/refused/reserved-type-name.firth` | checks; the compiler refuses it (`firth.compile.invalid-word-type`) | `SeqInt` is not a type |

(Each eval answer also appears, unchanged, under the run's `rescore-pin/`.)
The other 280 changes are first reports that become
`firth.syntax.underscore-in-name` (`invalid-token` 91, `unexpected-token` 62,
`expected-name` 62, `invalid-item` 39, `overlong-character` 24) and the two
rounds of deepseek-firth-9's sokoban, which go from `unexpected-eof` at the
end of the file to `firth.syntax.unnamed-stack-item` at line 1, column 57.
Of the scored run's 305 answers, the 38 whose report on main named `_` all
now get `firth.syntax.underscore-in-name`.

The comparison sends each source to each binary as one request and keeps
the first report's code, or `ok` when it checks:

```python
def run(binary, src):
    out = subprocess.run([binary], input=json.dumps({"request_id": "c",
        "source_path": "a.firth", "source_text": src,
        "language_version": "0.1", "gamma_version": "0.8"}),
        capture_output=True, text=True).stdout
    o = json.loads(out)
    return json.dumps(o.get("diagnostics", []), sort_keys=True) \
        if o.get("status") != "success" else "ok"
```

over `glob("eval/s7/**/solutions-*.json")` (each task's source) and
`glob("examples/**/*.firth") + glob("stdlib/**/*.firth")`, deduplicated by
text, with `binary` the `firthElaborate` built at ff6e72a and at this
branch.

The S7 eval inputs (`docs/getting-started.md`, `docs/firth-agent-guide.md`,
`examples/programs/README.md`, `AGENTS.md`) declare only `Int`, `Bool`,
`World`, `Handle` and `Bytes` in their examples, and the guide's placeholder
`name:Type^usage`:

```sh
grep -hoE "[a-z0-9?!-]+:[A-Z][A-Za-z]*( [A-Z][a-z]+)?" docs/firth-agent-guide.md \
  docs/getting-started.md examples/programs/README.md AGENTS.md \
  | sed 's/^[^:]*://' | sort | uniq -c
```

```text
      2 Bool
      1 Bytes
      2 Handle
     28 Int
      1 Type
      2 World
```

## Status

Accepted on 2026-10-11 by the project coordinator under the maintainer's
delegation ("you decide; hard now, easy later"), with these conditions:
keep the compiler's reserved-name guard with a Lean test that it still fires
on a word type built directly; show and commit the evidence that nothing on
main declares a type outside the list; and say here why `Unit` is excluded,
where the list comes from, and that `World`, `Handle` and `Bytes` come from
the world primitives' schemes. It amends section 3 of `spec/surface/syntax.md`
and adds a row to section 5 of `spec/types/type-system.md`. It changes no
kernel rule.
