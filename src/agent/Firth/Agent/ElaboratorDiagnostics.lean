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
private def effectNameHint (name : String) (inputs : List String) : String :=
  let names := Firth.Elaborator.localBinders inputs
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
    | "firth.name.locals-order" =>
        let names (list : List String) : String := s!"`locals \{ {" ".intercalate list} }`"
        let received (pairs : List (String × String × String)) : String :=
          ", ".intercalate (pairs.map fun (name, input, type) =>
            if name == input then s!"`{name}` the value named `{input}` ({type})"
            else s!"`{name}` the value the stack effect calls `{input}` ({type})")
        let described := error.localsBlocks.map fun block =>
          s!"{names (block.pairs.map (·.1))} in `{block.word}` gives {received block.pairs}"
        -- Every edit stated here was applied to the word and checked by
        -- the pipeline; a block whose edit was not accepted gets no edit.
        let (checked, unchecked) := error.localsBlocks.partition (·.checked)
        -- A reordering of the same names needs no change to the body.
        let (plain, reaching) := checked.partition fun block =>
          block.renames.isEmpty && block.prelude.isEmpty
        let plainFix := if plain.isEmpty then "" else
          s!" Write {", and ".intercalate (plain.map fun block => s!"{names block.block} in `{block.word}`")}, and keep {if plain.length == 1 then "the body" else "the bodies"} as {if plain.length == 1 then "it is" else "they are"}: each name then holds the value the stack effect gives it."
        let reachingFix := reaching.map fun block =>
          let renamed := if block.renames.isEmpty then "" else
            s!" In its body, write {", ".intercalate (block.renames.map fun (name, input) => s!"`{input}` for `{name}`")}, since the new block binds {if block.renames.length == 1 then "that input" else "those inputs"} under the stack effect's {if block.renames.length == 1 then "name" else "names"}."
          let prelude := if block.prelude.isEmpty then "" else
            let count := block.prelude.length
            s!" Then start the body with `{" ".intercalate block.prelude}`: the old block left {if count == 1 then "1 value" else s!"{count} values"} on the stack for the body, and the new block binds every input, so the body pushes {if count == 1 then "the input" else "the inputs"} none of the old names stood for."
          s!" Write {names block.block} in `{block.word}`: the block takes the inputs from the top of the stack, so for each name the stack effect declares to hold the value it gives that name, the block must bind every input from the deepest such name up to the top.{renamed}{prelude}"
        let uncheckedFix := unchecked.map fun block =>
          s!" In `{block.word}` the body was written for the values the names hold now, so changing the block alone does not fix it: bind the inputs by their own names, as in {names block.block}, and rewrite the body so that each name is used for the value it holds."
        (s!"A `locals` block binds the word's inputs in a different order from its stack effect: " ++
            "; ".intercalate described ++ ".",
          s!"A `locals` block takes one value off the stack for each name, the last name from the top, so the names must follow the stack effect's inputs from left to right.{plainFix}{String.join reachingFix}{String.join uncheckedFix} Swapping values with `swap` would not help, because the names are what is wrong.")
    | "firth.syntax.parenthesis-in-body" =>
        (s!"{actual} is not allowed in a word's body: parentheses only enclose the stack effect after the word's name.",
          "Pass values to an operation by pushing them in the order it takes them, with no grouping: write `n 1 prim +`, not `(n 1 prim +)`, and `xs i 1 prim + f`, not `xs (i 1 prim +) f`. To keep code to run later, quote it with `[ ... ]`. A comment is written `(* ... *)`, or `\\` to the end of the line.")
    | "firth.syntax.definition-ended-early" =>
        let opened := if error.expected == some "]" then "a quotation opened with `[`"
          else "a `locals` body opened with `{`"
        let hint := match error.closedBy with
          -- The brackets after this `;` already close what it left open.
          | some (closer, span, .delete) =>
              s!"A `;` in a word's body always ends the word. The brackets after this `;` already close everything still open, up to the `{closer}` on line {span.start.line}, so delete this `;` and keep the `;` that ends the word after that `{closer}`."
          | some (closer, span, .move) =>
              s!"A `;` in a word's body always ends the word. The brackets after this `;` close everything still open, up to the `{closer}` on line {span.start.line}, but no `;` ends the word after it, so move this `;` to just after that `{closer}`."
          | some (closer, span, .endAfterBody) =>
              s!"A `;` in a word's body always ends the word. The brackets after this `;` close everything still open, up to the `{closer}` on line {span.start.line}, and the body goes on after it with no `;` to end the word, so delete this `;` and end the word with `;` after its last item."
          | none =>
              s!"A `;` in a word's body always ends the word. Close each open bracket first, innermost first: `]` for a quotation and `}` for a `locals` body, as in `... ] if };`. Here the next one to close is `{(error.expected.getD "]")}`."
        (s!"`;` ends the definition here, but {opened} is still open.", hint)
    | "firth.syntax.invalid-item" =>
        (s!"{error.actual.map (s!"`{·}`") |>.getD "This"} cannot start an item in a word's body.", definitionShape)
    | "firth.syntax.overlong-character" =>
        ("A character literal holds exactly one character between its quotes, as in `'a'`.",
          "Write exactly one character between the quotes, and close the literal with `'`.")
    | "firth.syntax.quote-in-name" =>
        (s!"{error.actual.map (s!"`{·}`") |>.getD "This name"} is not a name: a name cannot contain `'`.",
          "Rename it without the `'`, for example `q'` as `q2`, and use the new name everywhere the old one appears.")
    | _ =>
        let expected := match error.expected with
          | some expected => s!", expected `{expected}`"
          | none => ""
        -- Only a report at the end of the input has no text of its own.
        let message := match error.actual with
          | some _ => s!"Unexpected {actual}{expected}."
          | none =>
              if error.code == "firth.syntax.unexpected-eof" then s!"The input ends here{expected}."
              else s!"This is not valid here ({(lastSegment error.code).replace "-" " "}){expected}."
        (message, definitionShape)
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

