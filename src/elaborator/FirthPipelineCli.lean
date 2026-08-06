import elaborator.Firth.Pipeline

open Firth.Elaborator

private def readInput : List String → IO (String × String)
  | [] => do
      let handle ← IO.getStdin
      let source ← handle.readToEnd
      pure ("<stdin>", source)
  | [path] => do
      let source ← IO.FS.readFile path
      pure (path, source)
  | _ => throw <| IO.userError "usage: firth [source-file]"

def main (args : List String) : IO Unit := do
  let (sourcePath, source) ← readInput args
  match elaborateWith { sourcePath } source with
  | .success program =>
      IO.println s!"{repr program}"
  | .failure diagnostics =>
      IO.println s!"{repr diagnostics}"
      throw <| IO.userError "elaboration failed"
