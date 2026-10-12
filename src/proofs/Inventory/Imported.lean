import proofs.Inventory.Target
import exports.Inventory.AllOrNothing

/-!
The allocator's two recorded contracts in a program that imports it.

`examples/inventory/policy-change/all-or-nothing.firth` imports
`examples/inventory/allocator.firth` (`dec.multi-file-imports`). Its export
dictionary (`exports/Inventory/AllOrNothing.lean`) gives every word the
allocator defines the same entry the allocator's own export gives it
(`allocator_extends`), and adds the client's own word, `reserve`. A run only
consults the dictionary to unfold a word, so a contract proved under the
allocator's dictionary holds under any dictionary that extends it
(`WordContract.Holds.extend` in `Firth/ProgramLogic.lean`). The two contracts
proved of `allocate-batch` in `Allocate.lean` and `Host.lean` therefore hold of
`allocate-batch` in the importing program, whose body is the same program, and
`targetHolds_of_holds` carries each to the target semantics of the importing
program's image, with the exceptions `TargetHolds` states.

Nothing here is proved again about the allocator: these theorems are the
allocator's, restated for the importing program's dictionary. They cover the
allocator's words in that program, not `reserve`, which has no contract.
-/

namespace Firth.Proofs.Inventory.Imported
open Firth.Interpreter
open Firth.Logic
open Firth.Compiler.ContractTarget

open Firth.Exports.Inventory.AllOrNothing

/-- The importing program's dictionary gives every allocator word the entry
the allocator's own export gives it. -/
theorem allocator_extends :
    DictionaryExtends dictionary Firth.Exports.Inventory.Allocator.dictionary := by
  intro name entry h
  unfold Firth.Exports.Inventory.Allocator.dictionary at h
  split at h <;> first | (cases h; rfl) | cases h

theorem allocate_batch_contract :
    Allocate.allocateBatchContract.Holds int64Gamma dictionary defaultCosts «allocate-batch».body :=
  Allocate.allocate_batch_contract.extend allocator_extends

theorem allocate_batch_host_contract :
    Host.allocateBatchHostContract.Holds int64Gamma dictionary defaultCosts «allocate-batch».body :=
  Host.allocate_batch_host_contract.extend allocator_extends

/-- The export's dictionary gives each exported word its body. -/
theorem dictionary_bodies :
    ∀ p ∈ exportPrograms words, ∃ e, dictionary p.1 = some e ∧ e.body = p.2 := by
  intro p hp
  simp only [exportPrograms, words, List.map_cons, List.map_nil, List.mem_cons,
    List.not_mem_nil, or_false] at hp
  rcases hp with rfl | rfl | rfl | rfl | rfl | rfl | rfl | rfl | rfl | rfl | rfl <;>
    exact ⟨_, rfl, rfl⟩

theorem allocate_batch_member : ("allocate-batch", «allocate-batch».body) ∈ exportPrograms words := by
  simp [exportPrograms, words]

theorem allocate_batch_target :
    TargetHolds Allocate.allocateBatchContract dictionary (exportPrograms words) "allocate-batch"
      «allocate-batch».body :=
  targetHolds_of_holds allocate_batch_contract dictionary_bodies allocate_batch_member

theorem allocate_batch_host_target :
    TargetHolds Host.allocateBatchHostContract dictionary (exportPrograms words) "allocate-batch"
      «allocate-batch».body :=
  targetHolds_of_holds allocate_batch_host_contract dictionary_bodies allocate_batch_member

end Firth.Proofs.Inventory.Imported
