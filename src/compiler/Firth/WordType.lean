/-!
Rendering an erased word type into the canonical target string.

`src/runtime/vm/target-spec.md` §7 fixes the grammar:

```text
WordType ::= "(" [ "forall" RowName { "," RowName } ";" ] Stack "--" Stack ")"
Stack    ::= [ Item { "," Item } ]
Item     ::= RowName | Name ":" ValueType
ValueType ::= Name [ "^many" | "^linear" ]
            | "[" Stack "--" Stack "]" [ "^many" | "^linear" ]
```

with no whitespace anywhere, `RowName` exactly one Unicode scalar, and `Name`
an ASCII identifier matching `[A-Za-z_][A-Za-z0-9_]*`.

The elaborator's stack shapes carry no item labels, and the grammar requires
one per value item, so items are labelled positionally as `v0`, `v1`, ...
counting from the bottom of each stack. Labels are not semantic: the VM
compares erased word types for equality when admitting a patch, so all that
matters is that the same checked word always renders to the same string.

Surface row names may be several characters (`ρ2` is legal surface syntax)
while a target `RowName` is exactly one Unicode scalar, so binders are renamed
positionally rather than passed through. `schemeOfEffect` already rejects
duplicate surface binders, so a positional map is injective.

An unresolved inference variable is refused rather than guessed at. A word
whose type still mentions one was never fully checked, and emitting an
approximation of it would put an unchecked claim into an image.

The usage annotation is always emitted, even though the grammar makes it
optional: `dictionary_digest` hashes these bytes, so two spellings of one type
would be two different images.
-/

namespace Firth.Compiler.WordType

/-- Ownership class, as the target grammar spells it. -/
inductive Usage where
  | many
  | linear
  deriving Repr, BEq

/-!
A resolved erased type and stack. `StackType.mk` carries an optional row
variable at the bottom followed by value items in bottom-to-top order, which
is the order the canonical string writes them in.
-/
mutual
  inductive ValueType where
    | base (name : String) (usage : Usage)
    | quotation (input output : StackType) (usage : Usage)
    deriving Repr, BEq

  inductive StackType where
    | mk (row : Option String) (items : List ValueType)
    deriving Repr, BEq
end

/-- A resolved erased word type: the declared row binders and the two stacks. -/
structure Scheme where
  rowVariables : List String
  input : StackType
  output : StackType
  deriving Repr, BEq

/-- The target `Name` grammar: `[A-Za-z_][A-Za-z0-9_]*`, ASCII only. -/
def isCanonicalIdentifier (name : String) : Bool :=
  let bytes := name.toUTF8
  if bytes.size == 0 then false
  else Id.run do
    let head := bytes.get! 0
    let alpha := fun (byte : UInt8) =>
      (65 ≤ byte && byte ≤ 90) || (97 ≤ byte && byte ≤ 122) || byte == 95
    let digit := fun (byte : UInt8) => 48 ≤ byte && byte ≤ 57
    if !alpha head then return false
    for index in [1:bytes.size] do
      let byte := bytes.get! index
      if !(alpha byte || digit byte) then return false
    return true

/-- The target `RowName` grammar: exactly one Unicode scalar. -/
def isRowName (name : String) : Bool :=
  name.length == 1

/-- Canonical target row names, assigned by binder position. Every entry is a
single Unicode scalar that is neither whitespace nor a grammar delimiter. `ρ`
comes first because it is the spec's own example and the one every fixture in
the repository uses. -/
def canonicalRowNames : Array String :=
  #["ρ", "σ", "τ", "υ", "φ", "χ", "ψ", "ω",
    "α", "β", "γ", "δ", "ε", "ζ", "η", "θ",
    "ι", "κ", "λ", "μ", "ν", "ξ", "π", "ς"]

/-- `MAX_WORD_TYPE_NESTING` from the VM decoder: level 32 is accepted, 33 is
rejected as an invalid word type. -/
def maxQuotationNesting : Nat := 32

private def renderUsage : Usage → String
  | .many => "^many"
  | .linear => "^linear"

mutual

private partial def renderValueType (rows : List (String × String)) (depth : Nat) :
    ValueType → Except String String
  | .base name usage =>
      if isCanonicalIdentifier name then .ok (name ++ renderUsage usage)
      else .error s!"type name is not a canonical target identifier: {name}"
  | .quotation input output usage => do
      if depth ≥ maxQuotationNesting then
        .error "quotation type nesting exceeds the target bound of 32"
      let inputText ← renderStackType rows (depth + 1) input
      let outputText ← renderStackType rows (depth + 1) output
      pure ("[" ++ inputText ++ "--" ++ outputText ++ "]" ++ renderUsage usage)

private partial def renderItems (rows : List (String × String)) (depth index : Nat) :
    List ValueType → Except String (List String)
  | [] => pure []
  | item :: rest => do
      let rendered ← renderValueType rows depth item
      let tail ← renderItems rows depth (index + 1) rest
      pure ((s!"v{index}:" ++ rendered) :: tail)

/-- Items arrive bottom-to-top, which is the order the canonical grammar
writes them in; an optional row variable sits below them all. -/
private partial def renderStackType (rows : List (String × String)) (depth : Nat) :
    StackType → Except String String
  | .mk row items => do
      let rowText ←
        match row with
        | none => pure []
        | some name =>
            match rows.find? (fun entry => entry.1 == name) with
            | some entry => pure [entry.2]
            | none => .error s!"row variable is not bound by the word type: {name}"
      let itemTexts ← renderItems rows depth 0 items
      pure (String.intercalate "," (rowText ++ itemTexts))

end

/-- Renders a resolved scheme as the canonical erased word type string. -/
def render (scheme : Scheme) : Except String String := do
  if scheme.rowVariables.eraseDups.length != scheme.rowVariables.length then
    throw "row binders repeat"
  if scheme.rowVariables.length > canonicalRowNames.size then
    throw s!"more row binders than canonical target row names: {scheme.rowVariables.length}"
  let rows : List (String × String) :=
    scheme.rowVariables.zipIdx.map (fun (name, index) => (name, canonicalRowNames[index]!))
  let binder :=
    if rows.isEmpty then ""
    else "forall" ++ String.intercalate "," (rows.map (·.2)) ++ ";"
  let input ← renderStackType rows 0 scheme.input
  let output ← renderStackType rows 0 scheme.output
  pure ("(" ++ binder ++ input ++ "--" ++ output ++ ")")

end Firth.Compiler.WordType