/-- Labels joined as a reader would list them: `a`, `a and b`, `a, b and c`. -/
private def listing (labels : List String) : String :=
  match labels.reverse with
  | [] => "nothing"
  | [one] => one
  | last :: rest => s!"{", ".intercalate rest.reverse} and {last}"

private def valueCount (count : Nat) : String :=
  if count == 1 then "1 value" else s!"{count} values"

/-- Where a checked edit is, as "on line L", or "on line L, column C" when
the text it replaces is found more than once there. -/
private def editPlace (line : Nat) : Option Nat → String
  | some column => s!"on line {line}, column {column}"
  | none => s!"on line {line}"

/-- What a checked edit leads to, as the sentence ending a hint: the word
then checks, or where its next error is. -/
private def editOutcome (word : String) (after : Option (Nat × Nat)) : String :=
  if word.isEmpty then "" else match after with
  | none => s!" With that edit `{word}` checks."
  | some (line, column) => s!" With that edit, the next error in `{word}` is at line {line}, column {column}."

/-- The message and hint for a refused `if` from the account of what each
branch does, value by value (`Account`). A branch that takes a value that is
not there is explained by the operation that takes it; branches that leave
different numbers of values, by what each leaves. `none` when the account
adds nothing, as when the branches differ only in types. -/
private def accountExplanation (word : String) (account : Firth.Elaborator.IfAccount)
    (cannotRun : Option (Bool × List String) := none) : Option (String × String) :=
  let inWord := if word.isEmpty then "" else s!" in `{word}`"
  let which := s!"the `if`{inWord} whose true branch is `{account.trueSource}`"
  let noEvening := "Adding a `drop` or pushing values to even out the branches would only move the mistake."
  let short (name : String) (branch : Firth.Elaborator.BranchAccount) :=
    (branch.reach.filter (·.missing > 0)).map (name, ·)
  let place (name : String) := if name == "true" then s!"In the true branch `{account.trueSource}` of the `if`{inWord}"
    else s!"In the false branch of {which}"
  -- A branch the checker says cannot run on the stack below the `if`, whose
  -- first operation that reaches below it finds every value it takes: the
  -- values are there but not the ones it takes, so say what it gets. Only
  -- when that operation declares the types it takes, and the ones it
  -- declares for the values from below are not what the stack below the
  -- `if` holds there. A `dup` or `swap` takes values of any type, and an
  -- operation whose types are met is not the one the branch fails on, so a
  -- later operation is to blame and the checker's own account is kept.
  -- (The checker's inferred input for the branch adds nothing here: every
  -- declared word and primitive type is monomorphic, so at those positions
  -- it is exactly the types the operation declares.)
  let wrongValues : Option (String × Firth.Elaborator.BranchReach) := cannotRun.bind fun (onTrueBranch, below) =>
    let name := if onTrueBranch then "true" else "false"
    let branch := if onTrueBranch then account.onTrue else account.onFalse
    let top (list : List String) (count : Nat) := list.drop (list.length - count)
    let blamed (reach : Firth.Elaborator.BranchReach) : Bool :=
      let count := reach.below.length
      reach.missing == 0 && reach.types.length == reach.count && count > 0 &&
        count ≤ below.length && reach.types.take count != top below count
    (branch.reach.filter blamed).map (name, ·)
  match wrongValues with
  | some (name, reach) =>
      let takes := if reach.inputs.isEmpty then s!"takes {valueCount reach.count}"
        else s!"takes {valueCount reach.count} ({", ".intercalate reach.inputs}, bottom to top)"
      let gets := (reach.below.map (s!"{·} from below the `if`")) ++ reach.own
      some (s!"{place name}, {reach.operation} {takes}. It gets, bottom to top, {listing gets}.",
        s!"Both branches start from the stack below the `if`, so a value {reach.operation} takes from there must be the one it expects at that position. Check that it gets the values it should, in its order, and push the ones it should use inside the branch, for example by writing the locals that hold them.")
  | none =>
  match short "true" account.onTrue <|> short "false" account.onFalse with
  | some (name, reach) =>
      let needs := if reach.inputs.isEmpty then s!"needs {valueCount reach.count}"
        else s!"needs {valueCount reach.count} ({", ".intercalate reach.inputs})"
      let own := if reach.own.isEmpty then "has pushed nothing before it"
        else s!"has pushed only {valueCount reach.own.length} before it ({listing reach.own})"
      let why := if reach.inLocals then "everything the word was given is bound to locals or already used"
        else "the word's inputs are used up, and what lies below them belongs to the caller"
      let notThere := if reach.missing == 1 then "is not there" else "are not there"
      -- Once a value is missing, nothing is left below the `if`, so every
      -- value the branch took from there was taken by this operation or an
      -- earlier one.
      let branch := if name == "true" then account.onTrue else account.onFalse
      let earlier := branch.took.take (branch.took.length - reach.below.length)
      let already := if earlier.isEmpty then ""
        else s!"Earlier in the branch, {listing earlier} {if earlier.length == 1 then "was" else "were"} already taken from below the `if`. "
      let below := if reach.below.isEmpty then
          s!"{already}The remaining {valueCount reach.missing} would come from below the `if`, where there {if reach.missing == 1 then "is none" else "are none"}: {why}."
        else
          s!"{already}It would take {listing reach.below} from below the `if`, and {valueCount reach.missing} more that {notThere}: {why}."
      let hint := if reach.inputs.isEmpty then
          s!"Check whether {reach.operation} belongs in this branch: the values it would work on are not there. Remove it, or push the values it should work on first. {noEvening}"
        else if reach.own.isEmpty then
          s!"Push every value {reach.operation} takes inside the branch, just before it and in this order: {", ".intercalate reach.inputs}, for example by writing the locals that hold them. If {reach.operation} should not be in this branch, remove it. {noEvening}"
        else
          -- The branch's own values are the top of what the operation
          -- takes, but which inputs the author left out is told by their
          -- types: `1` before `prim seq-int.push` stands for the last
          -- input, `xs 1` before a word taking `xs:Seq Int n:Int b:Bool` for
          -- the first two. The hint says where the missing inputs go only
          -- when the pushed values, in their order, fit the inputs in one
          -- way alone, and that way is the first or the last inputs;
          -- otherwise it does not choose.
          let pushed := reach.own.length
          let lacking := reach.count - pushed
          let one := pushed == 1
          -- The ways to fit `own` in order among `inputs`, counted up to 2.
          let rec fits : List (Option String) → List String → Nat
            | [], _ => 1
            | _ :: _, [] => 0
            | own@(value :: rest), input :: inputs =>
                let here := if value == some input then fits rest inputs else 0
                if here ≥ 2 then 2 else min 2 (here + fits own inputs)
          let unique := reach.types.length == reach.count && fits reach.ownTypes reach.types == 1
          let asLast := unique && reach.ownTypes == (reach.types.drop lacking).map some
          let asFirst := unique && reach.ownTypes == (reach.types.take pushed).map some
          let order := s!"Make the branch push, just before {reach.operation}, exactly the values it takes, in this order: {", ".intercalate reach.inputs}. The branch already pushes {listing reach.own}"
          let keep := s!"keep {if one then "it" else "each"} where it has that type and replace it where it does not"
          let them := if one then "it" else "them"
          -- Checked by the pipeline (`missingEdit`): the inputs lacking
          -- are named like locals in scope of their types.
          let named (first : Bool) := match account.edit with
            | some { fix := .missing names false, written, replacement, after, line, column, .. } =>
                let place := if first then asLast else asFirst
                if !place then none else
                some s!"by writing the {if names.length == 1 then "local" else "locals"} of {if names.length == 1 then "that name" else "those names"}, {listing (names.map (s!"`{·}`"))}: write `{replacement}` in place of `{written}` {editPlace line column}.{editOutcome word after}"
            | _ => none
          let locals := s!"for example by writing the locals that hold {if lacking == 1 then "it" else "them"}"
          let count (n : Nat) := if n == 1 then "one" else toString n
          let tail := s!"If {reach.operation} should not be in this branch, remove it. {noEvening}"
          match account.edit with
          | some { fix := .missing names true, written, replacement, after, line, column, .. } =>
              -- Checked by the pipeline (`missingEdit`): each value the
              -- branch pushed stands for a local named like an input.
              let described := (reach.own.zip reach.ownSources).map fun (label, source) =>
                match source with
                | some name => if label == s!"`{name}`" then label else s!"{label} (from `{name}`)"
                | none => label
              let lacks := if names.isEmpty then "" else
                s!", and write the {if names.length == 1 then "local" else "locals"} {listing (names.map (s!"`{·}`"))} for the {if names.length == 1 then "input" else "inputs"} it does not push"
              s!"Make the branch push, just before {reach.operation}, exactly the values it takes, in this order: {", ".intercalate reach.inputs}. The branch already pushes, bottom to top, {listing described}, which by their names are for inputs in another order. Push each in its input's place{lacks}: write `{replacement}` in place of `{written}` {editPlace line column}.{editOutcome word after} {tail}"
          | _ =>
          if asLast then
            match named true with
            | some named => s!"{order}, in the place of the last {count pushed} ({", ".intercalate (reach.inputs.drop lacking)}). Push the first {count lacking} ({", ".intercalate (reach.inputs.take lacking)}) before {them} {named} {tail}"
            | none => s!"{order}, in the place of the last {count pushed} ({", ".intercalate (reach.inputs.drop lacking)}): {keep}. Then push the first {count lacking} ({", ".intercalate (reach.inputs.take lacking)}) before {them}, {locals}. {tail}"
          else if asFirst then
            match named false with
            | some named => s!"{order}, in the place of the first {count pushed} ({", ".intercalate (reach.inputs.take pushed)}). Push the last {count lacking} ({", ".intercalate (reach.inputs.drop pushed)}) after {them} {named} {tail}"
            | none => s!"{order}, in the place of the first {count pushed} ({", ".intercalate (reach.inputs.take pushed)}): {keep}. Then push the last {count lacking} ({", ".intercalate (reach.inputs.drop pushed)}) after {them}, {locals}. {tail}"
          else
            s!"{order}: keep {if one then "it" else "each"} in its place where it is one of these and replace it where it is not, and push the other {count lacking} in {if lacking == 1 then "its place" else "their places"}, {locals}. {tail}"
      let inside := if reach.nested then " (inside a quotation in that branch)" else ""
      some (s!"{place name}, {reach.operation}{inside} {needs}, but the branch {own}. {below}", hint)
  | none =>
      let taken (branch : Firth.Elaborator.BranchAccount) := branch.took.length + branch.missing
      let net (branch : Firth.Elaborator.BranchAccount) : Int := (branch.leaves.length : Int) - (taken branch : Int)
      if net account.onTrue == net account.onFalse then none else
      let describe (branch : Firth.Elaborator.BranchAccount) :=
        let took := if branch.took.isEmpty then "" else s!"takes {listing branch.took} from below the `if` and "
        let leaves := if branch.leaves.isEmpty then "nothing"
          else if branch.leaves.length == 1 then listing branch.leaves
          else s!"{valueCount branch.leaves.length}, bottom to top: {listing branch.leaves}"
        s!"{took}leaves {leaves}"
      let (longer, shorter, branch) :=
        if net account.onTrue > net account.onFalse then ("true", "false", account.onTrue)
        else ("false", "true", account.onFalse)
      let extra := (net account.onTrue - net account.onFalse).natAbs
      let rule := "Both branches run on the same stack and must leave the same values."
      let (shorterBranch, longerBranch) := if longer == "true" then (account.onFalse, account.onTrue) else (account.onTrue, account.onFalse)
      -- The shorter branch may be shorter because it takes values from
      -- below the `if` that the longer branch leaves in place.
      -- A value the branch takes and puts back, as `swap` does, is not
      -- one it uses up.
      let usedUp (branch : Firth.Elaborator.BranchAccount) :=
        branch.leaves.foldl List.erase branch.took
      let kept := (usedUp shorterBranch).drop (usedUp longerBranch).length
      let hint :=
        match account.edit with
        | some { fix := .stale names values call, written, replacement, after, line, column, .. } =>
            -- Checked by the pipeline (`staleEdit`): each value left behind
            -- is a new value of a local the rest of the branch was handed
            -- again.
            let named := listing (names.map (s!"`{·}`"))
            let (isNew, itWas, newValues, them, theName) := if names.length == 1
              then ("is a new value of", "it was", "the new value is", "it", "the name")
              else ("are new values of", "they were", "the new values are", "them", "the names")
            s!"{(listing values).capitalize} {isNew} {named}, but {call} is then handed {named} as {itWas} before, so {newValues} left below. If {call} should get {if names.length == 1 then "the new value" else "the new values"}, bind {them} to {theName} {named} for the call: write `{replacement}` in place of `{written}` {editPlace line column}.{editOutcome word after} {rule}"
        | _ =>
        if kept.length ≥ extra && extra > 0 then
          let strays := kept.take extra
          let (it, is) := if extra == 1 then ("it", "is") else ("them", "are")
          s!"The {shorter} branch takes {listing strays} from below the `if`, and the {longer} branch leaves {it} in place, so after the {longer} branch {it} {is} still on the stack. If the {longer} branch should use {it} too, use {it} there, for example as an input of the operation that needs {it}, or drop {it}. If not, the {shorter} branch should not take {it}. {rule}"
        else if extra > branch.leaves.length then
          s!"The {longer} branch leaves {valueCount extra} more than the {shorter} branch. Make both branches take and leave the same values. {rule}"
        else
          let (strays, rest) := (branch.leaves.take extra, branch.leaves.drop extra)
          let (it, is) := if extra == 1 then ("it", "is") else ("them", "are")
          let place := if rest.isEmpty then s!"{listing strays} {is} left by the {longer} branch alone"
            else s!"{listing strays} {is} left below {listing rest}"
          s!"The {longer} branch leaves {valueCount extra} more than the {shorter} branch: {place}. If nothing is meant to use {it}, the mistake is where {if extra == 1 then "it is" else "they are"} pushed: pass {it} to the operation that should take {it}, or remove {it}. If the {shorter} branch should leave {it} too, change that branch instead. {rule}"
      some (s!"The two branches of {which} leave different numbers of values. The true branch {describe account.onTrue}; the false branch {describe account.onFalse}.", hint)

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
private def branchShapeExplanation (word : String) (onTrue onFalse : Nat × Nat)
    (locals : Firth.Elaborator.BranchLocals := {}) : String × String :=
  let inWord := if word.isEmpty then "" else s!" in `{word}`"
  let net (effect : Nat × Nat) : Int := (effect.2 : Int) - (effect.1 : Int)
  let values (count : Nat) := if count == 1 then "1 value" else s!"{count} values"
  let (longer, shorter, extra) :=
    if net onTrue > net onFalse then ("true", "false", (net onTrue - net onFalse).toNat)
    else ("false", "true", (net onFalse - net onTrue).toNat)
  let drops := " ".intercalate (List.replicate extra "drop")
  let reached := locals.reached.eraseDups
  let summary := s!"The two branches of `if`{inWord} leave different numbers of values: the true branch {depthChange onTrue}, and the false branch {depthChange onFalse}."
  -- A drop or a push would only move these mistakes, so neither is offered.
  let noEvening := "Adding a `drop` or pushing values to even out the branches would only move the mistake."
  if !reached.isEmpty then
    -- The `if` or a branch reaches for a local as if it were a value on the
    -- stack: the fix is to use the local by name and leave it in place.
    let quoted := reached.map (s!"`{·}`")
    let names := match quoted.reverse with
      | [] => ""
      | [one] => s!"the local {one}"
      | last :: rest => s!"the locals {", ".intercalate rest.reverse} and {last}"
    (s!"{summary} The condition and the values the branches take from below the `if` are looked for where {names} would be, but a local is not a value on the stack.",
      s!"Inside `locals`, a local is used by writing its name, which pushes a copy and leaves the local in place. Write the condition just before the two quotations (for example a local's name or a comparison), and in each branch use locals by name instead of taking them from the stack with `drop`, `swap` or an operator that is short of an operand. {noEvening}")
  else if locals.missing > 0 then
    -- The `if` or a branch takes values below everything this code pushed or
    -- was given: they belong to the caller.
    let count := locals.missing
    let taker := if onTrue.1 == onFalse.1 then "The `if`" else if onTrue.1 > onFalse.1 then "The true branch" else "The false branch"
    (s!"{summary} {taker} takes {values count} from below the `if` that this code does not have: everything it was given is bound to locals or already used, so {if count == 1 then "that value belongs" else "those values belong"} to the caller.",
      s!"Push what the branch needs inside the branch, by writing a local's name or computing the value there, or remove the operation that takes it if it should not be there. If the branch means to use a value computed before the `if`, keep a copy of it before the condition (for example with `dup`). {noEvening}")
  else
  (s!"The two branches of `if`{inWord} leave different numbers of values: the true branch {depthChange onTrue}, and the false branch {depthChange onFalse}. So the {longer} branch leaves {values extra} more than the {shorter} branch.",
    s!"If the values below those already agree, either add `{drops}` at the end of the {longer} branch, or make the {shorter} branch push {values extra} more, of the same {if extra == 1 then "type" else "types"} the {longer} branch leaves on top. If they do not, the branches also leave different types, and each must be changed until both leave the same values. Both branches run on the same stack and must leave the same number and types of values, so that the code after the `if` finds one stack.")

