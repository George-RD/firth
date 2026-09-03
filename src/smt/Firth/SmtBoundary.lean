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

structure SmtProofBindings where
  translationRuleHashes : List String
  translationSoundnessProofHashes : List String
  deriving Repr, BEq

def defaultSmtProofBindings : SmtProofBindings :=
  { translationRuleHashes :=
      ["sha256:5deded60a78d1e6a4eaef3d85663a63c614cc8248ef54f0184d6d1bf5ce0c714",
       "sha256:d66d0bab5887fedd138dee570d223bdf5b6aeee5ed34bf171bd5f562aad72fa9"]
    translationSoundnessProofHashes :=
      ["sha256:9a97b6a24e06c39a51117e5b598942a26fc9aaedbe361a3e596dc24c9e72e111",
       "sha256:f921db9f6e4e257cfc9060ddf2e61b0b6b0bae7f116a8bf3bed26a573f395774",
       "sha256:d2019818f45a5b7caad0cfd3482ebf8b6f1f29d15a10a013881bfe5c2932e005"] }

def validSmtProofBindings (bindings : SmtProofBindings) : Bool :=
  bindings == defaultSmtProofBindings

structure SmtResult where
  profile : SolverProfile
  proofBindings : SmtProofBindings := defaultSmtProofBindings
  /-- The canonical identity of the request this result answers.

  Without it a result carries no binding to the obligation it came from, so a
  verdict produced for one request could be attached to another. The default
  is empty and never matches a real request, which fails closed. -/
  requestIdentity : String := ""
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

inductive QfLiaSort where
  | integer
  | boolean
  deriving Repr, BEq, DecidableEq

-- firth:translation-rules-begin encoder
def encodeSort : SmtSort → QfLiaSort
  | .integer => .integer
  | .boolean => .boolean

inductive QfLiaIntExpr where
  | literal (value : Int)
  | variable (symbol : String)
  | add (left right : QfLiaIntExpr)
  | sub (left right : QfLiaIntExpr)
  | scale (coefficient : Int) (body : QfLiaIntExpr)
  deriving Repr, BEq, DecidableEq

inductive QfLiaPredicate where
  | truth
  | falsity
  | boolVariable (symbol : String)
  | not (body : QfLiaPredicate)
  | and (left right : QfLiaPredicate)
  | or (left right : QfLiaPredicate)
  | intEq (left right : QfLiaIntExpr)
  | intNe (left right : QfLiaIntExpr)
  | intLe (left right : QfLiaIntExpr)
  | intLt (left right : QfLiaIntExpr)
  deriving Repr, BEq, DecidableEq

def encodeIntExpr : IntExpr → QfLiaIntExpr
  | .literal value => .literal value
  | .variable name => .variable name
  | .add left right => .add (encodeIntExpr left) (encodeIntExpr right)
  | .sub left right => .sub (encodeIntExpr left) (encodeIntExpr right)
  | .scale coefficient body => .scale coefficient (encodeIntExpr body)

def encodePredicate : Predicate → Option QfLiaPredicate
  | .truth => some .truth
  | .falsity => some .falsity
  | .boolVariable name => some (.boolVariable name)
  | .not body =>
      match encodePredicate body with
      | some body => some (.not body)
      | none => none
  | .and left right =>
      match encodePredicate left, encodePredicate right with
      | some left, some right => some (.and left right)
      | _, _ => none
  | .or left right =>
      match encodePredicate left, encodePredicate right with
      | some left, some right => some (.or left right)
      | _, _ => none
  | .intEq left right => some (.intEq (encodeIntExpr left) (encodeIntExpr right))
  | .intNe left right => some (.intNe (encodeIntExpr left) (encodeIntExpr right))
  | .intLe left right => some (.intLe (encodeIntExpr left) (encodeIntExpr right))
  | .intLt left right => some (.intLt (encodeIntExpr left) (encodeIntExpr right))
  | .named _ _ _ | .nonlinear _ | .worldSensitive _ => none

structure QfLiaFormula where
  premises : List QfLiaPredicate
  conclusions : List QfLiaPredicate
  deriving Repr, BEq, DecidableEq

def encodePredicates : List Predicate → Option (List QfLiaPredicate)
  | [] => some []
  | predicate :: rest =>
      match encodePredicate predicate, encodePredicates rest with
      | some encoded, some encodedRest => some (encoded :: encodedRest)
      | _, _ => none

def encodeFormula (formula : Formula) : Option QfLiaFormula :=
  match encodePredicates formula.premises, encodePredicates formula.conclusions with
  | some premises, some conclusions => some { premises, conclusions }
  | _, _ => none


-- firth:translation-rules-end encoder

def evalQfLiaInt (valuation : Valuation) : QfLiaIntExpr → Option Int
  | .literal value => some value
  | .variable symbol => lookup symbol valuation.integers
  | .add left right => return (← evalQfLiaInt valuation left) +
      (← evalQfLiaInt valuation right)
  | .sub left right => return (← evalQfLiaInt valuation left) -
      (← evalQfLiaInt valuation right)
  | .scale coefficient body => return coefficient * (← evalQfLiaInt valuation body)

def evalQfLiaPredicate (valuation : Valuation) : QfLiaPredicate → Option Bool
  | .truth => some true
  | .falsity => some false
  | .boolVariable symbol => lookup symbol valuation.booleans
  | .not body => return !(← evalQfLiaPredicate valuation body)
  | .and left right => return (← evalQfLiaPredicate valuation left) &&
      (← evalQfLiaPredicate valuation right)
  | .or left right => return (← evalQfLiaPredicate valuation left) ||
      (← evalQfLiaPredicate valuation right)
  | .intEq left right => return (← evalQfLiaInt valuation left) ==
      (← evalQfLiaInt valuation right)
  | .intNe left right => return (← evalQfLiaInt valuation left) !=
      (← evalQfLiaInt valuation right)
  | .intLe left right => return (← evalQfLiaInt valuation left) <=
      (← evalQfLiaInt valuation right)
  | .intLt left right => return (← evalQfLiaInt valuation left) <
      (← evalQfLiaInt valuation right)
