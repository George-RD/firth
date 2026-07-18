import elaborator.Firth.Erasure

namespace Firth.Elaborator.StackEffect

open Firth.Interpreter
open Firth.Elaborator

inductive Row where
  | rigid (name : String)
  | mvar (id : Nat)
  deriving Repr, BEq, DecidableEq

inductive AUsage where
  | many
  | linear
  | mvar (id : Nat)
  | meet (left right : AUsage)
  deriving Repr, BEq, Nonempty

mutual
  inductive AType where
    | base (name : String) (usage : AUsage)
    | quotation (input output : AStack) (usage : AUsage)
    | mvar (id : Nat) (usage : AUsage)
    deriving Repr, BEq, Nonempty

  inductive AStack where
    | empty
    | row (tail : Row)
    | snoc (rest : AStack) (value : AType)
    deriving Repr, BEq, Nonempty
end

structure Effect where
  input : AStack
  output : AStack
  deriving Repr, BEq

structure Scheme where
  rowVariables : List String
  input : AStack
  output : AStack
  deriving Repr, BEq

structure Env where
  literal : Firth.Interpreter.Literal → Option AType := fun _ => none
  word : String → Option Scheme := fun _ => none
  primitive : String → Option Scheme := fun _ => none

structure Diagnostic where
  code : String
  primary : Span
  state : AStack
  expected : Option AStack := none
  actual : Option AStack := none
  deriving Repr, BEq, Nonempty

structure TypedHole where
  span : Span
  state : AStack
  deriving Repr, BEq

structure Definition where
  name : String
  declared : StackEffect
  program : KernelProgram
  span : Span

structure CheckedDefinition where
  name : String
  effect : Scheme
  deriving Repr, BEq

private structure InferState where
  nextRow : Nat := 0
  nextType : Nat := 0
  nextUsage : Nat := 0
  rows : List (Nat × AStack) := []
  types : List (Nat × AType) := []
  usages : List (Nat × AUsage) := []
  deriving Nonempty

private abbrev InferM := StateT InferState (Except Diagnostic)

private def lookupNat (id : Nat) : List (Nat × α) → Option α
  | [] => none
  | (key, value) :: rest => if key == id then some value else lookupNat id rest

mutual
  private partial def resolveUsage (state : InferState) : AUsage → AUsage
    | .many => .many
    | .linear => .linear
    | .mvar id => match lookupNat id state.usages with
      | none => .mvar id
      | some usage => resolveUsage state usage
    | .meet left right =>
        match resolveUsage state left, resolveUsage state right with
        | .many, .many => .many
        | .linear, _ | _, .linear => .linear
        | left, right => if left == right then left else .meet left right

  private partial def resolveType (state : InferState) : AType → AType
    | .base name usage => .base name (resolveUsage state usage)
    | .quotation input output usage =>
        .quotation (resolveStack state input) (resolveStack state output)
          (resolveUsage state usage)
    | .mvar id usage => match lookupNat id state.types with
      | none => .mvar id (resolveUsage state usage)
      | some type => resolveType state type

  private partial def resolveStack (state : InferState) : AStack → AStack
    | .empty => .empty
    | .row (.rigid name) => .row (.rigid name)
    | .row (.mvar id) => match lookupNat id state.rows with
      | none => .row (.mvar id)
      | some stack => resolveStack state stack
    | .snoc rest value => .snoc (resolveStack state rest) (resolveType state value)
end

mutual
  private partial def rowOccursInUsage (_id : Nat) (_usage : AUsage) : Bool := false

  private partial def rowOccursInType (id : Nat) : AType → Bool
    | .base _ usage => rowOccursInUsage id usage
    | .quotation input output usage =>
        rowOccursInStack id input || rowOccursInStack id output || rowOccursInUsage id usage
    | .mvar _ usage => rowOccursInUsage id usage

  private partial def rowOccursInStack (id : Nat) : AStack → Bool
    | .empty => false
    | .row (.rigid _) => false
    | .row (.mvar other) => id == other
    | .snoc rest value => rowOccursInStack id rest || rowOccursInType id value
end

mutual
  private partial def typeOccursInType (id : Nat) : AType → Bool
    | .base _ _ => false
    | .quotation input output _ => typeOccursInStack id input || typeOccursInStack id output
    | .mvar other _ => id == other

  private partial def typeOccursInStack (id : Nat) : AStack → Bool
    | .empty | .row _ => false
    | .snoc rest value => typeOccursInStack id rest || typeOccursInType id value
