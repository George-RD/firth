#!/usr/bin/env bash
set -euo pipefail

root=$(CDPATH= cd -- "$(dirname -- "$0")/../.." && pwd)

(cd "$root" && python3 tools/loop/test_tcb_boundary.py)
fixture="$root/src/runtime/vm/fixtures/kernel.tsv"
generated=$(mktemp)
trap 'rm -f "$generated"' EXIT

(cd "$root" && lake exe firthVmFixtures >"$generated")
if ! cmp -s "$generated" "$fixture"; then
  diff -u "$fixture" "$generated" || true
  echo "kernel fixture is not byte-identical to lake exe firthVmFixtures output" >&2
  exit 1
fi
