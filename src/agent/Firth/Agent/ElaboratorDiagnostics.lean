import agent.Firth.Agent.DiagnosticEnvelope
import elaborator.Firth.Parser
import elaborator.Firth.Erasure
import elaborator.Firth.StackEffect
import elaborator.Firth.Refinement
import elaborator.Firth.Pipeline

namespace Firth.Agent

open Lean

structure EmissionContext where
  payloadId : String
  requestId : String
  source : LocationSource
  obligations : List Obligation := []
  proposedFixes : List ProposedFix := []
  related : List Related := []
  groupId : Option String := none

private def locationFromSpan (source : LocationSource)
    (span : Firth.Elaborator.Span) : Location := {
  source
  range := {
    start := { line := span.start.line, column := span.start.column }
    stop := { line := span.stop.line, column := span.stop.column } } }

private def lastSegment (code : String) : String :=
  code.splitOn "." |>.reverse |>.head?.getD "unknown"

private def messageKey (code : String) : String :=
  "diagnostic." ++ (lastSegment code).replace "-" "_"

private def namedParams (name : String) : Json :=
  .mkObj [("name", .str name)]

private def stackValue (stack : Firth.Elaborator.StackEffect.AStack) : Opaque := {
  encoding := "opaque"
  value := .mkObj [
    ("lean_repr", .str s!"{repr stack}"),
    ("firth", .str (Firth.Elaborator.StackEffect.renderStack stack))]
  displayHint := some "firth" }

private def opaqueJson (value : Opaque) : Json :=
  let fields := [("encoding", Json.str value.encoding), ("value", value.value)]
  let fields := match value.displayHint with
    | none => fields
    | some hint => fields ++ [("display_hint", .str hint)]
  .mkObj fields

private def envelope (context : EmissionContext) (body : Diagnostic) : Envelope :=
  .diagnostic context.payloadId context.requestId {
    body with
    obligations := context.obligations
    proposedFixes := context.proposedFixes
    related := context.related
    groupId := context.groupId }

private def parseCause : Firth.Elaborator.ParseCause → String
  | .lexical => "lexical"
  | .grammar => "grammar"
  | .delimiter => "delimiter"
  | .validation => "validation"

private def parseCauseData (error : Firth.Elaborator.ParseError) : Json :=
  let fields := match error.expected with
    | none => []
    | some expected => [("expected", Json.str expected)]
  let fields := match error.actual with
    | none => fields
    | some actual => fields ++ [("actual", Json.str actual)]
  .mkObj fields

private def definitionShape : String :=
  "A definition looks like `: name (forall ρ; ρ n:Int^many -- ρ r:Int^many) body;`."

/-- The primitives the agent language accepts beyond the kernel's
`surfacePrimitives`, each with its typing scheme: `send`, which threads the
linear `World` past a `Handle` and `Bytes`. This is the one table for them:
`ElaborateAdapter.gammaTyping` and `gammaErasure` read their signatures from
it, and `Lowering.targetPrimitive` refuses exactly these names. -/
def worldPrimitiveSchemes : List (String × Firth.Elaborator.StackEffect.Scheme) :=
  let row : Firth.Elaborator.StackEffect.AStack := .row (.rigid "ρ")
  [("send",
    { rowVariables := ["ρ"]
      input := .snoc (.snoc (.snoc row (.base "World" .linear))
        (.base "Handle" .linear)) (.base "Bytes" .linear)
      output := .snoc row (.base "World" .linear) })]

/-- The names in `worldPrimitiveSchemes`. -/
def worldPrimitives : List String := worldPrimitiveSchemes.map (·.1)

/-- Every primitive a program can write: the kernel's `surfacePrimitives`,
the one table the elaborator, the reference and the compiler share, then
`worldPrimitives`. Hints list these, so they cannot fall behind the
language. -/
def languagePrimitives : List String :=
  Firth.Interpreter.surfacePrimitives.map (·.1) ++ worldPrimitives

/-- `languagePrimitives` as a program writes them. -/
def primitiveList : String :=
  ", ".intercalate (languagePrimitives.map fun surface => s!"`prim {surface}`")

private def availablePrimitives : String :=
  s!"The primitives are {primitiveList}."

/-- The hint for a stack-effect name used as a variable. Stack-effect names
document the stack; only `locals` binds names, taking one value from the
stack for each, the last name from the top. -/
private def freshBinder (name : String) (taken : List String) : Nat → Nat → String
  | 0, _ => name
  | fuel + 1, suffix =>
      let candidate := s!"{name}{suffix}"
      if taken.contains candidate then freshBinder name taken fuel (suffix + 1) else candidate

