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
    (text word : String) : Except String String :=
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
          { table, generated := mutate (generatedOperations table)
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
  refused "locals over a record (not yet)"
    (stock ++ ": f (forall ρ; ρ s:Stock -- ρ n:Int) locals { s } { 1 } ;") ["firth.type.locals-record-unsupported"]

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
  -- An alias equal to a record's name would turn `R.pack` into another word.
  refused "alias equal to a record name"
    "vocab helper { : pack ( forall ρ; ρ -- ρ ) ; : unpack ( forall ρ; ρ -- ρ ) ; }\nrecord R { x:Int }\nuse helper as R;"
    ["firth.name.duplicate-alias"]
  refused "alias equal to a record name declared later"
    "vocab helper { : pack ( forall ρ; ρ -- ρ ) ; : unpack ( forall ρ; ρ -- ρ ) ; }\nuse helper as R;\nrecord R { x:Int }"
    ["firth.name.duplicate-alias"]
  refused "alias equal to a record name inside a vocabulary"
    "vocab helper { : pack ( forall ρ; ρ -- ρ ) ; : unpack ( forall ρ; ρ -- ρ ) ; }\nvocab app {\n  record R { x:Int }\n  use helper as R;\n}"
    ["firth.name.duplicate-alias"]
  accepted "alias that is not a record name"
    "vocab helper { : pack ( forall ρ; ρ -- ρ ) ; : unpack ( forall ρ; ρ -- ρ ) ; }\nrecord R { x:Int }\nuse helper as h;"
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