def evalConjunction : (valuation : Valuation) → List Predicate → Option Bool
  | _, [] => some true
  | valuation, predicate :: rest =>
      return (← evalPredicate valuation predicate) &&
        (← evalConjunction valuation rest)

def evalAnyFalse : (valuation : Valuation) → List Predicate → Option Bool
  | _, [] => some false
  | valuation, predicate :: rest =>
      match evalPredicate valuation predicate with
      | some false =>
          match evalAnyFalse valuation rest with
          | none => none
          | some _ => some true
      | some true => evalAnyFalse valuation rest
      | none => none

def evalQfLiaConjunction :
    (valuation : Valuation) → List QfLiaPredicate → Option Bool
  | _, [] => some true
  | valuation, predicate :: rest =>
      return (← evalQfLiaPredicate valuation predicate) &&
        (← evalQfLiaConjunction valuation rest)

def evalQfLiaAnyFalse :
    (valuation : Valuation) → List QfLiaPredicate → Option Bool
  | _, [] => some false
  | valuation, predicate :: rest =>
      match evalQfLiaPredicate valuation predicate with
      | some false =>
          match evalQfLiaAnyFalse valuation rest with
          | none => none
          | some _ => some true
      | some true => evalQfLiaAnyFalse valuation rest
      | none => none

def evalFormula (valuation : Valuation) (formula : Formula) : Option Bool :=
  return (← evalConjunction valuation formula.premises) &&
    (← evalAnyFalse valuation formula.conclusions)


def evalEncodedPredicates (valuation : Valuation) :
    Option (List QfLiaPredicate) → Option Bool
  | none => none
  | some predicates => evalQfLiaConjunction valuation predicates

def evalEncodedAnyFalse (valuation : Valuation) :
    Option (List QfLiaPredicate) → Option Bool
  | none => none
  | some predicates => evalQfLiaAnyFalse valuation predicates




-- firth:translation-soundness-begin encoder
theorem encodeSort_preserves (sort : SmtSort) :
    encodeSort sort == (match sort with
      | .integer => QfLiaSort.integer
      | .boolean => QfLiaSort.boolean) := by
  cases sort <;> rfl

theorem encodeIntExpr_sound (valuation : Valuation) (expression : IntExpr) :
    evalQfLiaInt valuation (encodeIntExpr expression) =
      evalInt valuation expression := by
  induction expression with
  | literal => rfl
  | «variable» name => rfl
  | add left right ihLeft ihRight =>
      simp [encodeIntExpr, evalQfLiaInt, evalInt, ihLeft, ihRight]
  | sub left right ihLeft ihRight =>
      simp [encodeIntExpr, evalQfLiaInt, evalInt, ihLeft, ihRight]
  | scale coefficient body ih =>
      simp [encodeIntExpr, evalQfLiaInt, evalInt, ih]

def evalEncodedPredicate (valuation : Valuation) :
    Option QfLiaPredicate → Option Bool
  | none => none
  | some predicate => evalQfLiaPredicate valuation predicate

theorem encodePredicate_semantics (valuation : Valuation) (predicate : Predicate) :
    evalEncodedPredicate valuation (encodePredicate predicate) =
      evalPredicate valuation predicate := by
  induction predicate with
  | truth => rfl
  | falsity => rfl
  | boolVariable => rfl
  | not body ih =>
      simp only [encodePredicate, evalEncodedPredicate, evalPredicate]
      cases result : encodePredicate body with
      | none =>
          rw [← ih]
          simp [result, evalEncodedPredicate]
      | some encoded =>
          rw [← ih]
          simp [result, evalEncodedPredicate, evalQfLiaPredicate]
  | and left right ihLeft ihRight =>
      simp only [encodePredicate, evalEncodedPredicate, evalPredicate]
      cases leftResult : encodePredicate left with
      | none =>
          rw [← ihLeft]
          simp [leftResult, evalEncodedPredicate]
      | some leftEncoded =>
          cases rightResult : encodePredicate right with
          | none =>
              rw [← ihRight]
              simp [leftResult, rightResult, evalEncodedPredicate]
          | some rightEncoded =>
              rw [← ihLeft, ← ihRight]
              simp [leftResult, rightResult, evalEncodedPredicate,
                evalQfLiaPredicate]
  | or left right ihLeft ihRight =>
      simp only [encodePredicate, evalEncodedPredicate, evalPredicate]
      cases leftResult : encodePredicate left with
      | none =>
          rw [← ihLeft]
          simp [leftResult, evalEncodedPredicate]
      | some leftEncoded =>
          cases rightResult : encodePredicate right with
          | none =>
              rw [← ihRight]
              simp [leftResult, rightResult, evalEncodedPredicate]
          | some rightEncoded =>
              rw [← ihLeft, ← ihRight]
              simp [leftResult, rightResult, evalEncodedPredicate,
                evalQfLiaPredicate]
  | intEq left right =>
      simp [encodePredicate, evalEncodedPredicate, evalQfLiaPredicate,
        evalPredicate, encodeIntExpr_sound]
  | intNe left right =>
      simp [encodePredicate, evalEncodedPredicate, evalQfLiaPredicate,
        evalPredicate, encodeIntExpr_sound]
  | intLe left right =>
      simp [encodePredicate, evalEncodedPredicate, evalQfLiaPredicate,
        evalPredicate, encodeIntExpr_sound]
  | intLt left right =>
      simp [encodePredicate, evalEncodedPredicate, evalQfLiaPredicate,
        evalPredicate, encodeIntExpr_sound]
  | named => rfl
  | nonlinear => rfl
  | worldSensitive => rfl