/-- The names a `locals` block can bind for these inputs. A stack effect may
repeat a label (`n:Int n:Int`), but `locals` refuses a repeated name, so each
repeat gets the first numbered name (`n2`, `n3`, ...) that no input uses. -/
def localBinders (inputs : List String) : List String :=
  inputs.foldl (init := []) fun bound name =>
    if bound.contains name then
      let taken := inputs ++ bound
      bound ++ [freshBinder name taken (taken.length + 1) 2]
    else bound ++ [name]

private def effectNameHint (name : String) (inputs : List String) : String :=
  let names := localBinders inputs
  let binders := " ".intercalate names
  let renamed := if names == inputs then "" else
    " The stack effect repeats a name and `locals` needs distinct names, so the repeats are numbered here."
  let shape := if inputs.isEmpty then "" else
    s!" To use the inputs by name, bind them first: `locals \{ {binders} } \{ ... }` takes one value from the stack for each name, the last name from the top, and they are in scope inside the second braces." ++ renamed
  if inputs.contains name then
    s!"`{name}` is a name in the word's stack effect. Stack-effect names only document the stack; they are not variables in the body." ++ shape
  else
    s!"`{name}` names an output in the word's stack effect. Stack-effect names only document the stack; leave the result on the stack instead of naming it." ++ shape

/-- A plain-language sentence and a repair hint for a syntax or name error. -/
private def parseParams (error : Firth.Elaborator.ParseError) : Json :=
  let actual := error.actual.map (s!"`{·}`") |>.getD "the end of the input"
  let (message, hint) := match error.code with
    | "firth.name.unresolved" =>
        match error.actual, error.effectInputs ++ error.effectOutputs with
        | some name, _ :: _ =>
            (s!"{actual} is not a defined word, primitive or local.",
              effectNameHint name error.effectInputs)
        | _, _ =>
            (s!"{actual} is not a defined word, primitive or local.",
              "Define it (definitions may appear in any order), fix the spelling, or bind it as a local with `locals { name } { ... }`. Primitives are written with `prim`: " ++
                primitiveList ++ ". " ++ definitionShape)
    | _ =>
        let expected := match error.expected with
          | some expected => s!", expected `{expected}`"
          | none => ""
        (s!"Unexpected {actual}{expected}.", definitionShape)
  .mkObj [("message", .str message), ("hint", .str hint)]

def parserEnvelope (context : EmissionContext)
    (error : Firth.Elaborator.ParseError) : Envelope :=
  envelope context {
    code := error.code
    severity := "error"
    messageKey := messageKey error.code
    messageParams := parseParams error
    location := locationFromSpan context.source error.primary
    cause := { kind := parseCause error.cause, data := parseCauseData error }
    expectedStack := none
    actualStack := none }

def encodeParseError (context : EmissionContext)
    (error : Firth.Elaborator.ParseError) : String :=
  encode (parserEnvelope context error)

private structure ErasureDiagnostic where
  code : String
  cause : String
  params : Json
  span : Firth.Elaborator.Span

/-- What a branch does to the stack depth, in words: how many values it
takes from the stack below the `if` and how many it leaves in their place. -/
private def depthChange (effect : Nat × Nat) : String :=
  let (consumed, produced) := effect
  let values (count : Nat) := if count == 1 then "1 value" else s!"{count} values"
  if consumed == 0 then
    if produced == 0 then "leaves the stack as it is" else s!"pushes {values produced}"
  else s!"takes {values consumed} from the stack below the `if` and leaves {if produced == 0 then "nothing" else values produced}"

/-- The message and hint for an `if` in `word` whose branches change the
stack depth by different amounts: what each branch does, how many more values
one leaves than the other, and the edits that make them agree. Erasure knows
only the depths here, not the types; the type checker's report of the same
mistake, when it gets there, names the types too. -/
private def branchShapeExplanation (word : String) (onTrue onFalse : Nat × Nat) : String × String :=
  let inWord := if word.isEmpty then "" else s!" in `{word}`"
  let net (effect : Nat × Nat) : Int := (effect.2 : Int) - (effect.1 : Int)
  let values (count : Nat) := if count == 1 then "1 value" else s!"{count} values"
  let (longer, shorter, extra) :=
    if net onTrue > net onFalse then ("true", "false", (net onTrue - net onFalse).toNat)
    else ("false", "true", (net onFalse - net onTrue).toNat)
  let drops := " ".intercalate (List.replicate extra "drop")
  (s!"The two branches of `if`{inWord} leave different numbers of values: the true branch {depthChange onTrue}, and the false branch {depthChange onFalse}. So the {longer} branch leaves {values extra} more than the {shorter} branch.",
    s!"Either add `{drops}` at the end of the {longer} branch, or make the {shorter} branch push {values extra} more, of the same {if extra == 1 then "type" else "types"} the {longer} branch leaves on top. Both branches run on the same stack and must leave the same number and types of values, so that the code after the `if` finds one stack.")