/-- The message and hint for `prim <=`, `prim >` or `prim >=` in `word`:
the primitives that compute it (`comparisonRewrite`) and why, and the edit
that writes every such comparison in the word with them, checked by the
pipeline (`withComparisonEdit`). `none` for any other primitive. -/
private def comparisonExplanation (word name : String) (edit : Option Firth.Elaborator.ComparisonEdit) :
    Option (String × String) := do
  let replacement ← Firth.Elaborator.comparisonRewrite name
  let meaning := match name with
    | "<=" => "`a b prim <=`, `a` at most `b`, is `a b swap prim < prim not`: `a` is at most `b` exactly when `b < a` is false."
    | ">" => "`a b prim >`, `a` greater than `b`, is `a b swap prim <`: `a` is greater than `b` exactly when `b < a`."
    | _ => "`a b prim >=`, `a` at least `b`, is `a b prim < prim not`: `a` is at least `b` exactly when `a < b` is false."
  let inWord := if word.isEmpty then "" else s!" in `{word}`"
  let message := s!"`prim {name}`{inWord} is not a primitive: numbers are compared with `prim <` and `prim =`."
  let hint := match edit with
    | none => s!"{meaning} Write `{replacement}` in place of `prim {name}`."
    | some edit =>
        let others := if edit.others.isEmpty then "" else
          let each := edit.others.map fun (written, line) =>
            let rewrite := (Firth.Elaborator.comparisonRewrite (written.drop 5).toString).getD ""
            s!"`{written}` on line {line} as `{rewrite}`"
          s!", and write the other {if edit.others.length == 1 then "comparison" else "comparisons"}{inWord} with those primitives too: {listing each}"
        let outcome := if word.isEmpty then "" else
          let those := if edit.others.isEmpty then "that edit" else "those edits"
          match edit.after with
          | none => s!" With {those} `{word}` checks."
          | some (line, column) => s!" With {those}, the next error in `{word}` is at line {line}, column {column}."
        s!"{meaning} Write `{replacement}` in place of `{edit.written}` {editPlace edit.line edit.column}{others}.{outcome}"
  pure (message, hint)