theorem encodePredicates_conjunction_sound (valuation : Valuation)
    (predicates : List Predicate) :
    evalEncodedPredicates valuation (encodePredicates predicates) =
      evalConjunction valuation predicates := by
  induction predicates with
  | nil => rfl
  | cons predicate rest ih =>
      cases predicateResult : encodePredicate predicate with
      | none =>
          have predicateSemantics := encodePredicate_semantics valuation predicate
          rw [predicateResult] at predicateSemantics
          have predicateNone : evalPredicate valuation predicate = none := by
            simpa [evalEncodedPredicate] using predicateSemantics.symm
          simp [encodePredicates, predicateResult, evalEncodedPredicates,
            evalConjunction, predicateNone]
      | some encodedPredicate =>
          have predicateSemantics := encodePredicate_semantics valuation predicate
          rw [predicateResult] at predicateSemantics
          have predicateSound :
              evalQfLiaPredicate valuation encodedPredicate =
                evalPredicate valuation predicate := by
            simpa [evalEncodedPredicate] using predicateSemantics
          cases restResult : encodePredicates rest with
          | none =>
              rw [restResult] at ih
              have restNone : evalConjunction valuation rest = none := by
                simpa [evalEncodedPredicates] using ih.symm
              simp [encodePredicates, predicateResult, restResult,
                evalEncodedPredicates, evalQfLiaConjunction, evalConjunction,
                predicateSound, restNone]
          | some restEncoded =>
              rw [restResult] at ih
              have restSound :
                  evalQfLiaConjunction valuation restEncoded =
                    evalConjunction valuation rest := by
                simpa [evalEncodedPredicates] using ih
              simp [encodePredicates, predicateResult, restResult,
                evalEncodedPredicates, evalQfLiaConjunction, evalConjunction,
                predicateSound, restSound]
theorem encodePredicates_anyFalse_sound (valuation : Valuation)
    (predicates : List Predicate) :
    evalEncodedAnyFalse valuation (encodePredicates predicates) =
      evalAnyFalse valuation predicates := by
  induction predicates with
  | nil => rfl
  | cons predicate rest ih =>
      cases predicateResult : encodePredicate predicate with
      | none =>
          have predicateSemantics := encodePredicate_semantics valuation predicate
          rw [predicateResult] at predicateSemantics
          have predicateNone : evalPredicate valuation predicate = none := by
            simpa [evalEncodedPredicate] using predicateSemantics.symm
          simp [encodePredicates, predicateResult, evalEncodedAnyFalse,
            evalAnyFalse, predicateNone]
      | some encodedPredicate =>
          have predicateSemantics := encodePredicate_semantics valuation predicate
          rw [predicateResult] at predicateSemantics
          have predicateSound :
              evalQfLiaPredicate valuation encodedPredicate =
                evalPredicate valuation predicate := by
            simpa [evalEncodedPredicate] using predicateSemantics
          cases restResult : encodePredicates rest with
          | none =>
              rw [restResult] at ih
              have restNone : evalAnyFalse valuation rest = none := by
                simpa [evalEncodedAnyFalse] using ih.symm
              cases predicateValue : evalPredicate valuation predicate with
              | none =>
                  simp [encodePredicates, predicateResult, restResult,
                    evalEncodedAnyFalse, evalQfLiaAnyFalse, evalAnyFalse,
                    predicateValue, predicateSound, restNone]
              | some value =>
                  cases value <;>
                    simp [encodePredicates, predicateResult, restResult,
                      evalEncodedAnyFalse, evalQfLiaAnyFalse, evalAnyFalse,
                      predicateValue, predicateSound, restNone]
          | some restEncoded =>
              rw [restResult] at ih
              have restSound :
                  evalQfLiaAnyFalse valuation restEncoded =
                    evalAnyFalse valuation rest := by
                simpa [evalEncodedAnyFalse] using ih
              cases predicateValue : evalPredicate valuation predicate with
              | none =>
                  simp [encodePredicates, predicateResult, restResult,
                    evalEncodedAnyFalse, evalQfLiaAnyFalse, evalAnyFalse,
                    predicateValue, predicateSound, restSound]
              | some value =>
                  cases value <;>
                    simp [encodePredicates, predicateResult, restResult,
                      evalEncodedAnyFalse, evalQfLiaAnyFalse, evalAnyFalse,
                      predicateValue, predicateSound, restSound]
def evalEncodedFormula (valuation : Valuation) :
    Option QfLiaFormula → Option Bool
  | none => none
  | some formula =>
      return (← evalEncodedPredicates valuation (some formula.premises)) &&
        (← evalEncodedAnyFalse valuation (some formula.conclusions))

