# Proposal: quotation-erasure-regressions

The first real differential campaign at `52696f539b99aef57bd53d55ce067b0c97119d34`
rejected all 72 cases at `[ dup drop ]`. The erasure input-search bound counts
word and primitive signatures but omits kernel atoms, so it only tries an empty
input for a quotation containing only stack atoms. Direct source `dip` is also
missing from the erasure cases although the parser, checker and kernel know it.

Count kernel input arities conservatively in the finite quotation search. Add
the missing direct `dip` erasure rule and executable case, matching the existing
higher-order atom rules. Do not change kernel semantics or type/linearity
checking. Keep the original generator and failure artefacts unchanged.

Add exact kernel goldens for unary, binary, cumulative and nested quotation
inputs and explicit `dip`. Verify the same real seed matrix, Lean proof suites
and complete repository gates. This governed source change intentionally
invalidates old source/compiled bindings; regenerate only from the declared
source and actual pinned Lean build, then verify final pins without rewriting.
