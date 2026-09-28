import prooftests.Accepted

/-!
Theorems the proof-record audit must refuse. Their contracts are in
`src/prooftests/refused.json`, and `tools/loop/update_proof_records.py`
requires `firthProofRecords` to refuse each one with the expected reason.

`falseHypothesis`, `orTrue`, `registryOrTrue` and `vacuousPrecondition` are
the review probes on #138: each is provable without saying anything about
`sum-to`, and the audit before contracts accepted all of them as covering it.
-/

namespace Firth.ProofTests.Refused
open Firth.Interpreter Firth.Logic Firth.ReferenceRun
open Firth.Exports.Programs.SumTo
open Firth.Proofs.Programs.SumTo
open Firth.ProofTests.Accepted

/-- Mentions an export but rests on `Lean.trustCompiler`, which trusts the
compiled evaluator rather than the kernel; `native_decide` proofs rest on it
too. Naming it directly exercises the same refusal without a new
`native_decide`, which AGENTS.md rule 11 forbids even here. -/
theorem trustsCompiler (_ : words.length = words.length) : True :=
  Lean.trustCompiler

/-- A definition, not a theorem. -/
def notATheorem : Nat := words.length

/-- Proved honestly but says nothing about any exported word. -/
theorem unrelated : (2 : Nat) + 2 = 4 := rfl

/-- The contract, under a hypothesis that cannot hold. -/
theorem falseHypothesis (h : 1 = 2) :
    sumToContract.Holds int64Gamma dictionary defaultCosts «sum-to».body :=
  absurd h (by decide)

/-- The contract or `True`, which holds whatever the program does. -/
theorem orTrue :
    sumToContract.Holds int64Gamma dictionary defaultCosts «sum-to».body ∨ True :=
  .inr trivial

/-- A registry the audit does not know, with every primitive refused. -/
def weirdGamma : Gamma := { int64Gamma with primitive := fun _ => none }

/-- Names an allowed registry, but the claim about the program is under
another one and is `∨ True` besides. -/
theorem registryOrTrue : adapterGamma = adapterGamma ∧
    (sumToContract.Holds weirdGamma dictionary defaultCosts «sum-to».body ∨ True) :=
  ⟨rfl, .inr trivial⟩

/-- The shape of a contract whose precondition no input meets. `WordContract`
cannot be declared with such a precondition, because it needs a witness, so
the statement can only be written out by hand, and then it is not the
contract's. -/
theorem vacuousPrecondition : ∀ (n : Nat) (tail : Stack), (n : Int) < 0 →
    RunsWithin int64Gamma dictionary defaultCosts «sum-to».body
      (.literal (.int n) :: tail) (.literal (.int 0) :: tail) 0 0 :=
  fun n _ h => absurd h (by omega)

/-- `int64Gamma` under another name. The audit allows registries by name, so
even a copy is refused: it could be edited without the allowlist changing. -/
def renamedGamma : Gamma := int64Gamma

/-- A contract that holds under a registry the audit does not allow. -/
theorem otherRegistry :
    diffContract.Holds renamedGamma Firth.Exports.Programs.Signed.dictionary defaultCosts
      Firth.Exports.Programs.Signed.«diff».body :=
  int64Diff

/-- `diff`'s contract, but run under a dictionary of its own. -/
theorem foreignDictionary :
    diffContract.Holds int64Gamma (fun _ => none) defaultCosts
      Firth.Exports.Programs.Signed.«diff».body := by
  intro ⟨x, y⟩ tail (h : InInt64 (x - y))
  exact (show Runs int64Gamma _ defaultCosts _ _ _ 1 1 by runs_chain).within

end Firth.ProofTests.Refused
