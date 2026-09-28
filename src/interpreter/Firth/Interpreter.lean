namespace Firth.Interpreter

/-!
The executable definitions in this file follow `files/firth-kernel-spec-draft.md`.
The comments on `step` name the corresponding frozen small-step rules.
Stacks are represented top-first internally, so the first list element is the
rightmost value in the specification's bottom-to-top notation.
-/

inductive Usage where
  | many
  | linear
  deriving BEq, DecidableEq, Repr

inductive Literal where
  | int (value : Int)
  | bool (value : Bool)
  | unit
  /-- An immutable sequence of integers (`Seq Int` in source). Sequences are
  flat `many` data: they never hold a quotation or a linear value. -/
  | intSeq (values : List Int)
  /-- An immutable sequence of booleans (`Seq Bool` in source). -/
  | boolSeq (values : List Bool)
  deriving BEq, DecidableEq, Repr

abbrev Prim := String

inductive BaseType where
  | int
  | bool
  | unit
  | world
  | intSeq
  | boolSeq
  deriving BEq, DecidableEq, Repr

mutual
  inductive ValueType where
    | base (type : BaseType) (usage : Usage)
    | quotation (input output : StackType) (usage : Usage)
    deriving BEq, DecidableEq, Repr

  inductive StackType where
    | row (name : String)
    | snoc (rest : StackType) (value : ValueType)
    deriving BEq, DecidableEq, Repr
end

structure WordType where
  rowVariables : List String
  input : StackType
  output : StackType
  deriving BEq, Repr

mutual
  inductive Atom where
    | lit (value : Literal)
    | push (value : Value)
    | quotation (body : Program)
    | dup
    | drop
    | swap
    /-- Copy the value `depth` places below the top onto the top. -/
    | pick (depth : Nat)
    /-- Move the value `depth` places below the top onto the top. -/
    | roll (depth : Nat)
    | dip
    | call
    | compose
    | quote
    | ifThenElse
    | word (name : String)
    | prim (primitive : Prim)
    deriving BEq, Repr

  inductive Program where
    | empty
    | cons (head : Atom) (tail : Program)
    deriving BEq, Repr

  inductive Value where
    | literal (value : Literal)
    | quotation (body : Program) (usage : Usage)
    | world (id : Nat)
    deriving BEq, Repr
end

abbrev Stack := List Value

structure WordEntry where
  type : WordType
  body : Program
  deriving Repr

abbrev Dictionary := String → Option WordEntry

structure Config where
  stack : Stack
  program : Program
  deriving BEq, Repr

structure CostTable where
  atom : Atom → Nat
  primitive : Prim → Nat
  unfold : Nat

def defaultCosts : CostTable :=
  { atom := fun _ => 1, primitive := fun _ => 1, unfold := 1 }

/-- The value `depth` places below the top, and the stack without it. -/
def rollOut : Stack → Nat → Option (Value × Stack)
  | value :: tail, 0 => some (value, tail)
  | value :: tail, depth + 1 => (rollOut tail depth).map fun (moved, rest) => (moved, value :: rest)
  | [], _ => none

def Program.append : Program → Program → Program
  | .empty, right => right
  | .cons head tail, right => .cons head (append tail right)

def literalUsage : Literal → Usage
  | _ => .many

def quotationUsage (captured : Value) : Usage :=
  match captured with
  | .quotation _ usage => usage
  | .world _ => .linear
  | .literal literal => literalUsage literal

def usageMeet : Usage → Usage → Usage
  | .many, .many => .many
  | _, _ => .linear

mutual
  /-- The ownership footprint of a program's statically captured values. -/
  def programUsage : Program → Usage
    | .empty => .many
    | .cons head tail => usageMeet (atomUsage head) (programUsage tail)

  def atomUsage : Atom → Usage
    | .push value => quotationUsage value
    | .quotation body => programUsage body
    | _ => .many
end

structure PrimitiveSpec where
  input : StackType
  output : StackType
  delta : Stack → Option Stack
  /-- A partial primitive may fault on a well-typed stack (an out-of-range
  sequence index); `delta` is then `none` and execution stops with a
  primitive fault. Every other primitive must be total on its typed input,
  and progress is stated with that exception only. -/
  faults : Bool := false

