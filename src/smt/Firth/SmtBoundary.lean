namespace Firth.Smt

/-!
This is a provisional, typed backend IR.  It is deliberately not Firth surface
syntax: the language type-system design still owns that representation.  The
SMT layer imports no elaborator implementation details.
-/

inductive IntExpr where
  | literal (value : Int)
  | variable (name : String)
  | add (left right : IntExpr)
  | sub (left right : IntExpr)
  | scale (coefficient : Int) (body : IntExpr)
  deriving Repr, BEq, DecidableEq

inductive Predicate where
  | truth
  | falsity
  | boolVariable (name : String)
  | not (body : Predicate)
  | and (left right : Predicate)
  | or (left right : Predicate)
  | intEq (left right : IntExpr)
  | intNe (left right : IntExpr)
  | intLe (left right : IntExpr)
  | intLt (left right : IntExpr)
  | named (qualifiedName semanticVersion : String) (arguments : List IntExpr)
  | nonlinear (description : String)
  | worldSensitive (description : String)
  deriving Repr, BEq, DecidableEq

structure Formula where
  premises : List Predicate
  conclusions : List Predicate
  deriving Repr, BEq, DecidableEq

structure Valuation where
  integers : List (String × Int) := []
  booleans : List (String × Bool) := []
  deriving Repr, BEq

def lookup [BEq α] (name : α) : List (α × β) → Option β
  | [] => none
  | (key, value) :: rest => if key == name then some value else lookup name rest

def evalInt (valuation : Valuation) : IntExpr → Option Int
  | .literal value => some value
  | .variable name => lookup name valuation.integers
  | .add left right => return (← evalInt valuation left) + (← evalInt valuation right)
  | .sub left right => return (← evalInt valuation left) - (← evalInt valuation right)
  | .scale coefficient body => return coefficient * (← evalInt valuation body)

def evalPredicate (valuation : Valuation) : Predicate → Option Bool
  | .truth => some true
  | .falsity => some false
  | .boolVariable name => lookup name valuation.booleans
  | .not body => return !(← evalPredicate valuation body)
  | .and left right => return (← evalPredicate valuation left) && (← evalPredicate valuation right)
  | .or left right => return (← evalPredicate valuation left) || (← evalPredicate valuation right)
  | .intEq left right => return (← evalInt valuation left) == (← evalInt valuation right)
  | .intNe left right => return (← evalInt valuation left) != (← evalInt valuation right)
  | .intLe left right => return (← evalInt valuation left) <= (← evalInt valuation right)
  | .intLt left right => return (← evalInt valuation left) < (← evalInt valuation right)
  | .named _ _ _ | .nonlinear _ | .worldSensitive _ => none

private def frame (value : String) : String := s!"{value.toUTF8.size}:{value}"

private def encodeList (values : List String) : String :=
  s!"{values.length}[{String.intercalate "" (values.map frame)}]"

mutual
  def canonicalIntExpr : IntExpr → String
    | .literal value => s!"literal({value})"
    | .variable name => s!"variable({frame name})"
    | .add left right => s!"add({frame (canonicalIntExpr left)}{frame (canonicalIntExpr right)})"
    | .sub left right => s!"sub({frame (canonicalIntExpr left)}{frame (canonicalIntExpr right)})"
    | .scale coefficient body => s!"scale({coefficient},{frame (canonicalIntExpr body)})"

  def canonicalPredicate : Predicate → String
    | .truth => "truth"
    | .falsity => "falsity"
    | .boolVariable name => s!"bool-variable({frame name})"
    | .not body => s!"not({frame (canonicalPredicate body)})"
    | .and left right =>
        s!"and({frame (canonicalPredicate left)}{frame (canonicalPredicate right)})"
    | .or left right =>
        s!"or({frame (canonicalPredicate left)}{frame (canonicalPredicate right)})"
    | .intEq left right =>
        s!"int-eq({frame (canonicalIntExpr left)}{frame (canonicalIntExpr right)})"
    | .intNe left right =>
        s!"int-ne({frame (canonicalIntExpr left)}{frame (canonicalIntExpr right)})"
    | .intLe left right =>
        s!"int-le({frame (canonicalIntExpr left)}{frame (canonicalIntExpr right)})"
    | .intLt left right =>
        s!"int-lt({frame (canonicalIntExpr left)}{frame (canonicalIntExpr right)})"
    | .named name version arguments =>
        s!"named({frame name}{frame version}{encodeList (arguments.map canonicalIntExpr)})"
    | .nonlinear description => s!"nonlinear({frame description})"
    | .worldSensitive description => s!"world({frame description})"
