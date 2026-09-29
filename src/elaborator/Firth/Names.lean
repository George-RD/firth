import elaborator.Firth.Parser

namespace Firth.Elaborator

private def qualified (scopeName name : String) : String :=
  if scopeName.isEmpty then name else scopeName ++ "." ++ name

private def nameError (code name : String) (span : Span) : ParseError :=
  { code, primary := span, actual := some name, cause := .validation }

private partial def collectNamedWords (scopeName : String) : List Declaration → List WordDefinition
  | [] => []
  | .use _ :: rest => collectNamedWords scopeName rest
  | .word word :: rest =>
      { word with name := qualified scopeName word.name } :: collectNamedWords scopeName rest
  | .vocabulary name body _ :: rest =>
      collectNamedWords (qualified scopeName name) body ++ collectNamedWords scopeName rest

/-- Canonical dictionary keys retain vocabulary identity. -/
def collectWords (declarations : List Declaration) : List WordDefinition :=
  collectNamedWords "" declarations

private partial def collectVocabularies (scopeName : String) : List Declaration → List (String × Span)
  | [] => []
  | .use _ :: rest => collectVocabularies scopeName rest
  | .word _ :: rest => collectVocabularies scopeName rest
  | .vocabulary name body span :: rest =>
      let key := qualified scopeName name
      (key, span) :: (collectVocabularies key body ++ collectVocabularies scopeName rest)

private def checkUnique (values : List (String × Span)) : Except ParseError Unit := do
  let mut seen : List String := []
  for (name, span) in values do
    if seen.contains name then throw (nameError "firth.name.duplicate-canonical" name span)
    seen := name :: seen

private def expandAlias (uses : List UseDecl) (name : String) : String :=
  match name.splitOn "." with
  | scopeName :: suffix =>
      match uses.find? (fun use => use.alias == some scopeName) with
      | some use => use.name ++ "." ++ String.intercalate "." suffix
      | none => name
  | _ => name

/-- Resolves one word reference to its canonical dictionary key.

`external` names the words the caller's environment supplies outside this
file, such as a configured helper. A reference is a candidate only when it
names a dictionary key or an external word; a reference with no candidate is
`firth.name.unresolved` here, from the resolver, and never reaches erasure as
an unresolved effect. -/
private def resolveWord (keys : List String) (external : String → Bool) (scopeName : String)
    (uses : List UseDecl) (locals : List String) (name : String) (span : Span) :
    Except ParseError String := do
  if locals.contains name then return name
  if (name.splitOn ".").length > 1 then
    let canonical := expandAlias uses name
    if keys.contains canonical || external canonical then return canonical
    throw (nameError "firth.name.unresolved" name span)
  let imported : List String := uses.map (fun (declaration : UseDecl) => qualified declaration.name name)
  let visible : List String := qualified scopeName name :: imported
  let candidates := (visible.filter (fun key => keys.contains key)).eraseDups
  match candidates with
  | [candidate] => return candidate
  | [] =>
      if external name then return name
      throw (nameError "firth.name.unresolved" name span)
  | _ => throw (nameError "firth.name.ambiguous-use" name span)

private partial def resolveItems (keys : List String) (external : String → Bool)
    (scopeName : String) (uses : List UseDecl) (locals : List String) :
    List Item → Except ParseError (List Item)
  | [] => pure []
  | item :: rest => do
      let resolved : Item ← match item with
        | .word name span => do
            let canonical ← resolveWord keys external scopeName uses locals name span
            pure (Item.word canonical span)
        | .quotation body span => do
            let body ← resolveItems keys external scopeName uses locals body
            pure (Item.quotation body span)
        | .locals names body span => do
            let body ← resolveItems keys external scopeName uses (names.map (·.name) ++ locals) body
            pure (Item.locals names body span)
        | other => pure other
      let tail ← resolveItems keys external scopeName uses locals rest
      pure (resolved :: tail)

private def effectNames (items : List StackItem) : List String :=
  items.filterMap fun
    | .value name _ _ => some name
    | .row _ _ => none

/-- A name the word's stack effect declares is not in scope in its body: the
effect documents the stack, and only `locals` binds names. When an
unresolved name is one of them, the error carries the effect's names so the
diagnostic can say so. -/
private def withEffectNames (effect : StackEffect) (error : ParseError) : ParseError :=
  let inputs := effectNames effect.input
  let outputs := effectNames effect.output
  match error.code, error.actual with
  | "firth.name.unresolved", some name =>
      if inputs.contains name || outputs.contains name then
        { error with effectInputs := inputs, effectOutputs := outputs }
      else error
  | _, _ => error

/-- A `use` declaration names a vocabulary the file does not declare, or an
alias already taken. -/
private def badUse (vocabularies : List String) (uses : List UseDecl) (use : UseDecl) :
    Option ParseError :=
  if !vocabularies.contains use.name then some (nameError "firth.name.unresolved" use.name use.span)
  else match use.alias with
    | some alias =>
        if uses.any (fun prior => prior.alias == some alias) ||
            vocabularies.any (fun name => (name.splitOn ".").head? == some alias) then
          some (nameError "firth.name.duplicate-alias" alias use.span)
        else none
    | none => none