end

private def failAt (code : String) (span : Span) (current : AStack)
    (expected actual : Option AStack := none) : InferM α := fun state =>
  .error {
    code
    primary := span
    state := resolveStack state current
    expected := expected.map (resolveStack state)
    actual := actual.map (resolveStack state) }

private def freshRow : InferM AStack := do
  let state ← get
  set { state with nextRow := state.nextRow + 1 }
  pure (.row (.mvar state.nextRow))

private def freshUsage : InferM AUsage := do
  let state ← get
  set { state with nextUsage := state.nextUsage + 1 }
  pure (.mvar state.nextUsage)

private def freshType : InferM AType := do
  let state ← get
  let usage := AUsage.mvar state.nextUsage
  set { state with nextType := state.nextType + 1, nextUsage := state.nextUsage + 1 }
  pure (.mvar state.nextType usage)

private def usageOccurs (id : Nat) : AUsage → Bool
  | .many | .linear => false
  | .mvar other => id == other
  | .meet left right => usageOccurs id left || usageOccurs id right

private partial def unifyUsage (span : Span) (current : AStack)
    (expected actual : AUsage) : InferM Unit := do
  let state ← get
  let expected := resolveUsage state expected
  let actual := resolveUsage state actual
  match expected, actual with
  | .many, .many | .linear, .linear => pure ()
  | .mvar left, .mvar right =>
      if left == right then pure ()
      else set { state with usages := (left, actual) :: state.usages }
  | .mvar id, usage | usage, .mvar id =>
      if usageOccurs id usage then failAt "firth.type.occurs-check" span current
      else set { state with usages := (id, usage) :: state.usages }
  | .meet left right, usage =>
      match resolveUsage state (.meet left right) with
      | .meet _ _ =>
          if usage == .linear then pure ()
          else do unifyUsage span current left .many; unifyUsage span current right .many
      | reduced => unifyUsage span current reduced usage
  | usage, .meet left right => unifyUsage span current (.meet left right) usage
  | _, _ => failAt "firth.linearity.usage-mismatch" span current

mutual
  private partial def unifyType (code : String) (span : Span) (current : AStack)
      (expected actual : AType) : InferM Unit := do
    let state ← get
    let expected := resolveType state expected
    let actual := resolveType state actual
    match expected, actual with
    | .mvar left leftUsage, .mvar right rightUsage =>
        if left == right then unifyUsage span current leftUsage rightUsage
        else do
          unifyUsage span current leftUsage rightUsage
          let updated ← get
          set { updated with types := (left, actual) :: updated.types }
    | .mvar id usage, type | type, .mvar id usage =>
        if typeOccursInType id type then
          failAt "firth.type.occurs-check" span current
            (some (.snoc .empty expected)) (some (.snoc .empty actual))
        else do
          let targetUsage := match type with
            | .base _ valueUsage | .quotation _ _ valueUsage | .mvar _ valueUsage => valueUsage
          unifyUsage span current usage targetUsage
          let updated ← get
          set { updated with types := (id, type) :: updated.types }
    | .base expectedName expectedUsage, .base actualName actualUsage =>
        if expectedName == actualName then unifyUsage span current expectedUsage actualUsage
        else failAt code span current (some (.snoc .empty expected)) (some (.snoc .empty actual))
    | .quotation expectedInput expectedOutput expectedUsage,
        .quotation actualInput actualOutput actualUsage => do
        unifyUsage span current expectedUsage actualUsage
        unifyStack code span current expectedInput actualInput
        unifyStack code span current expectedOutput actualOutput
    | _, _ => failAt code span current (some (.snoc .empty expected)) (some (.snoc .empty actual))

  private partial def unifyStack (code : String) (span : Span) (current : AStack)
      (expected actual : AStack) : InferM Unit := do
    let state ← get
    let expected := resolveStack state expected
    let actual := resolveStack state actual
    match expected, actual with
    | .empty, .empty => pure ()
    | .row (.rigid left), .row (.rigid right) =>
        if left == right then pure () else failAt code span current (some expected) (some actual)
    | .row (.mvar left), .row (.mvar right) =>
        if left == right then pure ()
        else set { state with rows := (left, actual) :: state.rows }
    | .row (.mvar id), stack | stack, .row (.mvar id) =>
        if rowOccursInStack id stack then
          failAt "firth.type.occurs-check" span current (some expected) (some actual)
        else set { state with rows := (id, stack) :: state.rows }
    | .snoc expectedRest expectedValue, .snoc actualRest actualValue => do
        unifyStack code span current expectedRest actualRest
        unifyType code span current expectedValue actualValue
    | _, _ => failAt code span current (some expected) (some actual)