structure Gamma where
  literalType : Literal → Option BaseType
  primitive : Prim → Option PrimitiveSpec

def addIntDelta : Stack → Option Stack
  | .literal (.int right) :: .literal (.int left) :: rest =>
      some (.literal (.int (left + right)) :: rest)
  | _ => none

def subIntDelta : Stack → Option Stack
  | .literal (.int right) :: .literal (.int left) :: rest =>
      some (.literal (.int (left - right)) :: rest)
  | _ => none

def mulIntDelta : Stack → Option Stack
  | .literal (.int right) :: .literal (.int left) :: rest =>
      some (.literal (.int (left * right)) :: rest)
  | _ => none

def ltIntDelta : Stack → Option Stack
  | .literal (.int right) :: .literal (.int left) :: rest =>
      some (.literal (.bool (decide (left < right))) :: rest)
  | _ => none

def eqIntDelta : Stack → Option Stack
  | .literal (.int right) :: .literal (.int left) :: rest =>
      some (.literal (.bool (decide (left = right))) :: rest)
  | _ => none

def andBoolDelta : Stack → Option Stack
  | .literal (.bool right) :: .literal (.bool left) :: rest =>
      some (.literal (.bool (left && right)) :: rest)
  | _ => none

def orBoolDelta : Stack → Option Stack
  | .literal (.bool right) :: .literal (.bool left) :: rest =>
      some (.literal (.bool (left || right)) :: rest)
  | _ => none

def notBoolDelta : Stack → Option Stack
  | .literal (.bool value) :: rest => some (.literal (.bool (!value)) :: rest)
  | _ => none

def intSeqEmptyDelta : Stack → Option Stack
  | rest => some (.literal (.intSeq []) :: rest)

def intSeqLenDelta : Stack → Option Stack
  | .literal (.intSeq values) :: rest => some (.literal (.int values.length) :: rest)
  | _ => none

/-- The element at a signed index. A negative index, like one past the end,
has no element. -/
def elementAt? {α : Type} (values : List α) : Int → Option α
  | .ofNat index => values[index]?
  | .negSucc _ => none

/-- `at` faults on an index that is negative or past the end; it never
returns a default. -/
def intSeqAtDelta : Stack → Option Stack
  | .literal (.int index) :: .literal (.intSeq values) :: rest =>
      (elementAt? values index).map fun value => .literal (.int value) :: rest
  | _ => none

def intSeqPushDelta : Stack → Option Stack
  | .literal (.int value) :: .literal (.intSeq values) :: rest =>
      some (.literal (.intSeq (values ++ [value])) :: rest)
  | _ => none

def boolSeqEmptyDelta : Stack → Option Stack
  | rest => some (.literal (.boolSeq []) :: rest)

def boolSeqLenDelta : Stack → Option Stack
  | .literal (.boolSeq values) :: rest => some (.literal (.int values.length) :: rest)
  | _ => none

def boolSeqAtDelta : Stack → Option Stack
  | .literal (.int index) :: .literal (.boolSeq values) :: rest =>
      (elementAt? values index).map fun value => .literal (.bool value) :: rest
  | _ => none

def boolSeqPushDelta : Stack → Option Stack
  | .literal (.bool value) :: .literal (.boolSeq values) :: rest =>
      some (.literal (.boolSeq (values ++ [value])) :: rest)
  | _ => none

def makeWorldDelta : Stack → Option Stack
  | rest => some (.world 0 :: rest)

def consumeWorldDelta : Stack → Option Stack
  | .world _ :: rest => some rest
  | _ => none

