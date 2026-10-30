import elaborator.Firth.Names
import elaborator.Firth.StackEffect

/-!
Records (`dec.typed-records-and-variants`).

A record is a surface type that erases to its fields on the flat stack, so
the kernel, the checker, the compiler and the VM never see it. This module
checks the declarations, flattens word effects over them, and lowers a word's
body: it follows the shape of every value on the stack (a scalar, a record,
or a quotation) from the word's declared effect, refuses what the nominal
types forbid, and rewrites what a record changes into ordinary items:

* `R.pack` and `R.unpack` change the surface type and emit nothing;
* `R.f` and `R.set-f` are `locals` blocks over the record's flat slots;
* `dup`, `drop`, `swap`, `dip` and `quote` act on a whole composite value.

Everything emitted is an item the existing erasure already handles, so the
proof-carrying erasure is untouched, and every emitted item keeps the span of
the item it came from.
-/

namespace Firth.Elaborator

/-- A checked record: its canonical key and its fields in declaration order.
A field type naming another record carries that record's canonical key. -/
structure RecordInfo where
  key : String
  fields : List (LocatedName × TypeExpr)
  span : Span
  deriving Repr, BEq

abbrev RecordTable := List RecordInfo

private def typeError (code : String) (span : Span) (actual : Option String := none)
    (expected : Option String := none) : ParseError :=
  { code, primary := span, actual, expected, cause := .validation }

/-- The leaf slots of a type, each with the path that names it: `r.p.x`. A
type that is no record is one slot. -/
partial def leavesOf (table : RecordTable) (path : String) (type : TypeExpr) : List (String × TypeExpr) :=
  match table.find? (·.key == type.name) with
  | some record =>
      record.fields.flatMap fun (field, member) => leavesOf table (path ++ "." ++ field.name) member
  | none => [(path, type)]

/-- How many flat slots a value of this type takes. -/
def typeWidth (table : RecordTable) (type : TypeExpr) : Nat := (leavesOf table "" type).length

private def reservedTypeNames : List String := StackEffect.sourceTypeNames ++ ["Seq"]

/-- Whether `key` is reachable from the member types of `from_`, so that a
record containing itself, directly or through others, is found. -/
private partial def reaches (entries : List (String × List String)) (seen : List String)
    (target current : String) : Bool :=
  match entries.lookup current with
  | none => false
  | some members =>
      members.any fun member =>
        member == target || (!seen.contains member && reaches entries (member :: seen) target member)

/-- The checked table of the declared records, or the first fault in source
order: a name that does not start upper-case (`firth.type.type-name-case`) or
is a built-in type's (`firth.type.reserved-type-name`), a record with no
field, a repeated field (`firth.type.duplicate-field`) or one that would
collide with a generated operation (`firth.type.reserved-field-name`), a member
type that is no type (`firth.type.unknown-type`), a usage on a record-typed
member (`firth.type.linear-composite-field`) and a record that contains itself
(`firth.type.recursive-type`). -/
def checkRecords (entries : List RecordEntry) : Except ParseError RecordTable := do
  let keys := entries.map (·.key)
  let mut table : RecordTable := []
  let mut members : List (String × List String) := []
  for entry in entries do
    let decl := entry.decl
    unless decl.name.front.isUpper do
      throw (typeError "firth.type.type-name-case" decl.nameSpan (some decl.name))
    if reservedTypeNames.contains decl.name then
      throw (typeError "firth.type.reserved-type-name" decl.nameSpan (some decl.name))
    if decl.fields.isEmpty then
      throw (typeError "firth.type.empty-record" decl.nameSpan (some decl.name))
    let mut seen : List String := []
    let mut resolved : List (LocatedName × TypeExpr) := []
    for field in decl.fields do
      if reservedFieldName field.name.name then
        throw (typeError "firth.type.reserved-field-name" field.name.span (some field.name.name))
      if seen.contains field.name.name then
        throw (typeError "firth.type.duplicate-field" field.name.span (some field.name.name))
      seen := seen ++ [field.name.name]
      match ← resolveTypeName keys entry.scopeName entry.uses field.type.name field.type.span with
      | some key =>
          if field.type.usage == .linear then
            throw (typeError "firth.type.linear-composite-field" field.type.span (some field.type.name))
          resolved := resolved ++ [(field.name, { field.type with name := key })]
      | none =>
          unless StackEffect.sourceTypeNames.contains field.type.name do
            throw (typeError "firth.type.unknown-type" field.type.span (some field.type.name))
          resolved := resolved ++ [(field.name, field.type)]
    members := members ++ [(entry.key, (resolved.map (·.2.name)).filter keys.contains)]
    table := table ++ [{ key := entry.key, fields := resolved, span := decl.span }]
  for entry in entries do
    if reaches members [] entry.key entry.key then
      throw (typeError "firth.type.recursive-type" entry.decl.nameSpan (some entry.key))
  pure table