/-- Every word in source order, its body resolved, or as written together with
the first name in it that does not resolve. A bad `use` declaration ends the
walk: the words before it are returned with it, since the ones after it
cannot be resolved as their author meant. -/
private partial def resolveScope (keys vocabularies : List String) (external : String → Bool)
    (scopeName : String) (uses : List UseDecl) :
    List Declaration → List (WordDefinition × Option ParseError) × Option ParseError
  | [] => ([], none)
  | .use use :: rest =>
      match badUse vocabularies uses use with
      | some error => ([], some error)
      | none => resolveScope keys vocabularies external scopeName (uses ++ [use]) rest
  | .word word :: rest =>
      let name := qualified scopeName word.name
      let this := match resolveItems keys external scopeName uses [] word.body with
        | .ok body => ({ word with name, body }, none)
        | .error error => ({ word with name }, some (withEffectNames word.effect error))
      let (tail, stop) := resolveScope keys vocabularies external scopeName uses rest
      (this :: tail, stop)
  | .vocabulary name body _ :: rest =>
      match resolveScope keys vocabularies external (qualified scopeName name) uses body with
      | (inside, some error) => (inside, some error)
      | (inside, none) =>
          let (outside, stop) := resolveScope keys vocabularies external scopeName uses rest
          (inside ++ outside, stop)

private def freshBinder (name : String) (taken : List String) : Nat → Nat → String
  | 0, _ => name
  | fuel + 1, suffix =>
      let candidate := s!"{name}{suffix}"
      if taken.contains candidate then freshBinder name taken fuel (suffix + 1) else candidate

/-- The names a `locals` block can bind for these inputs. A stack effect may
repeat a label (`n:Int n:Int`), but `locals` refuses a repeated name, so each
repeat gets the first numbered name (`n2`, `n3`, ...) that no input uses.
A label in `reserved` is numbered the same way. -/
def localBinders (inputs : List String) (reserved : List String := []) : List String :=
  inputs.foldl (init := []) fun bound name =>
    if bound.contains name || reserved.contains name then
      let taken := inputs ++ bound ++ reserved
      bound ++ [freshBinder name taken (taken.length + 1) 2]
    else bound ++ [name]

/-- The names inner `locals` blocks of a body bind, at any depth. -/
private partial def innerBinders : List Item → List String
  | [] => []
  | .quotation items _ :: rest => innerBinders items ++ innerBinders rest
  | .locals names items _ :: rest => names.map (·.name) ++ innerBinders items ++ innerBinders rest
  | _ :: rest => innerBinders rest

/-- Every name a body refers to or binds, at any depth. -/
private partial def bodyNames : List Item → List String
  | [] => []
  | .word name _ :: rest => name :: bodyNames rest
  | .quotation items _ :: rest => bodyNames items ++ bodyNames rest
  | .locals names items _ :: rest => names.map (·.name) ++ bodyNames items ++ bodyNames rest
  | _ :: rest => bodyNames rest

/-- The `locals` block that opens a word's body, when a name the stack
effect gives to one input binds another. The block binds the inputs the last
name to the top, so `locals { b a }` for inputs `a b` binds `b` to the value
the effect calls `a`; when the two share a type the body still checks and
computes the wrong result. Names the effect does not declare, and blocks that
reach below the declared inputs, are left to the checker.