end

private def usageOf : AType → AUsage
  | .base _ usage | .quotation _ _ usage | .mvar _ usage => usage

private def requireMany (span : Span) (current : AStack) (type : AType) : InferM Unit :=
  unifyUsage span current (usageOf type) .many

private def push (stack : AStack) (type : AType) : AStack := .snoc stack type

private def pop (code : String) (span : Span) (current : AStack) : InferM (AStack × AType) := do
  let rest ← freshRow
  let value ← freshType
  unifyStack code span current (.snoc rest value) current
  let state ← get
  pure (resolveStack state rest, resolveType state value)

private def replaceRigid (rows : List (String × AStack)) : AStack → AStack
  | .empty => .empty
  | .row (.mvar id) => .row (.mvar id)
  | .row (.rigid name) => match rows.find? (fun row => row.1 == name) with
    | some (_, stack) => stack
    | none => .row (.rigid name)
  | .snoc rest value => .snoc (replaceRigid rows rest) (replaceRigidType rows value)
where
  replaceRigidType (rows : List (String × AStack)) : AType → AType
    | .base name usage => .base name usage
    | .quotation input output usage =>
        .quotation (replaceRigid rows input) (replaceRigid rows output) usage
    | .mvar id usage => .mvar id usage

private def allocateRows : List String → InferM (List (String × AStack))
  | [] => pure []
  | name :: rest => do
      let row ← freshRow
      let tail ← allocateRows rest
      pure ((name, row) :: tail)

private def instantiate (scheme : Scheme) : InferM Effect := do
  let rows ← allocateRows scheme.rowVariables
  pure { input := replaceRigid rows scheme.input, output := replaceRigid rows scheme.output }

def defaultLiteralType : Firth.Interpreter.Literal → Option AType
  | .nat _ => some (.base "Int" .many)
  | .bool _ => some (.base "Bool" .many)
  | .unit => some (.base "Unit" .many)

private def algorithmicUsage : Firth.Interpreter.Usage → AUsage
  | .many => .many
  | .linear => .linear

private def literalType (env : Env) (span : Span) (current : AStack)
    (literal : Firth.Interpreter.Literal) : InferM AType :=
  match env.literal literal with
  | none => failAt "firth.type.unknown-literal" span current
  | some type => match type with
      | .base _ .many => pure type
      | _ => failAt "firth.linearity.literal-not-many" span current

private def programAtoms : Program → List Atom
  | .empty => []
  | .cons head tail => head :: programAtoms tail

private def stripLocations : KernelProgram → Program
  | [] => .empty
  | item :: rest => .cons item.atom (stripLocations rest)

private def locateProgram (fallback : Span) (spans : List Span) (program : Program) : KernelProgram :=
  let rec go : List Span → List Atom → KernelProgram
    | _, [] => []
    | [], atom :: rest => { span := fallback, atom } :: go [] rest
    | span :: moreSpans, atom :: rest => { span, atom } :: go moreSpans rest
  go spans (programAtoms program)

mutual
private partial def valueType (env : Env) (span : Span) (current : AStack)
    (value : Value) : InferM AType :=
  match value with
  | .literal literal => literalType env span current literal
  | .world _ => pure (.base "World" .linear)
  | .quotation body usage => do
      let effect ← inferSequence env (locateProgram span [] body) (← freshRow)
      let stored := algorithmicUsage usage
      let inferred := algorithmicUsage (programUsage body)
      if stored == inferred then pure (.quotation effect.1 effect.2 inferred)
      else failAt "firth.linearity.invalid-quotation-usage" span current