def defaultGamma : Gamma :=
  { literalType := fun literal => match literal with
      | .int _ => some .int
      | .bool _ => some .bool
      | .unit => some .unit
      | .intSeq _ => some .intSeq
      | .boolSeq _ => some .boolSeq
    primitive := fun primitive => match primitive with
      | "addInt" => some { input := .snoc (.snoc (.row "ρ") (.base .int .many)) (.base .int .many),
                           output := .snoc (.row "ρ") (.base .int .many), delta := addIntDelta }
      | "subInt" => some { input := .snoc (.snoc (.row "ρ") (.base .int .many)) (.base .int .many),
                           output := .snoc (.row "ρ") (.base .int .many), delta := subIntDelta }
      | "mulInt" => some { input := .snoc (.snoc (.row "ρ") (.base .int .many)) (.base .int .many),
                           output := .snoc (.row "ρ") (.base .int .many), delta := mulIntDelta }
      | "ltInt" => some { input := .snoc (.snoc (.row "ρ") (.base .int .many)) (.base .int .many),
                          output := .snoc (.row "ρ") (.base .bool .many), delta := ltIntDelta }
      | "eqInt" => some { input := .snoc (.snoc (.row "ρ") (.base .int .many)) (.base .int .many),
                          output := .snoc (.row "ρ") (.base .bool .many), delta := eqIntDelta }
      | "andBool" => some { input := .snoc (.snoc (.row "ρ") (.base .bool .many)) (.base .bool .many),
                            output := .snoc (.row "ρ") (.base .bool .many), delta := andBoolDelta }
      | "orBool" => some { input := .snoc (.snoc (.row "ρ") (.base .bool .many)) (.base .bool .many),
                           output := .snoc (.row "ρ") (.base .bool .many), delta := orBoolDelta }
      | "notBool" => some { input := .snoc (.row "ρ") (.base .bool .many),
                            output := .snoc (.row "ρ") (.base .bool .many), delta := notBoolDelta }
      | "intSeqEmpty" => some { input := .row "ρ",
                                output := .snoc (.row "ρ") (.base .intSeq .many), delta := intSeqEmptyDelta }
      | "intSeqLen" => some { input := .snoc (.row "ρ") (.base .intSeq .many),
                              output := .snoc (.row "ρ") (.base .int .many), delta := intSeqLenDelta }
      | "intSeqAt" => some { input := .snoc (.snoc (.row "ρ") (.base .intSeq .many)) (.base .int .many),
                             output := .snoc (.row "ρ") (.base .int .many), delta := intSeqAtDelta,
                             faults := true }
      | "intSeqPush" => some { input := .snoc (.snoc (.row "ρ") (.base .intSeq .many)) (.base .int .many),
                               output := .snoc (.row "ρ") (.base .intSeq .many), delta := intSeqPushDelta }
      | "boolSeqEmpty" => some { input := .row "ρ",
                                 output := .snoc (.row "ρ") (.base .boolSeq .many), delta := boolSeqEmptyDelta }
      | "boolSeqLen" => some { input := .snoc (.row "ρ") (.base .boolSeq .many),
                               output := .snoc (.row "ρ") (.base .int .many), delta := boolSeqLenDelta }
      | "boolSeqAt" => some { input := .snoc (.snoc (.row "ρ") (.base .boolSeq .many)) (.base .int .many),
                              output := .snoc (.row "ρ") (.base .bool .many), delta := boolSeqAtDelta,
                              faults := true }
      | "boolSeqPush" => some { input := .snoc (.snoc (.row "ρ") (.base .boolSeq .many)) (.base .bool .many),
                                output := .snoc (.row "ρ") (.base .boolSeq .many), delta := boolSeqPushDelta }
      | "makeWorld" => some { input := .row "ρ",
                               output := .snoc (.row "ρ") (.base .world .linear), delta := makeWorldDelta }
      | "consumeWorld" => some { input := .snoc (.row "ρ") (.base .world .linear),
                                  output := .row "ρ", delta := consumeWorldDelta }
      | _ => none }

/-- The surface spelling of each executable kernel primitive. The elaborator,
the reference-run adapter and the compiler all read this one table, so the
three hosts accept exactly the same primitive names. -/
def surfacePrimitives : List (String × Prim) :=
  [("+", "addInt"), ("-", "subInt"), ("*", "mulInt"), ("<", "ltInt"), ("=", "eqInt"),
   ("and", "andBool"), ("or", "orBool"), ("not", "notBool"),
   ("seq-int.empty", "intSeqEmpty"), ("seq-int.len", "intSeqLen"),
   ("seq-int.at", "intSeqAt"), ("seq-int.push", "intSeqPush"),
   ("seq-bool.empty", "boolSeqEmpty"), ("seq-bool.len", "boolSeqLen"),
   ("seq-bool.at", "boolSeqAt"), ("seq-bool.push", "boolSeqPush")]

