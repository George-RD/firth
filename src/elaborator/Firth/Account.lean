import elaborator.Firth.StackEffect

/-!
# What each branch of an `if` does, value by value

A diagnostic aid, not part of checking. When the checker refuses an `if`
whose branches disagree, it knows how many values each branch takes and
leaves, and sometimes their types, but not which operation in the source is
responsible. This module walks a word's body as written and names every value
on the stack by the source that pushed it: a local's name, a literal, one of
the word's inputs, or "the result of" a word or primitive. At the `if` the
checker refused, it records the first operation in each branch that takes a
value the branch did not push, and the values each branch leaves.

The walk only follows what it can count exactly: literal quotations run by
`call`, `dip` and `if`, and words and primitives with known effects. Anything
else ends it, and the message falls back to the checker's own account. It
never changes whether a program is accepted.
-/

namespace Firth.Elaborator.Account

open Firth.Elaborator
open Firth.Elaborator.StackEffect

/-- What the walk needs to know besides the body: the words of the file, a
primitive's input types and output count, the source text, and the `if` the
checker refused, by the byte offset where it starts. -/
structure Context where
  words : List WordDefinition
  primitive : String → Option (List String × Nat)
  external : String → Option (Nat × Nat) := fun _ => none
  source : String
  target : Nat

/-- One value on the stack, named by the source that pushed it. `own` marks
the values a branch pushed itself; `quotation` keeps a literal quotation's
body so that `call`, `dip` and `if` can run it. -/
structure Entry where
  label : String
  own : Bool := true
  quotation : Option (List Item × Span) := none

/-- The stack (top first), the locals in scope, whether the word's inputs
were bound by `locals`, and the first operation that took a value its branch
did not push. -/
structure Walk where
  stack : List Entry
  locals : List String := []
  inLocals : Bool := false
  reach : Option BranchReach := none
  /-- The values not pushed by the branch that it took, and how many more it
  took that were not there. -/
  took : List String := []
  missing : Nat := 0
  /-- How many quotations deep the walk is inside the branch it accounts for. -/
  nesting : Nat := 0

inductive Outcome where
  | lost
  | next (walk : Walk)
  | found (account : IfAccount)
deriving Inhabited

private def sourceText (source : String) (span : Span) : String :=
  (String.fromUTF8? (source.toUTF8.extract span.start.offset span.stop.offset)).getD ""

/-- The start of a quotation as written, with its whitespace collapsed: all
of it when short, else its first eight tokens and `...`. -/
def quotationStart (source : String) (span : Span) : String :=
  let spaced := (sourceText source span).map fun c => if c.isWhitespace then ' ' else c
  let tokens := (spaced.splitOn " ").filter (!·.isEmpty)
  if tokens.length ≤ 10 then " ".intercalate tokens
  else " ".intercalate (tokens.take 8) ++ " ..."

private def literalText : Firth.Elaborator.Literal → String
  | .integer value => toString value
  | .boolean value => if value then "true" else "false"
  | _ => "a literal"

/-- Whether a stack effect keeps the stack below its inputs as it is: both
sides start with the same row variable. A closed effect, or one whose output
row differs, constrains the whole stack, which the walk does not model. -/
private def keepsRow (effect : StackEffect) : Bool :=
  match effect.input, effect.output with
  | .row input _ :: _, .row output _ :: _ => input == output
  | _, _ => false

private def valueItems (items : List StackItem) : List (String × String) :=
  items.filterMap fun
    | .value name type _ => some (name, type.name)
    | .row _ _ => none

/-- Takes `count` values for `operation`, recording it as the branch's first
reach below its own values when it takes one it did not push, or as its
first reach past the bottom when it takes a value that is not there. Returns
the values taken, top first. -/
private def take (walk : Walk) (operation : String) (inputs : List String) (count : Nat)
    (types : List String := []) : List Entry × Walk :=
  let taken := walk.stack.take count
  let ownTop := (walk.stack.takeWhile (·.own)).length
  let this : BranchReach :=
    { operation, inputs, count, types
      own := (taken.takeWhile (·.own)).reverse.map (·.label)
      below := (taken.dropWhile (·.own)).reverse.map (·.label)
      missing := count - taken.length
      inLocals := walk.inLocals
      nested := walk.nesting > 0 }
  -- The first operation that takes a value that is not there is the
  -- mistake to report, even when an earlier one took a value from below
  -- that was there.
  let reach := match walk.reach with
    | some earlier => if this.missing > 0 && earlier.missing == 0 then some this else some earlier
    | none => if count ≤ ownTop then none else some this
  let took := walk.took ++ (taken.filter (!·.own)).map (·.label)
  -- A value that is not there is still taken, so the walk can go on and
  -- report what the branch leaves.
  let absent := List.replicate (count - taken.length) { label := "a value that is not there" }
  (taken ++ absent, { walk with stack := walk.stack.drop count, reach, took,
                                missing := walk.missing + (count - taken.length) })