private def erasureDiagnostic (word : String) : Firth.Elaborator.ErasureError → ErasureDiagnostic
  | .duplicateLocal name span =>
      { code := "firth.name.duplicate-local", cause := "name-resolution", params := namedParams name, span }
  | .unboundLocal name span =>
      { code := "firth.name.unbound-local", cause := "name-resolution", params := namedParams name, span }
  | .unsupportedCapture name span =>
      { code := "firth.elaboration.unsupported-capture", cause := "elaboration", params := namedParams name, span }
  | .missingStackValue span =>
      { code := "firth.type.stack-underflow", cause := "type-checking", params := .mkObj [], span }
  | .linearCopy name span =>
      { code := "firth.linearity.copy", cause := "linearity", params := namedParams name, span }
  | .linearUnused name span =>
      { code := "firth.linearity.unconsumed-resource", cause := "linearity", params := namedParams name, span }
  | .unresolvedEffect name span =>
      { code := "firth.name.unresolved-effect", cause := "name-resolution", params := namedParams name, span }
  | .effectUnderflow name span =>
      { code := "firth.type.stack-underflow", cause := "type-checking", params := namedParams name, span }
  | .usageMismatch name span =>
      { code := "firth.linearity.usage-mismatch", cause := "linearity", params := namedParams name, span }
  | .unsupportedLiteral span =>
      { code := "firth.elaboration.unsupported-literal", cause := "elaboration", params := .mkObj [], span }
  | .unsupportedAtom name span =>
      { code := "firth.elaboration.unsupported-atom", cause := "elaboration", params := namedParams name, span }
  | .branchShape span onTrue onFalse =>
      let (message, hint) := branchShapeExplanation word onTrue onFalse
      { code := "firth.type.branch-mismatch", cause := "type-checking"
        params := .mkObj ([("at", .str "if")] ++ (if word.isEmpty then [] else [("word", .str word)]) ++
          [("message", .str message), ("hint", .str hint)])
        span }
  | .untrackedStack name span lost =>
      let params := match lost with
        | some lost => .mkObj [("name", .str name), ("at", .str lost.atom),
            ("at_line", .num lost.span.start.line)]
        | none => namedParams name
      { code := "firth.elaboration.untracked-local", cause := "elaboration", params, span }
  | .hiddenLocal name span =>
      { code := "firth.elaboration.hidden-local", cause := "elaboration", params := namedParams name, span }

private def erasureExplanation (code name : String) (params : Json) : String × String :=
  match code with
  | "firth.name.duplicate-local" =>
      (s!"The local `{name}` is bound twice in one `locals` block.", "Give each local a different name.")
  | "firth.name.unbound-local" =>
      (s!"`{name}` is not a local in scope here.", "Bind it with `locals { name } { ... }`, which takes values from the top of the stack, or fix the spelling.")
  | "firth.elaboration.unsupported-capture" =>
      (s!"The nested `locals` block uses the outer local `{name}`.", "Pass the value in on the stack instead, or bind it in the inner block.")
  | "firth.type.stack-underflow" =>
      match name with
      | "" => ("A `locals` block or an operation here needs more values than the stack holds.",
          "`locals { x y z }` takes one value from the top of the stack for each name. Words can only use their declared inputs, values pushed earlier in the body, and locals.")
      | "quotation" => ("The checker could not work out how many values a quotation here uses.",
          "Check that every word inside the quotation has its inputs available. If the program is correct, this is a checker limit: move the quotation's body into a named word.")
      | "erasure-depth" => ("This definition is nested too deeply for the checker.",
          "Split the definition into smaller named words.")
      | _ => (s!"`{name}` needs more values than the stack holds here.",
          s!"Words can only use their declared inputs, values pushed earlier in the body, and locals. Check how many values are on the stack before `{name}` and in what order.")
  | "firth.elaboration.hidden-local" =>
      (s!"The checker could not move the local `{name}` out of the way of the operation here.",
        "This is a checker limit, not an error in the program: name the values the operation takes in a `locals` block, or move the code into a named word.")
  | "firth.elaboration.untracked-local" =>
      let lostBy := match (params.getObjValAs? String "at").toOption,
          (params.getObjValAs? Nat "at_line").toOption with
        | some at_, some line => s!"`{at_}` on line {line}"
        | _, _ => "`call`, `dip` or `if`"
      (s!"The local `{name}` is used after {lostBy} ran a quotation whose stack effect is not known here, so its position on the stack can't be determined.",
        "Use the local before running that quotation, or pass the value through the stack explicitly. Quotations written inline with a fixed effect, like `[ 1 prim + ] call`, are fine.")
  | "firth.name.unresolved-effect" =>
      (s!"`prim {name}` is not a primitive.", availablePrimitives)
  | "firth.linearity.copy" =>
      (s!"The linear local `{name}` is used more than once.", "A linear value must be used exactly once.")
  | "firth.linearity.unconsumed-resource" =>
      (s!"The linear local `{name}` is never used.", "A linear value must be used exactly once.")
  | _ => ("", "")