/-! ### Flat effects -/

/-- `items` with every record-typed item replaced by one item per leaf slot,
named by the path: `r:Request` is `r.id:Int r.qty:Int`. -/
def flattenItems (table : RecordTable) : List StackItem → List StackItem
  | [] => []
  | .row name span :: rest => .row name span :: flattenItems table rest
  | .value name type span :: rest =>
      if table.any (·.key == type.name) then
        (leavesOf table name type).map (fun (path, leaf) =>
          StackItem.value path { leaf with span := type.span, refinements := [] } span) ++
          flattenItems table rest
      else .value name type span :: flattenItems table rest

/-- The effect with its record types flattened. -/
def flattenEffect (table : RecordTable) (effect : StackEffect) : StackEffect :=
  { effect with input := flattenItems table effect.input, output := flattenItems table effect.output }

/-- A refinement on a record-typed item is refused
(`firth.syntax.refinement-in-type`), as is a usage suffix
(`firth.type.composite-usage`): a record's usage is that of its slots. -/
def effectFault (table : RecordTable) (effect : StackEffect) : Option ParseError :=
  (effect.input ++ effect.output).findSome? fun
    | .value _ type _ =>
        if !table.any (·.key == type.name) then none
        else if !type.refinements.isEmpty then
          some (typeError "firth.syntax.refinement-in-type" type.span (some type.name))
        else if type.usage == .linear then
          some (typeError "firth.type.composite-usage" type.span (some type.name))
        else none
    | .row .. => none

/-! ### Shapes -/

/-- What the lowering knows of a value: one kernel slot (`val`), a record, or
a quotation with the number of values it takes from below and what it leaves,
top first. -/
inductive Shape where
  | val
  /-- A scalar whose type is known: `Int` or `Bool`. -/
  | scalar (name : String)
  | record (key : String)
  | quote (consumes : Nat) (produces : List Shape)

private def Shape.isRecord : Shape → Bool
  | .record _ => true
  | _ => false

private def Shape.describe : Shape → String
  | .record key => key
  | .quote .. => "a quotation"
  | .scalar name => name
  | .val => "a value"

def shapeOfType (table : RecordTable) (type : TypeExpr) : Shape :=
  if table.any (·.key == type.name) then .record type.name
  else if type.name == "Int" || type.name == "Bool" then .scalar type.name
  else .val

def Shape.width (table : RecordTable) : Shape → Nat
  | .record key => ((table.find? (·.key == key)).map fun record =>
      record.fields.foldl (fun total (_, member) => total + typeWidth table member) 0).getD 1
  | _ => 1

/-- A declared effect as shapes: inputs and outputs bottom to top, and
whether the effect keeps the stack below it. -/
structure EffectShape where
  input : List Shape
  output : List Shape
  keepsStack : Bool

private def itemShapes (table : RecordTable) (items : List StackItem) : List Shape :=
  items.filterMap fun
    | .value _ type _ => some (shapeOfType table type)
    | .row .. => none

private def itemRows (items : List StackItem) : List String :=
  items.filterMap fun
    | .row name _ => some name
    | .value .. => none

def effectShape (table : RecordTable) (effect : StackEffect) : EffectShape :=
  { input := itemShapes table effect.input
    output := itemShapes table effect.output
    keepsStack := itemRows effect.input == itemRows effect.output && !(itemRows effect.input).isEmpty }

def EffectShape.hasRecord (effect : EffectShape) : Bool :=
  (effect.input ++ effect.output).any Shape.isRecord

/-! ### Lowering -/

