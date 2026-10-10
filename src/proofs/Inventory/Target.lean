import compiler.Firth.ContractTarget
import proofs.Inventory.Host

/-!
The allocator's two recorded contracts carried to the target semantics.

`allocate_batch_target` and `allocate_batch_host_target` state, for every image
that publishes each word of `examples/inventory/allocator.firth` as the
compiler lowers it, what `TargetHolds` says (`compiler/Firth/ContractTarget.lean`):
running `allocate-batch`'s target name from a stack that stands for the
contract's input, given at least the contract's step bound as fuel, the target
halts with a stack that stands for the contract's output at a kernel cost
within the contract's cost bound, unless it exceeds its 256-frame call-depth
bound or takes the length of a sequence of 2^63 or more elements. The step
bound grows with the number of requests and the contract does not cap it; the
spec's limit of 64 requests is checked by the host. Up to 64 requests the step
bound is at most 361,269, inside the 1,000,000 fuel the inventory cases run
with, so on the target semantics no batch the host admits runs out of fuel
outside those two exceptions. When the reference run reaches a length overflow
the theorem says nothing about the target; that this cannot happen on admitted
input is inferred, not proved.

These are facts about the target semantics, a Lean model of `target-spec.md`.
The Rust VM is tested against it, not proved; `examples/inventory/run_cases.py`
checks that the image it hands the VM publishes the words these records cover,
by body digest. `specs/tcb-boundary.toml` names the parts that remain trusted.
-/

namespace Firth.Proofs.Inventory.Target
open Firth.Exports.Inventory.Allocator
open Firth.Compiler.ContractTarget

/-- The export's dictionary gives each exported word its body. -/
theorem dictionary_bodies :
    ∀ p ∈ exportPrograms words, ∃ e, dictionary p.1 = some e ∧ e.body = p.2 := by
  intro p hp
  simp only [exportPrograms, words, List.map_cons, List.map_nil, List.mem_cons,
    List.not_mem_nil, or_false] at hp
  rcases hp with rfl | rfl | rfl | rfl | rfl | rfl | rfl | rfl | rfl | rfl <;> exact ⟨_, rfl, rfl⟩

theorem allocate_batch_member : ("allocate-batch", «allocate-batch».body) ∈ exportPrograms words := by
  simp [exportPrograms, words]

theorem allocate_batch_target :
    TargetHolds Allocate.allocateBatchContract dictionary (exportPrograms words) "allocate-batch"
      «allocate-batch».body :=
  targetHolds_of_holds Allocate.allocate_batch_contract dictionary_bodies allocate_batch_member

theorem allocate_batch_host_target :
    TargetHolds Host.allocateBatchHostContract dictionary (exportPrograms words) "allocate-batch"
      «allocate-batch».body :=
  targetHolds_of_holds Host.allocate_batch_host_contract dictionary_bodies allocate_batch_member

end Firth.Proofs.Inventory.Target
