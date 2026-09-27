import exports.Programs.SumTo
import exports.Programs.Allocate
import Firth.ProgramLogic

/-!
Theorems the proof-record audit must refuse. `tools/loop/update_proof_records.py`
names each one in a contract and requires `firthProofRecords` to refuse it
with the expected reason.
-/

namespace Firth.ProofTests.Refused
open Firth.Exports.Programs.SumTo

/-- Mentions an export but is proved with `native_decide`, which rests on
`Lean.ofReduceBool` rather than on the kernel. -/
theorem native (_ : words.length = words.length) : (2 : Nat) + 2 = 4 := by
  native_decide

/-- Proved honestly but says nothing about any exported word. -/
theorem unrelated : (2 : Nat) + 2 = 4 := rfl

/-- A definition, not a theorem. -/
def notATheorem : Nat := words.length

/-- Mentions the export's `words` but names no word body and no call. -/
theorem namesNoWord : words.length = 2 := rfl

open Firth.Interpreter Firth.Logic Firth.ReferenceRun in
/-- About the exported `over` body, but run under a dictionary of its own, so
any call in it would not run the exported words. -/
theorem foreignDictionary (a b : Value) (tail : Stack) :
    Runs adapterGamma (fun _ => none) defaultCosts Firth.Exports.Programs.Allocate.«over».body
      (b :: a :: tail) (a :: b :: a :: tail) 5 4 := by
  runs_chain

end Firth.ProofTests.Refused