theorem encodeFormula_semantics (valuation : Valuation) (formula : Formula) :
    evalEncodedFormula valuation (encodeFormula formula) =
      evalFormula valuation formula := by
  cases formula with
  | mk premises conclusions =>
      cases premiseResult : encodePredicates premises with
      | none =>
          have premiseSemantics :=
            encodePredicates_conjunction_sound valuation premises
          rw [premiseResult] at premiseSemantics
          have premiseNone : evalConjunction valuation premises = none := by
            simpa [evalEncodedPredicates] using premiseSemantics.symm
          simp [encodeFormula, premiseResult, evalEncodedFormula, evalFormula,
            premiseNone]
      | some encodedPremises =>
          have premiseSemantics :=
            encodePredicates_conjunction_sound valuation premises
          rw [premiseResult] at premiseSemantics
          have premiseSound :
              evalQfLiaConjunction valuation encodedPremises =
                evalConjunction valuation premises := by
            simpa [evalEncodedPredicates] using premiseSemantics
          cases conclusionResult : encodePredicates conclusions with
          | none =>
              have conclusionSemantics :=
                encodePredicates_anyFalse_sound valuation conclusions
              rw [conclusionResult] at conclusionSemantics
              have conclusionNone : evalAnyFalse valuation conclusions = none := by
                simpa [evalEncodedAnyFalse] using conclusionSemantics.symm
              simp [encodeFormula, premiseResult, conclusionResult,
                evalEncodedFormula, evalFormula, premiseSound, conclusionNone]
          | some encodedConclusions =>
              have conclusionSemantics :=
                encodePredicates_anyFalse_sound valuation conclusions
              rw [conclusionResult] at conclusionSemantics
              have conclusionSound :
                  evalQfLiaAnyFalse valuation encodedConclusions =
                    evalAnyFalse valuation conclusions := by
                simpa [evalEncodedAnyFalse] using conclusionSemantics
              simp [encodeFormula, premiseResult, conclusionResult,
                evalEncodedFormula, evalEncodedPredicates, evalEncodedAnyFalse,
                evalFormula, premiseSound, conclusionSound]

-- firth:translation-soundness-end encoder

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
  proofBindings : SmtProofBindings := defaultSmtProofBindings
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

-- firth:translation-rules-begin serialiser
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

private def renderQfLiaSort : QfLiaSort → String
  | .integer => "Int"
  | .boolean => "Bool"

private def renderBinding (binding : SmtBinding) : String :=
  s!"(declare-fun {binding.symbol} () {renderQfLiaSort (encodeSort binding.sort)})"

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
-- firth:translation-rules-end serialiser

private def renderQfLiaIntExpr (bindings : List SmtBinding) :
    QfLiaIntExpr → Except SmtTranslationError String
  | .literal value => .ok (renderIntLiteral value)
  | .variable symbol => findBinding .integer symbol bindings
  | .add left right => do
      let left ← renderQfLiaIntExpr bindings left
      let right ← renderQfLiaIntExpr bindings right
      pure s!"(+ {left} {right})"
  | .sub left right => do
      let left ← renderQfLiaIntExpr bindings left
      let right ← renderQfLiaIntExpr bindings right
      pure s!"(- {left} {right})"
  | .scale coefficient body => do
      let body ← renderQfLiaIntExpr bindings body
      pure s!"(* {renderIntLiteral coefficient} {body})"

private def renderQfLiaPredicate (bindings : List SmtBinding) :
    QfLiaPredicate → Except SmtTranslationError String
  | .truth => .ok "true"
  | .falsity => .ok "false"
  | .boolVariable symbol => findBinding .boolean symbol bindings
  | .not body => do
      let body ← renderQfLiaPredicate bindings body
      pure s!"(not {body})"
  | .and left right => do
      let left ← renderQfLiaPredicate bindings left
      let right ← renderQfLiaPredicate bindings right
      pure s!"(and {left} {right})"
  | .or left right => do
      let left ← renderQfLiaPredicate bindings left
      let right ← renderQfLiaPredicate bindings right
      pure s!"(or {left} {right})"
  | .intEq left right => do
      let left ← renderQfLiaIntExpr bindings left
      let right ← renderQfLiaIntExpr bindings right
      pure s!"(= {left} {right})"
  | .intNe left right => do
      let left ← renderQfLiaIntExpr bindings left
      let right ← renderQfLiaIntExpr bindings right
      pure s!"(distinct {left} {right})"
  | .intLe left right => do
      let left ← renderQfLiaIntExpr bindings left
      let right ← renderQfLiaIntExpr bindings right
      pure s!"(<= {left} {right})"
  | .intLt left right => do
      let left ← renderQfLiaIntExpr bindings left
      let right ← renderQfLiaIntExpr bindings right
      pure s!"(< {left} {right})"

private def renderEncodedSmtLib (formula : QfLiaFormula) (bindings : List SmtBinding) :
    Except SmtTranslationError String := do
  let premises ← formula.premises.mapM (renderQfLiaPredicate bindings)
  let conclusions ← formula.conclusions.mapM (renderQfLiaPredicate bindings)
  let declarations := bindings.map renderBinding
  let lines :=
    ["(set-logic QF_LIA)"] ++
    declarations ++
    ["(assert " ++ renderConjunction premises ++ ")",
      "(assert (not " ++ renderConjunction conclusions ++ "))",
      "(check-sat)",
      "(exit)"]
  pure (String.intercalate "\n" lines)

-- firth:translation-soundness-begin serialiser
theorem renderIntExpr_encode (bindings : List SmtBinding) (expression : IntExpr) :
    renderIntExpr bindings expression =
      renderQfLiaIntExpr bindings (encodeIntExpr expression) := by
  induction expression with
  | literal => rfl
  | «variable» name => rfl
  | add left right ihLeft ihRight =>
      simp [renderIntExpr, renderQfLiaIntExpr, encodeIntExpr, ihLeft, ihRight]
  | sub left right ihLeft ihRight =>
      simp [renderIntExpr, renderQfLiaIntExpr, encodeIntExpr, ihLeft, ihRight]
  | scale coefficient body ih =>
      simp [renderIntExpr, renderQfLiaIntExpr, encodeIntExpr, ih]

