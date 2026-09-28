#!/usr/bin/env python3
"""Fail if Lean source or the built environment uses a proof escape hatch.

Two checks, both under AGENTS.md rule 11:

1. The source scan refuses the words `sorry`, `admit`, `axiom` and
   `native_decide` in `src/**/*.lean`. It is quick and needs no build, but it
   only knows those spellings.
2. The environment audit (`firthAxiomAudit`) reads what `lake build`
   produced and refuses every repository declaration that rests on an axiom
   other than `propext`, `Classical.choice` and `Quot.sound`. That also
   refuses `decide +native`, a direct `Lean.ofReduceBool` or
   `Lean.ofReduceNat`, `Lean.trustCompiler` and the auxiliary `_native`
   axioms, however they were written. Every `.lean` file under `src` is
   audited: Lake modules from their build, and the few files that are run with
   `lean --run` rather than built (the SMT process tests) are compiled into a
   scratch directory first.

Before auditing the repository, the audit is run on planted modules, each of
which must be refused naming the axiom it rests on, and on a clean one, which
must pass. `--source-only` runs the scan alone (for hosts without Lean).
"""

from __future__ import annotations

import os
from pathlib import Path
import re
import subprocess
import sys
import tempfile

pattern = re.compile(r"\b(?:sorry|admit|axiom|native_decide)\b")
AUDIT = Path(".lake/build/bin/firthAxiomAudit")
BUILD = Path(".lake/build/lib/lean")
# Compiled into a scratch directory under this prefix, so their names cannot
# collide with a repository module's.
SCRIPT_PREFIX = "FirthAuditScripts"
PLANT_PREFIX = "FirthAuditPlants"
# The module that holds the audit's one exempt declaration; every audit run
# includes it, since the audit refuses an exemption it cannot find.
EXEMPT_MODULE = "prooftests.Refused"

# Each plant must be refused, and the refusal must name its axiom.
PLANTS = {
    # Compiled evaluation leaves an auxiliary constant without a proof,
    # `t._native.decide.ax_1_1`, in place of `Lean.ofReduceBool`.
    "DecideNative": ("theorem t : 2 ^ 10 = 1024 := by decide +native\n", "t._native."),
    "NativeDecide": ("theorem t : 2 ^ 10 = 1024 := by native_decide\n", "t._native."),
    # A direct use of the constants compiled evaluation rests on.
    "OfReduceBool": ("theorem t : ∀ a b : Bool, Lean.reduceBool a = b → a = b := @Lean.ofReduceBool\n",
                     "Lean.ofReduceBool"),
    "OfReduceNat": ("theorem t : ∀ a b : Nat, Lean.reduceNat a = b → a = b := @Lean.ofReduceNat\n",
                    "Lean.ofReduceNat"),
    "TrustCompiler": ("theorem t : True := Lean.trustCompiler\n", "Lean.trustCompiler"),
    "Sorry": ("theorem t : 1 = 2 := sorry\n", "sorryAx"),
    "Axiom": ("axiom bad : 1 = 2\ntheorem t : 1 = 2 := bad\n", "bad"),
    # Resting on a refused axiom through another declaration is refused too.
    "Indirect": ("theorem h : 2 ^ 10 = 1024 := by decide +native\n"
                 "theorem t : 2 ^ 10 = 1024 ∧ True := ⟨h, trivial⟩\n", "h._native."),
}
CLEAN_PLANT = "theorem t : 2 + 2 = 4 := by decide\ndef n : Nat := 4\n"


def scan() -> list[str]:
    matches = []
    for path in sorted(Path("src").rglob("*.lean")):
        for line_number, line in enumerate(path.read_text().splitlines(), 1):
            if pattern.search(line):
                matches.append(f"{path}:{line_number}:{line.strip()}")
    return matches


def module_of(path: Path) -> str:
    """The module name Lake gives a source file: the `Firth` library's source
    directory is `src/interpreter`, every other library's is `src`."""
    root = Path("src/interpreter") if Path("src/interpreter") in path.parents else Path("src")
    return ".".join(path.relative_to(root).with_suffix("").parts)