/-- What a generated name does. -/
inductive Generated where
  | pack (record : RecordInfo)
  | unpack (record : RecordInfo)
  | read (record : RecordInfo) (index : Nat)
  | write (record : RecordInfo) (index : Nat)

/-- The operations a table generates, by canonical key. -/
def generatedOperations (table : RecordTable) : List (String × Generated) :=
  table.flatMap fun record =>
    (record.key ++ ".pack", .pack record) :: (record.key ++ ".unpack", .unpack record) ::
      ((List.range record.fields.length).zip record.fields).flatMap fun (index, (field, _)) =>
        [(record.key ++ "." ++ field.name, .read record index),
         (record.key ++ ".set-" ++ field.name, .write record index)]

/-- What lowering reads from its caller. `word` gives a dictionary word's
effect, and `primitive` the number of values a primitive takes and leaves. A
name neither knows is left for name resolution and erasure to report. -/
structure Ctx where
  table : RecordTable
  generated : List (String × Generated)
  word : String → Option EffectShape
  primitive : String → Option (List Shape × List Shape)
  inQuotation : Bool := false
  /-- The word's effect names no stack row, so nothing lies below its inputs. -/
  closed : Bool := false
  /-- The names `locals` binds, innermost first, with what is known of each.
  A record local is listed under its own name and under the path of each
  field (`s`, `s.on-hand`). -/
  locals : List (String × Shape) := []
  /-- The leading segments of the qualified names in scope (vocabularies,
  aliases and record types), which a record local must not shadow. -/
  prefixes : List String := []
  /-- Every canonical word and generated operation name, which a word finds
  again by its short name inside its own vocabulary. -/
  names : List String := []

private structure Sim where
  stack : List Shape := []
  /-- Values taken from below the start, which the lowering knows nothing of. -/
  below : Nat := 0
  deriving Inhabited

private abbrev SimM := StateT Sim (Except ParseError)

private def pop : SimM (Shape × Bool) := do
  let state ← get
  match state.stack with
  | top :: rest => set { state with stack := rest }; pure (top, false)
  | [] => set { state with below := state.below + 1 }; pure (.val, true)

private def push (shape : Shape) : SimM Unit :=
  modify fun state => { state with stack := shape :: state.stack }

private def refuse {α : Type} (code : String) (span : Span) (actual : Option String := none)
    (expected : Option String := none) : SimM α :=
  throw (typeError code span actual expected)

/-- Pops a value that must be `expected`: a record by the same name, or a
scalar. A record wanted below the values a quotation has built itself is the
quotation's limit (`firth.type.composite-in-quotation`). -/
private def popExpecting (ctx : Ctx) (span : Span) (expected : Shape) : SimM Unit := do
  let (actual, fromBelow) ← pop
  -- Pack and unpack erase to nothing, so a value they need that the declared
  -- inputs do not supply would otherwise vanish with them.
  if fromBelow && ctx.closed && !ctx.inQuotation then
    refuse "firth.type.mismatch" span (some "nothing") (some expected.describe)
  match expected, actual with
  | .record wanted, .record found =>
      if wanted != found then refuse "firth.type.mismatch" span (some found) (some wanted)
  | .record wanted, _ =>
      if fromBelow && ctx.inQuotation then
        refuse "firth.type.composite-in-quotation" span (some wanted)
      else refuse "firth.type.mismatch" span (some actual.describe) (some wanted)
  | _, .record found => refuse "firth.type.mismatch" span (some found) (some expected.describe)
  -- Pack and unpack erase to nothing, so the kernel never sees a field's type:
  -- a scalar of known type must match the field here.
  | .scalar wanted, .scalar found =>
      if wanted != found then refuse "firth.type.mismatch" span (some found) (some wanted)
  | _, _ => pure ()

/-- Whether two branches leave the same shape: records by name, and
quotations by what they take and leave, recursively. -/
private partial def sameShape : Shape → Shape → Bool
  | .record a, .record b => a == b
  | .record _, _ | _, .record _ => false
  | .quote takes left, .quote takes' right =>
      takes == takes' && left.length == right.length &&
        (left.zip right).all fun (a, b) => sameShape a b
  | _, _ => true

private def binders (prefixName : String) (count : Nat) : List String :=
  (List.range count).map fun index => s!"{prefixName}{index}"

