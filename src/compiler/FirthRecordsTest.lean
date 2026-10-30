import elaborator.Firth.Pipeline
import agent.Firth.Agent.ElaborateAdapter

/-!
Records (`dec.typed-records-and-variants`): what a declaration is, what a
record operation lowers to, and every refusal the surface layer adds to the
kernel's checks. The expected lowerings are written by hand from the recipes
of the decision, not produced by the code under test; each refusal is a
known-bad program, and a mutant of the lowering is shown to differ from the
hand-written text, so the comparison can fail.
-/

namespace Firth.RecordsTest

open Firth.Elaborator

private def fail (message : String) : IO α := throw <| IO.userError message

private def config : PipelineConfig :=
  { erasureEnv := Firth.Agent.Elaborate.gammaErasure, typingEnv := Firth.Agent.Elaborate.gammaTyping }

/-- The codes a file is refused with, in report order, or `[]` when it is
accepted. -/
private def codes (text : String) : List String :=
  match elaborateWith config text with
  | .success _ => []
  | .failure diagnostics => diagnostics.map fun
      | .parse error => error.code
      | .stackEffect diagnostic => diagnostic.code
      | .assumes _ _ _ (.parse error) => error.code
      -- The kernel's usage rule, which a record local's slots fall under,
      -- named by the slot it refuses.
      | .erasure _ (.linearUnused name _) => "linear-unused:" ++ name
      | .erasure _ (.linearCopy name _ _) => "linear-copy:" ++ name
      | .erasure _ (.duplicateLocal name _) => "duplicate-local:" ++ name
      | _ => "other"

private def refused (name text : String) (expected : List String) : IO Unit := do
  if codes text != expected then fail s!"{name}: refused with {codes text}, expected {expected}"

private def accepted (name text : String) : IO Unit := do
  if codes text != [] then fail s!"{name}: refused with {codes text}"

private def render : Item → String
  | .literal literal _ => match literal.value with
      | .integer value => toString value
      | .boolean value => toString value
      | _ => "literal"
  | .word name _ => name
  | .atom name _ => name
  | .primitive name _ => "prim " ++ name
  | .quotation items _ => "[ " ++ " ".intercalate (items.map render) ++ " ]"
  | .locals names items _ =>
      "locals { " ++ " ".intercalate (names.map (·.name)) ++ " } { " ++ " ".intercalate (items.map render) ++ " }"

/-- The body of `word` after lowering, rendered, for the file `text`, with
the table's generated operations replaced by `mutate`. -/
private def loweredWith (mutate : List (String × Generated) → List (String × Generated))
    (text word : String) (prefixes : List String := []) : Except String String :=
  match parse text with
  | .failure _ => .error "does not parse"
  | .success file =>
    match resolveEach file.declarations with
    | .error error => .error error.code
    | .ok (resolved, _) =>
      match checkRecords (collectRecords file.declarations) with
      | .error error => .error error.code
      | .ok table =>
        let own := resolved.map fun (entry, _) => (entry.name, effectShape table entry.effect)
        let ctx : Ctx :=
          { table, generated := mutate (generatedOperations table), prefixes
            word := fun name => own.lookup name
            primitive := primitiveShapes config }
        match resolved.find? (·.1.name == word) with
        | none => .error "no such word"
        | some (entry, _) =>
          match lowerWord ctx entry with
          | (lowered, none) => .ok (" ".intercalate (lowered.body.map render))
          | (_, some fault) => .error fault.code

private def lowered := loweredWith id

/-- A mutant of the field operations: `R.f` and `R.set-f` act on the next
field, the planted bug the hand-written lowerings must reject. -/
private def shifted : List (String × Generated) → List (String × Generated) :=
  List.map fun
    | (name, .read record index) => (name, .read record (index + 1))
    | (name, .write record index) => (name, .write record (index + 1))
    | other => other

private def stock : String :=
  "record Stock { on-hand:Int reserved:Int }\nrecord Pair { a:Int b:Int }\n"