theorem renderPredicate_of_encode (bindings : List SmtBinding)
    (predicate : Predicate) (encoded : QfLiaPredicate)
    (encodedEq : encodePredicate predicate = some encoded) :
    renderPredicate bindings predicate = renderQfLiaPredicate bindings encoded := by
  induction predicate generalizing encoded with
  | truth =>
      simp [encodePredicate] at encodedEq
      cases encodedEq
      rfl
  | falsity =>
      simp [encodePredicate] at encodedEq
      cases encodedEq
      rfl
  | boolVariable name =>
      simp [encodePredicate] at encodedEq
      cases encodedEq
      rfl
  | not body ih =>
      cases result : encodePredicate body with
      | none =>
          simp [encodePredicate, result] at encodedEq
      | some bodyEncoded =>
          simp [encodePredicate, result] at encodedEq
          cases encodedEq
          simp [renderPredicate, renderQfLiaPredicate,
            ih bodyEncoded result]
  | and left right ihLeft ihRight =>
      cases leftResult : encodePredicate left with
      | none => simp [encodePredicate, leftResult] at encodedEq
      | some leftEncoded =>
          cases rightResult : encodePredicate right with
          | none => simp [encodePredicate, leftResult, rightResult] at encodedEq
          | some rightEncoded =>
              simp [encodePredicate, leftResult, rightResult] at encodedEq
              cases encodedEq
              simp only [renderPredicate, renderQfLiaPredicate]
              rw [ihLeft leftEncoded leftResult, ihRight rightEncoded rightResult]
  | or left right ihLeft ihRight =>
      cases leftResult : encodePredicate left with
      | none => simp [encodePredicate, leftResult] at encodedEq
      | some leftEncoded =>
          cases rightResult : encodePredicate right with
          | none => simp [encodePredicate, leftResult, rightResult] at encodedEq
          | some rightEncoded =>
              simp [encodePredicate, leftResult, rightResult] at encodedEq
              cases encodedEq
              simp only [renderPredicate, renderQfLiaPredicate]
              rw [ihLeft leftEncoded leftResult, ihRight rightEncoded rightResult]
  | intEq left right =>
      simp [encodePredicate] at encodedEq
      cases encodedEq
      simp [renderPredicate, renderQfLiaPredicate, renderIntExpr_encode]
  | intNe left right =>
      simp [encodePredicate] at encodedEq
      cases encodedEq
      simp [renderPredicate, renderQfLiaPredicate, renderIntExpr_encode]
  | intLe left right =>
      simp [encodePredicate] at encodedEq
      cases encodedEq
      simp [renderPredicate, renderQfLiaPredicate, renderIntExpr_encode]
  | intLt left right =>
      simp [encodePredicate] at encodedEq
      cases encodedEq
      simp [renderPredicate, renderQfLiaPredicate, renderIntExpr_encode]
  | named =>
      simp [encodePredicate] at encodedEq
  | nonlinear =>
      simp [encodePredicate] at encodedEq
  | worldSensitive =>
      simp [encodePredicate] at encodedEq

theorem renderPredicates_of_encode (bindings : List SmtBinding)
    (predicates : List Predicate) (encoded : List QfLiaPredicate)
    (encodedEq : encodePredicates predicates = some encoded) :
    predicates.mapM (renderPredicate bindings) =
      encoded.mapM (renderQfLiaPredicate bindings) := by
  induction predicates generalizing encoded with
  | nil =>
      simp [encodePredicates] at encodedEq ⊢
      cases encodedEq
      rfl
  | cons predicate rest ih =>
      cases predicateResult : encodePredicate predicate with
      | none => simp [encodePredicates, predicateResult] at encodedEq
      | some predicateEncoded =>
          cases restResult : encodePredicates rest with
          | none => simp [encodePredicates, predicateResult, restResult] at encodedEq
          | some restEncoded =>
              simp [encodePredicates, predicateResult, restResult] at encodedEq
              cases encodedEq
              rw [List.mapM_cons, List.mapM_cons]
              rw [renderPredicate_of_encode bindings predicate predicateEncoded
                predicateResult, ih restEncoded restResult]

theorem renderSmtLib_of_encodeFormula (formula : Formula) (bindings : List SmtBinding)
    (encoded : QfLiaFormula) (encodedEq : encodeFormula formula = some encoded) :
    renderSmtLib formula bindings = renderEncodedSmtLib encoded bindings := by
  cases formula with
  | mk premises conclusions =>
      cases premiseResult : encodePredicates premises with
      | none => simp [encodeFormula, premiseResult] at encodedEq
      | some encodedPremises =>
          cases conclusionResult : encodePredicates conclusions with
          | none => simp [encodeFormula, premiseResult, conclusionResult] at encodedEq
          | some encodedConclusions =>
              simp [encodeFormula, premiseResult, conclusionResult] at encodedEq
              cases encodedEq
              simp only [renderSmtLib, renderEncodedSmtLib]
              rw [renderPredicates_of_encode bindings premises encodedPremises
                premiseResult, renderPredicates_of_encode bindings conclusions
                encodedConclusions conclusionResult]
-- firth:translation-soundness-end serialiser

def checkedSmtRequest (profile : SolverProfile) (formula : Formula) :
    Except SmtTranslationError SmtRequest :=
  if !validSolverProfile profile then
    .error .invalidSolverProfile
  else
    match classify formula with
    | .qfLia =>
        let bindings := formulaBindings formula
        match renderSmtLib formula bindings with
        | .ok smtLib =>
            .ok { profile, formula, bindings, proofBindings := defaultSmtProofBindings, smtLib }
        | .error error => .error error
    | fragment => .error (.unsupportedFragment fragment)