private def located (span : Span) (names : List String) : List LocatedName :=
  names.map fun name => { name, span }

private def wordItems (span : Span) (names : List String) : List Item :=
  names.map fun name => Item.word name span

/-- A `locals` block that takes `names`, bottom to top, and leaves `result`. -/
private def shuffle (span : Span) (names result : List String) : List Item :=
  [Item.locals (located span names) (wordItems span result) span]

private def dupItems (slots : List String) (span : Span) : List Item :=
  if slots.length ≤ 1 then [Item.atom "dup" span] else shuffle span slots (slots ++ slots)

private def dropItems (slots : List String) (span : Span) : List Item :=
  if slots.length ≤ 1 then [Item.atom "drop" span] else shuffle span slots []

/-- `swap` of a value over `lower` slots below one over `upper` slots. -/
private def swapItems (lower upper : List String) (span : Span) : List Item :=
  if lower.length ≤ 1 && upper.length ≤ 1 then [Item.atom "swap" span]
  else shuffle span (lower ++ upper) (upper ++ lower)

/-- `dip` over a value `width` slots wide: the quotation is wrapped in a
`dip` once per extra slot, so it runs beneath all of them. -/
private def dipItems (width : Nat) (span : Span) : List Item :=
  (List.range (width - 1)).flatMap (fun _ =>
    [Item.atom "quote" span, Item.quotation [Item.atom "dip" span] span, Item.atom "compose" span]) ++
    [Item.atom "dip" span]

/-- A quotation `quotation` run by `dip` over a value `width` slots wide:
`[ [ q ] dip ] dip` for two slots, so each `dip` is written next to a quotation
literal. -/
private def dipWrapped (width : Nat) (quotation : List Item) (span : Span) : List Item :=
  let wrapped := (List.range (width - 1)).foldl (init := quotation) fun items _ =>
    [Item.quotation (items ++ [Item.atom "dip" span]) span]
  wrapped ++ [Item.atom "dip" span]

/-- `quote` of a value `width` slots wide builds one quotation that pushes
all of its slots. -/
private def quoteItems (width : Nat) (span : Span) : List Item :=
  Item.atom "quote" span ::
    (List.range (width - 1)).flatMap fun _ =>
      [Item.atom "swap" span, Item.atom "quote" span, Item.atom "swap" span, Item.atom "compose" span]

/-- A quotation applied to `stack`: what is left, and how many values it took
from below the known stack. A quotation is erased on its own, before the
stack it runs on is known, so it treats every value it takes as one slot;
applying it to a record it takes is refused. -/
private def applyQuotation (span : Span) (quotation : Shape) (stack : List Shape) :
    Except ParseError (List Shape × Nat) :=
  match quotation with
  | .quote consumes produces =>
      match (stack.take consumes).find? Shape.isRecord with
      | some (.record key) => throw (typeError "firth.type.composite-in-quotation" span (some key))
      | _ => pure (produces ++ stack.drop consumes, consumes - (stack.take consumes).length)
  | _ => throw (typeError "firth.type.untracked-quotation" span)

private def fieldSlots (ctx : Ctx) (record : RecordInfo) (index : Nat) : Nat × Nat × Nat :=
  let widths := record.fields.map fun (_, member) => typeWidth ctx.table member
  (widths.take index |>.foldl (· + ·) 0, widths.getD index 1, widths.foldl (· + ·) 0)

private def droppedLinear (ctx : Ctx) (record : RecordInfo) (before width : Nat) : Bool :=
  let leaves := (record.fields.flatMap fun (field, member) => leavesOf ctx.table field.name member).map (·.2.usage)
  (leaves.take before ++ leaves.drop (before + width)).any (· == .linear)

private def droppedFieldLinear (ctx : Ctx) (record : RecordInfo) (before width : Nat) : Bool :=
  let leaves := (record.fields.flatMap fun (field, member) => leavesOf ctx.table field.name member).map (·.2.usage)
  ((leaves.drop before).take width).any (· == .linear)

