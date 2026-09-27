import exports.Programs.SumTo

/-!
Theorems the proof-record audit must refuse. `tools/loop/test_proof_records.py`
names each one in a contract and expects `firthProofRecords` to fail.
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

/-- An honest theorem about an export, used to show the audit accepts one. -/
theorem honest : words.length = 2 := rfl

end Firth.ProofTests.Refused