end

def canonicalFormula (formula : Formula) : String :=
  s!"formula({encodeList (formula.premises.map canonicalPredicate)}" ++
    s!"{encodeList (formula.conclusions.map canonicalPredicate)})"

inductive Fragment where
  | qfLia
  | untranslatedPredicate
  | nonlinearArithmetic
  | worldEffect
  deriving Repr, BEq, DecidableEq
structure SolverProfile where
  solverId : String
  version : String
  licence : String
  platform : String
  executableDigest : String
  acquisitionSource : String
  logic : String
  invocationOptions : List String
  wallTimeMilliseconds : Nat
  memoryBytes : Nat
  supportedFragments : List Fragment
  deriving Repr, BEq

def defaultSolverProfile : SolverProfile :=
  { solverId := "z3"
    version := "5.0.0"
    licence := "MIT"
    platform := "linux-arm64-glibc-2.38"
    executableDigest := "sha256:6457d93236741071c91bfa2927744372e15fdb236d0116bf487aa9930a38972e"
    acquisitionSource :=
      "https://github.com/Z3Prover/z3/releases/download/z3-5.0.0/z3-5.0.0-arm64-glibc-2.38.zip"
    logic := "QF_LIA"
    invocationOptions := ["-in", "-smt2", "-T:5", "-memory:256"]
    wallTimeMilliseconds := 5000
    memoryBytes := 268435456
    supportedFragments := [.qfLia] }

def validSolverProfile (profile : SolverProfile) : Bool :=
  profile == defaultSolverProfile


private def predicateFragment : Predicate → Fragment
  | .truth | .falsity | .boolVariable _ => .qfLia
  | .not body => predicateFragment body
  | .and left right | .or left right =>
      if predicateFragment left == .qfLia then predicateFragment right else predicateFragment left
  | .intEq _ _ | .intNe _ _ | .intLe _ _ | .intLt _ _ => .qfLia
  | .named _ _ _ => .untranslatedPredicate
  | .nonlinear _ => .nonlinearArithmetic
  | .worldSensitive _ => .worldEffect

def classify (formula : Formula) : Fragment :=
  let predicates := formula.premises ++ formula.conclusions
  predicates.foldl (fun result predicate =>
    if result == .qfLia then predicateFragment predicate else result) .qfLia

structure CheckedAdapterRequirements where
  logic : String := "QF_LIA"
  pinnedSolverRequired : Bool := true
  boundedWallTimeRequired : Bool := true
  boundedMemoryRequired : Bool := true
  normaliserProofRequired : Bool := true
  vcGeneratorProofRequired : Bool := true
  encoderProofRequired : Bool := true
  serialiserProofRequired : Bool := true
  deriving Repr, BEq

def checkedAdapterRequirements : CheckedAdapterRequirements := {}

inductive ExternalOutcome where
  | unknown
  | timeout (milliseconds : Nat)
  | resourceExhausted
  | malformed (detail : String)
  | crashed (detail : String)
  | uncheckedUnsat (evidence : String)
  | sat (model : Valuation)
  deriving Repr, BEq

structure SmtResult where
  profile : SolverProfile
  outcome : ExternalOutcome
  deriving Repr, BEq

private def allTrue (valuation : Valuation) : List Predicate → Bool
  | [] => true
  | predicate :: rest => evalPredicate valuation predicate == some true && allTrue valuation rest

