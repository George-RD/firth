import elaborator.Firth.Pipeline

open Firth.Elaborator

private def check (source : String) (names : List String) : IO Unit := do
  match elaborate source with
  | .success program =>
      if program.words.map (·.name) != names then
        throw (IO.userError s!"unexpected canonical names: {repr (program.words.map (·.name))}")
  | .failure diagnostics => throw (IO.userError s!"unexpected failure: {repr diagnostics}")

private def reject (source code : String) : IO Unit := do
  match elaborate source with
  | .failure [.parse error] =>
      if error.code != code then throw (IO.userError s!"expected {code}: {repr error}")
  | result => throw (IO.userError s!"expected {code}: {repr result}")

/-- The resolver lets the source through, whatever the checker then says. -/
private def notLocalsOrder (source : String) : IO Unit := do
  match elaborate source with
  | .failure [.parse error] =>
      if error.code == "firth.name.locals-order" then
        throw (IO.userError s!"unexpected locals-order refusal: {repr error}")
  | _ => pure ()

def main : IO Unit := do
  check "vocab a { : id ( -- ) ; : call-id ( -- ) id; } : main ( -- ) a.call-id;"
    ["a.id", "a.call-id", "main"]
  check "use a as lib; : main ( -- ) lib.id; vocab a { : id ( -- ) ; }"
    ["main", "a.id"]
  check "vocab a { : id ( -- ) ; } use a; : main ( -- ) id;"
    ["a.id", "main"]
  check "vocab a { : id ( -- ) ; } vocab b { : id ( -- ) ; } : main ( -- ) a.id b.id;"
    ["a.id", "b.id", "main"]
  reject "vocab a { : id ( -- ) ; } vocab b { : id ( -- ) ; } use a; use b; : main ( -- ) id;"
    "firth.name.ambiguous-use"
  reject "vocab a { : id ( -- ) ; } use a as x; use a as x;"
    "firth.name.duplicate-alias"
  reject "vocab a { : id ( -- ) ; } use a as a;"
    "firth.name.duplicate-alias"
  reject "use absent; : main ( -- ) ;" "firth.name.unresolved"
  reject ": same ( -- ) ; : same ( -- ) ;" "firth.name.duplicate-canonical"
  reject "vocab a {} vocab a {}" "firth.name.duplicate-canonical"
  reject ": root ( -- ) ; vocab a { : caller ( -- ) root; }" "firth.name.unresolved"
  -- A reference with no candidate is refused by the resolver with the
  -- normative code, whether it is unqualified, qualified into a known
  -- vocabulary, or qualified with a prefix that names nothing.
  reject ": main ( -- ) missing;" "firth.name.unresolved"
  reject "vocab a { : id ( -- ) ; } : main ( -- ) a.missing;" "firth.name.unresolved"
  reject ": main ( -- ) zzz.foo;" "firth.name.unresolved"
  reject "vocab a { : id ( -- ) ; } use a as lib; : main ( -- ) lib.missing;" "firth.name.unresolved"
  -- A `locals` block that opens a body binds the inputs, the last name to
  -- the top; a name the stack effect gives one input may not bind another.
  -- Reversed, same-typed inputs would check and compute with each other's
  -- values, so this is the only place the mistake can be caught.
  let two := ": sub (forall ρ; ρ a:Int^many b:Int^many -- ρ r:Int^many) "
  check (two ++ "locals { a b } { b };") ["sub"]
  reject (two ++ "locals { b a } { b };") "firth.name.locals-order"
  -- A shorter block binds the top inputs: `b` is right, `a` is not.
  check (two ++ "locals { b } { drop b };") ["sub"]
  reject (two ++ "locals { a } { drop a };") "firth.name.locals-order"
  -- Names the effect does not declare are the author's to choose.
  check (two ++ "locals { x y } { y };") ["sub"]
  -- One declared name out of place among fresh ones is still refused.
  reject (two ++ "locals { x a } { a };") "firth.name.locals-order"
  -- A block that does not open the body sees another stack (here the
  -- nested one binds whatever `a b` pushed), and a block that reaches below
  -- the declared inputs is the checker's to refuse.
  check (two ++ "locals { a b } { a b locals { b a } { b } };") ["sub"]
  notLocalsOrder (two ++ "locals { q b a } { a };")
  -- Three inputs permuted, the shape the authoring eval produced.
  reject ": helper-sum (forall ρ; ρ acc:Int^many idx:Int^many xs:Seq Int^many -- ρ result:Int^many)\n  locals { xs idx acc } { acc };"
    "firth.name.locals-order"
  check ": helper-sum (forall ρ; ρ acc:Int^many idx:Int^many xs:Seq Int^many -- ρ result:Int^many)\n  locals { acc idx xs } { acc };"
    ["helper-sum"]
  IO.println "all canonical name and lexical import regressions passed"
