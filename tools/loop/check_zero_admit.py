#!/usr/bin/env python3
"""Fail if Lean source or the built environment uses a proof escape hatch.

Two checks, both under AGENTS.md rule 11:

1. The source scan refuses the words `sorry`, `admit`, `axiom` and
   `native_decide` in `src/**/*.lean`. It is quick and needs no build, but it
   only knows those spellings.
2. The environment audit (`firthAxiomAudit`) reads what `lake build`
   produced and refuses every repository declaration that rests on an axiom
   other than `propext`, `Classical.choice` and `Quot.sound`, except the one
   planted refusal the proof-record audit needs (`AxiomAudit.exempt`). That also
   refuses `decide +native`, a direct `Lean.ofReduceBool` or
   `Lean.ofReduceNat`, `Lean.trustCompiler` and the auxiliary `_native`
   axioms, however they were written. Every `.lean` file under `src` is
   audited: Lake modules after `lake build` has brought each up to date, and
   the few files that are run with `lean --run` rather than built (the SMT
   process tests) compiled from their current source into a scratch directory.

Before auditing the repository, the audit is run on planted modules, each of
which must be refused naming the axiom it rests on, and on a clean one, which
must pass. `--source-only` runs the scan alone (for hosts without Lean).
"""

from __future__ import annotations

from concurrent.futures import ThreadPoolExecutor
import os
from pathlib import Path
import re
import subprocess
import sys
import tempfile

pattern = re.compile(r"\b(?:sorry|admit|axiom|native_decide)\b")
AUDIT = Path(".lake/build/bin/firthAxiomAudit")
# Compiled into a scratch directory under this prefix, so their names cannot
# collide with a repository module's.
SCRIPT_PREFIX = "FirthAuditScripts"
PLANT_PREFIX = "FirthAuditPlants"

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
    # The exemption belongs to one declaration in one module; the same name
    # declared anywhere else is audited.
    "Impostor": ("theorem Firth.ProofTests.Refused.trustsCompiler : True := Lean.trustCompiler\n",
                 "Lean.trustCompiler", "Firth.ProofTests.Refused.trustsCompiler"),
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
        for name, (source, axiom_name, *declared) in {**PLANTS, "Clean": (CLEAN_PLANT, None)}.items():
            marker = f"refused: {declared[0] if declared else 't'} rests on"
            module = f"{PLANT_PREFIX}.{name}"
            compile_into(scratch, module, source, f"the planted {name}")
            result = audit([module], scratch_path)
            output = result.stdout + result.stderr
            if axiom_name is None:
                if result.returncode != 0:
                    fail(f"the clean plant {module} was refused", output)
            elif result.returncode != 1 or "\n" + marker not in "\n" + output \
                    or axiom_name not in ("\n" + output).split("\n" + marker, 1)[1].splitlines()[0]:
                fail(f"the planted {name} was not refused naming {axiom_name}", output)

        # Build every Lake module, so no stale artefact is audited: `lake build`
        # brings each named module up to date, including those the default
        # targets leave out. A file Lake does not know is run with
        # `lean --run`; it is compiled from its current source instead.
        paths = {module_of(path): path for path in sorted(Path("src").rglob("*.lean"))}
        lake, scripts = list(paths), []
        while True:
            build = run(["lake", "build", "firthAxiomAudit", *(f"+{module}" for module in lake)])
            unknown = re.search(r"unknown module `([^`]+)`", build.stdout + build.stderr)
            if build.returncode == 0:
                break
            if not unknown or unknown.group(1) not in lake:
                fail("cannot build the modules under src", build.stdout[-4000:] + build.stderr[-4000:])
            lake.remove(unknown.group(1))
            scripts.append(unknown.group(1))
        for module in scripts:
            compile_into(scratch, f"{SCRIPT_PREFIX}.{module}", paths[module].read_text(), str(paths[module]))
        modules = lake + [f"{SCRIPT_PREFIX}.{module}" for module in scripts]
        # Each module gets an environment of its own: modules that are never
        # imported together may declare the same name (every executable's
        # `main`, for one).
        with ThreadPoolExecutor(max_workers=os.cpu_count() or 1) as pool:
            results = list(pool.map(lambda module: audit([module], scratch_path), modules))
        refused = [result for result in results if result.returncode != 0]
        for result in refused:
            print((result.stdout + result.stderr).rstrip())
        if refused:
            fail(f"{len(refused)} of {len(modules)} modules rest on refused axioms")
        declarations = sum(int(re.search(r"passed: (\d+) declarations", result.stdout).group(1))
                           for result in results)
        print(f"audit of axioms passed: {declarations} declarations in {len(modules)} modules "
              "rest only on propext, Classical.choice and Quot.sound")
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