/-- Whether a value of this shape has a linear slot, which it must not copy or
drop as a whole. -/
private def hasLinearSlot (ctx : Ctx) : Shape → Bool
  | .record key =>
      match ctx.table.find? (·.key == key) with
      | some record =>
          (record.fields.flatMap fun (field, member) => leavesOf ctx.table field.name member).any
            (·.2.usage == .linear)
      | none => false
  | _ => false

/-- Names for the slots of a value, which the erased program calls its
locals: a record's leaf paths (`Stock.reserved`), so a report that names a slot
names it as the author knows it. -/
private def slotNames (ctx : Ctx) (shape : Shape) (prefixText : String := "") : List String :=
  match shape with
  | .record key =>
      match ctx.table.find? (·.key == key) with
      | some record =>
          (record.fields.flatMap fun (field, member) => leavesOf ctx.table (key ++ "." ++ field.name) member).map
            (prefixText ++ ·.1)
      | none => [prefixText ++ "value"]
  | _ => [prefixText ++ "value"]

private def fieldShape (ctx : Ctx) (record : RecordInfo) (index : Nat) : Shape :=
  match record.fields[index]? with
  | some (_, member) => shapeOfType ctx.table member
  | none => .val

/-- The flat slots of the record `key` bound as `name`, named by path:
`s.on-hand s.reserved`, as `R.unpack` leaves them. -/
private def localSlots (ctx : Ctx) (name key : String) : List String :=
  match ctx.table.find? (·.key == key) with
  | some record =>
      (record.fields.flatMap fun (field, member) => leavesOf ctx.table (name ++ "." ++ field.name) member).map (·.1)
  | none => [name]

/-- What a record local `name` of the record `key` makes nameable: itself, and
each field by its path, with the nested records among them. -/
private partial def localScope (ctx : Ctx) (name key : String) : List (String × Shape) :=
  (name, .record key) ::
    match ctx.table.find? (·.key == key) with
    | some record =>
        record.fields.flatMap fun (field, member) =>
          let path := name ++ "." ++ field.name
          match shapeOfType ctx.table member with
          | .record nested => localScope ctx path nested
          | shape => [(path, shape)]
    | none => []

private def liftM {α : Type} (action : Except ParseError α) : SimM α := fun state => do
  let value ← action
  pure (value, state)

mutual
private partial def lowerItems (ctx : Ctx) : List Item → SimM (List Item)
  | [] => pure []
  -- A quotation written just before `dip`: when the value it runs under is
  -- `w` slots wide, the quotation is wrapped in `w - 1` more `dip`s, as
  -- written quotations, which erasure tracks (`dipWrapped`).
  | .quotation body quoteSpan :: .atom "dip" span :: rest => do
      let lowered ← lowerItem ctx (.quotation body quoteSpan)
      let (quotation, _) ← pop
      let (kept, _) ← pop
      applyTop span quotation
      push kept
      pure (dipWrapped (kept.width ctx.table) lowered span ++ (← lowerItems ctx rest))
  | item :: rest => do
      let lowered ← lowerItem ctx item
      pure (lowered ++ (← lowerItems ctx rest))

