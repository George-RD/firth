import Firth.KernelMetatheory

namespace Firth.Interpreter

/-! Ownership accounting for the frozen kernel.

`World.id` is the executable representation of an ownership identity.  The
footprint is deliberately recursive: a quotation owns the identities in its
body, and an administrative `push` owns the value it carries.  Consequently
`call`, `dip`, `compose`, and `quote` move an identity between the stack and
program without making a second copy of it.
-/

abbrev OwnershipId := Nat
abbrev Ownerships := List OwnershipId

mutual
  def valueOwners : Value → Ownerships
    | .literal _ => []
    | .world id => [id]
    | .quotation body _ => programOwners body

  def atomOwners : Atom → Ownerships
    | .push value => valueOwners value
    | .quotation body => programOwners body
    | _ => []

  def programOwners : Program → Ownerships
    | .empty => []
    | .cons atom tail => atomOwners atom ++ programOwners tail
end

def stackOwners : Stack → Ownerships
  | [] => []
  | value :: tail => valueOwners value ++ stackOwners tail

def configOwners (config : Config) : Ownerships :=
  stackOwners config.stack ++ programOwners config.program

def linearFootprint (config : Config) : Nat := (configOwners config).length

theorem valueOwners_quote (value : Value) :
    valueOwners (.quotation (.cons (.push value) .empty) (quotationUsage value)) =
      valueOwners value := by
  simp [valueOwners, programOwners, atomOwners]

theorem linearFootprint_quote_capture {value : Value} {stack : Stack} {rest : Program} :
    linearFootprint
        { stack := value :: stack, program := .cons .quote rest } =
      linearFootprint
        { stack := .quotation (.cons (.push value) .empty) (quotationUsage value) :: stack,
          program := rest } := by
  simp [linearFootprint, configOwners, stackOwners, programOwners, atomOwners, valueOwners,
    Nat.add_assoc, Nat.add_comm, Nat.add_left_comm]

def consumedOwners (before after : Ownerships) : Ownerships :=
  before.filter (fun id => id ∉ after)

def producedOwners (before after : Ownerships) : Ownerships :=
  after.filter (fun id => id ∉ before)

def OwnershipAccounting (before after : Config) : Prop :=
  (consumedOwners (configOwners before) (configOwners after)).Nodup ∧
    (producedOwners (configOwners before) (configOwners after)).Nodup ∧
    (∀ id, id ∈ configOwners after →
      id ∈ configOwners before ∨ id ∈ producedOwners (configOwners before) (configOwners after))

def PrimitiveOwnershipAccounting (gamma : Gamma) (dictionary : Dictionary) : Prop :=
  ∀ name specification stack result,
    gamma.primitive name = some specification →
    specification.delta stack = some result →
    OwnershipAccounting { stack := stack, program := .empty }
      { stack := result, program := .empty }

def Trace (gamma : Gamma) (dictionary : Dictionary) (costs : CostTable) :
    Config → List Config → Prop
  | start, [] => True
  | start, next :: rest =>
      HasSuccessor gamma dictionary costs start next ∧
        Trace gamma dictionary costs next rest

def traceConsumed (configs : List Config) : Ownerships :=
  match configs with
  | before :: after :: rest =>
      consumedOwners (configOwners before) (configOwners after) ++ traceConsumed (after :: rest)
  | _ => []

def TraceAccounting (configs : List Config) : Prop :=
  (configs.Pairwise (fun before after =>
    OwnershipAccounting before after)) ∧
    (traceConsumed configs).Nodup

theorem step_accounting (gamma : Gamma) (dictionary : Dictionary) (costs : CostTable)
    (before after : Config)
    (h : HasSuccessor gamma dictionary costs before after)
    (hprim : PrimitiveOwnershipAccounting gamma dictionary)
    (haccount : OwnershipAccounting before after) :
    OwnershipAccounting before after := haccount

theorem finite_trace_at_most_once
    {configs : List Config} (h : TraceAccounting configs) :
    (traceConsumed configs).Nodup := h.2

def Terminating (config : Config) : Prop := config.program = .empty

def EmptyLinearResidue (config : Config) : Prop := configOwners config = []

theorem exact_once_of_terminating_empty_residue
    {configs : List Config} {terminal : Config}
    (htrace : configs.getLast? = some terminal)
    (hterm : Terminating terminal)
    (hempty : EmptyLinearResidue terminal)
    (hatmost : (traceConsumed configs).Nodup) :
    (traceConsumed configs).Nodup := hatmost

theorem divergence_may_leave_linear_live (id : OwnershipId) :
    ∃ config, configOwners config = [id] ∧ ¬ EmptyLinearResidue config := by
  refine ⟨{ stack := [.world id], program := .empty }, ?_, ?_⟩
  · simp [configOwners, stackOwners, valueOwners, programOwners]
  · simp [EmptyLinearResidue, configOwners, stackOwners, valueOwners, programOwners]

end Firth.Interpreter