/-- What each input of a primitive is for, bottom to top, by its surface
name, for the primitives whose inputs repeat a type beside another type:
there the types alone cannot tell an author which value goes where, and a
primitive's inputs have no names. `xs i v seq-int.set` is `xs` with element
`i` replaced by `v`. Only for telling the author; it never decides the
order. The diagnostic tests check that every such primitive is listed. -/
def primitiveRoles : String → Option (List String)
  | "seq-int.set" | "seq-bool.set" => some ["the sequence", "the index", "the new value"]
  | "seq-int.at" | "seq-bool.at" => some ["the sequence", "the index"]
  | "seq-int.push" | "seq-bool.push" => some ["the sequence", "the value pushed"]
  | _ => none

/-- `primitiveRoles` for an operation as a report writes it, `` `prim seq-int.set` ``. -/
private def operationRoles (operation : String) : Option (List String) :=
  if operation.startsWith "`prim " && operation.endsWith "`" then
    primitiveRoles ((operation.drop 6).dropEnd 1).toString
  else none

/-- The message and hint for a word or primitive handed fewer values than it
takes, as the body is written (`CallAccount.missing`): what it takes, the
values it gets by source, and, when the pipeline found and checked one, the
edit that moves the values written just after it to before it. -/
private def shortExplanation (inWord : String) (word : Option String)
    (account : Firth.Elaborator.CallAccount) : String × String :=
  let count := account.present.length + account.missing
  let takes := match operationRoles account.operation with
    | some roles =>
        if roles.length == account.inputs.length then
          listing ((roles.zip account.inputs).map fun ((role, type) : String × String) => s!"{role} ({type})")
        else ", ".intercalate account.inputs
    | none => ", ".intercalate account.inputs
  let typed := (account.present.zip (account.types ++ List.replicate account.present.length none)).map
    fun ((label, type) : String × Option String) => match type.filter (fun type => !type.startsWith "?" && !type.startsWith "[") with
      | some type => s!"{label} ({type})"
      | none => label
  let gets := match account.present.length with
    | 0 => "but nothing is on the stack before it"
    | 1 => s!"but only 1 value is on the stack before it: {listing typed}"
    | n => s!"but only {n} values are on the stack before it, bottom to top: {listing typed}"
  let message := s!"{account.operation}{inWord} takes {valueCount count} ({takes}), bottom to top, {gets}."
  let them := if account.missing == 1 then "the missing value" else s!"the {account.missing} missing values"
  let hint := match account.edit with
    | some edit =>
        let outcome := match edit.after, word with
          | none, some word => s!" With that edit `{word}` checks."
          | some (line, column), some word => s!" With that edit, the next error in `{word}` is at line {line}, column {column}."
          | _, none => ""
        s!"The values {account.operation} takes are pushed before it, and {listing ((edit.written.splitOn " ").drop ((edit.written.splitOn " ").length - account.missing) |>.map (s!"`{·}`"))} {if account.missing == 1 then "is" else "are"} written after it. Write `{edit.replacement}` in place of `{edit.written}` {editPlace edit.line edit.column}.{outcome}"
    | none =>
        if account.locals.isEmpty then
          s!"Push {them} before {account.operation}, or take {if account.missing == 1 then "it" else "them"} as {if account.missing == 1 then "an input" else "inputs"} in the signature."
        else
          let names := account.locals.eraseDups
          let theLocals := if names.length == 1 then s!"The local here, `{names.headD ""}`, is not a value" else s!"The locals here, {listing (names.map (s!"`{·}`"))}, are not values"
          s!"Push {them} before {account.operation}. {theLocals} on the stack: writing a local's name pushes its value."
  (message, hint)

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
  | .unresolvedEffect name span edit =>
      let params := match comparisonExplanation word name edit with
        | some (message, hint) => (namedParams name).mergeObj
            (.mkObj ((if word.isEmpty then [] else [("word", .str word)]) ++
              [("message", .str message), ("hint", .str hint)]))
        | none => namedParams name
      { code := "firth.name.unresolved-effect", cause := "name-resolution", params, span }
  | .effectUnderflow name span account =>
      let params := match account.filter (·.missing > 0) with
        | some account =>
            let (message, hint) := shortExplanation (if word.isEmpty then "" else s!" in `{word}`")
              (if word.isEmpty then none else some word) account
            (namedParams name).mergeObj (.mkObj ((if word.isEmpty then [] else [("word", .str word)]) ++
              [("message", .str message), ("hint", .str hint)]))
        | none => namedParams name
      { code := "firth.type.stack-underflow", cause := "type-checking", params, span }
  | .usageMismatch name span =>
      { code := "firth.linearity.usage-mismatch", cause := "linearity", params := namedParams name, span }
  | .unsupportedLiteral span =>
      { code := "firth.elaboration.unsupported-literal", cause := "elaboration", params := .mkObj [], span }
  | .unsupportedAtom name span =>
      { code := "firth.elaboration.unsupported-atom", cause := "elaboration", params := namedParams name, span }
  | .branchShape span onTrue onFalse locals account =>
      let (message, hint) := (account.bind (accountExplanation word)).getD
        (branchShapeExplanation word onTrue onFalse locals)
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
      -- An operation handed fewer values than it takes, with the values it
      -- gets, has its own explanation already.
      if (params.getObjValAs? String "hint").isOk then ("", "") else
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
      -- A comparison with no primitive has its own explanation already.
      if (params.getObjValAs? String "hint").isOk then ("", "")
      else (s!"`prim {name}` is not a primitive.", availablePrimitives)
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
  -- The values both branches leave, from the bottom: a drop or a push fixes
  -- the count only when these agree.
  let sharedDifference (longerValues shorterValues : List AType) :=
    firstDifference (longerValues.take shorterValues.length) shorterValues
  let alsoDiffers (name other : String) (extra : List AType) (depth : Nat) (onName onOther : AType) :=
    s!"The {name} branch leaves {plural extra.length "more value"} than the {other} branch ({renderValues extra} on top), and below those the two differ too: {ordinalFromTop depth} of the values both leave is {renderType onName} after the {name} branch and {renderType onOther} after the {other} branch. Change the branches until both leave the same values. {rule}"
  if trueRow != falseRow then
    (base, s!"The two branches leave different parts of the caller's stack (ρ): one of them consumes values it should keep, or keeps values it should consume. {rule}")
  else if trueValues.length > falseValues.length then
    let extra := trueValues.drop falseValues.length
    match sharedDifference trueValues falseValues with
    | some (depth, onTrueType, onFalseType) => (base, alsoDiffers "true" "false" extra depth onTrueType onFalseType)
    | none => (base, longer "true" "false" extra)
  else if falseValues.length > trueValues.length then
    let extra := falseValues.drop trueValues.length
    match sharedDifference falseValues trueValues with
    | some (depth, onFalseType, onTrueType) => (base, alsoDiffers "false" "true" extra depth onFalseType onTrueType)
    | none => (base, longer "false" "true" extra)
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
/-- The message and hint for a word or primitive handed values it does not
take, from the account of where each value came from (`Account.ofCall`):
what it takes, what it gets by source, and, when the pipeline found and
checked one, the edit that pushes them in its order. `none` when there is no
account, or its types disagree with the checker's. -/
private def callExplanation (inWord : String) (word : Option String) (wanted present : List AType)
    (account : Option Firth.Elaborator.CallAccount) : Option (String × String) := do
  let account ← account
  let count := wanted.length
  if account.values.length != count || present.length < count then none else
  let got := (present.drop (present.length - count)).map renderType
  let plain (type : String) := !type.startsWith "?" && !type.startsWith "["
  -- The walk and the checker must agree on every type both know.
  if (got.zip account.types).any (fun (checked, walked) =>
      walked.any fun walked => plain checked && plain walked && checked != walked) then none else
  let typed := (account.values.zip (got.zip account.types)).map fun (label, checked, walked) =>
    match (if plain checked then some checked else walked.filter plain) with
    | some type => s!"{label} ({type})"
    | none => label
  -- A word the environment defines outside the file has no names for its
  -- inputs in the account; its types are the checker's.
  let takes ← if !account.inputs.isEmpty then
      match operationRoles account.operation with
      | some roles =>
          if roles.length == account.inputs.length then
            some s!"takes {listing ((roles.zip account.inputs).map fun (role, type) => s!"{role} ({type})")}"
          else some s!"takes {", ".intercalate account.inputs}"
      | none => some s!"takes {", ".intercalate account.inputs}"
    else if (wanted.map renderType).all plain then some s!"takes {", ".intercalate (wanted.map renderType)}"
    else none
  let message := s!"{account.operation}{inWord} {takes}, bottom to top, but here it gets, bottom to top, {listing typed}."
  match account.edit with
  | some edit =>
      let outcome := match edit.after, word with
        | none, some word => s!" With that edit `{word}` checks."
        | some (line, column), some word => s!" With that edit, the next error in `{word}` is at line {line}, column {column}."
        | _, none => ""
      pure (message, s!"These are the values {account.operation} takes, in another order. To push them in its order, write `{edit.replacement}` in place of `{edit.written}` {editPlace edit.line edit.column}.{outcome}")
  | none =>
      if !account.assignment.isEmpty then
        let name (input : String) := ((input.splitOn ":").head?).getD input
        -- A primitive's inputs are told by what they are for, where the
        -- types alone repeat.
        let roles := operationRoles account.operation
        let roleOf (i : Nat) (input : String) : String :=
          match roles.bind (·[i]?) with
          | some role => role
          | none => s!"`{name input}`"
        let quoted (texts : List String) := listing (texts.map (s!"`{·}`"))
        -- Inputs that could take the same values are one group, told where
        -- the first of them is.
        let parts := account.assignment.foldl (init := (([], []) : List String × List (List String)))
          fun (parts, seen) ((_, choices) : String × List String) =>
            if choices.length ≤ 1 then
              (parts, seen)
            else if seen.contains choices then (parts, seen)
            else
              let inputs := ((account.assignment.zipIdx.filter fun ((_, other), _) => other == choices)).map fun ((input, _), i) => roleOf i input
              (parts ++ [s!"{quoted choices} are for {listing inputs}, in the order you mean"], seen ++ [choices])
        let certain := account.assignment.zipIdx.filterMap fun ((input, choices), i) =>
          match choices with
          | [text] => some s!"`{text}` is for {roleOf i input}"
          | _ => none
        let certainText := if certain.isEmpty then "" else s!"By their names and types, {listing certain}. "
        pure (message, s!"These are the values {account.operation} takes, in another order. {certainText}Of the values of one type, {"; ".intercalate parts.1}: only you can tell which is which. Push them in the order of its inputs.")
      else
      match firstDifference wanted (present.drop (present.length - count)) with
      | some (depth, want, _) =>
          let index := count - 1 - depth
          let value := (typed[index]?).getD "the value there"
          pure (message, s!"{capitalize (ordinalFromTop depth)}, {value}, is not what {account.operation} takes there ({renderType want}). Check that it gets the values it should, in its order (`swap` exchanges the top two values), or the operation.")
      | none => none

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
      match callExplanation inWord diagnostic.word wanted present diagnostic.callAccount with
      | some explanation => explanation
      | none =>
      if present.length < wanted.length && row.isSome then
        (base, s!"`{at_}` takes {plural wanted.length "value"} but only {plural present.length "value"} {if present.length == 1 then "is" else "are"} available. Push or keep the missing input before it (for example `dup` to copy, or `over` if defined), or take it as a parameter in the signature." ++ rowNote)
      else match firstDifference wanted present with
        | some (depth, want, got) =>
            (base, s!"{capitalize (ordinalFromTop depth)} is {renderType got} but `{at_}` expects {renderType want}. Check the argument order (`swap` exchanges the top two values) or the operation.")
        | none => (base, s!"The inputs to `{at_}` do not match its signature {renderValues wanted}.")
  | "firth.type.stack-underflow", _, _ =>
      match diagnostic.callAccount.filter (·.missing > 0) with
      | some account => shortExplanation inWord diagnostic.word account
      | none =>
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
      match diagnostic.ifAccount.bind fun account =>
          accountExplanation (diagnostic.word.getD "") account
            (diagnostic.branchInput.map fun (onTrueBranch, _) =>
              (onTrueBranch, (stackValues diagnostic.state).1.map renderType)) with
      | some explanation => explanation
      | none =>
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
  -- Checked by the pipeline (`conditionEdit`): the error is in the
  -- condition of an `if` written after its quotations, or at that `if`.
  let hint := match diagnostic.conditionEdit with
    | some edit =>
        let atIf := if diagnostic.code == "firth.type.expected-bool" then
            "`if` finds the condition on top of its two quotations, not under them"
          else "this is in the condition of an `if`, written after its two quotations, so they are on the stack under it"
        s!"{capitalize atIf}. `if` takes the condition first, then the two quotations, and runs the first quotation when the condition is true. Write the condition before the first `[`: write `{edit.replacement}` in place of `{edit.written}` {editPlace edit.line edit.column}.{editOutcome (diagnostic.word.getD "") edit.after}"
    | none => hint
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

