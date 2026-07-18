import Firth

namespace Firth.Interpreter

def one (atom : Atom) : Program := .cons atom .empty

def renderValue : Value → String
  | .literal (.nat value) => s!"{value}"
  | .literal (.bool value) => if value then "true" else "false"
  | .literal .unit => "unit"
  | .quotation _ usage => if usage == .many then "quotation-many" else "quotation-linear"
  | .world _ => "world"

def renderStack (stack : Stack) : String :=
  String.intercalate "," (stack.reverse.map renderValue)

mutual
def renderAtom : Atom → String
  | .lit (.nat value) => s!"pushi:{value}"
  | .lit (.bool value) => s!"pushb:{value}"
  | .lit .unit => "pushu"
  | .push value => s!"pushv:{renderValue value}"
  | .quotation body => s!"pushq:{renderProgram body}"
  | .dup => "dup"
  | .drop => "drop"
  | .swap => "swap"
  | .dip => "dip"
  | .call => "call"
  | .compose => "compose"
  | .quote => "quote"
  | .ifThenElse => "if"
  | .word name => s!"word:{name}"
  | .prim primitive => s!"prim:{repr primitive}"

def renderProgram : Program → String
  | .empty => ""
  | .cons head tail =>
      let rest := renderProgram tail
      if rest.isEmpty then renderAtom head else s!"{renderAtom head},{rest}"
end

def renderResidualFrame (config : Config) : String :=
  if config.program == .empty then "-" else "main@0"

def emit (name dictionary targetCost : String) (dictionaryValue : Dictionary) (config : Config) : IO Unit := do
  let initial := renderStack config.stack
  let code := renderProgram config.program
  match run defaultGamma dictionaryValue defaultCosts 64 config with
  | .terminal final _ cost =>
      IO.println s!"{name}|{initial}|{dictionary}|{code}|terminal|{renderStack final.stack}|{cost}|-|{targetCost}"
  | .stuck stuck _ cost =>
      IO.println s!"{name}|{initial}|{dictionary}|{code}|stuck|{renderStack stuck.stack}|{cost}|{renderResidualFrame stuck}|{targetCost}"
  | .outOfFuel last _ cost =>
      IO.println s!"{name}|{initial}|{dictionary}|{code}|fuel|{renderStack last.stack}|{cost}|-|{targetCost}"

def wordDictionary : Dictionary := fun name =>
  if name == "one" then
    some { type := { rowVariables := ["ρ"], input := .row "ρ", output := .snoc (.row "ρ") (.base .nat .many) }, body := one (.lit (.nat 1)) }
  else none

def main : IO Unit := do
  emit "dup" "-" "1" emptyDictionary
    { stack := [.literal (.nat 7)], program := one .dup }
  emit "drop" "-" "1" emptyDictionary
    { stack := [.literal (.nat 7)], program := one .drop }
  emit "drop-fault" "-" "0" emptyDictionary
    { stack := [], program := one .drop }
  emit "swap" "-" "1" emptyDictionary
    { stack := [.literal (.nat 2), .literal (.nat 1)], program := one .swap }
  emit "dip" "-" "4" emptyDictionary
    { stack := [], program := .cons (.lit (.nat 4))
        (.cons (.quotation (one (.lit (.nat 5)))) (one .dip)) }
  emit "call" "-" "3" emptyDictionary
    { stack := [], program := .cons (.quotation (one (.lit (.nat 9)))) (one .call) }
  emit "compose" "-" "6" emptyDictionary
    { stack := [], program := .cons (.quotation (one (.lit (.nat 1))))
        (.cons (.quotation (one (.lit (.nat 2))))
          (.cons .compose (one .call))) }
  emit "quote" "-" "1" emptyDictionary
    { stack := [.literal (.nat 7)], program := one .quote }
  emit "if-true" "-" "5" emptyDictionary
    { stack := [], program := .cons (.lit (.bool true))
        (.cons (.quotation (one (.lit (.nat 1))))
          (.cons (.quotation (one (.lit (.nat 2)))) (one .ifThenElse))) }
  emit "if-false" "-" "5" emptyDictionary
    { stack := [], program := .cons (.lit (.bool false))
        (.cons (.quotation (one (.lit (.nat 1))))
          (.cons (.quotation (one (.lit (.nat 2)))) (one .ifThenElse))) }
  emit "word" "one=pushi:1" "3" wordDictionary
    { stack := [], program := one (.word "one") }
  emit "addNat" "-" "3" emptyDictionary
    { stack := [], program := .cons (.lit (.nat 3))
        (.cons (.lit (.nat 4)) (one (.prim "addNat"))) }
  emit "world" "-" "2" emptyDictionary
    { stack := [], program := .cons (.prim "makeWorld") (one (.prim "consumeWorld")) }

end Firth.Interpreter

def main : IO Unit := Firth.Interpreter.main
