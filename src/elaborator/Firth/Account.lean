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
primitive's input and output types, the source text, and the `if` the
checker refused, by the byte offset where it starts. -/
structure Context where
  words : List WordDefinition
  primitive : String → Option (List String × List String)
  external : String → Option (Nat × Nat) := fun _ => none
  source : String
  target : Nat

/-- One value on the stack, named by the source that pushed it. `own` marks
the values a branch pushed itself; `quotation` keeps a literal quotation's
body so that `call`, `dip` and `if` can run it. -/
structure Entry where
  label : String
  /-- The value's type, where the walk knows it. -/
  type : Option String := none
  own : Bool := true
  quotation : Option (List Item × Span) := none
  /-- For a quotation, the types of the locals where it was written: a
  local it names is that one, whatever the locals where it runs. -/
  scope : List (String × String) := []

/-- The stack (top first), the locals in scope, whether the word's inputs
were bound by `locals`, and the first operation that took a value its branch
did not push. -/
structure Walk where
  stack : List Entry
  locals : List String := []
  /-- The types of the locals in scope, where known. -/
  localTypes : List (String × String) := []
  inLocals : Bool := false
  reach : Option BranchReach := none
  /-- The values not pushed by the branch that it took, and how many more it
  took that were not there. -/
  took : List String := []
  missing : Nat := 0
  /-- How many quotations deep the walk is inside the branch it accounts for. -/
  nesting : Nat := 0
  /-- After an operation was handed values of the wrong known type (see
  `misreads`), the reach the walk had then, that operation's own if it
  became the reach. The counts still follow the program, but which value
  an operation takes may not, so a reach recorded after it, replacing this
  one, is not reported. -/
  trusted : Option (Option BranchReach) := none
  /-- Whether the walk is inside a branch of the refused `if`, where it
  records reaches. Before it, reaches are discarded when the branches start. -/
  inBranch : Bool := false

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

/-- A stack effect's values with their types, written with their usage as
the checker renders them (`World^linear`), so that they compare with a
primitive's types and with the checker's stack. -/
private def valueItems (items : List StackItem) : List (String × String) :=
  items.filterMap fun
    | .value name type _ => some (name, type.name ++ if type.usage == .linear then "^linear" else "")
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
      ownTypes := (taken.takeWhile (·.own)).reverse.map (·.type)
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

/-- Whether an operation declaring input `types` (bottom to top) was handed
values, `taken` (top first), whose known types no order of its inputs fits:
more values of some type than it takes. Values in the wrong order
(`idx xs prim seq-int.at`) are a mistake the report can still count past,
but values of the wrong kind mean the walk, which hands values out by
count, may have given this operation values meant for another, as when an
argument is missing before it. Only concrete types are compared. -/
private def misreads (taken : List Entry) (types : List String) : Bool :=
  let concrete (type : String) := type.front.isUpper
  let known := taken.filterMap fun entry => entry.type.filter concrete
  types.all concrete && known.any fun type => known.count type > types.count type

/-- Marks the first operation handed values of the wrong kind: the reach the
walk has after it can still be reported (it was recorded before, or it is
that operation, which is then reported with the values it gets, as
`true prim +` is), but a later one replacing it cannot. -/
private def noteMisread (after : Walk) (taken : List Entry) (types : List String) : Walk :=
  if after.trusted.isNone && misreads taken types then
    { after with trusted := some after.reach }
  else after

/-- Pushes values with their labels and types, bottom to top. -/
private def pushTyped (walk : Walk) (values : List (String × Option String)) : Walk :=
  { walk with stack := values.reverse.map (fun (label, type) => { label, type }) ++ walk.stack }