private def anyFalse (valuation : Valuation) : List Predicate → Bool
  | [] => false
  | predicate :: rest => evalPredicate valuation predicate == some false || anyFalse valuation rest

private def uniqueKeys : List (String × α) → Bool
  | [] => true
  | (key, _) :: rest => !(rest.any fun entry => entry.1 == key) && uniqueKeys rest

def IntExpr.variables : IntExpr → List String
  | .literal _ => []
  | .variable name => [name]
  | .add left right | .sub left right => left.variables ++ right.variables
  | .scale _ body => body.variables

def Predicate.integerVariables : Predicate → List String
  | .truth | .falsity | .boolVariable _ | .nonlinear _ | .worldSensitive _ => []
  | .not body => body.integerVariables
  | .and left right | .or left right => left.integerVariables ++ right.integerVariables
  | .intEq left right | .intNe left right | .intLe left right | .intLt left right =>
      left.variables ++ right.variables
  | .named _ _ arguments => arguments.flatMap IntExpr.variables

def Predicate.booleanVariables : Predicate → List String
  | .truth | .falsity | .intEq _ _ | .intNe _ _ | .intLe _ _ | .intLt _ _ |
      .named _ _ _ | .nonlinear _ | .worldSensitive _ => []
  | .boolVariable name => [name]
  | .not body => body.booleanVariables
  | .and left right | .or left right => left.booleanVariables ++ right.booleanVariables

private def allBound (names : List String) (entries : List (String × α)) : Bool :=
  names.all fun name => (lookup name entries).isSome

def validatesCounterexample (formula : Formula) (model : Valuation) : Bool :=
  let predicates := formula.premises ++ formula.conclusions
  let integerVariables := predicates.flatMap Predicate.integerVariables
  let booleanVariables := predicates.flatMap Predicate.booleanVariables
  uniqueKeys model.integers && uniqueKeys model.booleans &&
    allBound integerVariables model.integers && allBound booleanVariables model.booleans &&
    allTrue model formula.premises && anyFalse model formula.conclusions

inductive SmtSort where
  | integer
  | boolean
  deriving Repr, BEq, DecidableEq

structure SmtBinding where
  sourceName : String
  symbol : String
  sort : SmtSort
  deriving Repr, BEq, DecidableEq

inductive SmtTranslationError where
  | invalidSolverProfile
  | unsupportedFragment (fragment : Fragment)
  | unboundVariable (sort : SmtSort) (name : String)
  deriving Repr, BEq, DecidableEq

structure SmtRequest where
  profile : SolverProfile
  formula : Formula
  bindings : List SmtBinding
  smtLib : String
  deriving Repr, BEq

private def insertSortedUnique (name : String) : List String → List String
  | [] => [name]
  | head :: tail =>
      if name == head then head :: tail
      else if name < head then name :: head :: tail
      else head :: insertSortedUnique name tail

private def uniqueSorted (names : List String) : List String :=
  names.foldl (fun result name => insertSortedUnique name result) []

private def indexedBindings (sort : SmtSort) (tag : String) :
    Nat → List String → List SmtBinding
  | _, [] => []
  | index, name :: rest =>
      { sourceName := name
        symbol := tag ++ toString index
        sort } :: indexedBindings sort tag (index + 1) rest

private def formulaBindings (formula : Formula) : List SmtBinding :=
  let predicates := formula.premises ++ formula.conclusions
  let integerNames := uniqueSorted (predicates.flatMap Predicate.integerVariables)
  let booleanNames := uniqueSorted (predicates.flatMap Predicate.booleanVariables)
  indexedBindings .integer "i" 0 integerNames ++
    indexedBindings .boolean "b" 0 booleanNames

private def findBinding (sort : SmtSort) (name : String) :
    List SmtBinding → Except SmtTranslationError String
  | [] => .error (.unboundVariable sort name)
  | binding :: rest =>
      if binding.sort == sort && binding.sourceName == name then
        .ok binding.symbol
      else
        findBinding sort name rest

private def renderIntLiteral (value : Int) : String :=
  if value < 0 then
    s!"(- {toString (-value)})"
  else
    toString value