def erasureEnvelope (context : EmissionContext)
    (error : Firth.Elaborator.ErasureError) (word : String := "") : Envelope :=
  let diagnostic := erasureDiagnostic word error
  envelope context {
    code := diagnostic.code
    severity := "error"
    messageKey := messageKey diagnostic.code
    messageParams :=
      let name := (diagnostic.params.getObjValAs? String "name").toOption.getD ""
      match erasureExplanation diagnostic.code name diagnostic.params with
      | ("", _) => diagnostic.params
      | (message, hint) => diagnostic.params.mergeObj
          (.mkObj [("message", .str message), ("hint", .str hint)])
    location := locationFromSpan context.source diagnostic.span
    cause := { kind := diagnostic.cause }
    expectedStack := none
    actualStack := none }

def encodeErasureError (context : EmissionContext)
    (error : Firth.Elaborator.ErasureError) : String :=
  encode (erasureEnvelope context error)

private def stableWarningCode (code : String) : String :=
  match code with
  | "LOCAL_DEPTH" => "firth.elaboration.local-depth"
  | "STACK_JUGGLE" => "firth.elaboration.stack-juggle"
  | _ => "firth.elaboration.warning"

def erasureWarningEnvelope (context : EmissionContext)
    (warning : Firth.Elaborator.LintWarning) : Envelope :=
  let code := stableWarningCode warning.code
  envelope context {
    code
    severity := "warning"
    messageKey := messageKey code
    messageParams := if code == "firth.elaboration.warning" then
      .mkObj [("producer_code", .str warning.code)]
    else .mkObj []
    location := locationFromSpan context.source warning.span
    cause := { kind := "elaboration" }
    expectedStack := none
    actualStack := none }

def encodeErasureWarning (context : EmissionContext)
    (warning : Firth.Elaborator.LintWarning) : String :=
  encode (erasureWarningEnvelope context warning)

private def causeForCode (code : String) : String :=
  match code.splitOn "." with
  | "firth" :: "type" :: _ => "type-checking"
  | "firth" :: "linearity" :: _ => "linearity"
  | "firth" :: "name" :: _ => "name-resolution"
  | _ => "elaboration"

open Firth.Elaborator.StackEffect in
private def plural (count : Nat) (noun : String) : String :=
  if count == 1 then s!"1 {noun}" else s!"{count} {noun}s"

open Firth.Elaborator.StackEffect in
private def renderValues (values : List AType) : String :=
  if values.isEmpty then "nothing" else " ".intercalate (values.map renderType)

open Firth.Elaborator.StackEffect in
/-- The first position, counted from the top, where two value lists differ. -/
private def firstDifference (expected actual : List AType) : Option (Nat × AType × AType) :=
  let rec go (depth : Nat) : List AType → List AType → Option (Nat × AType × AType)
    | expectedTop :: expectedRest, actualTop :: actualRest =>
        if renderType expectedTop == renderType actualTop then go (depth + 1) expectedRest actualRest
        else some (depth, expectedTop, actualTop)
    | _, _ => none
  go 0 expected.reverse actual.reverse

private def ordinalFromTop : Nat → String
  | 0 => "the top value"
  | 1 => "the second value from the top"
  | 2 => "the third value from the top"
  | depth => s!"value {depth + 1} from the top"

private def capitalize (text : String) : String :=
  match text.toList with
  | first :: rest => String.ofList (first.toUpper :: rest)
  | [] => text

private def operandsNeeded : String → Option Nat
  | "dup" | "drop" | "call" | "quote" => some 1
  | "swap" | "dip" | "compose" => some 2
  | "if" => some 3
  | _ => none