private partial def inferAtom (env : Env) (located : LocatedKernel)
    (current : AStack) : InferM AStack := do
  let span := located.span
  match located.atom with
  | .lit literal => pure (push current (← literalType env span current literal))
  | .push value => pure (push current (← valueType env span current value))
  | .quotation body =>
      let input ← freshRow
      let children ← if located.children.isEmpty then
        pure (locateProgram span located.childSpans body)
      else if stripLocations located.children == body then pure located.children
      else failAt "firth.elaboration.provenance-mismatch" span current
      let (_, output) ← inferSequence env children input
      pure (push current (.quotation input output (algorithmicUsage (programUsage body))))
  | .dup =>
      let (rest, value) ← pop "firth.type.stack-underflow" span current
      requireMany span current value
      pure (push (push rest value) value)
  | .drop =>
      let (rest, value) ← pop "firth.type.stack-underflow" span current
      requireMany span current value
      pure rest
  | .swap =>
      let (rest, second) ← pop "firth.type.stack-underflow" span current
      let (rest, first) ← pop "firth.type.stack-underflow" span rest
      pure (push (push rest second) first)
  | .call =>
      let (rest, quotation) ← pop "firth.type.stack-underflow" span current
      let input ← freshRow
      let output ← freshRow
      let usage ← freshUsage
      unifyType "firth.type.expected-quotation" span current
        (.quotation input output usage) quotation
      unifyStack "firth.type.quotation-input-mismatch" span current input rest
      let state ← get
      pure (resolveStack state output)
  | .dip =>
      let (rest, quotation) ← pop "firth.type.stack-underflow" span current
      let (rest, preserved) ← pop "firth.type.stack-underflow" span rest
      let input ← freshRow
      let output ← freshRow
      let usage ← freshUsage
      unifyType "firth.type.expected-quotation" span current
        (.quotation input output usage) quotation
      unifyStack "firth.type.quotation-input-mismatch" span current input rest
      let state ← get
      pure (push (resolveStack state output) (resolveType state preserved))
  | .compose =>
      let (rest, second) ← pop "firth.type.stack-underflow" span current
      let (rest, first) ← pop "firth.type.stack-underflow" span rest
      let input ← freshRow
      let middle ← freshRow
      let output ← freshRow
      let firstUsage ← freshUsage
      let secondUsage ← freshUsage
      unifyType "firth.type.expected-quotation" span current
        (.quotation input middle firstUsage) first
      unifyType "firth.type.quotation-compose-mismatch" span current
        (.quotation middle output secondUsage) second
      let state ← get
      pure (push (resolveStack state rest)
        (.quotation (resolveStack state input) (resolveStack state output)
          (.meet (resolveUsage state firstUsage) (resolveUsage state secondUsage))))
  | .quote =>
      let (rest, value) ← pop "firth.type.stack-underflow" span current
      let row ← freshRow
      pure (push rest (.quotation row (push row value) (usageOf value)))
  | .ifThenElse =>
      let (rest, falseBranch) ← pop "firth.type.stack-underflow" span current
      let (rest, trueBranch) ← pop "firth.type.stack-underflow" span rest
      let (rest, condition) ← pop "firth.type.stack-underflow" span rest
      unifyType "firth.type.expected-bool" span current (.base "Bool" .many) condition
      let output ← freshRow
      unifyType "firth.type.branch-mismatch" span current
        (.quotation rest output .many) trueBranch
      unifyType "firth.type.branch-mismatch" span current
        (.quotation rest output .many) falseBranch
      let state ← get
      pure (resolveStack state output)
  | .word name => match env.word name with
      | none => failAt "firth.name.unknown-word" span current
      | some scheme => do
          let effect ← instantiate scheme
          unifyStack "firth.type.word-input-mismatch" span current effect.input current
          let state ← get
          pure (resolveStack state effect.output)
  | .prim name => match env.primitive name with
      | none => failAt "firth.name.unknown-primitive" span current
      | some scheme => do
          let effect ← instantiate scheme
          unifyStack "firth.type.primitive-input-mismatch" span current effect.input current
          let state ← get
          pure (resolveStack state effect.output)

private partial def inferSequence (env : Env) : KernelProgram → AStack → InferM (AStack × AStack)
  | [], input => pure (input, input)
  | item :: rest, input => do
      let next ← inferAtom env item input
      match rest with
      | [] => pure (input, next)
      | _ =>
          let (_, output) ← inferSequence env rest next
          pure (input, output)
end

private def runEffect (action : InferM Effect) : Except Diagnostic Effect := do
  let (effect, state) ← action.run {}
  pure { input := resolveStack state effect.input, output := resolveStack state effect.output }

def infer (env : Env) (program : KernelProgram) : Except Diagnostic Effect :=
  runEffect do
    let input ← freshRow
    let (_, output) ← inferSequence env program input
    pure { input, output }

def check (env : Env) (scheme : Scheme) (program : KernelProgram)
    (boundary : Span) : Except Diagnostic Effect :=
  runEffect do
    let declared : Effect := { input := scheme.input, output := scheme.output }
    let (_, actual) ← inferSequence env program declared.input
    unifyStack "firth.type.declared-effect-mismatch" boundary actual declared.output actual
    pure declared