def serialiseQfLia (formula : Formula) : Except SmtTranslationError String :=
  match checkedSmtRequest defaultSolverProfile formula with
  | .ok request => .ok request.smtLib
  | .error error => .error error

/-- The canonical identity of a request: every byte that determines what was
asked and of which solver. `spec/smt/refinement-discharge-architecture.md` §3
requires a record to bind its result to the request, and this is the value
both sides quote. Like `obligationIdentity` it is a canonical framed string
rather than a digest, so it can be compared without a hash implementation on
this path. -/
def canonicalRequestIdentity (request : SmtRequest) : String :=
  "request(" ++ frame request.profile.solverId ++ frame request.profile.version ++
    frame request.profile.executableDigest ++
    frame (encodeList request.profile.invocationOptions) ++
    frame (toString request.profile.wallTimeMilliseconds) ++
    frame (toString request.profile.memoryBytes) ++
    frame (canonicalFormula request.formula) ++ frame request.smtLib ++
    frame (encodeList request.proofBindings.translationRuleHashes) ++
    frame (encodeList request.proofBindings.translationSoundnessProofHashes) ++ ")"

def validSmtRequest (request : SmtRequest) : Bool :=
  match checkedSmtRequest request.profile request.formula with
  | .ok expected => expected == request
  | .error _ => false

/-!
## What an `unsat` verdict establishes

`spec/smt/refinement-discharge-architecture.md` §3 requires Lean to check the
translation pipeline before a solver answer may be used as evidence. The
encoder and serialiser theorems above relate the source formula to the script
that is emitted; the theorems below say what an answer to that script means.

The script asserts the premises and the negation of the conclusions, so a
model of it is a valuation satisfying the premises and falsifying some
conclusion. `unsat` says no such model exists.

Two facts about the two model theories have to be kept straight. An SMT model
is total: it assigns every declared symbol. A Lean `Valuation` is a partial
association list, and a predicate mentioning an unbound variable is
unevaluable rather than false. So an `unsat` verdict establishes validity over
valuations that bind the formula, which is what `ValidUnderBinding` states,
and not the unrestricted `Firth.Elaborator.Refinement.Valid`. The Lean
discharge path reaches the unrestricted form because closed predicates
evaluate identically under every valuation; the external path does not, and
saying so precisely is the point of these definitions.
-/

/-- The integer variables a formula mentions, premises and conclusions alike. -/
def Formula.integerVariables (formula : Formula) : List String :=
  (formula.premises ++ formula.conclusions).flatMap Predicate.integerVariables

/-- The boolean variables a formula mentions, premises and conclusions alike. -/
def Formula.booleanVariables (formula : Formula) : List String :=
  (formula.premises ++ formula.conclusions).flatMap Predicate.booleanVariables

/-- A valuation binds a formula when it assigns every variable the formula
mentions. This is the totality an SMT model has by construction, and it is
exactly the condition `validatesCounterexample` already imposes on a model
offered as a counterexample. -/
def Binds (formula : Formula) (valuation : Valuation) : Prop :=
  (∀ name ∈ formula.integerVariables, (lookup name valuation.integers).isSome) ∧
  (∀ name ∈ formula.booleanVariables, (lookup name valuation.booleans).isSome)

/-- A model of the emitted script. -/
def ScriptModel (formula : Formula) (valuation : Valuation) : Prop :=
  Binds formula valuation ∧
  evalConjunction valuation formula.premises = some true ∧
  evalAnyFalse valuation formula.conclusions = some true

/-- The `unsat` verdict, as a proposition about the script's models. This is
the one claim the pinned solver is trusted for; everything else on the path is
checked here. -/
def ScriptUnsatisfiable (formula : Formula) : Prop :=
  ∀ valuation, ¬ ScriptModel formula valuation

/-- Validity over binding valuations: the claim an `unsat` verdict supports. -/
def ValidUnderBinding (formula : Formula) : Prop :=
  ∀ valuation, Binds formula valuation →
    (∀ predicate ∈ formula.premises, evalPredicate valuation predicate = some true) →
      ∀ predicate ∈ formula.conclusions, evalPredicate valuation predicate = some true

-- firth:translation-soundness-begin adapter
theorem evalInt_isSome (valuation : Valuation) (expression : IntExpr)
    (bound : ∀ name ∈ expression.variables, (lookup name valuation.integers).isSome) :
    (evalInt valuation expression).isSome := by
  induction expression with
  | literal => simp [evalInt]
  | «variable» name =>
      have := bound name (by simp [IntExpr.variables])
      simpa [evalInt] using this
  | add left right leftIh rightIh =>
      have leftBound := fun name (member : name ∈ left.variables) =>
        bound name (by simp [IntExpr.variables]; exact Or.inl member)
      have rightBound := fun name (member : name ∈ right.variables) =>
        bound name (by simp [IntExpr.variables]; exact Or.inr member)
      have leftSome := leftIh leftBound
      have rightSome := rightIh rightBound
      cases leftValue : evalInt valuation left <;> cases rightValue : evalInt valuation right <;>
        simp_all [evalInt]
  | sub left right leftIh rightIh =>
      have leftBound := fun name (member : name ∈ left.variables) =>
        bound name (by simp [IntExpr.variables]; exact Or.inl member)
      have rightBound := fun name (member : name ∈ right.variables) =>
        bound name (by simp [IntExpr.variables]; exact Or.inr member)
      have leftSome := leftIh leftBound
      have rightSome := rightIh rightBound
      cases leftValue : evalInt valuation left <;> cases rightValue : evalInt valuation right <;>
        simp_all [evalInt]
  | scale coefficient body ih =>
      have bodyBound := fun name (member : name ∈ body.variables) =>
        bound name (by simpa [IntExpr.variables] using member)
      have bodySome := ih bodyBound
      cases bodyValue : evalInt valuation body <;> simp_all [evalInt]