private def literalType : Firth.Elaborator.Literal → Option String
  | .integer _ => some "Int"
  | .boolean _ => some "Bool"
  | _ => none

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
  quotation sees the locals of the block it is written in. The types of
  those locals are the ones in `scope`, recorded where it was written. -/
  partial def runQuotation (context : Context) (walk : Walk) (body : List Item)
      (scope : List (String × String)) : Outcome :=
    match walkItems context { walk with nesting := walk.nesting + 1, localTypes := scope } body with
    | .next after => .next { after with nesting := walk.nesting, localTypes := walk.localTypes }
    | other => other

  partial def step (context : Context) (walk : Walk) : Item → Outcome
    | .literal literal _ => .next (pushTyped walk [(s!"`{literalText literal.value}`", literalType literal.value)])
    | .quotation items span =>
        .next { walk with stack := { label := s!"the quotation `{quotationStart context.source span}`", quotation := some (items, span), scope := walk.localTypes } :: walk.stack }
    | .word name _ =>
        if walk.locals.contains name then
          .next (pushTyped walk [(s!"`{name}`", (walk.localTypes.lookup name))]) else
        match context.words.find? (·.name == name) with
        | some word =>
            if !keepsRow word.effect then .lost else
            let inputs := valueItems word.effect.input
            let outputs := valueItems word.effect.output
            let (taken, after) := take walk s!"`{name}`" (inputs.map fun (n, t) => s!"{n}:{t}") inputs.length (inputs.map (·.2))
            let walk := noteMisread after taken (inputs.map (·.2))
            .next (pushTyped walk ((resultLabels s!"`{name}`" (outputs.map (·.1))).zip (outputs.map (some ·.2))))
        | none => match context.external name with
          | some (inputs, outputs) =>
              let (_, walk) := take walk s!"`{name}`" [] inputs
              .next (push walk (resultLabels s!"`{name}`" (List.replicate outputs "")))
          | none => .lost
    | .primitive name _ => match context.primitive name with
        | some (inputs, outputs) =>
            let operation := s!"`prim {name}`"
            let (taken, after) := take walk operation inputs inputs.length inputs
            let walk := noteMisread after taken inputs
            .next (pushTyped walk ((resultLabels operation (List.replicate outputs.length "")).zip (outputs.map some)))
        | none => .lost
    | .locals names body _ =>
        let (taken, inner) := take walk "`locals`" [] names.length
        -- `taken` is top first; the block names its values bottom to top.
        let bound := (names.map (·.name)).zip (taken.reverse.map (·.type))
        let typed := if taken.length == names.length then
            bound.filterMap fun (name, type) => type.map (name, ·) else []
        let shadowed := walk.localTypes.filter fun (name, _) => !names.any (·.name == name)
        match walkItems context { inner with locals := names.map (·.name) ++ walk.locals, inLocals := true,
                                             localTypes := typed ++ shadowed } body with
        | .next after => .next { after with locals := walk.locals, inLocals := walk.inLocals, localTypes := walk.localTypes }
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
        | [{ quotation := some (body, _), scope, .. }] => runQuotation context walk body scope
        | _ => .lost
    | .atom "dip" _ =>
        let (taken, walk) := take walk "`dip`" [] 2
        match taken with
        | [{ quotation := some (body, _), scope, .. }, kept] =>
            match runQuotation context walk body scope with
            | .next after => .next { after with stack := { kept with own := true } :: after.stack }
            | other => other
        | _ => .lost
    | .atom "if" span =>
        let (taken, below) := take walk "`if`" [] 3
        match taken with
        | [{ quotation := some (onFalse, _), scope := falseScope, .. },
            { quotation := some (onTrue, trueSpan), scope := trueScope, .. }, _] =>
            if span.start.offset == context.target then
              -- An `if` that takes its own condition or quotations from where
              -- there are none is its own mistake, not its branches'; the
              -- checker's account of what it reaches for says more.
              if below.missing > walk.missing then .lost else
              -- The refused `if`: each branch starts from the stack below
              -- the condition, none of it its own.
              let base : Walk :=
                { below with stack := below.stack.map ({ · with own := false }),
                             reach := none, took := [], missing := 0, nesting := 0,
                             inBranch := true
                             -- After a misread before the `if`, no reach in
                             -- its branches is reported.
                             trusted := below.trusted.map fun _ => none }
              let branch (body : List Item) (scope : List (String × String)) : Option BranchAccount :=
                match walkItems context { base with localTypes := scope } body with
                -- After a misread, a later operation the branch reaches below
                -- with may not be the mistake: its count is right, but the
                -- values it would take may be meant for an earlier one.
                | .next after =>
                    if after.trusted.any (· != after.reach) then none else
                    some { reach := after.reach, took := after.took,
                           missing := after.missing, leaves := ownValues after }
                | _ => none
              match branch onTrue trueScope, branch onFalse falseScope with
              | some onTrueAccount, some onFalseAccount =>
                  .found { trueSource := quotationStart context.source trueSpan,
                           onTrue := onTrueAccount, onFalse := onFalseAccount }
              | _, _ => .lost
            else
              match runQuotation context below onTrue trueScope, runQuotation context below onFalse falseScope with
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
                  -- branch's own values, taking the same values from below
                  -- and missing as many, is one account, whichever path
                  -- pushed them; a value the paths push differently is
                  -- named by both. Paths whose reaches differ in anything
                  -- else are lost. Equal counts, values below and missing
                  -- values leave the two paths as many own values.
                  -- Before the refused `if`, reaches are dropped when its
                  -- branches start, so only the stacks need to agree.
                  let reach : Option (Option BranchReach) :=
                    if !walk.inBranch then some afterTrue.reach else
                    match afterTrue.reach, afterFalse.reach with
                    | none, none => some none
                    | some onTrue, some onFalse =>
                        if { onTrue with own := onFalse.own, ownTypes := onFalse.ownTypes } == onFalse then
                          some (some { onTrue with
                            own := (onTrue.own.zip onFalse.own).map fun (a, b) =>
                              if a == b then a else s!"{a} or {b}"
                            ownTypes := (onTrue.ownTypes.zip onFalse.ownTypes).map fun (a, b) =>
                              if a == b then a else none })
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
                    -- Two quotations can share a label, which shows only a
                    -- long quotation's start: only the same quotation is kept.
                    if onTrue.label == onFalse.label && onTrue.type == onFalse.type &&
                        onTrue.quotation == onFalse.quotation then onTrue
                    else { label := "the result of an `if`", own := onTrue.own,
                           type := if onTrue.type == onFalse.type then onTrue.type else none }
                  -- A reach both paths still trust is trusted merged.
                  let trusted : Option (Option BranchReach) :=
                    if afterTrue.trusted.isNone && afterFalse.trusted.isNone then none
                    else if afterTrue.trusted.all (· == afterTrue.reach) &&
                        afterFalse.trusted.all (· == afterFalse.reach) then some reach
                    else some none
                  .next { afterTrue with stack := merged, reach, trusted }
              | _, _ => .lost
        | _ => .lost
    | .atom _ _ => .lost
end

/-- The account of the `if` starting at `context.target` in `word`, if the
walk can follow the body that far. The word's inputs are named as such. -/
def ofWord (context : Context) (word : WordDefinition) : Option IfAccount :=
  let inputs := (valueItems word.effect.input).map fun (name, type) => (s!"the input `{name}`", some type)
  match walkItems context (pushTyped { stack := [] } inputs) word.body with
  | .found account => some account
  | _ => none

/-- The account of the refused `if` at `span`, searching every word, since
the checker's report names the word but the span is what identifies the `if`. -/
def ofIf (context : Context) (span : Span) : Option IfAccount :=
  let context := { context with target := span.start.offset }
  context.words.findSome? fun word =>
    if word.span.start.offset ≤ span.start.offset && span.start.offset < word.span.stop.offset
    then ofWord context word else none

/-- A primitive's input and output types, bottom to top, from its scheme,
when the scheme keeps the stack below its inputs as it is. -/
def primitiveShape (scheme : Scheme) : Option (List String × List String) :=
  let (inputs, below) := stackValues scheme.input
  let (outputs, after) := stackValues scheme.output
  if below.isSome && below == after then some (inputs.map renderType, outputs.map renderType) else none

end Firth.Elaborator.Account
