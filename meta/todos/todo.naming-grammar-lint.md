---
node: firth.language.surface
status: open
created: 2026-09-09
---

Requires: surface-syntax-spec

## Goal

Implement the PRD R17 naming-grammar lint. Today no naming lint exists: the
only lint codes in `src/elaborator/Firth/*.lean` are `LOCAL_DEPTH` and
`STACK_JUGGLE`, and `spec/surface/syntax.md` section 1 defines only the
lexical `word-name` production, not the closed morpheme set, composition
rules and affix symbols that PRD 4.1 names. `surface-syntax-spec` is design
evidence for R17, never implementation evidence.

## Acceptance criteria

- Land the normative naming grammar in `spec/surface` through an accepted
  decision: a closed English morpheme set, deterministic composition rules
  and a small fixed affix symbol set, consistent with the lexical `word-name`
  production. This is a surface concern (kernel spec section 10) and amends
  no frozen kernel rule.
- Check every defined and referenced word name against that grammar.
  Violations are lint warnings with a stable code, never errors; they change
  no erasure output and no checked kernel term.
- Emit each warning through the accepted diagnostic envelope with the span
  and the offending morpheme or affix, deterministically across repeated
  elaboration.
- Add positive, negative and boundary cases to the Lean suites under the
  `lake test` driver plus one case through the public source runner; the
  zero-admit gate stays green.

## Traceability

PRD R17 and 4.1 naming grammar; obligations `req-r17` and
`scope-language-naming-grammar`. Opened by the baseline obligation audit
(`meta/changes/baseline-obligation-audit/`) at `80a9d41`.