open Firth.Elaborator.StackEffect in
/-- A value an author can push to stand for one of type `type`, if there is
an obvious one. -/
private def exampleValue (type : AType) : Option String :=
  match renderType type with
  | "Int" => some "0"
  | "Bool" => some "false"
  | _ => none

open Firth.Elaborator.StackEffect in
/-- An `if` whose branches leave different stacks: what each branch leaves,
by how much they differ, and an edit that makes them agree. -/
private def branchExplanation (inWord : String) (below onTrue onFalse : AStack) :
    String × String :=
  let (trueValues, trueRow) := stackValues onTrue
  let (falseValues, falseRow) := stackValues onFalse
  let base := s!"The two branches of `if`{inWord} leave different stacks. Below the condition and the two quotations the stack is {renderStack below}; the true branch leaves {renderStack onTrue} and the false branch leaves {renderStack onFalse}."
  let rule := "Both branches run on the same stack and must leave the same number and types of values, so that the code after the `if` finds one stack."
  let longer (name other : String) (extra : List AType) : String :=
    let count := extra.length
    let drops := if count == 1 then "`drop`" else s!"`drop` {count} times"
    let pushes := match extra.mapM exampleValue with
      | some values => s!"push {if count == 1 then "a value" else s!"{count} values"} of the same type at the end of the {other} branch (for example `{" ".intercalate values}`)"
      | none => s!"push {renderValues extra} at the end of the {other} branch"
    s!"The {name} branch leaves {plural count "more value"} than the {other} branch ({renderValues extra} on top). Either add {drops} at the end of the {name} branch, or {pushes}. {rule}"
  if trueRow != falseRow then
    (base, s!"The two branches leave different parts of the caller's stack (ρ): one of them consumes values it should keep, or keeps values it should consume. {rule}")
  else if trueValues.length > falseValues.length then
    (base, longer "true" "false" (trueValues.drop falseValues.length))
  else if falseValues.length > trueValues.length then
    (base, longer "false" "true" (falseValues.drop trueValues.length))
  else match firstDifference trueValues falseValues with
    | some (depth, onTrueType, onFalseType) =>
        (base, s!"Both leave {plural trueValues.length "value"}, but {ordinalFromTop depth} is {renderType onTrueType} after the true branch and {renderType onFalseType} after the false branch. Make both branches leave the same type there. {rule}")
    | none => (base, rule)

open Firth.Elaborator.StackEffect in
/-- An `if` with a branch that cannot run on the stack below the condition:
what that stack is, what the branch takes, and where they first differ. -/
private def branchInputExplanation (inWord : String) (below : AStack) (onTrueBranch : Bool)
    (takes : AStack) : String × String :=
  let name := if onTrueBranch then "true" else "false"
  let (belowValues, _) := stackValues below
  let (takesValues, _) := stackValues takes
  let base := s!"The {name} branch of `if`{inWord} cannot run on the stack it is given. Below the condition and the two quotations the stack is {renderStack below}, but the {name} branch takes {renderStack takes}."
  let rule := "Both branches run on the stack that is left once `if` has taken the condition and the two quotations, so each branch must start from that stack."
  match firstDifference takesValues belowValues with
  | some (depth, want, got) =>
      (base, s!"{capitalize (ordinalFromTop depth)} there is {renderType got}, but the {name} branch expects {renderType want}. Check the order of the values the branch uses (`swap` exchanges the top two), or what was pushed before the condition. {rule}")
  | none =>
      if takesValues.length > belowValues.length then
        (base, s!"The {name} branch takes more values than are there. Push them before the condition, or take them as parameters in the signature. {rule}")
      else (base, rule)

