#!/usr/bin/env bash
set -euo pipefail

repo_root=$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)
cd "$repo_root"

audit_file=$(mktemp "${TMPDIR:-/tmp}/firth-axiom-audit.XXXXXX.lean")
audit_output=$(mktemp "${TMPDIR:-/tmp}/firth-axiom-audit.XXXXXX.out")
trap 'rm -f "$audit_file" "$audit_output"' EXIT

python3 - "$audit_file" <<'PY'
from pathlib import Path
import re
import sys

output = Path(sys.argv[1])
files = [
    (Path("src/interpreter/Firth/Linearity.lean"), "Firth.Interpreter"),
    (Path("src/interpreter/FirthTest.lean"), ""),
]
declaration = re.compile(
    r"^\s*(?:@\[[^\]]+\]\s*)*(?:private\s+)?"
    r"(?:def|theorem|abbrev|structure|inductive|class|opaque|axiom|instance)\s+"
    r"([A-Za-z_][A-Za-z0-9_']*(?:\.[A-Za-z_][A-Za-z0-9_']*)?)\b"
)

names = []
for path, namespace in files:
    for line in path.read_text().splitlines():
        match = declaration.match(line)
        if match:
            name = match.group(1)
            # The executable `def main : IO Unit` in FirthTest is a test
            # entrypoint, not a theorem or library definition to audit.
            if name == "main":
                continue
            names.append(f"{namespace}.{name}" if namespace else name)

if len(names) != len(set(names)):
    duplicates = sorted(name for name in set(names) if names.count(name) > 1)
    raise SystemExit(f"duplicate declarations in audit input: {duplicates}")

with output.open("w") as handle:
    handle.write("import FirthTest\n")
    handle.write("\n".join(f"#print axioms {name}" for name in names))
    handle.write("\n")
PY

lake build firthTest >/dev/null
lake env lean "$audit_file" >"$audit_output" 2>&1

if rg -n 'error:|sorryAx|Classical\.choice|Quot\.sound|funext|propext,|, propext' "$audit_output"; then
  echo "axiom audit failed" >&2
  exit 1
fi

if rg -n 'depends on axioms:' "$audit_output" | rg -v 'depends on axioms: \[propext\]$'; then
  echo "axiom audit found an axiom other than propext" >&2
  exit 1
fi

if ! rg -q "does not depend on any axioms|depends on axioms: \[propext\]" "$audit_output"; then
  echo "axiom audit produced no declaration results" >&2
  exit 1
fi

count=$(rg "does not depend on any axioms|depends on axioms: \[propext\]" "$audit_output" | wc -l | tr -d ' ')
echo "audited ${count} declarations; allowed axioms: propext only"