private def expectLowering (name text word expected : String) : IO Unit := do
  match lowered text word with
  | .ok got => if got != expected then fail s!"{name}: lowered to `{got}`, expected `{expected}`"
  | .error code => fail s!"{name}: refused with {code}"

/-- The hand-written lowering must reject the mutant: under the planted bug
the same word lowers to something else. -/
private def rejectsMutant (name text word expected : String) : IO Unit := do
  match loweredWith shifted text word with
  | .ok got => if got == expected then fail s!"{name}: the mutant lowers the same way"
  | .error code => fail s!"{name}: the mutant was refused with {code}, so nothing was compared"

/-- A record local named like a qualified name's first segment is refused
only because the caller lists that segment: with the list left empty, the
planted bug, the same word lowers. -/
private def prefixCheckNeedsPrefixes (name text word : String) (prefixes : List String) : IO Unit := do
  match loweredWith id text word prefixes with
  | .error "firth.name.local-shadows-prefix" => pure ()
  | other => fail s!"{name}: with the prefixes listed, got {repr (other.toOption)} or another code"
  match loweredWith id text word [] with
  | .ok _ => pure ()
  | .error code => fail s!"{name}: without the prefixes the planted bug was still refused with {code}"

/-- A file elaborated with `lib.f` imported from another file. -/
private def importedCodes (text : String) (imported : List ImportedWord) : List String :=
  match elaborateWith { config with imported } text with
  | .success _ => []
  | .failure diagnostics => diagnostics.map fun
      | .parse error => error.code
      | _ => "other"

private def emptyEffect : StackEffect :=
  { rowBinders := [], rows := [], input := [], output := []
    span := { start := { offset := 0, line := 1, column := 1 }, stop := { offset := 0, line := 1, column := 1 } } }