open Firth.Elaborator.StackEffect in
/-- A plain-language sentence and a repair hint for a checker diagnostic,
written for an author who sees only this message and the source. -/
private def explain (diagnostic : Firth.Elaborator.StackEffect.Diagnostic) : String × String :=
  let at_ := diagnostic.subject.getD "this operation"
  let inWord := match diagnostic.word with
    | some word => s!" in `{word}`"
    | none => ""
  let before := renderStack diagnostic.state
  let expected := diagnostic.expected.map stackValues
  let actual := diagnostic.actual.map stackValues
  let rowNote := " Here ρ stands for the caller's values that this word must leave untouched."
  match diagnostic.code, expected, actual with
  | "firth.type.declared-effect-mismatch", some (declared, _), some (left, _) =>
      let word := diagnostic.word.getD "this word"
      let base := s!"`{word}` declares that it leaves {(diagnostic.expected.map renderStack).getD "?"} but its body leaves {(diagnostic.actual.map renderStack).getD "?"}."
      if left.length > declared.length then
        let extra := left.length - declared.length
        (base, s!"The body leaves {plural extra "extra value"} on top ({renderValues (left.drop declared.length)}). Consume or `drop` {if extra == 1 then "it" else "them"} before the end of the word, or declare {if extra == 1 then "it" else "them"} in the signature's output." ++ rowNote)
      else if left.length < declared.length then
        let missing := declared.length - left.length
        (base, s!"The body leaves {plural missing "value"} fewer than declared. Something consumes a value it should keep: copy it first with `dup`, or fix the signature." ++ rowNote)
      else match firstDifference declared left with
        | some (depth, want, got) =>
            (base, s!"{capitalize (ordinalFromTop depth)} is {renderType got} but the signature says {renderType want}. Convert it or change the declared output type.")
        | none => (base, "The stack shapes differ; compare the declared output with the body's result value by value.")
  | "firth.type.primitive-input-mismatch", some (wanted, _), some (present, row)
  | "firth.type.word-input-mismatch", some (wanted, _), some (present, row) =>
      let base := s!"`{at_}`{inWord} needs {renderValues wanted} on top of the stack, but the stack before it is {before}."
      if present.length < wanted.length && row.isSome then
        (base, s!"`{at_}` takes {plural wanted.length "value"} but only {plural present.length "value"} {if present.length == 1 then "is" else "are"} available. Push or keep the missing input before it (for example `dup` to copy, or `over` if defined), or take it as a parameter in the signature." ++ rowNote)
      else match firstDifference wanted present with
        | some (depth, want, got) =>
            (base, s!"{capitalize (ordinalFromTop depth)} is {renderType got} but `{at_}` expects {renderType want}. Check the argument order (`swap` exchanges the top two values) or the operation.")
        | none => (base, s!"The inputs to `{at_}` do not match its signature {renderValues wanted}.")
  | "firth.type.stack-underflow", _, _ =>
      let count := match operandsNeeded at_ with
        | some count => s!" needs {plural count "value"} and"
        | none => ""
      (s!"`{at_}`{inWord}{count} ran out of values: the stack before it is {before}.",
        "A word can only use values declared as inputs in its signature or pushed earlier in its body. Add the missing input to the signature or push it first." ++ rowNote)
  | "firth.type.expected-bool", _, _ =>
      (s!"`if`{inWord} needs a Bool condition under its two quotations, but the stack before it is {before}.",
        "Write `condition [ then-branch ] [ else-branch ] if`, where the condition is Bool, for example from `prim <` or `prim =`.")
  | "firth.type.expected-quotation", _, _ =>
      (s!"`{at_}`{inWord} needs a quotation, but the stack before it is {before}.",
        "Put a `[ ... ]` quotation where the operation expects one.")
  | "firth.type.branch-mismatch", _, _ =>
      match diagnostic.branchOutputs, diagnostic.branchInput with
      | some (onTrue, onFalse), _ => branchExplanation inWord diagnostic.state onTrue onFalse
      | none, some (onTrueBranch, takes) => branchInputExplanation inWord diagnostic.state onTrueBranch takes
      | none, none =>
      (s!"The two branches of `if`{inWord} leave different stacks.",
        s!"Both branches must leave the same number and types of values. Expected {(diagnostic.expected.map renderStack).getD "?"}, found {(diagnostic.actual.map renderStack).getD "?"}.")
  | "firth.type.quotation-input-mismatch", _, _ =>
      (s!"The quotation run by `{at_}`{inWord} does not accept the stack below it ({before}).",
        "Check what the quotation body consumes against the values available under it.")
  | "firth.name.unknown-word", _, _ =>
      (s!"`{at_}`{inWord} is not a defined word.",
        s!"Define it with `: {at_} (forall ρ; ρ in:Int^many -- ρ out:Int^many) ...;` or fix the spelling. Primitives are written with `prim`: {primitiveList}.")
  | "firth.name.unknown-primitive", _, _ =>
      (s!"`{at_}`{inWord} is not a primitive.", availablePrimitives)
  | "firth.linearity.usage-mismatch", _, _ =>
      (s!"`{at_}`{inWord} copies or drops a value that must be used exactly once.",
        "Linear values cannot be duplicated or dropped; pass them on instead.")
  | code, _, _ =>
      let detail := match diagnostic.expected, diagnostic.actual with
        | some wanted, some found => s!" Expected {renderStack wanted}, found {renderStack found}."
        | _, _ => ""
      (s!"`{at_}`{inWord} failed the check {code}; the stack before it is {before}.{detail}", "")