private partial def lowerItem (ctx : Ctx) : Item → SimM (List Item)
  | .literal literal span => do
      push (match literal.value with
        | .integer _ => .scalar "Int"
        | .boolean _ => .scalar "Bool"
        | _ => .val)
      pure [.literal literal span]
  | .primitive name span => do
      match ctx.primitive name with
      | none => pure [.primitive name span]
      | some (takes, leaves) =>
          for shape in takes.reverse do popExpecting ctx span shape
          for shape in leaves do push shape
          pure [.primitive name span]
  | .quotation items span => do
      let (lowered, state) ← liftM (lowerBody { ctx with inQuotation := true } items)
      push (.quote state.below state.stack)
      pure [.quotation lowered span]
  | .locals names items span => do
      -- The names are bottom to top, so the top of the stack binds the last.
      let mut bound : List (LocatedName × Shape) := []
      for name in names.reverse do
        let (shape, _) ← pop
        bound := (name, shape) :: bound
      -- A record local binds one local per flat slot (`s.on-hand`), in order,
      -- and the program names the whole record or a field by path.
      -- A repeated name is left to the erasure's `firth.name.duplicate-local`,
      -- which must not depend on the layouts of the records it binds.
      let repeated := names.any fun name => (names.filter (·.name == name.name)).length > 1
      let mut slots : List LocatedName := []
      let mut scope : List (String × Shape) := []
      for (name, shape) in bound do
        match shape with
        | .record key =>
            if !repeated && ctx.prefixes.contains name.name then
              refuse "firth.name.local-shadows-prefix" name.span (some name.name)
            slots := slots ++ (if repeated then [name] else
              (localSlots ctx name.name key).map fun slot => { name := slot, span := name.span })
            scope := localScope ctx name.name key ++ scope
        | _ =>
            slots := slots ++ [name]
            scope := (name.name, shape) :: scope
      -- A name bound again hides the earlier binding and every field path of it.
      let outer := ctx.locals.filter fun (outerName, _) =>
        !bound.any fun (name, _) => outerName == name.name || outerName.startsWith (name.name ++ ".")
      let lowered ← lowerItems { ctx with locals := scope ++ outer } items
      pure [.locals slots lowered span]
  | .atom name span => lowerAtom ctx name span
  | .word name span => do
      if let some (_, shape) := ctx.locals.find? (·.1 == name) then
        push shape
        match shape with
        | .record key => pure ((localSlots ctx name key).map fun slot => Item.word slot span)
        | _ => pure [.word name span]
      else match ctx.generated.lookup name with
        | some operation => lowerGenerated ctx operation span
        | none =>
          match ctx.word name with
          | none =>
              -- The resolver let a dotted name through because its first
              -- segment is a local; it names no field of a record local.
              if (name.splitOn ".").length > 1 && ctx.locals.any (fun (binder, _) => (name.splitOn ".").head? == some binder) then
                refuse "firth.name.unresolved" span (some name)
              else pure [.word name span]
          | some effect =>
              for shape in effect.input.reverse do popExpecting ctx span shape
              if !effect.keepsStack then modify fun state => { state with stack := [] }
              for shape in effect.output do push shape
              pure [.word name span]

private partial def lowerAtom (ctx : Ctx) (name : String) (span : Span) : SimM (List Item) := do
  match name with
  | "dup" =>
      let (top, _) ← pop
      if hasLinearSlot ctx top then refuse "firth.type.record-copy-linear" span (some top.describe)
      push top; push top
      pure (dupItems (slotNames ctx top) span)
  | "drop" =>
      let (top, _) ← pop
      if hasLinearSlot ctx top then refuse "firth.type.record-drop-linear" span (some top.describe)
      pure (dropItems (slotNames ctx top) span)
  | "swap" =>
      let (upper, _) ← pop
      let (lower, _) ← pop
      push upper; push lower
      pure (swapItems (slotNames ctx lower "below ") (slotNames ctx upper "above ") span)
  | "quote" =>
      let (top, _) ← pop
      push (.quote 0 [top])
      pure (quoteItems (top.width ctx.table) span)
  | "call" =>
      let (quotation, _) ← pop
      applyTop span quotation
      pure [.atom name span]
  | "dip" =>
      let (quotation, _) ← pop
      let (kept, _) ← pop
      applyTop span quotation
      push kept
      pure (dipItems (kept.width ctx.table) span)
  | "compose" =>
      let (second, _) ← pop
      let (first, _) ← pop
      match first, second with
      | .quote takes leaves, .quote .. =>
          let (rest, below) ← liftM (applyQuotation span second leaves)
          push (.quote (takes + below) rest)
          pure [.atom name span]
      | _, _ => refuse "firth.type.untracked-quotation" span
  | "if" =>
      let (otherwise, _) ← pop
      let (consequent, _) ← pop
      popExpecting ctx span .val
      let state ← get
      let (afterThen, belowThen) ← liftM (applyQuotation span consequent state.stack)
      let (afterElse, belowElse) ← liftM (applyQuotation span otherwise state.stack)
      if afterThen.length != afterElse.length ||
          !(afterThen.zip afterElse).all (fun (a, b) => sameShape a b) then
        refuse "firth.type.mismatch" span (some "the branches of the `if` leave different values")
      set { state with stack := afterThen, below := state.below + max belowThen belowElse }
      pure [.atom name span]
  | _ => pure [.atom name span]

private partial def applyTop (span : Span) (quotation : Shape) : SimM Unit := do
  let state ← get
  let (after, below) ← liftM (applyQuotation span quotation state.stack)
  set { state with stack := after, below := state.below + below }