def kernelPrimitive (surface : String) : Option Prim :=
  (surfacePrimitives.find? (·.1 == surface)).map (·.2)

inductive StepResult where
  | terminal (config : Config)
  | stepped (config : Config) (cost : Nat)
  | stuck (config : Config)
  deriving Repr

def step (gamma : Gamma) (dictionary : Dictionary) (costs : CostTable) : Config → StepResult
  | config@⟨_, .empty⟩ => .terminal config
  | config@⟨stack, .cons atom rest⟩ =>
      match atom with
      | .lit literal =>
          -- (S-LIT): literals are always many; no linear resource is made here.
          if (gamma.literalType literal).isSome then
            .stepped { stack := .literal literal :: stack, program := rest } (costs.atom atom)
          else .stuck config
      | .push value =>
          -- (S-PUSH): administrative push used by dip and quote. The frozen
          -- kappa table does not categorise this transition; the governed gap
          -- dec.gap-firth-language-kernel-kappa-cost-table-does-not-categorise
          -- records the current zero-cost interpreter choice.
          .stepped { stack := value :: stack, program := rest } 0
      | .quotation body =>
          -- (S-QUOT): closed quotations carry their recursive capture footprint.
          .stepped { stack := .quotation body (programUsage body) :: stack, program := rest }
            (costs.atom atom)
      | .dup =>
          -- (S-DUP): the type system admits this only for many values.
          match stack with
          | value :: tail => .stepped { stack := value :: value :: tail, program := rest } (costs.atom atom)
          | _ => .stuck config
      | .drop =>
          -- (S-DROP): the type system admits this only for many values.
          match stack with
          | _value :: tail => .stepped { stack := tail, program := rest } (costs.atom atom)
          | _ => .stuck config
      | .swap =>
          -- (S-SWAP): exchange the two top values.
          match stack with
          | second :: first :: tail =>
              .stepped { stack := first :: second :: tail, program := rest } (costs.atom atom)
          | _ => .stuck config
      | .pick depth =>
          -- (S-PICK): the type system admits this only for many values.
          match stack[depth]? with
          | some value => .stepped { stack := value :: stack, program := rest } (costs.atom atom)
          | none => .stuck config
      | .roll depth =>
          -- (S-ROLL): move one value to the top, keeping the others in order.
          match rollOut stack depth with
          | some (value, tail) => .stepped { stack := value :: tail, program := rest } (costs.atom atom)
          | none => .stuck config
      | .call =>
          -- (S-CALL): consume one quotation and concatenate its body.
          match stack with
          | .quotation body _ :: tail =>
              .stepped { stack := tail, program := body.append rest } (costs.atom atom)
          | _ => .stuck config
      | .dip =>
          -- (S-DIP): consume the quotation, burying the preserved value.
          match stack with
          | .quotation body _ :: value :: tail =>
              .stepped { stack := tail, program := body.append (.cons (.push value) rest) }
                (costs.atom atom)
          | _ => .stuck config
      | .compose =>
          -- (S-COMP): transfer both quotation owners to their composition.
          match stack with
          | .quotation second usage₂ :: .quotation first usage₁ :: tail =>
              let usage := if usage₁ == .linear || usage₂ == .linear then .linear else .many
              .stepped { stack := .quotation (first.append second) usage :: tail, program := rest }
                (costs.atom atom)
          | _ => .stuck config
      | .quote =>
          -- (S-QUOTE): capture the top value without copying it.
          match stack with
          | value :: tail =>
              .stepped { stack := .quotation (.cons (.push value) .empty) (quotationUsage value) :: tail,
                         program := rest } (costs.atom atom)
          | _ => .stuck config
      | .ifThenElse =>
          -- (S-IF-T)/(S-IF-F): branches are many and have equal effects by typing.
          match stack with
          | .quotation falseBranch _ :: .quotation trueBranch _ :: .literal (.bool condition) :: tail =>
              let chosen := if condition then trueBranch else falseBranch
              .stepped { stack := tail, program := chosen.append rest } (costs.atom atom)
          | _ => .stuck config
      | .word name =>
          -- (S-WORD): dictionary words unfold by program concatenation.
          match dictionary name with
          | some entry => .stepped { stack := stack, program := entry.body.append rest } costs.unfold
          | none => .stuck config
      | .prim primitive =>
          -- (S-PRIM): execute the deterministic total delta supplied by Γ.
          match gamma.primitive primitive with
          | some specification =>
              match specification.delta stack with
              | some result => .stepped { stack := result, program := rest } (costs.primitive primitive)
              | none => .stuck config
          | none => .stuck config

