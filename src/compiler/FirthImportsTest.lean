import elaborator.Firth.Imports
import compiler.Firth.Compile
import agent.Firth.Agent.Sources
import compiler.Firth.ExportLean

/-!
Programs of several files (`dec.multi-file-imports`): load order, name
resolution across files, every import error, checking against imported
effects, the elaborate adapter's `files` and `sources`, and the compiler's
source binding of imported files. Each refusal below is a known-bad program
the import checks must reject.
-/

namespace Firth.ImportsTest

open Firth.Elaborator

private def fail (message : String) : IO α := throw <| IO.userError message

private def src (path text : String) : Source := { path, text }

/-- The program whose root is `root`, checked file by file with the pipeline. -/
private def program (root : Source) (files : List Source) :
    Except (List (String × PipelineDiagnostic)) (List (Source × CheckedProgram)) :=
  elaborateProgram
    (fun source imported =>
      let config : PipelineConfig := { erasureEnv := Firth.Agent.Elaborate.gammaErasure
                                       typingEnv := Firth.Agent.Elaborate.gammaTyping
                                       sourcePath := source.path, imported }
      match elaborateWith config source.text with
      | .success program => .ok program
      | .failure diagnostics => .error (diagnostics.map (source.path, ·)))
    (fun source error => (source.path, .parse error)) root files

private def accept (name : String) (root : Source) (files : List Source)
    (expected : List (String × List String)) : IO Unit := do
  match program root files with
  | .ok programs =>
      let got := programs.map fun (source, program) => (source.path, program.words.map (·.name))
      if got != expected then fail s!"{name}: files and words {repr got}, expected {repr expected}"
  | .error diagnostics => fail s!"{name}: refused {repr diagnostics}"

/-- The code, file and other files of a parse-stage report. -/
private def summary : String × PipelineDiagnostic → String × String × List String
  | (path, .parse error) => (error.code, path, error.files)
  | (path, other) => (s!"{repr other}", path, [])

private def reject (name : String) (root : Source) (files : List Source)
    (expected : List (String × String × List String)) : IO Unit := do
  match program root files with
  | .ok _ => fail s!"{name}: accepted"
  | .error diagnostics =>
      let got := diagnostics.map summary
      if got != expected then fail s!"{name}: reports {repr got}, expected {repr expected}"

/-- Some report of `diagnostics` in `path` is not a parse-stage one: the
checker, not name resolution, refused that file. -/
private def checkerRefused (name path : String) (root : Source) (files : List Source) : IO Unit := do
  match program root files with
  | .ok _ => fail s!"{name}: accepted"
  | .error diagnostics =>
      if !diagnostics.any fun (file, diagnostic) =>
          file == path && !(diagnostic matches .parse _) then
        fail s!"{name}: no checker report in {path}: {repr diagnostics}"

private def lib : Source := src "lib.firth" "export double;
: double (forall ρ; ρ n:Int^many -- ρ m:Int^many) dup prim +;
: helper (forall ρ; ρ n:Int^many -- ρ m:Int^many) 1 prim +;"

private def main₀ (body : String) : Source :=
  src "main.firth" ("import \"lib.firth\";\n: main ( -- r:Int^many ) " ++ body ++ ";")

/-- An elaborate request for `root` with `files`. -/
private def elaborateRequest (root : Source) (files : List Source) : String :=
  let file (source : Source) : String :=
    "{\"source_path\":" ++ (Lean.Json.str source.path).compress ++ ",\"source_text\":"
      ++ (Lean.Json.str source.text).compress ++ "}"
  "{\"request_id\":\"r1\",\"source_path\":" ++ (Lean.Json.str root.path).compress
    ++ ",\"source_text\":" ++ (Lean.Json.str root.text).compress
    ++ ",\"files\":[" ++ ",".intercalate (files.map file) ++ "]"
    ++ ",\"language_version\":\"0.1\",\"gamma_version\":\"0.8\"}"

private def elaborateJson (root : Source) (files : List Source) : IO (List (String × Lean.Json)) := do
  match Firth.Agent.Elaborate.runRequest (elaborateRequest root files) with
  | .error error => fail s!"elaborate: {error}"
  | .ok output => match Lean.Json.parse output with
    | .ok (.obj values) => pure values.toList
    | _ => fail s!"elaborate: not an object: {output}"