/-- A word not type-checked because a word it calls has no valid signature:
said as an error, so that its silence is never read as a pass. -/
private def uncheckedEnvelope (context : EmissionContext) (word callee : String)
    (span : Firth.Elaborator.Span) : Envelope :=
  envelope context {
    code := "firth.type.unchecked-word"
    severity := "error"
    messageKey := messageKey "firth.type.unchecked-word"
    messageParams := .mkObj [
      ("message", .str s!"`{word}` was not checked, because it calls `{callee}`, whose stack effect is not a valid signature."),
      ("hint", .str s!"Fix the stack effect of `{callee}` first; `{word}` is then checked against it, and may have errors of its own."),
      ("word", .str word)]
    location := locationFromSpan context.source span
    cause := { kind := "type-checking" }
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

/-- `callees` as prose: "`f`", "`f` and `g`", "`f`, `g` and `h`". -/
private def wordList (callees : List String) : String :=
  match callees.map (s!"`{·}`") |>.reverse with
  | [] => ""
  | [one] => one
  | last :: rest => s!"{", ".intercalate rest.reverse} and {last}"

/-- The sentence saying that `word`'s error was found against the declared
effects of `callees`, which have errors of their own: fixing one of their
effects rather than its body can change this report, or remove it. -/
def assumesClause (word : String) (callees : List String) : String :=
  match callees with
  | [callee] =>
      s!"`{word}` calls `{callee}`, which has an error of its own; this report assumes `{callee}` keeps its stack effect."
  | _ =>
      s!"`{word}` calls {wordList callees}, which have errors of their own; this report assumes they keep their stack effects."

/-- The sentence saying that the edit a hint offers was checked against the
declared effects of `callees`, which have errors of their own, though the
report itself does not depend on them. -/
def editAssumesClause (callees : List String) : String :=
  match callees with
  | [callee] => s!"That edit was checked assuming `{callee}`, which has an error of its own, keeps its stack effect."
  | _ => s!"That edit was checked assuming {wordList callees}, which have errors of their own, keep their stack effects."

/-- The clause joins the message, where a reader of the report sees it, and
the callees are also given as `message_params.assumes`. Callees only the
hint's checked edit depends on join the hint instead, as
`message_params.edit_assumes`. -/
private def withAssumes (word : String) (callees edits : List String) (envelope : Envelope) :
    Envelope :=
  match envelope.body with
  | .diagnostic diagnostic =>
      match diagnostic.messageParams with
      | .obj fields =>
          let append (fields : Std.TreeMap.Raw String Lean.Json compare) (key clause : String) :=
            match fields.get? key with
            | some (.str text) => fields.insert key (.str s!"{text} {clause}")
            | _ => fields.insert key (.str clause)
          let names (list : List String) : Lean.Json := .arr (list.map Lean.Json.str).toArray
          let fields := if callees.isEmpty then fields else
            (append fields "message" (assumesClause word callees)).insert "assumes" (names callees)
          let fields := if edits.isEmpty then fields else
            (append fields "hint" (editAssumesClause edits)).insert "edit_assumes" (names edits)
          { envelope with body := .diagnostic { diagnostic with messageParams := .obj fields } }
      | _ => envelope
  | _ => envelope

private def pipelineDiagnosticEnvelope (context : EmissionContext) :
    Firth.Elaborator.PipelineDiagnostic → Envelope
  | .parse error => parserEnvelope context error
  | .erasure word error => erasureEnvelope context error word
  | .stackEffect diagnostic => stackEffectEnvelope context diagnostic
  | .refinement _ diagnostic => withContextSource context (refinementEnvelope diagnostic)
  | .unchecked word callee span => uncheckedEnvelope context word callee span
  | .internal span => internalEnvelope context span
  | .assumes word callees edits inner => withAssumes word callees edits (pipelineDiagnosticEnvelope context inner)

private def positionWithin (span : Firth.Elaborator.Span) (position : Position) : Bool :=
  let start : Position := { line := span.start.line, column := span.start.column }
  let stop : Position := { line := span.stop.line, column := span.stop.column }
  !positionBefore position start && !positionBefore stop position

/-- The word a diagnostic is in, as `message_params.word`, unless it names one
already: with an error reported for each word, a reader needs to know which
word each is in. -/
private def withWord (words : List (String × Firth.Elaborator.Span)) (envelope : Envelope) :
    Envelope :=
  match envelope.body with
  | .diagnostic diagnostic =>
      match diagnostic.messageParams, words.find? (positionWithin ·.2 diagnostic.location.range.start) with
      | .obj fields, some (word, _) =>
          if fields.contains "word" then envelope else
          { envelope with body := .diagnostic { diagnostic with
              messageParams := .obj (fields.insert "word" (.str word)) } }
      | _, _ => envelope
  | _ => envelope

/-- Payload ids made unique within one response, which the protocol requires
(`validateBatch`): the first keeps its id, a later one with the same id gets
`.2`, `.3`, ... by its place in the list. -/
private def uniquePayloadIds (envelopes : List Envelope) : List Envelope :=
  let (_, out) := envelopes.foldl (init := (([] : List String), ([] : List Envelope)))
    fun (seen, out) envelope =>
      let id := if seen.contains envelope.payloadId
        then s!"{envelope.payloadId}.{out.length + 1}" else envelope.payloadId
      (id :: envelope.payloadId :: seen, out ++ [{ envelope with payloadId := id }])
  out

/-- `text` with the checker's inferred variables numbered in the order they
first appear, one numbering for each kind: rows, types (in the source
notation too, as `?t`) and usages. Two reports that differ only in how many
variables the checker made before them then read the same. -/
private def renumberVariables (text : String) : String :=
  let kinds := [["Row.mvar "], ["AType.mvar ", "?t"], ["AUsage.mvar "]]
  kinds.foldl (init := text) fun text prefixes =>
    (prefixes.foldl (init := (text, ([] : List String))) fun (text, seen) pre =>
      match text.splitOn pre with
      | [] => (text, seen)
      | first :: parts =>
          let (pieces, seen) := parts.foldl (init := ([first], seen)) fun (pieces, seen) part =>
            let digits := String.ofList (part.toList.takeWhile Char.isDigit)
            if digits.isEmpty then (pieces ++ [part], seen) else
            let seen := if seen.contains digits then seen else seen ++ [digits]
            (pieces ++ [s!"{seen.idxOf digits}" ++ String.ofList (part.toList.drop digits.length)], seen)
          (pre.intercalate pieces, seen)).1

def elaboratePipeline (context : EmissionContext) (source : String)
    (config : Firth.Elaborator.PipelineConfig := {}) : StructuredElaborationResult :=
  let config := { config with
    requestId := context.requestId
    sourcePath := sourcePath context.source
    sameReport := fun one other =>
      renumberVariables (encode (pipelineDiagnosticEnvelope context one)) ==
        renumberVariables (encode (pipelineDiagnosticEnvelope context other)) }
  match Firth.Elaborator.elaborateWith config source with
  | .success program => .success program
  | .failure diagnostics =>
      let words := match Firth.Elaborator.parse source with
        | .success file => (Firth.Elaborator.collectWords file.declarations).map fun word => (word.name, word.span)
        | .failure _ => []
      .failure (uniquePayloadIds (sortDiagnosticEnvelopes
        (diagnostics.map (withWord words ∘ pipelineDiagnosticEnvelope context))))

end Firth.Agent
