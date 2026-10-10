import Lean.Data.Json
import elaborator.Firth.Imports
import agent.Firth.Agent.JsonMembers

/-!
The source loader (`lake exe firthSources`): reads a program's root file and
every file it imports, transitively, from a directory on disk, and returns
them as the source part of a `firth.source.v1` request (`source_path`,
`source_text` and `files`). The elaborator itself never reads the file system
(`dec.multi-file-imports`).

Request: `{"request_id", "source_root", "source_path"}`, where `source_root`
is a directory and `source_path` the root file's path relative to it,
normalised. Imports are found with the elaborator's own parser and path rules
(`Firth.Elaborator.loadProgram`), so the loader and the checker cannot
disagree on which files a program has. An import naming no file on disk is
left out, and the elaborator reports it as `firth.name.import-not-found`. A
file whose real path is outside the source root, through a symbolic link for
example, or that is not UTF-8, is an error.
-/

namespace Firth.Agent.Sources

open Lean
open Firth.Elaborator

private def quote (value : String) : String := (Json.str value).compress

private def obj (values : List (String × String)) : String :=
  "{" ++ ",".intercalate (values.map fun (key, value) => quote key ++ ":" ++ value) ++ "}"

private def arr (values : List String) : String := "[" ++ ",".intercalate values ++ "]"

private def str (values : List (String × Json)) (name : String) : Except String String :=
  match values.find? (·.1 == name) with
  | some (_, .str value) => if value.isEmpty then .error s!"request.{name}: empty string" else pure value
  | some _ => .error s!"request.{name}: expected string"
  | none => .error s!"request: missing {name}"

/-- Reads the file at `path`, relative to the source root whose real path is
`root`, or `none` when there is no such file. -/
private def readSource (root path : String) : IO (Option String) := do
  let rootPrefix := if root.endsWith "/" then root else root ++ "/"
  let full : System.FilePath := rootPrefix ++ path
  if !(← full.pathExists) then return none
  let real ← IO.FS.realPath full
  if !real.toString.startsWith rootPrefix then
    throw <| IO.userError s!"{path} is outside the source root"
  if (← real.isDir) then return none
  match String.fromUTF8? (← IO.FS.readBinFile real) with
  | some text => return some text
  | none => throw <| IO.userError s!"{path} is not UTF-8"

/-- The root file and the files it imports, in load order without the root.
Imports resolve against the root's path, so a root that imports a file must
have a normalised relative path; one that imports nothing may have any name
inside the source root, such as `my program.firth`. -/
def load (sourceRoot sourcePath : String) : IO (Source × List Source) := do
  let root := (← IO.FS.realPath sourceRoot).toString
  if !(← System.FilePath.isDir root) then throw <| IO.userError "source_root is not a directory"
  let some text ← readSource root sourcePath
    | throw <| IO.userError s!"{sourcePath} does not exist"
  let main : Source := { path := sourcePath, text }
  if !normalisedPath sourcePath then
    let imports := (loadProgram main []).any fun file =>
      file.source.path == sourcePath &&
        (file.declarations.getD []).any (· matches .import _)
    if imports then
      throw <| IO.userError s!"source_path {sourcePath} imports files, so it must be a normalised relative .firth path"
    return (main, [])
  -- Load what is known, read every import that was not found, and repeat
  -- until a round finds no new file.
  let mut files : List Source := []
  let mut absent : List String := []
  repeat
    let wanted := ((loadProgram main files).flatMap (·.errors)).filterMap fun error =>
      if error.code == "firth.name.import-not-found" then error.files.head? else none
    let fresh := wanted.eraseDups.filter (!absent.contains ·)
    if fresh.isEmpty then break
    for path in fresh do
      match ← readSource root path with
      | some text => files := files ++ [{ path, text }]
      | none => absent := absent ++ [path]
  let order := (loadProgram main files).map (·.source)
  pure (main, order.filter (·.path != sourcePath))

def runRequest (input : String) : IO String := do
  match Firth.Agent.rejectDuplicateMembers input with
  | .ok () => pure ()
  | .error _ => throw <| IO.userError "duplicate or malformed JSON member"
  let json ← IO.ofExcept (Json.parse input)
  let values ← match json with
    | .obj values => pure values.toList
    | _ => throw <| IO.userError "request: expected object"
  if values.any (fun (key, _) => !["request_id", "source_root", "source_path"].contains key) then
    throw <| IO.userError "request: unknown member"
  let requestId ← IO.ofExcept (str values "request_id")
  let (main, files) ← load (← IO.ofExcept (str values "source_root")) (← IO.ofExcept (str values "source_path"))
  pure (obj [("request_id", quote requestId), ("status", quote "success"),
    ("source_path", quote main.path), ("source_text", quote main.text),
    ("files", arr (files.map fun file =>
      obj [("source_path", quote file.path), ("source_text", quote file.text)]))])

/-- One request on stdin, one response on stdout; an error is reported as
`{"status": "error", "error": ...}` on stderr with exit status 1. -/
def main (args : List String) : IO UInt32 := do
  if !args.isEmpty then
    IO.eprintln "firthSources accepts stdin JSON only"
    return 2
  let input ← (← IO.getStdin).readToEnd
  try
    IO.println (← runRequest input)
    return 0
  catch error =>
    IO.eprintln (obj [("status", quote "error"), ("error", quote (toString error))])
    return 1

end Firth.Agent.Sources