private def member (values : List (String × Lean.Json)) (name : String) : IO Lean.Json :=
  match values.find? (·.1 == name) with
  | some (_, value) => pure value
  | none => fail s!"missing {name}"

/-- The compile response for `entry` of the program, bound to `boundFiles`
as its source's imported files. -/
private def compileWith (root : Source) (files boundFiles : List Source) (entry : String) :
    IO (Except String (List (String × Lean.Json))) := do
  let elaboration ← elaborateJson root files
  let file (source : Source) : String :=
    "{\"source_path\":" ++ (Lean.Json.str source.path).compress ++ ",\"source_text\":"
      ++ (Lean.Json.str source.text).compress ++ "}"
  let request := "{\"request_id\":\"r1\",\"entry\":" ++ (Lean.Json.str entry).compress
    ++ ",\"checked_words\":" ++ (← member elaboration "checked_words").compress
    ++ ",\"erased_word_types\":" ++ (← member elaboration "erased_word_types").compress
    ++ ",\"gamma_version\":\"0.8\",\"target_version\":\"0.1\",\"source\":{\"source_path\":"
    ++ (Lean.Json.str root.path).compress ++ ",\"source_text\":" ++ (Lean.Json.str root.text).compress
    ++ ",\"files\":[" ++ ",".intercalate (boundFiles.map file) ++ "],\"language_version\":\"0.1\"}}"
  match Firth.Compiler.Compile.runRequest request with
  | .error error => pure (.error error)
  | .ok output => match Lean.Json.parse output with
    | .ok (.obj values) => pure (.ok values.toList)
    | _ => fail s!"compile: not an object: {output}"