private def stackFromItems (bound : List String)
    (items : List StackItem) : Except Diagnostic AStack :=
  let fail span := .error {
    code := "firth.type.invalid-signature"
    primary := span
    state := .empty }
  let rec values (stack : AStack) : List StackItem → Except Diagnostic AStack
    | [] => .ok stack
    | .row _ span :: _ => fail span
    | .value _ type _ :: rest =>
        let usage := match type.usage with | .many => AUsage.many | .linear => AUsage.linear
        values (.snoc stack (.base type.name usage)) rest
  let rec misplacedRow : List StackItem → Option Span
    | [] => none
    | .row _ span :: _ => some span
    | _ :: rest => misplacedRow rest
  match items with
  | [] => .ok .empty
  | .row name span :: rest =>
      if bound.contains name then values (.row (.rigid name)) rest else fail span
  | _ :: rest => match misplacedRow rest with
      | some rowSpan => fail rowSpan
      | none => values .empty items

def schemeOfEffect (effect : StackEffect) : Except Diagnostic Scheme := do
  let names := effect.rowBinders.map (·.name)
  if names.any (fun name => names.count name > 1) then
    .error { code := "firth.type.invalid-signature", primary := effect.span, state := .empty }
  else
    let input ← stackFromItems names effect.input
    let output ← stackFromItems names effect.output
    pure { rowVariables := names, input, output }

def typedHole (env : Env) (input : AStack) (programPrefix : KernelProgram)
    (span : Span) : Except Diagnostic TypedHole := do
  let (hole, state) ← (do
    let (_, output) ← inferSequence env programPrefix input
    pure output).run (freshStateFor input)
  pure { span, state := resolveStack state hole }

where
  usageCeiling : AUsage → Nat
    | .many | .linear => 0
    | .mvar id => id + 1
    | .meet left right => max (usageCeiling left) (usageCeiling right)
  typeCeilings : AType → Nat × Nat × Nat
    | .base _ usage => (0, 0, usageCeiling usage)
    | .mvar id usage => (0, id + 1, usageCeiling usage)
    | .quotation input output usage =>
        let left := stackCeilings input
        let right := stackCeilings output
        (max left.1 right.1, max left.2.1 right.2.1,
          max (max left.2.2 right.2.2) (usageCeiling usage))
  stackCeilings : AStack → Nat × Nat × Nat
    | .empty | .row (.rigid _) => (0, 0, 0)
    | .row (.mvar id) => (id + 1, 0, 0)
    | .snoc rest value =>
        let left := stackCeilings rest
        let right := typeCeilings value
        (max left.1 right.1, max left.2.1 right.2.1, max left.2.2 right.2.2)
  freshStateFor (input : AStack) : InferState :=
    let ceilings := stackCeilings input
    { nextRow := ceilings.1, nextType := ceilings.2.1, nextUsage := ceilings.2.2 }

private def collectSchemes (definitions : List Definition) :
    Except Diagnostic (List (String × Scheme)) :=
  let rec go (seen : List (String × Scheme)) : List Definition →
      Except Diagnostic (List (String × Scheme))
    | [] => .ok seen.reverse
    | definition :: rest =>
        if seen.any (fun entry => entry.1 == definition.name) then
          .error { code := "firth.name.duplicate-word", primary := definition.span, state := .empty }
        else do
          let scheme ← schemeOfEffect definition.declared
          go ((definition.name, scheme) :: seen) rest
  go [] definitions

def checkDictionary (gamma : Env) (definitions : List Definition) :
    Except Diagnostic (List CheckedDefinition) := do
  let schemes ← collectSchemes definitions
  let env : Env := {
    literal := gamma.literal
    word := fun name => (schemes.find? (fun entry => entry.1 == name)).map (·.2)
    primitive := gamma.primitive }
  let rec checkAll : List Definition → Except Diagnostic (List CheckedDefinition)
    | [] => .ok []
    | definition :: rest => do
        let scheme := (schemes.find? (fun entry => entry.1 == definition.name)).map (·.2)
        match scheme with
        | none => .error { code := "firth.name.unknown-word", primary := definition.span, state := .empty }
        | some declared =>
            let _ ← check env declared definition.program definition.declared.span
            let tail ← checkAll rest
            pure ({ name := definition.name, effect := declared } :: tail)
  checkAll definitions

end Firth.Elaborator.StackEffect