open Firth.Elaborator.StackEffect in
private def stackEffectParams (diagnostic : Firth.Elaborator.StackEffect.Diagnostic) : Json :=
  let (message, hint) := explain diagnostic
  let fields := [("message", Json.str message), ("state", .str (renderStack diagnostic.state))]
  let fields := match diagnostic.word with
    | some word => ("word", .str word) :: fields
    | none => fields
  let fields := match diagnostic.subject with
    | some subject => fields ++ [("at", .str subject)]
    | none => fields
  let fields := match diagnostic.expected with
    | some stack => fields ++ [("expected", .str (renderStack stack))]
    | none => fields
  let fields := match diagnostic.actual with
    | some stack => fields ++ [("actual", .str (renderStack stack))]
    | none => fields
  let fields := match diagnostic.branchOutputs with
    | some (onTrue, onFalse) =>
        fields ++ [("true_branch", .str (renderStack onTrue)), ("false_branch", .str (renderStack onFalse))]
    | none => fields
  let fields := match diagnostic.branchInput with
    | some (onTrueBranch, takes) =>
        fields ++ [("branch", .str (if onTrueBranch then "true" else "false")), ("branch_takes", .str (renderStack takes))]
    | none => fields
  let fields := if hint.isEmpty then fields else fields ++ [("hint", .str hint)]
  .mkObj fields

def stackEffectEnvelope (context : EmissionContext)
    (diagnostic : Firth.Elaborator.StackEffect.Diagnostic) : Envelope :=
  let state := stackValue diagnostic.state
  envelope context {
    code := diagnostic.code
    severity := "error"
    messageKey := messageKey diagnostic.code
    messageParams := stackEffectParams diagnostic
    location := locationFromSpan context.source diagnostic.primary
    cause := {
      kind := causeForCode diagnostic.code
      data := .mkObj [("state", opaqueJson state)] }
    expectedStack := diagnostic.expected.map stackValue
    actualStack := diagnostic.actual.map stackValue }

def encodeStackEffectDiagnostic (context : EmissionContext)
    (diagnostic : Firth.Elaborator.StackEffect.Diagnostic) : String :=
  encode (stackEffectEnvelope context diagnostic)

private def refinementPairs (values : List (String × String)) : Json :=
  .mkObj (values.map fun (name, value) => (name, .str value))

private def refinementData
    (data : Firth.Elaborator.Refinement.OpaqueData) : Json :=
  .mkObj [
    ("encoding", .str data.encoding),
    ("value", refinementPairs data.value)]

private def refinementStack
    (stack : Firth.Elaborator.Refinement.OpaqueStack) : Opaque := {
  encoding := stack.encoding
  value := .mkObj [("lean_repr", .str s!"{repr stack.value}")] }

private def refinementStatus : Firth.Elaborator.Refinement.ObligationStatus → String
  | .deferred => "deferred"
  | .failed => "failed"

private def refinementLocation
    (location : Firth.Elaborator.Refinement.DiagnosticLocation) : Location :=
  locationFromSpan (.path location.path) location.range

private def refinementObligation
    (obligation : Firth.Elaborator.Refinement.DiagnosticObligation) : Obligation := {
  obligationId := obligation.obligationId
  kind := obligation.kind.canonical
  status := refinementStatus obligation.status
  data := refinementData obligation.data }

private def refinementEdit
    (edit : Firth.Elaborator.Refinement.DiagnosticEdit) : Edit := {
  location := refinementLocation edit.location
  replacement := edit.replacement }

private def refinementFix
    (fix : Firth.Elaborator.Refinement.ProposedFix) : ProposedFix := {
  fixId := fix.fixId
  kind := fix.kind
  titleKey := fix.titleKey
  applicability := fix.applicability
  edits := fix.edits.map refinementEdit }

private def refinementRelated
    (related : Firth.Elaborator.Refinement.RelatedDiagnostic) : Related := {
  relation := related.relation
  location := refinementLocation related.location
  payloadId := related.payloadId }

def refinementEnvelope
    (diagnostic : Firth.Elaborator.Refinement.RefinementDiagnostic) : Envelope :=
  .diagnostic diagnostic.payloadId diagnostic.requestId {
    code := diagnostic.body.code
    severity := diagnostic.body.severity
    messageKey := diagnostic.body.messageKey
    messageParams := refinementPairs diagnostic.body.messageParams
    location := refinementLocation diagnostic.body.location
    cause := {
      kind := diagnostic.body.cause.kind
      data := refinementData diagnostic.body.cause.data }
    expectedStack := some (refinementStack diagnostic.body.expectedStack)
    actualStack := some (refinementStack diagnostic.body.actualStack)
    obligations := diagnostic.body.obligations.map refinementObligation
    proposedFixes := diagnostic.body.proposedFixes.map refinementFix
    related := diagnostic.body.related.map refinementRelated
    groupId := some diagnostic.body.groupId }

