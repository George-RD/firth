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
  IO.println "all canonical name and lexical import regressions passed"