The block to write binds every input from the deepest one the block names up
to the top, so that every declared name holds the value the stack effect
gives it. Each declared name in the old block claims its input. The author's
reading is that the block names the top inputs and leaves the rest on the
stack, so the old block left, as the deepest of the inputs no name claims, as
many values as the body found on the stack below its names: the body now
pushes those first. Each undeclared name stands for one of the other
unclaimed inputs, in order, and the body writes that input's name for it.
When the old block was a reordering of the new one, the body stays as it
is. -/
private def misorderedInputLocals (word : WordDefinition) (written : List Item) :
    Option (LocatedName × LocalsBlock) :=
  match word.body with
  -- A block that repeats a name is refused as `firth.name.duplicate-local`,
  -- which says more.
  | .locals names _ _ :: _ =>
      if (names.map (·.name)).eraseDups.length != names.length then none else
      let inputs := word.effect.input.filterMap fun
        | .value name type _ => some (name, type.name)
        | .row _ _ => none
      if names.length > inputs.length then none else
      let start := inputs.length - names.length
      let pairs := names.zip (inputs.drop start)
      let declared := inputs.map (·.1)
      (pairs.find? fun (bound, input, _) => declared.contains bound.name && bound.name != input).map
        fun (bound, _) =>
          -- The deepest input the block names, by the name the effect gives it.
          let first := (names.filterMap fun name => declared.idxOf? name.name).foldl min start
          let positions := (List.range declared.length).filter (first ≤ ·)
          -- A declared name claims the first input with that label the new
          -- block binds; a label the effect repeats is claimed once.
          let (claimed, fresh) := names.foldl (init := (([] : List Nat), ([] : List String)))
            fun (claimed, fresh) name =>
              match positions.find? fun index => declared[index]? == some name.name && !claimed.contains index with
              | some index => (claimed ++ [index], fresh)
              | none => (claimed, fresh ++ [name.name])
          let unclaimed := positions.filter (!claimed.contains ·)
          -- Names the body uses that the old block does not bind, words it
          -- calls and inner locals, which a new binder must not shadow. They
          -- are read from the body as written, before word names are
          -- resolved, since the author edits that text. The old block's
          -- names that are to be renamed are reserved too, so that a
          -- numbered binder is never one of them (`b2` for a repeated `b`
          -- where the old block binds `b2` to another input).
          let items := match written with
            | .locals _ items _ :: _ => items
            | _ => []
          let reserved := (bodyNames items).filter (fun name => !names.any (·.name == name)) ++ fresh
          -- A name to rename that an inner block binds again means two
          -- things in the body, so "write `b` for `x`" would be read for
          -- both: no edit is stated.
          let rebound := fresh.any fun name => (innerBinders items).contains name
          let binders := localBinders declared reserved
          let binder (index : Nat) : String := binders[index]?.getD ""
          (bound, { word := word.name
                    pairs := pairs.map fun (bound, input, type) => (bound.name, input, type)
                    block := binders.drop first
                    renames := fresh.zip ((unclaimed.drop (start - first)).map binder)
                    prelude := (unclaimed.take (start - first)).map binder
                    rebound })
  | _ => none

private partial def renameItems (renames : List (String × String)) : List Item → List Item
  | [] => []
  | .word name span :: rest => .word ((renames.lookup name).getD name) span :: renameItems renames rest
  | .quotation items span :: rest => .quotation (renameItems renames items) span :: renameItems renames rest
  | .locals names items span :: rest =>
      .locals names (renameItems renames items) span :: renameItems renames rest
  | item :: rest => item :: renameItems renames rest

/-- The word with the edit `block` states applied, as an author reading the
diagnostic would apply it: the new block, each renamed name written in its
place throughout the body, and the prelude names first. -/
def applyLocalsBlock (word : WordDefinition) (block : LocalsBlock) : WordDefinition :=
  match word.body with
  | .locals _ items span :: rest =>
      let names := block.block.map fun name => ({ name := name, span := span } : LocatedName)
      let prelude := block.prelude.map fun name => Item.word name span
      { word with body := .locals names (prelude ++ renameItems block.renames items) span :: rest }
  | _ => word

/-- Every word whose opening `locals` block binds its inputs out of order,
refused as one `firth.name.locals-order` error at the first such name, so an
author sees each block to fix in one report. `written` gives the words as
written, before their names are resolved. -/
def checkInputLocals (words : List WordDefinition) (written : List WordDefinition := words) :
    Except ParseError Unit :=
  let body (word : WordDefinition) : List Item :=
    ((written.find? (·.name == word.name)).map (·.body)).getD word.body
  match words.filterMap fun word => misorderedInputLocals word (body word) with
  | [] => pure ()
  | blocks@((bound, block) :: _) =>
      throw { code := "firth.name.locals-order", primary := bound.span, cause := .validation,
              actual := some block.word, localsBlocks := blocks.map (·.2) }

/-- Name resolution word by word. Duplicate canonical names are refused for
the whole file. Otherwise each word comes back with its body resolved, or as
written together with the first name in it that does not resolve, and a bad
`use` declaration comes last, ending the words that could be resolved.
Local names remain sugar; they must not be rewritten into dictionary calls.
`external` names words the caller's environment defines outside the file; any
other reference without a candidate is refused as `firth.name.unresolved`. -/
def resolveEach (declarations : List Declaration) (external : String → Bool := fun _ => false) :
    Except ParseError (List (WordDefinition × Option ParseError) × Option ParseError) := do
  let words := collectWords declarations
  let vocabularies := collectVocabularies "" declarations
  checkUnique (words.map (fun word => (word.name, word.span)))
  checkUnique vocabularies
  pure (resolveScope (words.map (·.name)) (vocabularies.map (·.1)) external "" [] declarations)

/-- Resolve lexical imports and canonical word names before erasure/checking,
refusing at the first error in the source (`resolveEach`). -/
def resolveNames (declarations : List Declaration) (external : String → Bool := fun _ => false) :
    Except ParseError (List WordDefinition) := do
  let (words, stop) ← resolveEach declarations external
  match words.findSome? (·.2), stop with
  | some error, _ => throw error
  | none, some error => throw error
  | none, none => pure (words.map (·.1))

end Firth.Elaborator