def main : IO Unit := do
  -- Paths: relative to the importing file's directory, inside the root.
  let paths := [("main.firth", "lib.firth", some "lib.firth"),
    ("app/main.firth", "../lib.firth", some "lib.firth"),
    ("app/main.firth", "./util/x.firth", some "app/util/x.firth"),
    ("app/main.firth", "../../lib.firth", none), ("main.firth", "/lib.firth", none),
    ("main.firth", "lib.txt", none), ("main.firth", "a//lib.firth", none),
    ("main.firth", "a\\lib.firth", none), ("main.firth", ".firth", none),
    ("main.firth", "lib .firth", none)]
  for (importer, target, expected) in paths do
    if resolveImportPath importer target != expected then
      fail s!"resolveImportPath {importer} {target}: {repr (resolveImportPath importer target)}"

  -- An imported word is checked against, and named by, its own file's key.
  accept "import" (main₀ "2 double") [lib]
    [("lib.firth", ["double", "helper"]), ("main.firth", ["main"])]
  -- Files the program does not import are left out.
  accept "unused file" (main₀ "2 double") [lib, src "other.firth" ": other ( -- ) ;"]
    [("lib.firth", ["double", "helper"]), ("main.firth", ["main"])]
  -- The importer is checked against the imported effect: `double` leaves an
  -- Int, so treating its result as a Bool is a type error in main.
  checkerRefused "imported effect" "main.firth" (main₀ "2 double [ 1 ] [ 2 ] if") [lib]
  -- Words an import defines but does not export are not visible.
  reject "not exported" (main₀ "2 helper") [lib] [("firth.name.not-exported", "main.firth", ["lib.firth"])]
  -- Exports name words of their own file, once.
  let badExport := src "lib.firth" "export missing; : w ( -- ) ;"
  reject "unresolved export" (main₀ "1") [badExport]
    [("firth.name.unresolved", "lib.firth", []), ("firth.name.import-failed", "main.firth", ["lib.firth"])]
  -- An importer of a refused file is not checked, even for a key it shares with that file.
  reject "refused import before its collision" (src "main.firth" "import \"lib.firth\"; : w ( -- ) ;") [badExport]
    [("firth.name.unresolved", "lib.firth", []), ("firth.name.import-failed", "main.firth", ["lib.firth"])]
  -- A file with a bad import still reports a collision among the files it did load.
  reject "bad import beside a collision"
    (src "main.firth" "import \"lib.firth\"; import \"absent.firth\"; : double ( -- ) ;") [lib]
    [("firth.name.import-not-found", "main.firth", ["absent.firth"]),
     ("firth.name.duplicate-canonical", "main.firth", ["lib.firth"])]
  reject "duplicate export" (src "main.firth" "export w w; : w ( -- ) ;") []
    [("firth.name.duplicate-export", "main.firth", [])]
  -- Import errors, each at its import.
  reject "not found" (main₀ "1") [] [("firth.name.import-not-found", "main.firth", ["lib.firth"])]
  reject "bad path" (src "main.firth" "import \"../lib.firth\"; : main ( -- ) ;") [lib]
    [("firth.name.import-path", "main.firth", [])]
  reject "duplicate import" (src "main.firth" "import \"lib.firth\"; import \"./lib.firth\"; : main ( -- ) ;") [lib]
    [("firth.name.duplicate-import", "main.firth", ["lib.firth"])]
  -- A repeat is a duplicate even when the first import named a missing file
  -- or closed a cycle.
  reject "duplicate missing import" (src "main.firth" "import \"gone.firth\"; import \"./gone.firth\"; : main ( -- ) ;") []
    [("firth.name.import-not-found", "main.firth", ["gone.firth"]),
     ("firth.name.duplicate-import", "main.firth", ["gone.firth"])]
  reject "duplicate self import" (src "main.firth" "import \"main.firth\"; import \"main.firth\"; : main ( -- ) ;") []
    [("firth.name.import-cycle", "main.firth", ["main.firth", "main.firth"]),
     ("firth.name.duplicate-import", "main.firth", ["main.firth"])]
  reject "self import" (src "main.firth" "import \"main.firth\"; : main ( -- ) ;") []
    [("firth.name.import-cycle", "main.firth", ["main.firth", "main.firth"])]
  let a := src "a.firth" "import \"b.firth\"; export a; : a ( -- ) ;"
  let b := src "b.firth" "import \"a.firth\"; export b; : b ( -- ) ;"
  reject "cycle" a [b]
    [("firth.name.import-cycle", "b.firth", ["a.firth", "b.firth", "a.firth"]),
     ("firth.name.import-failed", "a.firth", ["b.firth"])]
  -- `import` opens the file; `export` stays out of vocabularies.
  reject "import after a word" (src "main.firth" ": w ( -- ) ; import \"lib.firth\";") [lib]
    [("firth.syntax.misplaced-import", "main.firth", [])]
  reject "import in a vocabulary" (src "main.firth" "vocab v { import \"lib.firth\"; }") [lib]
    [("firth.syntax.misplaced-import", "main.firth", [])]
  reject "export in a vocabulary" (src "main.firth" "vocab v { : w ( -- ) ; export w; }") []
    [("firth.syntax.misplaced-export", "main.firth", [])]

  -- A diamond loads its base once, after nothing it does not import, and
  -- the load order follows the imports as written, not the order of `files`.
  let base := src "base.firth" "export one; : one (forall ρ; ρ -- ρ r:Int^many) 1;"
  let left := src "left.firth" "import \"base.firth\"; export l; : l (forall ρ; ρ -- ρ r:Int^many) one;"
  let right := src "right.firth" "import \"base.firth\"; export r; : r (forall ρ; ρ -- ρ r:Int^many) one one prim +;"
  let top := src "top.firth" "import \"left.firth\";\nimport \"right.firth\";\n: top ( -- r:Int^many ) l r prim +;"
  let order := [("base.firth", ["one"]), ("left.firth", ["l"]), ("right.firth", ["r"]), ("top.firth", ["top"])]
  accept "diamond" top [base, left, right] order
  accept "diamond, files reversed" top [right, left, base] order
  -- Imports are not transitive.
  reject "transitive" (src "top.firth" "import \"left.firth\"; : top ( -- r:Int^many ) one;") [base, left]
    [("firth.name.unresolved", "top.firth", [])]

  -- One dictionary: a key defined by two files is refused, at the importer's
  -- own word or at the second import that brings it in.
  reject "own word collides" (src "main.firth" "import \"lib.firth\"; : helper ( -- ) ;") [lib]
    [("firth.name.duplicate-canonical", "main.firth", ["lib.firth"])]
  let other := src "other.firth" "export w; : w ( -- ) ; : helper ( -- ) ;"
  reject "imports collide" (src "main.firth" "import \"lib.firth\"; import \"other.firth\"; : main ( -- ) ;")
    [lib, other] [("firth.name.duplicate-canonical", "main.firth", ["lib.firth", "other.firth"])]

  -- An operation a record generates is a key like any other: a record whose
  -- `R.pack` is also an imported word would erase that word's calls.
  let packLib := src "packlib.firth" "vocab R { : pack ( forall ρ; ρ n:Int -- ρ m:Int ) 1 prim + ; }\nexport R.pack;"
  reject "generated key collides with an import"
    (src "main.firth" "import \"packlib.firth\"; record R { x:Int }\n: f ( forall ρ; ρ n:Int -- ρ n:Int ) ;") [packLib]
    [("firth.name.duplicate-canonical", "main.firth", ["packlib.firth"])]
  -- The record's own name is a key too: an imported word `R` and `record R`.
  let nameLib := src "namelib.firth" "export R;\n: R ( forall ρ; ρ n:Int -- ρ n:Int ) ;"
  reject "record name collides with an imported word"
    (src "main.firth" "import \"namelib.firth\"; record R { x:Int }\n: f ( forall ρ; ρ n:Int -- ρ n:Int ) ;") [nameLib]
    [("firth.name.duplicate-canonical", "main.firth", ["namelib.firth"])]
  accept "a record beside an import with other names"
    (src "main.firth" "import \"packlib.firth\"; record S { x:Int }\n: f ( forall ρ; ρ n:Int -- ρ n:Int ) ;") [packLib]
    [("packlib.firth", ["R.pack"]), ("main.firth", ["f"])]

  -- A collision is reported once, where it happens; a file that imports that
  -- one gets the failed import, not the collision again.
  let mid := src "mid.firth" "import \"lib.firth\"; export m; : m ( -- ) ; : helper ( -- ) ;"
  reject "collision reported once" (src "top.firth" "import \"mid.firth\"; : top ( -- ) m;") [lib, mid]
    [("firth.name.duplicate-canonical", "mid.firth", ["lib.firth"]),
     ("firth.name.import-failed", "top.firth", ["mid.firth"])]
  let pair := src "pair.firth" "import \"lib.firth\"; import \"other.firth\"; export p; : p ( -- ) ;"
  reject "import collision reported once" (src "top.firth" "import \"pair.firth\"; : top ( -- ) p;")
    [lib, other, pair]
    [("firth.name.duplicate-canonical", "pair.firth", ["lib.firth", "other.firth"]),
     ("firth.name.import-failed", "top.firth", ["pair.firth"])]

  -- A vocabulary of an imported file is a `use` target, with or without an alias.
  let core := src "core.firth" "vocab core { : id ( forall ρ; ρ -- ρ ) ; : hidden ( forall ρ; ρ -- ρ ) ; }\nexport core.id;"
  accept "use" (src "main.firth" "import \"core.firth\"; use core; : main ( -- ) id;") [core]
    [("core.firth", ["core.id", "core.hidden"]), ("main.firth", ["main"])]
  accept "use as" (src "main.firth" "import \"core.firth\"; use core as c; : main ( -- ) c.id core.id;") [core]
    [("core.firth", ["core.id", "core.hidden"]), ("main.firth", ["main"])]
  reject "hidden vocabulary word" (src "main.firth" "import \"core.firth\"; : main ( -- ) core.hidden;") [core]
    [("firth.name.not-exported", "main.firth", ["core.firth"])]
  reject "unexported vocabulary" (src "main.firth" "import \"lib.firth\"; use core; : main ( -- ) ;") [lib]
    [("firth.name.unresolved", "main.firth", [])]

  -- An imported word exported from outside any vocabulary is a candidate
  -- inside the importer's vocabularies too, beside their own words.
  accept "top-level import in a vocabulary"
    (src "main.firth" "import \"lib.firth\"; vocab app { : main ( -- r:Int^many ) 2 double; }") [lib]
    [("lib.firth", ["double", "helper"]), ("main.firth", ["app.main"])]
  reject "unexported top-level import in a vocabulary"
    (src "main.firth" "import \"lib.firth\"; vocab app { : main ( -- r:Int^many ) 2 helper; }") [lib]
    [("firth.name.not-exported", "main.firth", ["lib.firth"])]
  reject "top-level import beside a vocabulary word"
    (src "main.firth" ("import \"lib.firth\"; vocab app { : double (forall ρ; ρ n:Int^many -- ρ m:Int^many) ; "
      ++ ": main ( -- r:Int^many ) 2 double; }")) [lib]
    [("firth.name.ambiguous-use", "main.firth", [])]

  -- A refused import stops its importers, not the files beside it.
  let broken := src "broken.firth" "export bad; : bad ( -- r:Int^many ) true;"
  let ok := src "ok.firth" "export good; : good ( -- r:Int^many ) 1; : wrong ( -- r:Int^many ) false;"
  match program (src "main.firth" "import \"broken.firth\"; import \"ok.firth\"; : main ( -- ) ;") [broken, ok] with
  | .ok _ => fail "broken import: accepted"
  | .error diagnostics =>
      let files := diagnostics.map (·.1)
      if !(files.contains "broken.firth" && files.contains "ok.firth") then
        fail s!"broken import: expected reports in both imports: {repr diagnostics}"
      if (diagnostics.filter (·.1 == "main.firth")).map summary !=
          [("firth.name.import-failed", "main.firth", ["broken.firth"]),
           ("firth.name.import-failed", "main.firth", ["ok.firth"])] then
        fail s!"broken import: main's reports {repr diagnostics}"

  -- The elaborate adapter: `files` in, `sources` out, diagnostics by path.
  let elaboration ← elaborateJson (main₀ "2 double") [lib]
  if (← member elaboration "status") != .str "success" then fail "adapter: refused"
  let sources := (← member elaboration "sources").compress
  if !(sources.contains "\"source_path\":\"lib.firth\"" && sources.contains "\"words\":[\"double\",\"helper\"]") then
    fail s!"adapter: sources {sources}"
  -- A warning's range is in its word's own file, so the warning names that file.
  let deep (name : String) : String :=
    s!": {name} ( a:Int^many b:Int^many c:Int^many d:Int^many e:Int^many -- ) locals \{ a b c d e } \{ } ;"
  let warned := src "warned.firth" (deep "lib-deep" ++ "\nexport lib-deep;")
  let warnedMain := src "main.firth" ("import \"warned.firth\";\n" ++ deep "main-deep")
  let warnings ← match (← member (← elaborateJson warnedMain [warned]) "warnings").getArr? with
    | .ok values => pure values.toList
    | .error error => fail s!"adapter: warnings {error}"; pure []
  -- Five locals give each word one `LOCAL_DEPTH` and one `STACK_JUGGLE`.
  let warningPaths (warnings : List Lean.Json) :=
    warnings.map fun warning =>
      ((warning.getObjValAs? String "word").toOption, (warning.getObjValAs? String "code").toOption,
       (warning.getObjValAs? String "source_path").toOption)
  let expectedPaths := ["lib-deep", "main-deep"].flatMap fun word =>
    let path := if word == "lib-deep" then "warned.firth" else "main.firth"
    ["LOCAL_DEPTH", "STACK_JUGGLE"].map fun code => (some word, some code, some path)
  if warningPaths warnings != expectedPaths then
    fail s!"adapter: warning paths {repr (warningPaths warnings)}"
  -- Known-bad responses the check must reject: the path dropped, and every
  -- warning named with the root's path.
  let dropped := warnings.map fun warning => Lean.Json.mkObj
    [("word", warning.getObjValD "word"), ("code", warning.getObjValD "code"),
     ("range", warning.getObjValD "range")]
  let rootOnly := warnings.map (·.setObjVal! "source_path" (.str "main.firth"))
  for bad in [dropped, rootOnly] do
    if warningPaths bad == expectedPaths then
      fail s!"adapter: the warning-path check accepted {repr (warningPaths bad)}"
  match Firth.Agent.Elaborate.runRequest (elaborateRequest (main₀ "2 helper") [lib]) with
  | .ok output =>
      if !(output.contains "firth.name.not-exported" && output.contains "\"path\":\"main.firth\"") then
        fail s!"adapter: not-exported report {output}"
  | .error error => fail s!"adapter: {error}"
  -- The hint names the export by the word's canonical key, whatever the reference's spelling.
  let core := src "core.firth" "vocab core { : id ( forall ρ; ρ -- ρ ) ; : hidden ( forall ρ; ρ -- ρ ) ; }\nexport core.id;"
  match Firth.Agent.Elaborate.runRequest
      (elaborateRequest (src "main.firth" "import \"core.firth\"; use core; : main ( -- ) hidden;") [core]) with
  | .ok output =>
      if !(output.contains "firth.name.not-exported" && output.contains "export core.hidden;") then
        fail s!"adapter: not-exported hint {output}"
  | .error error => fail s!"adapter: {error}"
  match Firth.Agent.Elaborate.runRequest (elaborateRequest (main₀ "1") [badExport]) with
  | .ok output =>
      if !(output.contains "\"path\":\"lib.firth\"" && output.contains "firth.name.import-failed") then
        fail s!"adapter: a report in lib.firth carries its own path {output}"
  | .error error => fail s!"adapter: {error}"
  for files in [[lib, lib], [{ lib with path := "../lib.firth" }], [{ lib with path := "main.firth" }]] do
    if (Firth.Agent.Elaborate.runRequest (elaborateRequest (main₀ "2 double") files)) matches .ok _ then
      fail s!"adapter: accepted files {repr (files.map (·.path))}"
  -- Imports resolve against the root's path, so with files it is normalised.
  let dotted := { main₀ "2 double" with path := "app/./main.firth" }
  if (Firth.Agent.Elaborate.runRequest (elaborateRequest dotted [{ lib with path := "app/lib.firth" }])) matches .ok _ then
    fail "adapter: accepted files beside a root path that is not normalised"

  -- The compiler binds every file: debug locations name each word's file,
  -- the imported file's digest is recorded, and an imported file other than
  -- the one checked is refused.
  match ← compileWith (main₀ "2 double") [lib] [lib] "main" with
  | .error error => fail s!"compile: {error}"
  | .ok response =>
      let debug := (← member response "debug_locations").compress
      if !(debug.contains "\"word\":\"double\"" && debug.contains "\"source_path\":\"lib.firth\""
          && debug.contains "\"source_path\":\"main.firth\"") then
        fail s!"compile: debug locations {debug}"
      let verification := (← member response "verification").compress
      if !verification.contains ("\"imported_sha256\":[{\"source_path\":\"lib.firth\",\"source_sha256\":\""
          ++ Firth.Compiler.Digest.hexOfString lib.text ++ "\"}]") then
        fail s!"compile: verification {verification}"
      -- The image digest of an imported word is the one it has compiled alone.
      let digests := (← member response "word_digests").compress
      match ← compileWith lib [] [] "double" with
      | .ok alone =>
          let digest := (← member alone "word_digests").getObjValD "double"
          if !digests.contains ("\"double\":" ++ digest.compress) then
            fail s!"compile: digest of double {digests} differs from alone {digest.compress}"
      | .error error => fail s!"compile alone: {error}"
  let tampered := { lib with text := lib.text.replace "dup prim +" "dup prim *" }
  if (← compileWith (main₀ "2 double") [lib] [tampered] "main") matches .ok _ then
    fail "compile: accepted a source envelope whose imported file differs from the checked one"
  if (← compileWith (main₀ "2 double") [lib] [] "main") matches .ok _ then
    fail "compile: accepted a source envelope without its imported file"
  -- The loader reads a program's files from disk, in load order, and refuses
  -- a file whose real path leaves the source root.
  let scratch ← IO.FS.createTempDir
  let outside ← IO.FS.createTempDir
  try
    IO.FS.createDirAll (scratch / "app")
    IO.FS.writeFile (scratch / "lib.firth") lib.text
    IO.FS.writeFile (scratch / "app" / "main.firth") "import \"../lib.firth\";\n: main ( -- r:Int^many ) 2 double;"
    let (root, files) ← Firth.Agent.Sources.load scratch.toString "app/main.firth"
    if root.path != "app/main.firth" || files != [lib] then
      fail s!"loader: {repr root} {repr files}"
    -- A missing import is left for the elaborator to report.
    IO.FS.writeFile (scratch / "gone.firth") "import \"absent.firth\"; : g ( -- ) ;"
    let (_, loadedFiles) ← Firth.Agent.Sources.load scratch.toString "gone.firth"
    if !loadedFiles.isEmpty then fail s!"loader: read files for a missing import {repr loadedFiles}"
    IO.FS.writeFile (outside / "secret.firth") ": secret ( -- ) ;"
    let link ← IO.Process.output { cmd := "ln", args := #["-s", (outside / "secret.firth").toString,
      (scratch / "secret.firth").toString] }
    if link.exitCode != 0 then fail s!"loader: ln failed {link.stderr}"
    IO.FS.writeFile (scratch / "leak.firth") "import \"secret.firth\"; : leak ( -- ) secret;"
    let leaked ← try
        let _ ← Firth.Agent.Sources.load scratch.toString "leak.firth"
        pure true
      catch _ => pure false
    if leaked then fail "loader: read a file through a link out of the source root"
    -- The same through a linked directory, and for the root file itself.
    let dirLink ← IO.Process.output { cmd := "ln", args := #["-s", outside.toString,
      (scratch / "elsewhere").toString] }
    if dirLink.exitCode != 0 then fail s!"loader: ln failed {dirLink.stderr}"
    IO.FS.writeFile (scratch / "via-dir.firth") "import \"elsewhere/secret.firth\"; : via ( -- ) secret;"
    let refuses (path : String) : IO Bool := do
      try
        let _ ← Firth.Agent.Sources.load scratch.toString path
        pure false
      catch _ => pure true
    if !(← refuses "via-dir.firth") then
      fail "loader: read a file through a linked directory out of the source root"
    if !(← refuses "elsewhere/secret.firth") then
      fail "loader: read a root file through a link out of the source root"
    -- A source root of `/` reads the same files as their own directory.
    let absolute := (← IO.FS.realPath scratch).toString
    let (_, fromSlash) ← Firth.Agent.Sources.load "/" ((absolute.drop 1).toString ++ "/app/main.firth")
    if fromSlash.map (·.text) != [lib.text] then
      fail s!"loader: a source root of / read {repr fromSlash}"
    -- The exporter reads `./app/main.firth` as `app/main.firth` under the working directory.
    let (exportRoot, exportPath) := Firth.Compiler.ExportLean.sourceLocation "./app/main.firth"
    if (exportRoot, exportPath) != (".", "app/main.firth") then
      fail s!"exporter: ./app/main.firth is read as {exportPath} under {exportRoot}"
    let (_, exported) ← Firth.Agent.Sources.load scratch.toString exportPath
    if exported != [lib] then fail s!"exporter: ./app/main.firth loaded {repr exported}"
    -- A root that imports nothing may have a name outside the import-path
    -- grammar; one that imports a file may not.
    IO.FS.writeFile (scratch / "my program.firth") ": alone ( -- ) ;"
    let (spaced, rest) ← Firth.Agent.Sources.load scratch.toString "my program.firth"
    if spaced.text != ": alone ( -- ) ;" || !rest.isEmpty then
      fail s!"loader: a standalone root with a space in its name read {repr spaced} {repr rest}"
    IO.FS.writeFile (scratch / "my main.firth") "import \"lib.firth\"; : m ( -- ) ;"
    if !(← refuses "my main.firth") then
      fail "loader: read imports for a root path outside the import-path grammar"
    -- A file that is not UTF-8 is refused rather than decoded.
    IO.FS.writeBinFile (scratch / "latin.firth") (ByteArray.mk #[0x3a, 0x20, 0xe9, 0x20, 0x3b])
    IO.FS.writeFile (scratch / "reads-latin.firth") "import \"latin.firth\"; : r ( -- ) ;"
    if !(← refuses "reads-latin.firth") then fail "loader: read a file that is not UTF-8"
  finally
    IO.FS.removeDirAll scratch
    IO.FS.removeDirAll outside
  IO.println "imports: ok"

end Firth.ImportsTest

def main : IO Unit := Firth.ImportsTest.main
