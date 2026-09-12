# Tasks: compiler admission recheck

- [x] Retain public-input reproducers against the current compiler.
- [x] Recheck all kernel bodies and types using the existing Lean checker.
- [x] Bind source-backed requests by real re-elaboration and exact comparison.
- [x] Report checking scope honestly and document the legacy digest limitation.
- [x] Add negative tests and verify the unchanged source campaign.
- [x] Run exact-candidate language, Python and Cairn gates and record evidence.

Verified against the exact candidate in CI run `34359174884`. See
`verification.md` for source/blob identities, before/after results and scope.
The product commit must independently pass normal PR CI before it is a
landing candidate. Other M0 blockers prevent merging PR #109 at this point.
