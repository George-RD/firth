import Lean
import compiler.Firth.ProofRecords

/-!
The audit of axioms behind AGENTS.md rule 11: every declaration of this
repository's built modules may rest only on `propext`, `Classical.choice` and
`Quot.sound`.

The source scan in `tools/loop/check_zero_admit.py` finds the escape-hatch
keywords by name, but not every spelling of the same trust: `decide +native` and a direct use of
`Lean.ofReduceBool` also make a proof rest on the compiled evaluator. This
audit reads the environment that `lake build` produced instead of the text, so
it sees the constant each spelling leaves behind (`sorryAx`,
`Lean.ofReduceBool`, `Lean.ofReduceNat`, `Lean.trustCompiler`, the auxiliary
`_native` axioms and any other constant declared without a proof), however it
was written.

`firthAxiomAudit MODULE...` imports the named modules and walks every constant
declared in one of them, through types, values and inductive constructors, as
`ProofRecords.reach` does for a record. It prints each constant that reaches any
other axioms, naming them, and exits 1. `exempt` names the one declaration
that rests on refused axioms on purpose. `tools/loop/check_zero_admit.py` runs
it once for each `.lean` file under `src`.
-/

namespace Firth.Compiler.AxiomAudit
open Lean

/-- Declarations allowed to rest on refused axioms, and why. The walk still
passes through them, so anything else that uses one is refused, and a renamed
one is refused under its new name. -/
def exempt : List (Name × String) :=
  [(`Firth.ProofTests.Refused.trustsCompiler,
    "the proof-record audit's planted refusal (src/prooftests/Refused.lean)")]

/-- The refused axioms `name` reaches. -/
def refusedFrom (env : Environment) (roots : List Name) : Except String (List Name) := do
  let (_, axioms) ← Firth.Compiler.ProofRecords.reach.go env roots {} {}
  pure (axioms.toList.filter (!Firth.Compiler.ProofRecords.allowedAxioms.contains ·)
    |>.mergeSort (fun a b => a.toString ≤ b.toString))

/-- The constants declared in `modules`, less the exempt ones, sorted. -/
def declaredIn (env : Environment) (modules : List Name) : List Name :=
  let indices := modules.filterMap env.getModuleIdx?
  let names := env.constants.map₁.toList.filterMap fun (name, _) =>
    match env.getModuleIdxFor? name with
    | some index => if indices.contains index && !(exempt.any (·.1 == name)) then some name else none
    | none => none
  names.mergeSort (fun a b => a.toString ≤ b.toString)

/-- Audit the declarations of `module` in `env`. Returns how many there were,
or the refusals. -/
def auditModule (env : Environment) (module : Name) : Except (List String) Nat := Id.run do
  -- A module missing from its own environment would have no declarations and
  -- pass silently; a module that only re-exports others is fine.
  if (env.getModuleIdx? module).isNone then
    return .error [s!"{module}: not found in its own environment"]
  let roots := declaredIn env [module]
  -- One walk from every root settles the common case; only a failure pays for
  -- a walk per root to name the culprits.
  match refusedFrom env roots with
  | .error message => .error [s!"{module}: {message}"]
  | .ok [] => .ok roots.length
  | .ok _ =>
      let mut refusals := []
      for root in roots do
        match refusedFrom env [root] with
        | .ok [] => pure ()
        | .ok axioms => refusals := refusals ++ [s!"{root} rests on {axioms}"]
        | .error message => refusals := refusals ++ [s!"{root}: {message}"]
      return .error refusals

def main (args : List String) : IO UInt32 := do
  if args.isEmpty then
    IO.eprintln "usage: firthAxiomAudit MODULE..."
    return 2
  initSearchPath (← findSysroot)
  let modules := args.map String.toName
  -- The named modules are imported together, so they must not clash: each
  -- executable's root module declares `main`, and the caller audits those
  -- one at a time.
  let env ← importModules (modules.map ({ module := · })).toArray {}
  let mut declarations := 0
  let mut refusals : List String := []
  for module in modules do
    match auditModule env module with
    | .ok count => declarations := declarations + count
    | .error found => refusals := refusals ++ found
  unless refusals.isEmpty do
    for refusal in refusals do IO.eprintln s!"refused: {refusal}"
    return 1
  IO.println s!"audit of axioms passed: {declarations} declarations in {modules.length} modules rest only on {Firth.Compiler.ProofRecords.allowedAxioms}"
  return 0

end Firth.Compiler.AxiomAudit
