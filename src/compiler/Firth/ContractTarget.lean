import compiler.Firth.LoweringSimulation

/-!
A word contract carried from the reference interpreter to the target.

Step 4 of `todo.compiler-vm-agreement-proof`.

A proof record's contract is a `RunsWithin` fact about an exported word's body
under `int64Gamma` (`WordContract.Holds`). `targetHolds_of_holds` turns it,
through `execute_of_reaches` in `LoweringSimulation.lean`, into a fact about the
target semantics running an image that publishes every exported word as
`lowerProgram` lowers it: from a stack that stands for the contract's input and
with at least the contract's step bound as fuel, the target halts with a stack
that stands for the contract's output, at a kernel cost within the contract's
cost bound. The stated exceptions are those of `compileWords_correct`: the
target exceeds its 256-frame call-depth bound, or the run takes the length of a
sequence with 2^63 or more elements.

`PublishesLowering` is what the gate can check of the image the VM is given:
each exported word published under the name `nameMapOf` gives it, with the code
whose `body_digest` the export records. The digest comparison, the JSON the
compiler emits, the Rust decoder and the VM itself are outside this theorem;
`specs/tcb-boundary.toml` names them.

Only the kernel cost is related. The target's total cost, which adds a charge
per word entry, is not, and neither is the cost of a run that faults.
-/

namespace Firth.Compiler.ContractTarget

open Firth.Compiler Firth.Compiler.Lowering Firth.Compiler.TargetSemantics
open Firth.Compiler.LoweringCorrect

/-- An export's words as name and kernel program, from the
`(name, body, bodyDigest, erasedType)` rows `src/exports/` declares. -/
def exportPrograms (words : List (String × Firth.Interpreter.Program × String × String)) :
    List (String × Firth.Interpreter.Program) :=
  words.map fun row => (row.1, row.2.1)

/-- The image publishes each word under the target name the map `M` gives it,
as the code `lowerProgram` lowers its body to. -/
def PublishesLowering (M : List (String × String)) (words : List (String × Firth.Interpreter.Program))
    (image : List Target.WordEntry) : Prop :=
  ∀ p ∈ words, ∃ target w, M.find? (fun e => e.1 == p.1) = some (p.1, target) ∧
    image.find? (·.name == target) = some w ∧
    lowerProgram { word := p.1, words := M } p.2 = .ok w.code

/-- What the target does with `word`, whose body is `body`, under `contract`:
for every image that publishes the lowering of `words`, running `word`'s target
name from a stack that stands for the contract's input, given at least the
contract's step bound as fuel, halts with a stack that stands for its output at
a kernel cost within its cost bound, unless the target exceeds its call-depth
bound or the run takes the length of a sequence too long for an `i64`. -/
def TargetHolds (contract : Firth.Logic.WordContract) (D : Firth.Interpreter.Dictionary)
    (words : List (String × Firth.Interpreter.Program)) (word : String)
    (body : Firth.Interpreter.Program) : Prop :=
  ∀ M image, nameMapOf (words.map (·.1)) = .ok M → PublishesLowering M words image →
    ∃ target, M.find? (fun e => e.1 == word) = some (word, target) ∧
      ∀ (args : contract.Args) tail stack fuel, contract.pre args →
        ListRel (ValRel M) (contract.input args ++ tail) stack → contract.steps args ≤ fuel →
        (∃ s m', execute image target stack fuel = .halted s m' ∧
            ListRel (ValRel M) (contract.output args ++ tail) s ∧ m'.cost.kernel ≤ contract.cost args) ∨
          (∃ m', execute image target stack fuel = .trapped .callDepthExceeded m') ∨
          (∃ cfg n k, Firth.Logic.Reaches Firth.Logic.int64Gamma D Firth.Interpreter.defaultCosts
              ⟨contract.input args ++ tail, body⟩ cfg n k ∧ LenOverflowAt cfg)

/-- An image that publishes the lowering of `words` stands for a dictionary
that gives each of them its body. -/
theorem imageRel_of_publishes {D : Firth.Interpreter.Dictionary}
    {words : List (String × Firth.Interpreter.Program)} {M : List (String × String)}
    {image : List Target.WordEntry}
    (hD : ∀ p ∈ words, ∃ e, D p.1 = some e ∧ e.body = p.2)
    (hM : nameMapOf (words.map (·.1)) = .ok M) (himage : PublishesLowering M words image) :
    ImageRel M D image := by
  intro name entry hfind
  obtain ⟨hnames, _, _⟩ := nameMapOf_ok hM
  have hname : entry.1 = name := by simpa using List.find?_some hfind
  have : name ∈ words.map (·.1) := hnames ▸ hname ▸ List.mem_map_of_mem (List.mem_of_find?_eq_some hfind)
  obtain ⟨p, hp, rfl⟩ := List.mem_map.mp this
  obtain ⟨target, w, hfind', hw, hlower⟩ := himage p hp
  rw [hfind'] at hfind
  cases hfind
  obtain ⟨e, he, hbody⟩ := hD p hp
  exact ⟨e, w, he, hw, hbody ▸ lowerProgram_rel (context := { word := p.1, words := M }) rfl p.2 w.code hlower []⟩

/-- A contract proved of an exported word's body under `int64Gamma` and the
default costs holds of the target running any image that publishes the
lowering of the export's words, with the exceptions `TargetHolds` states. -/
theorem targetHolds_of_holds {contract : Firth.Logic.WordContract} {D : Firth.Interpreter.Dictionary}
    {words : List (String × Firth.Interpreter.Program)} {word : String} {body : Firth.Interpreter.Program}
    (hH : contract.Holds Firth.Logic.int64Gamma D Firth.Interpreter.defaultCosts body)
    (hD : ∀ p ∈ words, ∃ e, D p.1 = some e ∧ e.body = p.2) (hmem : (word, body) ∈ words) :
    TargetHolds contract D words word body := by
  intro M image hM himage
  have hI := imageRel_of_publishes hD hM himage
  obtain ⟨target, w, hfind, hw, hlower⟩ := himage _ hmem
  have hcode : CodeRel M [] w.code body :=
    lowerProgram_rel (context := { word := word, words := M }) rfl body w.code hlower []
  refine ⟨target, hfind, fun args tail stack fuel hpre hS hfuel => ?_⟩
  obtain ⟨steps, cost, hruns, hsteps, hcost⟩ := hH args tail hpre
  have hrun := hruns .empty
  rw [Firth.Logic.programAppend_empty] at hrun
  rcases execute_of_reaches hI hw hcode hS hrun (Nat.le_trans hsteps hfuel) with
    ⟨s, m', hex, hrel, hk⟩ | h | h
  · exact .inl ⟨s, m', hex, hrel, hk ▸ hcost⟩
  · exact .inr (.inl h)
  · exact .inr (.inr h)

end Firth.Compiler.ContractTarget
