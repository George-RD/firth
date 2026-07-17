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
  | nat (value : Nat)
  | bool (value : Bool)
  | unit
  deriving BEq, DecidableEq, Repr

abbrev Prim := String

inductive BaseType where
  | nat
  | bool
  | unit
  | world
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

structure PrimitiveSpec where
  input : StackType
  output : StackType
  delta : Stack → Option Stack

structure Gamma where
  literalType : Literal → Option BaseType
  primitive : Prim → Option PrimitiveSpec

def addNatDelta : Stack → Option Stack
  | .literal (.nat right) :: .literal (.nat left) :: rest =>
      some (.literal (.nat (left + right)) :: rest)
  | _ => none

def makeWorldDelta : Stack → Option Stack
  | rest => some (.world 0 :: rest)

def consumeWorldDelta : Stack → Option Stack
  | .world _ :: rest => some rest
  | _ => none

def defaultGamma : Gamma :=
  { literalType := fun literal => match literal with
      | .nat _ => some .nat
      | .bool _ => some .bool
      | .unit => some .unit
    primitive := fun primitive => match primitive with
      | "addNat" => some { input := .snoc (.snoc (.row "ρ") (.base .nat .many)) (.base .nat .many),
                           output := .snoc (.row "ρ") (.base .nat .many), delta := addNatDelta }
      | "makeWorld" => some { input := .row "ρ",
                               output := .snoc (.row "ρ") (.base .world .linear), delta := makeWorldDelta }
      | "consumeWorld" => some { input := .snoc (.row "ρ") (.base .world .linear),
                                  output := .row "ρ", delta := consumeWorldDelta }
      | _ => none }

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
          -- (S-QUOT): a closed quotation is replayable and therefore many.
          .stepped { stack := .quotation body .many :: stack, program := rest }
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

/-! The shared kernel typing judgements. Concrete stacks are typed by extending
the symbolic row `ρ` from the bottom upwards; this matches the executable
top-first stack representation with the specification's bottom-to-top rules. -/

def usageMeet : Usage → Usage → Usage
  | .many, .many => .many
  | _, _ => .linear

def ValueType.usage : ValueType → Usage
  | .base _ usage => usage
  | .quotation _ _ usage => usage

mutual
  inductive ValueTyping (gamma : Gamma) (dictionary : Dictionary) : Value → ValueType → Prop where
    | literal {literal : Literal} {base : BaseType}
        (h : gamma.literalType literal = some base) :
        ValueTyping gamma dictionary (.literal literal) (.base base .many)
    | quotation {body : Program} {input output : StackType} {usage : Usage}
        (h : ProgramTyping gamma dictionary body input output) :
        ValueTyping gamma dictionary (.quotation body usage)
          (.quotation input output usage)
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
          (.snoc stack (.quotation input output .many))
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
