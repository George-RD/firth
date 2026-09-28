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

private partial def resolveScope (keys vocabularies : List String) (external : String → Bool)
    (scopeName : String) (uses : List UseDecl) :
    List Declaration → Except ParseError (List WordDefinition)
  | [] => pure []
  | .use use :: rest => do
      if !vocabularies.contains use.name then
        throw (nameError "firth.name.unresolved" use.name use.span)
      if let some alias := use.alias then
        if uses.any (fun prior => prior.alias == some alias) ||
            vocabularies.any (fun name => (name.splitOn ".").head? == some alias) then
          throw (nameError "firth.name.duplicate-alias" alias use.span)
      resolveScope keys vocabularies external scopeName (uses ++ [use]) rest
  | .word word :: rest => do
      let body ← match resolveItems keys external scopeName uses [] word.body with
        | .ok body => pure body
        | .error error => throw (withEffectNames word.effect error)
      let tail ← resolveScope keys vocabularies external scopeName uses rest
      return { word with name := qualified scopeName word.name, body } :: tail
  | .vocabulary name body _ :: rest => do
      let inside ← resolveScope keys vocabularies external (qualified scopeName name) uses body
      let outside ← resolveScope keys vocabularies external scopeName uses rest
      return inside ++ outside

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
private def misorderedInputLocals (word : WordDefinition) : Option (LocatedName × LocalsBlock) :=
  match word.body with
  | .locals names _ _ :: _ =>
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
          (bound, { word := word.name
                    pairs := pairs.map fun (bound, input, type) => (bound.name, input, type)
                    inputs := declared
                    first
                    renames := fresh.zip (unclaimed.drop (start - first))
                    prelude := unclaimed.take (start - first) })
  | _ => none

/-- Every word whose opening `locals` block binds its inputs out of order,
refused as one `firth.name.locals-order` error at the first such name, so an
author sees each block to fix in one report. -/
def checkInputLocals (words : List WordDefinition) : Except ParseError Unit :=
  match words.filterMap misorderedInputLocals with
  | [] => pure ()
  | blocks@((bound, block) :: _) =>
      throw { code := "firth.name.locals-order", primary := bound.span, cause := .validation,
              actual := some block.word, localsBlocks := blocks.map (·.2) }

/-- Resolve lexical imports and canonical word names before erasure/checking.
Local names remain sugar; they must not be rewritten into dictionary calls.
`external` names words the caller's environment defines outside the file; any
other reference without a candidate is refused here as `firth.name.unresolved`. -/
def resolveNames (declarations : List Declaration) (external : String → Bool := fun _ => false) :
    Except ParseError (List WordDefinition) := do
  let words := collectWords declarations
  let vocabularies := collectVocabularies "" declarations
  checkUnique (words.map (fun word => (word.name, word.span)))
  checkUnique vocabularies
  resolveScope (words.map (·.name)) (vocabularies.map (·.1)) external "" [] declarations

end Firth.Elaborator
