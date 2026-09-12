# Proposal: smt-source-envelope

Close the transitive translation-helper binding gap in
`todo.language-01-smt-record-admission` (PRD G4, R8/R9/R15). Marked rule/proof
regions currently omit executable helpers such as `formulaBindings`,
`findBinding`, canonical identities and evaluation definitions. A helper edit
can change the solver question without changing the pinned translation hashes.

Bind every existing region hash to a conservative envelope of the complete
Lean source tree and its toolchain/build inputs. Keep the four rule and six
soundness regions and their pairing checks. Add failing-before/passing-after
mutation tests and regenerate compiled evidence from the pinned Lean build.

This does not authenticate a solver invocation. The parent admission task and
baseline acceptance stay open. No source application, acceptance corpus,
translation rule or theorem is changed.