private partial def lowerGenerated (ctx : Ctx) (operation : Generated) (span : Span) : SimM (List Item) := do
  match operation with
  | .pack record =>
      for (_, member) in record.fields.reverse do popExpecting ctx span (shapeOfType ctx.table member)
      push (.record record.key)
      pure []
  | .unpack record =>
      popExpecting ctx span (.record record.key)
      for (_, member) in record.fields do push (shapeOfType ctx.table member)
      pure []
  | .read record index =>
      popExpecting ctx span (.record record.key)
      push (fieldShape ctx record index)
      let (before, width, total) := fieldSlots ctx record index
      if droppedLinear ctx record before width then
        refuse "firth.type.record-drop-linear" span (some record.key)
      if width == total then pure []
      else
        let slots := slotNames ctx (.record record.key)
        pure (shuffle span slots ((slots.drop before).take width))
  | .write record index =>
      popExpecting ctx span (fieldShape ctx record index)
      popExpecting ctx span (.record record.key)
      push (.record record.key)
      let (before, width, _) := fieldSlots ctx record index
      if droppedFieldLinear ctx record before width then
        refuse "firth.type.record-drop-linear" span (some record.key)
      let slots := slotNames ctx (.record record.key)
      let value := (slots.drop before |>.take width).map ("new " ++ ·)
      pure (shuffle span (slots ++ value) (slots.take before ++ value ++ slots.drop (before + width)))

private partial def lowerBody (ctx : Ctx) (items : List Item) : Except ParseError (List Item × Sim) :=
  (lowerItems ctx items).run {}
end

/-- Whether a body mentions a record, or reads a field of a local (`s.f`),
which the resolver lets through for the lowering to resolve or refuse. -/
private partial def mentionsRecord (ctx : Ctx) (binders : List String := []) : List Item → Bool
  | [] => false
  | .word name _ :: rest =>
      ctx.generated.any (·.1 == name) || (ctx.word name).any (·.hasRecord) ||
        (name.splitOn ".").length > 1 && binders.contains ((name.splitOn ".").headD name) ||
        mentionsRecord ctx binders rest
  | .quotation items _ :: rest => mentionsRecord ctx binders items || mentionsRecord ctx binders rest
  | .locals names items _ :: rest =>
      mentionsRecord ctx (names.map (·.name) ++ binders) items || mentionsRecord ctx binders rest
  | _ :: rest => mentionsRecord ctx binders rest

/-- A word with its effect flattened and, when it names a record or calls a
word that does, its body lowered; and the first fault found, for which the
word is refused. A word that has nothing to do with a record keeps its body.
After the body, the stack must hold what the declared effect leaves. -/
def lowerWord (ctx : Ctx) (word : WordDefinition) : WordDefinition × Option ParseError :=
  let flat := { word with effect := flattenEffect ctx.table word.effect }
  match effectFault ctx.table word.effect with
  | some fault => (flat, some fault)
  | none =>
    let shape := effectShape ctx.table word.effect
    -- Inside a vocabulary a word finds its neighbours by their short names, so
    -- the first segment of such a name is a prefix a record local must not take.
    let scope := (word.name.splitOn ".").dropLast
    let scopeName := ".".intercalate scope
    let neighbours := if scope.isEmpty then [] else
      ctx.names.filterMap fun name =>
        if name.startsWith (scopeName ++ ".") then
          match (name.splitOn ".").drop scope.length with
          | head :: _ :: _ => some head
          | _ => none
        else none
    let ctx := { ctx with closed := (itemRows word.effect.input).isEmpty, prefixes := neighbours ++ ctx.prefixes }
    if !shape.hasRecord && !mentionsRecord ctx [] word.body then (flat, none)
    else
      let finish : SimM Unit := do
        for expected in shape.output.reverse do popExpecting ctx word.effect.span expected
      let run : Except ParseError (List Item) := do
        let (lowered, state) ← (lowerItems ctx word.body).run { stack := shape.input.reverse }
        let _ ← finish.run state
        pure lowered
      match run with
      | .ok body => ({ flat with body }, none)
      | .error fault => (flat, some fault)

end Firth.Elaborator
