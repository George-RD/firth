# Cairn feedback log

Friction recorded by `cairn feedback`. Triage entries into upstream issues at
https://github.com/cairn-framework/cairn/issues/new

## 2026-07-16T17:01:15Z (cairn 0.3.0)

Cairn 0.3.0 reports CAIRN_PATH_GITIGNORED for .claude even though git check-ignore -v .claude returns no match; files under .claude are consequently treated as unreconciled or Ghost. Please investigate dot-directory reconciliation.
