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

Canonical row names come from `canonicalRowName`: the first 24 binders take
the fixed Greek table every fixture and digest in the repository already uses,
and every later binder takes one CJK Unified Ideograph counting up from
`U+4E00`. Both ranges are single scalars that are never Unicode `White_Space`,
never a grammar delimiter and never ASCII, so they cannot collide with a `Name`
and the VM's `row_name` parser accepts them. The block gives 20992 further
names; a scheme needing more is refused rather than wrapped into another
block. `isRowName` states that predicate once and `render` checks every name it
emits against it.

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

/-- Unicode `White_Space`, which is what Rust's `char::is_whitespace` tests
in the VM's `row_name` parser. Lean's `Char.isWhitespace` covers ASCII only. -/
def isUnicodeWhitespace (c : Char) : Bool :=
  let n := c.toNat
  (0x9 ≤ n && n ≤ 0xD) || n == 0x20 || n == 0x85 || n == 0xA0 || n == 0x1680
    || (0x2000 ≤ n && n ≤ 0x200A) || n == 0x2028 || n == 0x2029 || n == 0x202F
    || n == 0x205F || n == 0x3000

/-- The scalars the VM's `row_name` parser refuses besides whitespace. -/
def rowNameDelimiters : List Char := [',', ';', ':', '^', '(', ')', '[', ']', '-']

/-- The target `RowName` grammar as `src/runtime/vm/src/syntax.rs` parses it:
exactly one Unicode scalar that is neither `White_Space` nor a delimiter. The
compiler additionally excludes ASCII, which the VM would otherwise read as the
start of a `Name` in item position, so the names it emits are unambiguous. -/
def isRowName (name : String) : Bool :=
  match name.toList with
  | [c] => !isUnicodeWhitespace c && !rowNameDelimiters.contains c && c.toNat ≥ 0x80
  | _ => false

/-- The fixed canonical row names for the first 24 binder positions. `ρ` comes
first because it is the spec's own example and the one every fixture in the
repository uses; the table is frozen because `dictionary_digest` hashes it. -/
def canonicalRowNames : Array String :=
  #["ρ", "σ", "τ", "υ", "φ", "χ", "ψ", "ω",
    "α", "β", "γ", "δ", "ε", "ζ", "η", "θ",
    "ι", "κ", "λ", "μ", "ν", "ξ", "π", "ς"]

#guard canonicalRowNames.all isRowName

/-- The first scalar of the CJK Unified Ideographs block, used for binder 24. -/
def generatedRowNameBase : Nat := 0x4E00

/-- The number of scalars in that block, `U+4E00` to `U+9FFF`. -/
def generatedRowNameCount : Nat := 0x5200

/-- The most row binders one erased word type can name. -/
def maxRowBinders : Nat := canonicalRowNames.size + generatedRowNameCount

/-- The canonical target row name of binder `index`: the fixed table below 24,
then `U+4E00 + (index - 24)`. Total, but only meaningful below
`maxRowBinders`; `render` refuses larger schemes. -/
def canonicalRowName (index : Nat) : String :=
  if h : index < canonicalRowNames.size then canonicalRowNames[index]
  else String.singleton (Char.ofNat (generatedRowNameBase + (index - canonicalRowNames.size)))

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
  if scheme.rowVariables.length > maxRowBinders then
    throw s!"more row binders than canonical target row names: {scheme.rowVariables.length}"
  let rows : List (String × String) :=
    scheme.rowVariables.zipIdx.map (fun (name, index) => (name, canonicalRowName index))
  match rows.find? (fun entry => !isRowName entry.2) with
  | some entry => throw s!"generated row name is not a target row name: {entry.2}"
  | none => pure ()
  let binder :=
    if rows.isEmpty then ""
    else "forall" ++ String.intercalate "," (rows.map (·.2)) ++ ";"
  let input ← renderStackType rows 0 scheme.input
  let output ← renderStackType rows 0 scheme.output
  pure ("(" ++ binder ++ input ++ "--" ++ output ++ ")")

end Firth.Compiler.WordType