def main : IO Unit := do
  -- Lowerings, from the recipes of the decision.
  expectLowering "read" (stock ++ ": f (forall ρ; ρ s:Stock -- ρ n:Int) Stock.reserved ;") "f"
    "locals { Stock.on-hand Stock.reserved } { Stock.reserved }"
  rejectsMutant "read" (stock ++ ": f (forall ρ; ρ s:Stock -- ρ n:Int) Stock.reserved ;") "f"
    "locals { Stock.on-hand Stock.reserved } { Stock.reserved }"
  expectLowering "read first" (stock ++ ": f (forall ρ; ρ s:Stock -- ρ n:Int) Stock.on-hand ;") "f"
    "locals { Stock.on-hand Stock.reserved } { Stock.on-hand }"
  rejectsMutant "read first" (stock ++ ": f (forall ρ; ρ s:Stock -- ρ n:Int) Stock.on-hand ;") "f"
    "locals { Stock.on-hand Stock.reserved } { Stock.on-hand }"
  expectLowering "set" (stock ++ ": f (forall ρ; ρ s:Stock n:Int -- ρ s:Stock) Stock.set-reserved ;") "f"
    "locals { Stock.on-hand Stock.reserved new Stock.reserved } { Stock.on-hand new Stock.reserved }"
  rejectsMutant "set" (stock ++ ": f (forall ρ; ρ s:Stock n:Int -- ρ s:Stock) Stock.set-on-hand ;") "f"
    "locals { Stock.on-hand Stock.reserved new Stock.on-hand } { new Stock.on-hand Stock.reserved }"
  expectLowering "set first" (stock ++ ": f (forall ρ; ρ s:Stock n:Int -- ρ s:Stock) Stock.set-on-hand ;") "f"
    "locals { Stock.on-hand Stock.reserved new Stock.on-hand } { new Stock.on-hand Stock.reserved }"
  expectLowering "pack and unpack emit nothing"
    (stock ++ ": f (forall ρ; ρ a:Int b:Int -- ρ a:Int b:Int) Stock.pack Stock.unpack ;") "f" ""
  expectLowering "dup" (stock ++ ": f (forall ρ; ρ s:Stock -- ρ s:Stock s:Stock) dup ;") "f"
    "locals { Stock.on-hand Stock.reserved } { Stock.on-hand Stock.reserved Stock.on-hand Stock.reserved }"
  expectLowering "drop" (stock ++ ": f (forall ρ; ρ s:Stock -- ρ) drop ;") "f" "locals { Stock.on-hand Stock.reserved } {  }"
  expectLowering "swap" (stock ++ ": f (forall ρ; ρ s:Stock n:Int -- ρ n:Int s:Stock) swap ;") "f"
    "locals { below Stock.on-hand below Stock.reserved above value } { above value below Stock.on-hand below Stock.reserved }"
  expectLowering "swap of two records"
    (stock ++ ": f (forall ρ; ρ s:Stock p:Pair -- ρ p:Pair s:Stock) swap ;") "f"
    "locals { below Stock.on-hand below Stock.reserved above Pair.a above Pair.b } { above Pair.a above Pair.b below Stock.on-hand below Stock.reserved }"
  expectLowering "dip over a record"
    (stock ++ ": f (forall ρ; ρ s:Stock -- ρ n:Int s:Stock) [ 1 ] dip ;") "f"
    "[ [ 1 ] dip ] dip"
  expectLowering "dip of a built quotation over a record"
    (stock ++ ": f (forall ρ; ρ s:Stock -- ρ n:Int s:Stock) [ 1 ] [ ] compose dip ;") "f"
    "[ 1 ] [  ] compose quote [ dip ] compose dip"
  expectLowering "dip over a three-slot record"
    ("record Tri { a:Int b:Int c:Int }\n: f (forall ρ; ρ t:Tri -- ρ n:Int t:Tri) [ 1 ] dip ;") "f"
    "[ [ [ 1 ] dip ] dip ] dip"
  expectLowering "dip over a scalar keeps the plain atom"
    (stock ++ ": f (forall ρ; ρ a:Int -- ρ n:Int a:Int) [ 1 ] dip ;") "f" "[ 1 ] dip"
  expectLowering "quote" (stock ++ ": f (forall ρ; ρ s:Stock -- ρ s:Stock) quote call ;") "f"
    "quote swap quote swap compose call"
  -- A call to a word over records needs no code.
  expectLowering "call"
    (stock ++ ": g (forall ρ; ρ s:Stock -- ρ s:Stock) ;\n: f (forall ρ; ρ s:Stock -- ρ s:Stock) g ;") "f" "g"

  -- Records accepted: nested, in vocabularies, by qualified name.
  accepted "nested" "record A { x:Int y:Int }\nrecord B { p:A z:Bool }\n: f (forall ρ; ρ b:B -- ρ x:Int) B.unpack drop A.unpack drop ;"
  accepted "vocabulary"
    "vocab inv { record Item { id:Int qty:Int } : qty (forall ρ; ρ i:Item -- ρ n:Int) inv.Item.qty ; }\n: use-it (forall ρ; ρ i:inv.Item -- ρ n:Int) inv.qty ;"
  accepted "type used after its vocabulary's use"
    "vocab inv { record Item { id:Int qty:Int } }\nuse inv;\n: f (forall ρ; ρ i:Item -- ρ n:Int) Item.id ;"

  -- Declarations: each refusal is a known-bad program.
  refused "lower-case type name" "record request { id:Int }" ["firth.type.type-name-case"]
  refused "built-in type name" "record Seq { id:Int }" ["firth.type.reserved-type-name"]
  refused "no field" "record Empty { }" ["firth.type.empty-record"]
  refused "repeated field" "record P { a:Int a:Int }" ["firth.type.duplicate-field"]
  refused "field named pack" "record P { pack:Int }" ["firth.type.reserved-field-name"]
  refused "field named unpack" "record P { unpack:Int }" ["firth.type.reserved-field-name"]
  refused "field named seq" "record P { seq:Int }" ["firth.type.reserved-field-name"]
  refused "field named set-x" "record P { set-x:Int }" ["firth.type.reserved-field-name"]
  refused "unknown member type" "record P { a:Nope }" ["firth.type.unknown-type"]
  refused "refinement on a member" "record P { a:Int{ positive a } }" ["firth.syntax.refinement-in-type"]
  refused "linear composite member" "record A { x:Int }\nrecord B { a:A^linear }" ["firth.type.linear-composite-field"]
  refused "recursive record" "record A { a:A }" ["firth.type.recursive-type"]
  refused "mutually recursive records" "record A { b:B }\nrecord B { a:A }" ["firth.type.recursive-type"]
  refused "type and word share a key" "record P { a:Int }\n: P (forall ρ; ρ -- ρ) ;" ["firth.name.duplicate-canonical"]
  refused "word named like a generated operation"
    "record P { a:Int }\nvocab P { : pack (forall ρ; ρ -- ρ) ; }" ["firth.name.duplicate-canonical"]
  refused "two types with one key" "record P { a:Int }\nrecord P { b:Int }" ["firth.name.duplicate-canonical"]
  refused "type and vocabulary share a key" "record P { a:Int }\nvocab P { }" ["firth.name.duplicate-canonical"]

  -- Uses of a record.
  refused "usage on a record" (stock ++ ": f (forall ρ; ρ s:Stock^linear -- ρ) drop ;") ["firth.type.composite-usage"]
  refused "refinement on a record" (stock ++ ": f (forall ρ; ρ s:Stock{ positive s } -- ρ) drop ;")
    ["firth.syntax.refinement-in-type"]
  refused "other record where a record is wanted"
    (stock ++ ": f (forall ρ; ρ p:Pair -- ρ n:Int) Stock.reserved ;") ["firth.type.mismatch"]
  refused "record where a value is wanted"
    (stock ++ ": f (forall ρ; ρ s:Stock -- ρ n:Int) 1 prim + ;") ["firth.type.mismatch"]
  refused "value where a record is wanted"
    (stock ++ ": f (forall ρ; ρ n:Int m:Int -- ρ s:Stock) ;") ["firth.type.mismatch"]
  refused "packing the wrong members"
    (stock ++ ": f (forall ρ; ρ n:Int -- ρ s:Stock) Pair.pack ;") ["firth.type.mismatch"]
  -- Pack and unpack erase to nothing, so the field types are checked here.
  refused "a Bool packed into an Int field, then unpacked"
    ("record R { x:Int }\n: f (forall ρ; ρ b:Bool -- ρ b:Bool) R.pack R.unpack ;") ["firth.type.mismatch"]
  refused "a Bool literal packed into an Int field"
    ("record R { x:Int }\n: f (forall ρ; ρ -- ρ r:R) true R.pack ;") ["firth.type.mismatch"]
  refused "a Bool field unpacked into an Int field"
    ("record R { x:Int }\nrecord Q { b:Bool }\n: f (forall ρ; ρ q:Q -- ρ r:R) Q.unpack R.pack ;")
    ["firth.type.mismatch"]
  refused "a pack and unpack that the closed effect gives no value for"
    ("record R { x:Int }\n: f ( -- ) R.pack R.unpack ;") ["firth.type.mismatch"]
  refused "an unpack that the closed effect gives no record for"
    ("record R { x:Int }\n: f ( -- n:Int ) R.unpack ;") ["firth.type.mismatch"]
  accepted "an Int packed into an Int field, then unpacked"
    ("record R { x:Int }\n: f (forall ρ; ρ n:Int -- ρ n:Int) R.pack R.unpack ;")
  refused "branches that leave different records"
    (stock ++ ": f (forall ρ; ρ b:Bool -- ρ s:Stock) [ 1 2 Stock.pack ] [ 1 2 Pair.pack ] if ;")
    ["firth.type.mismatch"]
  refused "branches that build quotations of different records"
    ("record A { x:Int }\nrecord B { x:Int }\n: f (forall ρ; ρ b:Bool -- ρ a:A) [ [ 1 A.pack ] ] [ [ 2 B.pack ] ] if call ;")
    ["firth.type.mismatch"]
  accepted "branches that build quotations of one record"
    ("record A { x:Int }\n: f (forall ρ; ρ b:Bool -- ρ a:A) [ [ 1 A.pack ] ] [ [ 2 A.pack ] ] if call ;")
  refused "a record read inside a quotation"
    (stock ++ ": f (forall ρ; ρ s:Stock -- ρ n:Int) [ Stock.reserved ] call ;") ["firth.type.composite-in-quotation"]
  refused "a record passed through a quotation that takes it"
    (stock ++ ": f (forall ρ; ρ s:Stock -- ρ s:Stock s:Stock) [ dup ] call ;") ["firth.type.composite-in-quotation"]
  refused "a quotation of unknown effect over a record"
    (stock ++ ": f (forall ρ; ρ s:Stock -- ρ s:Stock) [ call ] call ;") ["firth.type.untracked-quotation"]
  refused "a field read that drops a linear slot"
    "record Box { h:Handle^linear n:Int }\n: f (forall ρ; ρ b:Box -- ρ n:Int) Box.n ;" ["firth.type.record-drop-linear"]
  refused "a field write that drops a linear slot"
    "record Box { h:Handle^linear n:Int }\n: f (forall ρ; ρ b:Box h:Handle^linear -- ρ b:Box) Box.set-h ;" ["firth.type.record-drop-linear"]
  refused "a linear slot dropped whole" "record Box { h:Handle^linear n:Int }\n: f (forall ρ; ρ b:Box -- ρ) drop ;" ["firth.type.record-drop-linear"]
  refused "a linear slot copied whole" "record Box { h:Handle^linear n:Int }\n: f (forall ρ; ρ b:Box -- ρ b:Box b:Box) dup ;" ["firth.type.record-copy-linear"]
  accepted "a linear slot moved whole" "record Box { h:Handle^linear n:Int }\n: f (forall ρ; ρ b:Box n:Int -- ρ n:Int b:Box) swap ;"
  -- Record locals: a record binds one local per flat slot, named by path.
  expectLowering "record local, whole"
    (stock ++ ": f (forall ρ; ρ s:Stock -- ρ s:Stock s:Stock) locals { s } { s s } ;") "f"
    "locals { s.on-hand s.reserved } { s.on-hand s.reserved s.on-hand s.reserved }"
  expectLowering "record local, field"
    (stock ++ ": f (forall ρ; ρ s:Stock -- ρ n:Int) locals { s } { s.reserved } ;") "f"
    "locals { s.on-hand s.reserved } { s.reserved }"
  expectLowering "record local beside a scalar"
    (stock ++ ": f (forall ρ; ρ n:Int s:Stock -- ρ m:Int) locals { n s } { s.on-hand n prim + } ;") "f"
    "locals { n s.on-hand s.reserved } { s.on-hand n prim + }"
  expectLowering "nested record local, inner record whole"
    (stock ++ "record Order { request:Pair price:Int }\n: f (forall ρ; ρ o:Order -- ρ p:Pair) locals { o } { o.request } ;") "f"
    "locals { o.request.a o.request.b o.price } { o.request.a o.request.b }"
  accepted "nested record local, inner record rebuilt and checked by name"
    (stock ++ "record Order { request:Pair price:Int }\n: f (forall ρ; ρ o:Order -- ρ p:Pair) locals { o } { o.request } ;")
  refused "a nested record local read as the wrong record"
    (stock ++ "record Order { request:Pair price:Int }\n: f (forall ρ; ρ o:Order -- ρ n:Int) locals { o } { o.request Stock.reserved } ;")
    ["firth.type.mismatch"]
  refused "a record local read as the wrong record"
    (stock ++ ": f (forall ρ; ρ p:Pair -- ρ n:Int) locals { p } { p Stock.reserved } ;") ["firth.type.mismatch"]
  refused "a field of a record local that does not exist"
    (stock ++ ": f (forall ρ; ρ s:Stock -- ρ n:Int) locals { s } { s.free } ;") ["firth.name.unresolved"]
  refused "a field of a scalar local"
    (stock ++ ": f (forall ρ; ρ n:Int -- ρ m:Int) locals { n } { n.free } ;") ["firth.name.unresolved"]
  refused "a record local that shadows a vocabulary"
    (stock ++ "vocab s { : f (forall ρ; ρ -- ρ) ; }\n: g (forall ρ; ρ s:Stock -- ρ n:Int) locals { s } { s.reserved } ;")
    ["firth.name.local-shadows-prefix"]
  prefixCheckNeedsPrefixes "shadow check reads the prefixes"
    (stock ++ ": g (forall ρ; ρ s:Stock -- ρ n:Int) locals { s } { s.reserved } ;") "g" ["s"]
  refused "a record local that shadows a use alias, nested in a vocabulary"
    (stock ++ "vocab a { : f (forall ρ; ρ -- ρ) ; }\nvocab b { use a as s; : g (forall ρ; ρ s:Stock -- ρ n:Int) locals { s } { s.reserved } ; }")
    ["firth.name.local-shadows-prefix"]
  accepted "a scalar local beside a vocabulary of the same name keeps its resolved call"
    ("record R { x:Int }\nvocab s { : f (forall ρ; ρ -- ρ n:Int) 1 ; }\n: g (forall ρ; ρ s:Int -- ρ n:Int) locals { s } { s.f } ;")
  accepted "a resolved call beside a scalar local does not send a scalar body through record lowering"
    ("record R { x:Int }\nvocab s { : f (forall ρ; ρ -- ρ) ; }\n: g (forall ρ; ρ n:Int -- ρ m:Int) locals { s } { s.f } [ 1 ] [ call ] call ;")
  refused "a record local rebound hides the outer record's fields"
    ("record A { x:Int }\nrecord B { y:Int }\n: g (forall ρ; ρ a:A -- ρ n:Int) locals { r } { 1 B.pack locals { r } { r.x } } ;")
    ["firth.name.unresolved"]
  refused "a record local rebound to a scalar hides the outer record's fields"
    ("record A { x:Int }\n: g (forall ρ; ρ a:A -- ρ n:Int) locals { r } { 1 locals { r } { r.x } } ;")
    ["firth.name.unresolved"]
  refused "a record local that shadows a record's short name in its vocabulary"
    "vocab v { record R { x:Int } : f (forall ρ; ρ a:R b:R -- ρ n:Int) locals { R } { R.x } ; }"
    ["firth.name.local-shadows-prefix"]
  refused "one name bound twice over records with different fields"
    ("record A { x:Int }\nrecord B { y:Int }\n: f (forall ρ; ρ a:A b:B -- ρ n:Int) locals { r r } { r.x r.y prim + } ;")
    ["duplicate-local:r"]
  refused "a record local named like a record type"
    ("record Stock { on-hand:Int reserved:Int }\n: f (forall ρ; ρ Stock:Stock -- ρ m:Int) locals { Stock } { Stock.on-hand } ;")
    ["firth.name.local-shadows-prefix"]
  -- The imported vocabulary's name is a prefix only because the import lists it:
  -- the same file with no import is accepted, the planted bug.
  let importedLocal := stock ++ ": g (forall ρ; ρ lib:Stock -- ρ n:Int) locals { lib } { lib.reserved } ;"
  let libWord : ImportedWord := { name := "lib.f", effect := emptyEffect, exported := true, source := "lib.firth" }
  if importedCodes importedLocal [libWord] != ["firth.name.local-shadows-prefix"] then
    fail s!"a record local named like an imported vocabulary: got {importedCodes importedLocal [libWord]}"
  if importedCodes importedLocal [] != [] then
    fail s!"a record local with no import of that name: got {importedCodes importedLocal []}"
  refused "an opening block that swaps a scalar and a record input"
    ("record R { x:Int }\n: f (forall ρ; ρ n:Int r:R -- ρ m:Int) locals { r n } { r } ;")
    ["firth.name.locals-order"]
  -- The neutral report: no edit is stated as checked for a word with records.
  let swapped := "record R { x:Int }\n: f (forall ρ; ρ n:Int r:R -- ρ m:Int) locals { r n } { r } ;"
  match elaborateWith config swapped with
  | .failure [.parse error] =>
      if error.localsBlocks.isEmpty || error.localsBlocks.any (·.checked) then
        fail "the locals-order report on a word with records states a checked edit"
  | _ => fail "the swapped opening block was not refused with one parse error"
  accepted "an opening block over a scalar and a record input in order"
    ("record R { x:Int }\n: f (forall ρ; ρ n:Int r:R -- ρ m:Int) locals { n r } { r.x } ;")
  accepted "a record local over a linear field, each linear slot used once"
    "record Box { h:Handle^linear n:Int }\n: f (forall ρ; ρ b:Box -- ρ h:Handle^linear n:Int) locals { b } { b.h b.n } ;"
  refused "a record local over a linear field left unused"
    "record Box { h:Handle^linear n:Int }\n: f (forall ρ; ρ b:Box -- ρ n:Int) locals { b } { b.n } ;" ["linear-unused:b.h"]
  refused "a record local over a linear field used twice"
    "record Box { h:Handle^linear n:Int }\n: f (forall ρ; ρ b:Box -- ρ h:Handle^linear h:Handle^linear n:Int) locals { b } { b.h b.h b.n } ;" ["linear-copy:b.h"]

  refused "export of a record (until types can be imported)" "record P { a:Int }\nexport P;"
    ["firth.name.export-type-unsupported"]
  refused "export of a word that takes a record"
    "export qty-of;\nrecord Request { id:Int qty:Int }\n: qty-of (forall ρ; ρ r:Request -- ρ n:Int) Request.qty ;"
    ["firth.name.export-type-unsupported"]
  refused "export of a word that leaves a record"
    "export make;\nrecord Request { id:Int qty:Int }\n: make (forall ρ; ρ id:Int qty:Int -- ρ r:Request) Request.pack ;"
    ["firth.name.export-type-unsupported"]
  accepted "export of a word over the fields of a record"
    "export qty-of;\nrecord Request { id:Int qty:Int }\n: qty-of (forall ρ; ρ id:Int qty:Int -- ρ n:Int) Request.pack Request.qty ;"
  accepted "a word that takes a record, not exported"
    "record Request { id:Int qty:Int }\n: qty-of (forall ρ; ρ r:Request -- ρ n:Int) Request.qty ;"
  -- `record` and `match` are ordinary names where no declaration may stand.
  accepted "a word named record"
    ": record (forall ρ; ρ -- ρ) ;\n: match (forall ρ; ρ -- ρ) ;\n: f (forall ρ; ρ -- ρ) record match ;"
  accepted "a word named record beside a record"
    "record P { a:Int }\n: record (forall ρ; ρ a:Int -- ρ p:P) P.pack ;"

  -- Words that mention no record are untouched.
  accepted "plain word beside records" (stock ++ ": f (forall ρ; ρ a:Int -- ρ b:Int) dup prim + ;")
  -- A declared scalar of the wrong type is refused at the pack, and so is the
  -- result of a primitive or a value read from a local.
  refused "wrong base type in a field"
    (stock ++ ": f (forall ρ; ρ b:Bool n:Int -- ρ s:Stock) Stock.pack ;") ["firth.type.mismatch"]
  refused "a primitive's Bool result packed into an Int field"
    (stock ++ ": f (forall ρ; ρ a:Int b:Int -- ρ s:Stock) prim < 1 Stock.pack ;")
    ["firth.type.mismatch"]
  refused "a Bool local packed into an Int field"
    ("record R { x:Int }\n: f (forall ρ; ρ b:Bool -- ρ r:R) locals { b } { b R.pack } ;")
    ["firth.type.mismatch"]
  accepted "an Int local packed into an Int field"
    ("record R { x:Int }\n: f (forall ρ; ρ n:Int -- ρ r:R) locals { n } { n R.pack } ;")
  accepted "a primitive's Int result packed into an Int field"
    (stock ++ ": f (forall ρ; ρ a:Int b:Int -- ρ s:Stock) prim + 1 Stock.pack ;")
  IO.println "records: ok"

end Firth.RecordsTest

def main : IO Unit := Firth.RecordsTest.main