theorem evalPredicate_isSome (valuation : Valuation) (predicate : Predicate)
    (translatable : (encodePredicate predicate).isSome)
    (integers : ∀ name ∈ predicate.integerVariables, (lookup name valuation.integers).isSome)
    (booleans : ∀ name ∈ predicate.booleanVariables, (lookup name valuation.booleans).isSome) :
    (evalPredicate valuation predicate).isSome := by
  induction predicate with
  | truth => simp [evalPredicate]
  | falsity => simp [evalPredicate]
  | boolVariable name =>
      have := booleans name (by simp [Predicate.booleanVariables])
      simpa [evalPredicate] using this
  | «not» body ih =>
      have bodyTranslatable : (encodePredicate body).isSome := by
        cases bodyEncoded : encodePredicate body <;> simp_all [encodePredicate]
      have bodySome := ih bodyTranslatable
        (fun name member => integers name (by simpa [Predicate.integerVariables] using member))
        (fun name member => booleans name (by simpa [Predicate.booleanVariables] using member))
      cases bodyValue : evalPredicate valuation body <;> simp_all [evalPredicate]
  | «and» left right leftIh rightIh =>
      have leftTranslatable : (encodePredicate left).isSome := by
        cases leftEncoded : encodePredicate left <;> simp_all [encodePredicate]
      have rightTranslatable : (encodePredicate right).isSome := by
        cases leftEncoded : encodePredicate left <;> cases rightEncoded : encodePredicate right <;>
          simp_all [encodePredicate]
      have leftSome := leftIh leftTranslatable
        (fun name member => integers name (by simp [Predicate.integerVariables]; exact Or.inl member))
        (fun name member => booleans name (by simp [Predicate.booleanVariables]; exact Or.inl member))
      have rightSome := rightIh rightTranslatable
        (fun name member => integers name (by simp [Predicate.integerVariables]; exact Or.inr member))
        (fun name member => booleans name (by simp [Predicate.booleanVariables]; exact Or.inr member))
      cases leftValue : evalPredicate valuation left <;>
        cases rightValue : evalPredicate valuation right <;> simp_all [evalPredicate]
  | «or» left right leftIh rightIh =>
      have leftTranslatable : (encodePredicate left).isSome := by
        cases leftEncoded : encodePredicate left <;> simp_all [encodePredicate]
      have rightTranslatable : (encodePredicate right).isSome := by
        cases leftEncoded : encodePredicate left <;> cases rightEncoded : encodePredicate right <;>
          simp_all [encodePredicate]
      have leftSome := leftIh leftTranslatable
        (fun name member => integers name (by simp [Predicate.integerVariables]; exact Or.inl member))
        (fun name member => booleans name (by simp [Predicate.booleanVariables]; exact Or.inl member))
      have rightSome := rightIh rightTranslatable
        (fun name member => integers name (by simp [Predicate.integerVariables]; exact Or.inr member))
        (fun name member => booleans name (by simp [Predicate.booleanVariables]; exact Or.inr member))
      cases leftValue : evalPredicate valuation left <;>
        cases rightValue : evalPredicate valuation right <;> simp_all [evalPredicate]
  | intEq left right | intNe left right | intLe left right | intLt left right =>
      have leftSome := evalInt_isSome valuation left
        (fun name member => integers name (by simp [Predicate.integerVariables]; exact Or.inl member))
      have rightSome := evalInt_isSome valuation right
        (fun name member => integers name (by simp [Predicate.integerVariables]; exact Or.inr member))
      cases leftValue : evalInt valuation left <;> cases rightValue : evalInt valuation right <;>
        simp_all [evalPredicate]
  | named _ _ _ => simp [encodePredicate] at translatable
  | nonlinear _ => simp [encodePredicate] at translatable
  | worldSensitive _ => simp [encodePredicate] at translatable

theorem encodePredicates_mem (predicates : List Predicate) (encoded : List QfLiaPredicate)
    (encodedEq : encodePredicates predicates = some encoded) :
    ∀ predicate ∈ predicates, (encodePredicate predicate).isSome := by
  induction predicates generalizing encoded with
  | nil => intro predicate member; cases member
  | cons head tail ih =>
      intro predicate member
      cases headEncoded : encodePredicate head with
      | none => simp [encodePredicates, headEncoded] at encodedEq
      | some headValue =>
          cases tailEncoded : encodePredicates tail with
          | none => simp [encodePredicates, headEncoded, tailEncoded] at encodedEq
          | some tailValue =>
              cases member with
              | head => simp [headEncoded]
              | tail _ rest => exact ih tailValue tailEncoded predicate rest

theorem evalConjunction_of_all_true (valuation : Valuation) (predicates : List Predicate)
    (allTrue : ∀ predicate ∈ predicates, evalPredicate valuation predicate = some true) :
    evalConjunction valuation predicates = some true := by
  induction predicates with
  | nil => rfl
  | cons head tail ih =>
      have headTrue := allTrue head (by simp)
      have tailTrue := ih (fun predicate member => allTrue predicate (by simp [member]))
      simp [evalConjunction, headTrue, tailTrue]