/-- Pushes values named `labels`, bottom to top. -/
private def push (walk : Walk) (labels : List String) : Walk :=
  { walk with stack := labels.reverse.map ({ label := · }) ++ walk.stack }

private def resultLabels (operation : String) (names : List String) : List String :=
  match names with
  | [_] => [s!"the result of {operation}"]
  | _ => names.map (s!"the output `{·}` of {operation}")

private def ownValues (walk : Walk) : List String :=
  (walk.stack.takeWhile (·.own)).reverse.map (·.label)

mutual
  /-- Runs `items` from `walk`, stopping at the `if` the context names. -/
  partial def walkItems (context : Context) (walk : Walk) : List Item → Outcome
    | [] => .next walk
    | item :: rest =>
        match step context walk item with
        | .next walk => walkItems context walk rest
        | other => other

  /-- Runs a quotation body on `walk`, keeping the locals of the caller: a
  quotation sees the locals of the block it is written in. -/
  partial def runQuotation (context : Context) (walk : Walk) (body : List Item) : Outcome :=
    match walkItems context { walk with nesting := walk.nesting + 1 } body with
    | .next after => .next { after with nesting := walk.nesting }
    | other => other

  partial def step (context : Context) (walk : Walk) : Item → Outcome
    | .literal literal _ => .next (push walk [s!"`{literalText literal.value}`"])
    | .quotation items span =>
        .next { walk with stack := { label := s!"the quotation `{quotationStart context.source span}`", quotation := some (items, span) } :: walk.stack }
    | .word name _ =>
        if walk.locals.contains name then .next (push walk [s!"`{name}`"]) else
        match context.words.find? (·.name == name) with
        | some word =>
            if !keepsRow word.effect then .lost else
            let inputs := valueItems word.effect.input
            let outputs := valueItems word.effect.output
            let (_, walk) := take walk s!"`{name}`" (inputs.map fun (n, t) => s!"{n}:{t}") inputs.length (inputs.map (·.2))
            .next (push walk (resultLabels s!"`{name}`" (outputs.map (·.1))))
        | none => match context.external name with
          | some (inputs, outputs) =>
              let (_, walk) := take walk s!"`{name}`" [] inputs
              .next (push walk (resultLabels s!"`{name}`" (List.replicate outputs "")))
          | none => .lost
    | .primitive name _ => match context.primitive name with
        | some (inputs, outputs) =>
            let operation := s!"`prim {name}`"
            let (_, walk) := take walk operation inputs inputs.length inputs
            .next (push walk (resultLabels operation (List.replicate outputs "")))
        | none => .lost
    | .locals names body _ =>
        let (_, inner) := take walk "`locals`" [] names.length
        match walkItems context { inner with locals := names.map (·.name) ++ walk.locals, inLocals := true } body with
        | .next after => .next { after with locals := walk.locals, inLocals := walk.inLocals }
        | other => other
    | .atom "dup" _ =>
        let (taken, walk) := take walk "`dup`" [] 1
        match taken with
        | [value] => .next { walk with stack := { value with own := true } :: { value with own := true } :: walk.stack }
        | _ => .lost
    | .atom "drop" _ => .next (take walk "`drop`" [] 1).2
    | .atom "swap" _ =>
        let (taken, walk) := take walk "`swap`" [] 2
        match taken with
        | [top, second] => .next { walk with stack := { second with own := true } :: { top with own := true } :: walk.stack }
        | _ => .lost
    | .atom "call" _ =>
        let (taken, walk) := take walk "`call`" [] 1
        match taken with
        | [{ quotation := some (body, _), .. }] => runQuotation context walk body
        | _ => .lost
    | .atom "dip" _ =>
        let (taken, walk) := take walk "`dip`" [] 2
        match taken with
        | [{ quotation := some (body, _), .. }, kept] =>
            match runQuotation context walk body with
            | .next after => .next { after with stack := { kept with own := true } :: after.stack }
            | other => other
        | _ => .lost
    | .atom "if" span =>
        let (taken, below) := take walk "`if`" [] 3
        match taken with
        | [{ quotation := some (onFalse, _), .. }, { quotation := some (onTrue, trueSpan), .. }, _] =>
            if span.start.offset == context.target then
              -- An `if` that takes its own condition or quotations from where
              -- there are none is its own mistake, not its branches'; the
              -- checker's account of what it reaches for says more.
              if below.missing > walk.missing then .lost else
              -- The refused `if`: each branch starts from the stack below
              -- the condition, none of it its own.
              let base := { below with stack := below.stack.map ({ · with own := false }),
                                       reach := none, took := [], missing := 0, nesting := 0 }
              let branch (body : List Item) : Option BranchAccount :=
                match walkItems context base body with
                | .next after => some { reach := after.reach, took := after.took,
                                        missing := after.missing, leaves := ownValues after }
                | _ => none
              match branch onTrue, branch onFalse with
              | some onTrueAccount, some onFalseAccount =>
                  .found { trueSource := quotationStart context.source trueSpan,
                           onTrue := onTrueAccount, onFalse := onFalseAccount }
              | _, _ => .lost
            else
              match runQuotation context below onTrue, runQuotation context below onFalse with
              | .found account, _ | _, .found account => .found account
              | .next afterTrue, .next afterFalse =>
                  -- Either path may run, so the walk goes on only where
                  -- both first reached below the refused `if` the same way
                  -- and leave the same number of values, each pushed by the
                  -- refused `if`'s branch on both paths or on neither.
                  -- Otherwise what comes after depends on which ran. The
                  -- checker accepted this `if`, so both paths leave the same
                  -- depth: with the same number of values they missed the
                  -- same number. With the same values left in place below,
                  -- they took the same ones, since values below are taken
                  -- from the top down; only the order they were taken in
                  -- may differ, and the true path's is kept.
                  -- The same operation reaching below with as many of the
                  -- branch's own values is one account, whichever path
                  -- pushed them; a value the paths push differently is
                  -- named by both.
                  let reach : Option (Option BranchReach) := match afterTrue.reach, afterFalse.reach with
                    | none, none => some none
                    | some onTrue, some onFalse =>
                        if onTrue.operation == onFalse.operation && onTrue.own.length == onFalse.own.length then
                          some (some { onTrue with own := (onTrue.own.zip onFalse.own).map fun (a, b) =>
                            if a == b then a else s!"{a} or {b}" })
                        else none
                    -- A path that reaches below and one that does not also
                    -- leave different values in place or a different number,
                    -- so this case is caught below as well.
                    | _, _ => none
                  match reach with
                  | none => .lost
                  | some reach =>
                  if afterTrue.stack.length != afterFalse.stack.length ||
                      (afterTrue.stack.zip afterFalse.stack).any (fun (a, b) => a.own != b.own) then
                    .lost
                  else
                  -- Where the branches leave different values, the value is
                  -- whichever branch ran.
                  let merged := (afterTrue.stack.zip afterFalse.stack).map fun (onTrue, onFalse) =>
                    if onTrue.label == onFalse.label then onTrue
                    else { label := "the result of an `if`", own := onTrue.own }
                  .next { afterTrue with stack := merged, reach }
              | _, _ => .lost
        | _ => .lost
    | .atom _ _ => .lost
end

/-- The account of the `if` starting at `context.target` in `word`, if the
walk can follow the body that far. The word's inputs are named as such. -/
def ofWord (context : Context) (word : WordDefinition) : Option IfAccount :=
  let inputs := (valueItems word.effect.input).map fun (name, _) => s!"the input `{name}`"
  match walkItems context (push { stack := [] } inputs) word.body with
  | .found account => some account
  | _ => none

/-- The account of the refused `if` at `span`, searching every word, since
the checker's report names the word but the span is what identifies the `if`. -/
def ofIf (context : Context) (span : Span) : Option IfAccount :=
  let context := { context with target := span.start.offset }
  context.words.findSome? fun word =>
    if word.span.start.offset ≤ span.start.offset && span.start.offset < word.span.stop.offset
    then ofWord context word else none

/-- A primitive's input types, bottom to top, and output count, from its
scheme, when the scheme keeps the stack below its inputs as it is. -/
def primitiveShape (scheme : Scheme) : Option (List String × Nat) :=
  let (inputs, below) := stackValues scheme.input
  let (outputs, after) := stackValues scheme.output
  if below.isSome && below == after then some (inputs.map renderType, outputs.length) else none

end Firth.Elaborator.Account
