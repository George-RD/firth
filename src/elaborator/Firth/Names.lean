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

private def resolveWord (keys : List String) (scopeName : String) (uses : List UseDecl)
    (locals : List String) (name : String) (span : Span) : Except ParseError String := do
  if locals.contains name then return name
  if (name.splitOn ".").length > 1 then return expandAlias uses name
  let candidates := ((qualified scopeName name :: uses.map (fun use => qualified use.name name))
    .filter keys.contains).eraseDups
  match candidates with
  | [candidate] => return candidate
  | [] =>
      if keys.contains name then throw (nameError "firth.name.unresolved" name span)
      return name -- The erasure environment may supply a configured external word.
  | _ => throw (nameError "firth.name.ambiguous-use" name span)

private partial def resolveItems (keys : List String) (scopeName : String) (uses : List UseDecl)
    (locals : List String) : List Item → Except ParseError (List Item)
  | [] => pure []
  | item :: rest => do
      let item ← match item with
        | .word name span => return .word (← resolveWord keys scopeName uses locals name span) span
        | .quotation body span => return .quotation (← resolveItems keys scopeName uses locals body) span
        | .locals names body span =>
            return .locals names (← resolveItems keys scopeName uses
              (names.map (·.name) ++ locals) body) span
        | other => pure other
      return item :: (← resolveItems keys scopeName uses locals rest)

private partial def resolveScope (keys vocabularies : List String) (scopeName : String)
    (uses : List UseDecl) : List Declaration → Except ParseError (List WordDefinition)
  | [] => pure []
  | .use use :: rest => do
      if !vocabularies.contains use.name then
        throw (nameError "firth.name.unresolved" use.name use.span)
      if let some alias := use.alias then
        if uses.any (fun prior => prior.alias == some alias) ||
            vocabularies.any (fun name => (name.splitOn ".").head? == some alias) then
          throw (nameError "firth.name.duplicate-alias" alias use.span)
      resolveScope keys vocabularies scopeName (uses ++ [use]) rest
  | .word word :: rest => do
      let body ← resolveItems keys scopeName uses [] word.body
      let tail ← resolveScope keys vocabularies scopeName uses rest
      return { word with name := qualified scopeName word.name, body } :: tail
  | .vocabulary name body _ :: rest => do
      let inside ← resolveScope keys vocabularies (qualified scopeName name) uses body
      let outside ← resolveScope keys vocabularies scopeName uses rest
      return inside ++ outside

/-- Resolve lexical imports and canonical word names before erasure/checking.
Local names remain sugar; they must not be rewritten into dictionary calls. -/
def resolveNames (declarations : List Declaration) : Except ParseError (List WordDefinition) := do
  let words := collectWords declarations
  let vocabularies := collectVocabularies "" declarations
  checkUnique (words.map (fun word => (word.name, word.span)))
  checkUnique vocabularies
  resolveScope (words.map (·.name)) (vocabularies.map (·.1)) "" [] declarations

end Firth.Elaborator