theorem evalAnyFalse_isSome (valuation : Valuation) (predicates : List Predicate)
    (evaluable : ∀ predicate ∈ predicates, (evalPredicate valuation predicate).isSome) :
    (evalAnyFalse valuation predicates).isSome := by
  induction predicates with
  | nil => simp [evalAnyFalse]
  | cons head tail ih =>
      have headSome := evaluable head (by simp)
      have tailSome := ih (fun predicate member => evaluable predicate (by simp [member]))
      cases headValue : evalPredicate valuation head with
      | none => simp [headValue] at headSome
      | some value =>
          cases value <;>
            cases tailValue : evalAnyFalse valuation tail <;>
              simp_all [evalAnyFalse]

theorem evalAnyFalse_of_not_all_true (valuation : Valuation) (predicates : List Predicate)
    (evaluable : ∀ predicate ∈ predicates, (evalPredicate valuation predicate).isSome)
    (witness : Predicate) (member : witness ∈ predicates)
    (notTrue : evalPredicate valuation witness ≠ some true) :
    evalAnyFalse valuation predicates = some true := by
  induction predicates with
  | nil => cases member
  | cons head tail ih =>
      have headSome := evaluable head (by simp)
      have tailEvaluable := fun predicate (m : predicate ∈ tail) =>
        evaluable predicate (by simp [m])
      have tailSome := evalAnyFalse_isSome valuation tail tailEvaluable
      cases headValue : evalPredicate valuation head with
      | none => simp [headValue] at headSome
      | some value =>
          cases value with
          | false =>
              cases tailValue : evalAnyFalse valuation tail with
              | none => simp [tailValue] at tailSome
              | some _ => simp [evalAnyFalse, headValue, tailValue]
          | true =>
              cases member with
              | head => exact absurd headValue notTrue
              | tail _ rest =>
                  simp only [evalAnyFalse, headValue]
                  exact ih tailEvaluable rest

/-- The adapter-soundness bridge.

An `unsat` verdict on the emitted script establishes that the formula holds
under every valuation binding it. This is the theorem that makes a solver
answer usable as evidence at all: without it, a discharge record would record
a verdict about a string with no stated relation to the obligation. -/
theorem validUnderBinding_of_scriptUnsatisfiable (formula : Formula)
    (encoded : QfLiaFormula) (encodedEq : encodeFormula formula = some encoded)
    (unsat : ScriptUnsatisfiable formula) : ValidUnderBinding formula := by
  intro valuation binds premisesTrue predicate member
  have conclusionsEncoded : encodePredicates formula.conclusions = some encoded.conclusions := by
    cases premiseResult : encodePredicates formula.premises with
    | none => simp [encodeFormula, premiseResult] at encodedEq
    | some encodedPremises =>
        cases conclusionResult : encodePredicates formula.conclusions with
        | none => simp [encodeFormula, premiseResult, conclusionResult] at encodedEq
        | some encodedConclusions =>
            simp [encodeFormula, premiseResult, conclusionResult] at encodedEq
            simp [conclusionResult, ← encodedEq]
  have translatable :=
    encodePredicates_mem formula.conclusions encoded.conclusions conclusionsEncoded
  have evaluable : ∀ conclusion ∈ formula.conclusions,
      (evalPredicate valuation conclusion).isSome := by
    intro conclusion conclusionMember
    refine evalPredicate_isSome valuation conclusion (translatable conclusion conclusionMember)
      (fun name nameMember => binds.1 name ?_) (fun name nameMember => binds.2 name ?_)
    · exact List.mem_flatMap.mpr ⟨conclusion, by simp [conclusionMember], nameMember⟩
    · exact List.mem_flatMap.mpr ⟨conclusion, by simp [conclusionMember], nameMember⟩
  cases witnessValue : evalPredicate valuation predicate with
  | none =>
      have := evaluable predicate member
      simp [witnessValue] at this
  | some value =>
      cases value with
      | true => rfl
      | false =>
          exact absurd
            ⟨binds, evalConjunction_of_all_true valuation formula.premises premisesTrue,
              evalAnyFalse_of_not_all_true valuation formula.conclusions evaluable predicate
                member (by simp [witnessValue])⟩
            (unsat valuation)

/-- The checked adapter never rewrites the formula it was asked about, so a
verdict on the request is a verdict on the obligation. -/
theorem checkedSmtRequest_formula (profile : SolverProfile) (formula : Formula)
    (request : SmtRequest) (checked : checkedSmtRequest profile formula = .ok request) :
    request.formula = formula := by
  cases valid : validSolverProfile profile with
  | false => simp [checkedSmtRequest, valid] at checked
  | true =>
      cases fragment : classify formula with
      | qfLia =>
          cases rendered : renderSmtLib formula (formulaBindings formula) with
          | error error => simp [checkedSmtRequest, valid, fragment, rendered] at checked
          | ok text =>
              simp [checkedSmtRequest, valid, fragment, rendered] at checked
              simp [← checked]
      | untranslatedPredicate => simp [checkedSmtRequest, valid, fragment] at checked
      | nonlinearArithmetic => simp [checkedSmtRequest, valid, fragment] at checked
      | worldEffect => simp [checkedSmtRequest, valid, fragment] at checked

/-- The same bridge, stated over a request the checked adapter produced. -/
theorem validUnderBinding_of_checkedRequest (profile : SolverProfile) (formula : Formula)
    (request : SmtRequest) (checked : checkedSmtRequest profile formula = .ok request)
    (encoded : QfLiaFormula) (encodedEq : encodeFormula formula = some encoded)
    (unsat : ScriptUnsatisfiable request.formula) : ValidUnderBinding formula :=
  validUnderBinding_of_scriptUnsatisfiable formula encoded encodedEq
    (checkedSmtRequest_formula profile formula request checked ▸ unsat)
-- firth:translation-soundness-end adapter

end Firth.Smt
