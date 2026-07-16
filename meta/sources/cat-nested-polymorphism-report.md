---
id: src.cat-nested-polymorphism-report
file: https://groups.google.com/g/catlanguage/c/LiBFXXoO7bA
verification: external
type: language designer issue report
date: 2026-07-16
---

Christopher Diggins' 2008 report that Cat did not handle nested polymorphism
compositionally. The factored programs `[id] dup dip` and `[id] dd` received
different inferred types because polymorphic variables were not handled
correctly. This is evidence of inference incompleteness and instability, not a
demonstrated runtime type-safety counterexample.