inductive RunResult where
  | terminal (config : Config) (steps cost : Nat)
  | stuck (config : Config) (steps cost : Nat)
  | outOfFuel (config : Config) (steps cost : Nat)
  deriving Repr

inductive OracleStatus where
  | terminal
  | stuck
  | fuelExhausted
  deriving BEq, DecidableEq, Repr

/- A canonical, serialisable summary of one bounded execution. The stack
   remains top-first, matching the executable representation and preserving
   the residual program exactly. -/
structure OracleResult where
  status : OracleStatus
  residualStack : Stack
  residualProgram : Program
  worldState : List Nat
  fuelBudget : Nat
  steps : Nat
  cost : Nat
  deriving BEq, Repr

mutual
  def observeWorld : Stack → List Nat
    | [] => []
    | value :: tail => observeWorldValue value ++ observeWorld tail

  def observeWorldValue : Value → List Nat
    | .literal _ => []
    | .world id => [id]
    | .quotation body _ => observeWorldProgram body

  def observeWorldProgram : Program → List Nat
    | .empty => []
    | .cons head tail => observeWorldAtom head ++ observeWorldProgram tail

  def observeWorldAtom : Atom → List Nat
    | .push value => observeWorldValue value
    | .quotation body => observeWorldProgram body
    | _ => []
end

private def oracleResult (fuel : Nat) : RunResult → OracleResult
  | .terminal config steps cost =>
      { status := .terminal
        residualStack := config.stack
        residualProgram := config.program
        worldState := observeWorld config.stack ++ observeWorldProgram config.program
        fuelBudget := fuel
        steps
        cost }
  | .stuck config steps cost =>
      { status := .stuck
        residualStack := config.stack
        residualProgram := config.program
        worldState := observeWorld config.stack ++ observeWorldProgram config.program
        fuelBudget := fuel
        steps
        cost }
  | .outOfFuel config steps cost =>
      { status := .fuelExhausted
        residualStack := config.stack
        residualProgram := config.program
        worldState := observeWorld config.stack ++ observeWorldProgram config.program
        fuelBudget := fuel
        steps
        cost }

inductive OracleComparison where
  | equivalent
  | inconclusive
  | mismatch
  deriving BEq, DecidableEq, Repr

def sameOracleObservation (left right : OracleResult) : Bool :=
  left.status == right.status &&
    left.residualStack == right.residualStack &&
    left.residualProgram == right.residualProgram &&
    left.worldState == right.worldState

def compareOracleResults (left right : OracleResult) : OracleComparison :=
  match left.status, right.status with
  | .fuelExhausted, .fuelExhausted =>
      if left.fuelBudget == right.fuelBudget then
        .inconclusive
      else
        .mismatch
  | .fuelExhausted, _ => .mismatch
  | _, .fuelExhausted => .mismatch
  | _, _ =>
      if sameOracleObservation left right then .equivalent else .mismatch

inductive TargetStatus where
  | terminal
  | stuck
  | fuelExhausted
  | trap
  | rejected
  deriving BEq, DecidableEq, Repr

/- A target report carries semantic residue separately from target-specific
   instruction accounting. `cost` is the aggregated target κ cost, not an
   interpreter step count. -/
structure TargetObservation where
  status : TargetStatus
  residualStack : Stack
  residualProgram : Program
  worldState : List Nat
  fuelBudget : Nat
  cost : Nat
  deriving BEq, Repr

def sameTargetObservation (oracle : OracleResult) (target : TargetObservation) : Bool :=
  oracle.residualStack == target.residualStack &&
    oracle.residualProgram == target.residualProgram &&
    oracle.worldState == target.worldState

