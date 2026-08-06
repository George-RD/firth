import elaborator.Firth.Pipeline

open Firth.Elaborator
open Firth.Elaborator.StackEffect
private def mixedUsageConfig : PipelineConfig :=
  let signature : Signature := { input := [.linear], output := [] }
  let scheme : Scheme :=
    { rowVariables := ["ρ"]
      input := .snoc (.row (.rigid "ρ")) (.base "Int" .linear)
      output := .row (.rigid "ρ") }
  { erasureEnv :=
      { primitive := fun name =>
          if name == "consumeLinear" then some signature else none }
    typingEnv :=
      { literal := defaultLiteralType
        primitive := fun name =>
          if name == "consumeLinear" then some scheme else none } }

private def externalWordConfig : PipelineConfig :=
  let signature : Signature := { input := [], output := [] }
  let scheme : Scheme := { rowVariables := [], input := .empty, output := .empty }
  { erasureEnv :=
      { word := fun name =>
          if name == "helper" then some signature else none }
    typingEnv :=
      { literal := defaultLiteralType
        word := fun name =>
          if name == "helper" then some scheme else none } }

private def fail (message : String) : IO α := throw <| IO.userError message

private def expectTrue (condition : Bool) (message : String) : IO Unit :=
  if condition then pure () else fail message

private def expectEq [BEq α] [Repr α] (actual expected : α) (message : String) : IO Unit :=
  if actual == expected then pure ()
  else fail s!"{message}\nactual: {repr actual}\nexpected: {repr expected}"

def runPipelineTests : IO Unit := do
  match elaborate "vocab core { : id ( a:Int^many -- a:Int^many ) ; }" with
  | .success program =>
      expectEq (program.words.map (·.name)) ["id"] "vocabulary words are flattened"
      expectEq program.words.length 1 "one checked word is returned"
      match program.words with
      | [word] =>
          expectEq word.program.length 0 "empty body lowers to an empty kernel program"
          expectEq word.refinement.leanRecords.length 1
            "the refinement stage discharges the empty specification"
          expectEq word.refinement.diagnostics.length 0
            "successful refinement leaves no diagnostics"
      | _ => fail "checked word is absent"
  | .failure diagnostics => fail s!"valid source failed: {repr diagnostics}"

  match elaborate
      ": id ( forall ρ; ρ -- ρ ) ; : caller ( h:Handle^linear -- h:Handle^linear ) id ;" with
  | .success program =>
      expectEq (program.words.map (·.name)) ["id", "caller"]
        "row-polymorphic words remain usable at concrete linear stacks"
  | .failure diagnostics => fail s!"row-polymorphic word failed: {repr diagnostics}"

  match elaborateWith externalWordConfig ": caller ( -- ) helper ;" with
  | .success program =>
      expectEq (program.words.map (·.name)) ["caller"]
        "configured external words remain available to dictionary checking"
  | .failure diagnostics => fail s!"external word failed: {repr diagnostics}"

  match elaborateWith mixedUsageConfig
      ": producer ( a:Int^linear -- a:Int^linear b:Int^many ) 1 ; : discard ( x:Int^many -- ) drop ; : consume ( x:Int^linear -- ) producer swap prim consumeLinear discard ;" with
  | .success program =>
      expectEq (program.words.map (·.name)) ["producer", "discard", "consume"]
        "referenced mixed-usage outputs retain bottom-to-top source order"
  | .failure diagnostics => fail s!"mixed-usage reference failed: {repr diagnostics}"

  match elaborate ": bad ( -- ) missing ;" with
  | .failure [.erasure "bad" (.unresolvedEffect "missing" _)] => pure ()
  | result => fail s!"expected an erasure diagnostic, got {repr result}"

  match elaborate ": bad ( -- ) 1 ;" with
  | .failure [.stackEffect diagnostic] =>
      expectEq diagnostic.code "firth.type.declared-effect-mismatch"
        "stack-effect diagnostics retain the stage code"
  | result => fail s!"expected a stack-effect diagnostic, got {repr result}"

  match elaborate ":" with
  | .failure [.parse error] =>
      expectTrue (error.code.startsWith "firth.syntax") "parse diagnostic retains its syntax code"
  | result => fail s!"expected a parse diagnostic, got {repr result}"

  IO.println "pipeline tests passed"

def main : IO Unit := runPipelineTests
