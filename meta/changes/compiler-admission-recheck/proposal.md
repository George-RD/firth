# Proposal: compiler-admission-recheck

Close the `language-02-compiler-evidence` compiler-input bypass. The current
adapter trusts caller-written `checked`/`available` markers and the lowerer
emits content hashes in legacy evidence slots without rechecking the body.

Recheck the complete kernel dictionary with the existing Lean stack-effect and
ownership checker before returning any compiled artefact. For source-backed
execution, re-elaborate the submitted source inside the compiler and compare
all supplied bodies and types with that result. Keep direct kernel compilation
available, but explicitly report that it does not authenticate source origin.

Do not infer refinement proofs from type checking, content digests or JSON
markers. Preserve the target v1 wire format and document its unauthenticated
legacy evidence fields. Runtime image admission and SMT record authentication
remain separate blockers. Preserve the existing authored corpus and proof
statements; refresh source/compiled pins only from the changed build inputs.