def compareTargetObservation (oracle : OracleResult) (target : TargetObservation)
    (expectedCost : Nat) : OracleComparison :=
  if target.cost != expectedCost then
    .mismatch
  else
    match oracle.status, target.status with
    | .fuelExhausted, .fuelExhausted =>
        if oracle.fuelBudget == target.fuelBudget then .inconclusive else .mismatch
    | .fuelExhausted, _ => .mismatch
    | _, .fuelExhausted => .mismatch
    | .terminal, .terminal =>
        if sameTargetObservation oracle target then .equivalent else .mismatch
    | .stuck, .stuck =>
        if sameTargetObservation oracle target then .equivalent else .mismatch
    | _, _ => .mismatch

def run (gamma : Gamma) (dictionary : Dictionary) (costs : CostTable) : Nat → Config → RunResult
  | fuel, config =>
      match step gamma dictionary costs config with
      | .terminal final => .terminal final 0 0
      | .stuck stuckConfig => .stuck stuckConfig 0 0
      | .stepped next stepCost =>
          match fuel with
          | 0 => .outOfFuel config 0 0
          | fuel + 1 =>
              match run gamma dictionary costs fuel next with
              | .terminal final steps cost => .terminal final (steps + 1) (cost + stepCost)
              | .stuck stuckConfig steps cost => .stuck stuckConfig (steps + 1) (cost + stepCost)
              | .outOfFuel last steps cost => .outOfFuel last (steps + 1) (cost + stepCost)

def runOracle (gamma : Gamma) (dictionary : Dictionary) (costs : CostTable)
    (fuel : Nat) (config : Config) : OracleResult :=
  oracleResult fuel (run gamma dictionary costs fuel config)

/-! The shared kernel typing judgements. Concrete stacks are typed by extending
the symbolic row `ρ` from the bottom upwards; this matches the executable
top-first stack representation with the specification's bottom-to-top rules. -/

/-- The type `depth` places below the top of a stack type. -/
def StackType.pickAt : StackType → Nat → Option ValueType
  | .snoc _ type, 0 => some type
  | .snoc rest _, depth + 1 => rest.pickAt depth
  | .row _, _ => none

/-- The type `depth` places below the top, and the stack type without it. -/
def StackType.rollAt : StackType → Nat → Option (StackType × ValueType)
  | .snoc rest type, 0 => some (rest, type)
  | .snoc rest type, depth + 1 =>
      (rest.rollAt depth).map fun (remaining, moved) => (.snoc remaining type, moved)
  | .row _, _ => none

def ValueType.usage : ValueType → Usage
  | .base _ usage => usage
  | .quotation _ _ usage => usage

