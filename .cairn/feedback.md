# Cairn feedback log

Friction recorded by `cairn feedback`. Triage entries into upstream issues at
https://github.com/cairn-framework/cairn/issues/new

## 2026-07-16T17:01:15Z (cairn 0.3.0)

Cairn 0.3.0 reports CAIRN_PATH_GITIGNORED for .claude even though git check-ignore -v .claude returns no match; files under .claude are consequently treated as unreconciled or Ghost. Please investigate dot-directory reconciliation.

## 2026-07-17T05:00:55Z (cairn 0.5.0)

select_unit.py silently drops Requires edges written as a ## Requires heading with bullets and fails open (dependents become eligible); parser only accepts inline Requires: lines