private def renderIntExpr (bindings : List SmtBinding) : IntExpr → Except SmtTranslationError String
  | .literal value => .ok (renderIntLiteral value)
  | .variable name => findBinding .integer name bindings
  | .add left right => do
      let left ← renderIntExpr bindings left
      let right ← renderIntExpr bindings right
      pure s!"(+ {left} {right})"
  | .sub left right => do
      let left ← renderIntExpr bindings left
      let right ← renderIntExpr bindings right
      pure s!"(- {left} {right})"
  | .scale coefficient body => do
      let body ← renderIntExpr bindings body
      pure s!"(* {renderIntLiteral coefficient} {body})"

private def renderPredicate (bindings : List SmtBinding) :
    Predicate → Except SmtTranslationError String
  | .truth => .ok "true"
  | .falsity => .ok "false"
  | .boolVariable name => findBinding .boolean name bindings
  | .not body => do
      let body ← renderPredicate bindings body
      pure s!"(not {body})"
  | .and left right => do
      let left ← renderPredicate bindings left
      let right ← renderPredicate bindings right
      pure s!"(and {left} {right})"
  | .or left right => do
      let left ← renderPredicate bindings left
      let right ← renderPredicate bindings right
      pure s!"(or {left} {right})"
  | .intEq left right => do
      let left ← renderIntExpr bindings left
      let right ← renderIntExpr bindings right
      pure s!"(= {left} {right})"
  | .intNe left right => do
      let left ← renderIntExpr bindings left
      let right ← renderIntExpr bindings right
      pure s!"(distinct {left} {right})"
  | .intLe left right => do
      let left ← renderIntExpr bindings left
      let right ← renderIntExpr bindings right
      pure s!"(<= {left} {right})"
  | .intLt left right => do
      let left ← renderIntExpr bindings left
      let right ← renderIntExpr bindings right
      pure s!"(< {left} {right})"
  | .named _ _ _ => .error (.unsupportedFragment .untranslatedPredicate)
  | .nonlinear _ => .error (.unsupportedFragment .nonlinearArithmetic)
  | .worldSensitive _ => .error (.unsupportedFragment .worldEffect)

private def renderConjunction : List String → String
  | [] => "true"
  | [value] => value
  | values => s!"(and {String.intercalate " " values})"

private def renderBinding (binding : SmtBinding) : String :=
  match binding.sort with
  | .integer => s!"(declare-fun {binding.symbol} () Int)"
  | .boolean => s!"(declare-fun {binding.symbol} () Bool)"

private def renderSmtLib (formula : Formula) (bindings : List SmtBinding) :
    Except SmtTranslationError String := do
  let premises ← formula.premises.mapM (renderPredicate bindings)
  let conclusions ← formula.conclusions.mapM (renderPredicate bindings)
  let declarations := bindings.map renderBinding
  let lines :=
    ["(set-logic QF_LIA)"] ++
    declarations ++
    ["(assert " ++ renderConjunction premises ++ ")",
      "(assert (not " ++ renderConjunction conclusions ++ "))",
      "(check-sat)",
      "(exit)"]
  pure (String.intercalate "\n" lines)

def checkedSmtRequest (profile : SolverProfile) (formula : Formula) :
    Except SmtTranslationError SmtRequest :=
  if !validSolverProfile profile then
    .error .invalidSolverProfile
  else
    match classify formula with
    | .qfLia =>
        let bindings := formulaBindings formula
        match renderSmtLib formula bindings with
        | .ok smtLib => .ok { profile, formula, bindings, smtLib }
        | .error error => .error error
    | fragment => .error (.unsupportedFragment fragment)

def serialiseQfLia (formula : Formula) : Except SmtTranslationError String :=
  match checkedSmtRequest defaultSolverProfile formula with
  | .ok request => .ok request.smtLib
  | .error error => .error error

def validSmtRequest (request : SmtRequest) : Bool :=
  match checkedSmtRequest request.profile request.formula with
  | .ok expected => expected == request
  | .error _ => false

end Firth.Smt