mutual
  inductive ValueTyping (gamma : Gamma) (dictionary : Dictionary) : Value → ValueType → Prop where
    | literal {literal : Literal} {base : BaseType}
        (h : gamma.literalType literal = some base) :
        ValueTyping gamma dictionary (.literal literal) (.base base .many)
    | quotation {body : Program} {input output : StackType}
        (h : ProgramTyping gamma dictionary body input output) :
        ValueTyping gamma dictionary (.quotation body (programUsage body))
          (.quotation input output (programUsage body))
    | world {id : Nat} :
        ValueTyping gamma dictionary (.world id) (.base .world .linear)

  inductive StackTyping (gamma : Gamma) (dictionary : Dictionary) : Stack → StackType → Prop where
    | empty : StackTyping gamma dictionary [] (.row "ρ")
    | cons {value : Value} {tail : Stack} {rest : StackType} {type : ValueType}
        (valueType : ValueTyping gamma dictionary value type)
        (tailType : StackTyping gamma dictionary tail rest) :
        StackTyping gamma dictionary (value :: tail) (.snoc rest type)

  inductive AtomTyping (gamma : Gamma) (dictionary : Dictionary) : Atom → StackType → StackType → Prop where
    | lit {literal : Literal} {base : BaseType} {stack : StackType}
        (h : gamma.literalType literal = some base) :
        AtomTyping gamma dictionary (.lit literal) stack
          (.snoc stack (.base base .many))
    | push {value : Value} {type : ValueType} {stack : StackType}
        (h : ValueTyping gamma dictionary value type) :
        AtomTyping gamma dictionary (.push value) stack (.snoc stack type)
    | quotation {body : Program} {input output stack : StackType}
        (h : ProgramTyping gamma dictionary body input output) :
        AtomTyping gamma dictionary (.quotation body) stack
          (.snoc stack (.quotation input output (programUsage body)))
    | dup {stack : StackType} {type : ValueType}
        (h : type.usage = .many) :
        AtomTyping gamma dictionary .dup (.snoc stack type)
          (.snoc (.snoc stack type) type)
    | drop {stack : StackType} {type : ValueType}
        (h : type.usage = .many) :
        AtomTyping gamma dictionary .drop (.snoc stack type) stack
    | swap {stack : StackType} {first second : ValueType} :
        AtomTyping gamma dictionary .swap (.snoc (.snoc stack first) second)
          (.snoc (.snoc stack second) first)
    | pick {stack : StackType} {depth : Nat} {type : ValueType}
        (h : stack.pickAt depth = some type) (many : type.usage = .many) :
        AtomTyping gamma dictionary (.pick depth) stack (.snoc stack type)
    | roll {stack rest : StackType} {depth : Nat} {type : ValueType}
        (h : stack.rollAt depth = some (rest, type)) :
        AtomTyping gamma dictionary (.roll depth) stack (.snoc rest type)
    | call {input output : StackType} {usage : Usage} :
        AtomTyping gamma dictionary .call
          (.snoc input (.quotation input output usage)) output
    | dip {input output : StackType} {type : ValueType} {usage : Usage} :
        AtomTyping gamma dictionary .dip
          (.snoc (.snoc input type) (.quotation input output usage))
          (.snoc output type)
    | compose {stack input middle output : StackType} {usage₁ usage₂ : Usage} :
        AtomTyping gamma dictionary .compose
          (.snoc (.snoc stack (.quotation input middle usage₁))
            (.quotation middle output usage₂))
          (.snoc stack (.quotation input output (usageMeet usage₁ usage₂)))
    | quote {stack : StackType} {type : ValueType} {row : String} :
        AtomTyping gamma dictionary .quote (.snoc stack type)
          (.snoc stack (.quotation (.row row) (.snoc (.row row) type)
            (usageMeet .many type.usage)))
    | ifThenElse {input output : StackType} :
        AtomTyping gamma dictionary .ifThenElse
          (.snoc (.snoc (.snoc input (.base .bool .many))
            (.quotation input output .many)) (.quotation input output .many)) output
    | word {name : String} {input output : StackType}
        (h : ∃ entry, dictionary name = some entry ∧ entry.type.input = input ∧
          entry.type.output = output) :
        AtomTyping gamma dictionary (.word name) input output
    | prim {name : Prim} {specification : PrimitiveSpec}
        (h : gamma.primitive name = some specification) :
        AtomTyping gamma dictionary (.prim name) specification.input specification.output

  inductive ProgramTyping (gamma : Gamma) (dictionary : Dictionary) :
      Program → StackType → StackType → Prop where
    | empty {stack : StackType} :
        ProgramTyping gamma dictionary .empty stack stack
    | cons {head : Atom} {tail : Program} {input middle output : StackType}
        (headType : AtomTyping gamma dictionary head input middle)
        (tailType : ProgramTyping gamma dictionary tail middle output) :
        ProgramTyping gamma dictionary (.cons head tail) input output
end

def TypedConfig (gamma : Gamma) (dictionary : Dictionary) (config : Config) : Prop :=
  ∃ stackType outputType,
    StackTyping gamma dictionary config.stack stackType ∧
      ProgramTyping gamma dictionary config.program stackType outputType

def DictionaryWellTyped (gamma : Gamma) (dictionary : Dictionary) : Prop :=
  ∀ name entry, dictionary name = some entry →
    ProgramTyping gamma dictionary entry.body entry.type.input entry.type.output

def PrimitivesPreserve (gamma : Gamma) (dictionary : Dictionary) : Prop :=
  ∀ name specification stack result,
    gamma.primitive name = some specification →
    StackTyping gamma dictionary stack specification.input →
    specification.delta stack = some result →
    StackTyping gamma dictionary result specification.output

def emptyDictionary : Dictionary := fun _ => none

end Firth.Interpreter