def olean(root: Path, module: str) -> Path:
    return root.joinpath(*module.split(".")).with_suffix(".olean")


def run(command: list[str], **kwargs) -> subprocess.CompletedProcess:
    return subprocess.run(command, capture_output=True, text=True, **kwargs)


def fail(message: str, detail: str = "") -> None:
    print(f"axiom audit failed: {message}")
    if detail:
        print(detail.rstrip())
    sys.exit(1)


def audit(modules: list[str], lean_path: str) -> subprocess.CompletedProcess:
    return run([str(AUDIT), *modules], env={**os.environ, "LEAN_PATH": lean_path})


def compile_into(scratch: Path, module: str, source: str, origin: str) -> None:
    """Compile `source` as `module` into the scratch directory."""
    target = olean(scratch, module)
    file = target.with_suffix(".lean")
    file.parent.mkdir(parents=True, exist_ok=True)
    file.write_text(source)
    result = run(["lake", "env", "lean", f"--root={scratch}", str(file), "-o", str(target)])
    if result.returncode != 0:
        fail(f"cannot compile {origin}", result.stdout + result.stderr)


def environment() -> None:
    build = run(["lake", "build", "firthAxiomAudit"])
    if build.returncode != 0:
        fail("cannot build firthAxiomAudit", build.stdout[-4000:] + build.stderr[-4000:])
    lean_path = run(["lake", "env", "printenv", "LEAN_PATH"]).stdout.strip()
    if not lean_path:
        fail("lake env gave no LEAN_PATH")
    with tempfile.TemporaryDirectory(prefix="firth-axiom-audit-") as directory:
        scratch = Path(directory)
        scratch_path = f"{lean_path}:{scratch}"

        # Plants first: an audit that refuses nothing must not pass the repository.
        for name, (source, axiom_name) in {**PLANTS, "Clean": (CLEAN_PLANT, None)}.items():
            module = f"{PLANT_PREFIX}.{name}"
            compile_into(scratch, module, source, f"the planted {name}")
            result = audit([EXEMPT_MODULE, module], scratch_path)
            output = result.stdout + result.stderr
            if axiom_name is None:
                if result.returncode != 0:
                    fail(f"the clean plant {module} was refused", output)
            elif result.returncode != 1 or "\nrefused: t rests on" not in "\n" + output \
                    or axiom_name not in ("\n" + output).split("\nrefused: t rests on", 1)[1].splitlines()[0]:
                fail(f"the planted {name} was not refused naming {axiom_name}", output)

        modules = []
        for path in sorted(Path("src").rglob("*.lean")):
            module = module_of(path)
            if not olean(BUILD, module).exists():
                # Build a Lake module that the default targets leave out.
                result = run(["lake", "build", f"+{module}"])
                if result.returncode != 0 and "unknown module" in result.stdout + result.stderr:
                    # A file Lake does not know is run with `lean --run`.
                    module = f"{SCRIPT_PREFIX}.{module}"
                    compile_into(scratch, module, path.read_text(), str(path))
                elif result.returncode != 0:
                    fail(f"cannot build {module}", result.stdout[-4000:] + result.stderr[-4000:])
            modules.append(module)
        result = audit(modules, scratch_path)
        print((result.stdout + result.stderr).rstrip())
        if result.returncode != 0:
            fail("repository declarations rest on refused axioms")
        print(f"axiom audit refused all {len(PLANTS)} planted modules and passed the clean one")


def main(argv: list[str]) -> int:
    if argv not in ([], ["--source-only"]):
        print("usage: check_zero_admit.py [--source-only]")
        return 2
    matches = scan()
    if matches:
        print("zero-admit check failed")
        print("\n".join(matches))
        return 1
    print("zero-admit check passed")
    if not argv:
        environment()
    return 0


if __name__ == "__main__":
    sys.exit(main(sys.argv[1:]))