def encodeRefinementDiagnostic
    (diagnostic : Firth.Elaborator.Refinement.RefinementDiagnostic) : String :=
  encode (refinementEnvelope diagnostic)

def typedHoleEnvelope (context : EmissionContext) (holeId : String)
    (hole : Firth.Elaborator.StackEffect.TypedHole) : Envelope :=
  .typedHole context.payloadId context.requestId {
    holeId
    location := locationFromSpan context.source hole.span
    inferredStackState := stackValue hole.state
    obligations := context.obligations }

def encodeTypedHole (context : EmissionContext) (holeId : String)
    (hole : Firth.Elaborator.StackEffect.TypedHole) : String :=
  encode (typedHoleEnvelope context holeId hole)

private def sourceKey : LocationSource → String
  | .uri uri | .uriAndPath uri _ => uri
  | .path path => path

private def positionBefore (left right : Position) : Bool :=
  left.line < right.line || (left.line == right.line && left.column < right.column)

private def rangeBefore (left right : SourceRange) : Bool :=
  if left.start == right.start then
    if left.stop == right.stop then false else positionBefore left.stop right.stop
  else positionBefore left.start right.start

private def diagnosticBefore (left right : Envelope) : Bool :=
  match left.body, right.body with
  | .diagnostic leftBody, .diagnostic rightBody =>
      let leftSource := sourceKey leftBody.location.source
      let rightSource := sourceKey rightBody.location.source
      if leftSource != rightSource then leftSource < rightSource
      else if leftBody.location.range != rightBody.location.range then
        rangeBefore leftBody.location.range rightBody.location.range
      else if leftBody.code != rightBody.code then leftBody.code < rightBody.code
      else left.payloadId < right.payloadId
  | .diagnostic _, _ => true
  | _, .diagnostic _ => false
  | _, _ => left.payloadId < right.payloadId

def sortDiagnosticEnvelopes (envelopes : List Envelope) : List Envelope :=
  envelopes.mergeSort diagnosticBefore

def refinementEnvelopes
    (result : Firth.Elaborator.Refinement.PipelineResult) : List Envelope :=
  sortDiagnosticEnvelopes (result.diagnostics.map refinementEnvelope)


inductive StructuredElaborationResult where
  | success (program : Firth.Elaborator.CheckedProgram)
  | failure (diagnostics : List Envelope)

private def sourcePath : LocationSource → String
  | .uri uri => uri
  | .path path => path
  | .uriAndPath uri path => if path.isEmpty then uri else path

private def internalEnvelope (context : EmissionContext) (span : Firth.Elaborator.Span) :
    Envelope :=
  envelope context {
    code := "firth.elaboration.internal"
    severity := "error"
    messageKey := messageKey "firth.elaboration.internal"
    messageParams := .mkObj []
    location := locationFromSpan context.source span
    cause := { kind := "elaboration" }
    expectedStack := none
    actualStack := none }

private def withContextSource (context : EmissionContext) (envelope : Envelope) :
    Envelope :=
  { envelope with
    body := match envelope.body with
    | .diagnostic diagnostic =>
        .diagnostic { diagnostic with
          location := { diagnostic.location with source := context.source } }
    | body => body }

private def pipelineDiagnosticEnvelope (context : EmissionContext) :
    Firth.Elaborator.PipelineDiagnostic → Envelope
  | .parse error => parserEnvelope context error
  | .erasure word error => erasureEnvelope context error word
  | .stackEffect diagnostic => stackEffectEnvelope context diagnostic
  | .refinement _ diagnostic => withContextSource context (refinementEnvelope diagnostic)
  | .internal span => internalEnvelope context span

def elaboratePipeline (context : EmissionContext) (source : String)
    (config : Firth.Elaborator.PipelineConfig := {}) : StructuredElaborationResult :=
  let config := { config with
    requestId := context.requestId
    sourcePath := sourcePath context.source }
  match Firth.Elaborator.elaborateWith config source with
  | .success program => .success program
  | .failure diagnostics =>
      .failure (sortDiagnosticEnvelopes
        (diagnostics.map (pipelineDiagnosticEnvelope context)))

end Firth.Agent
