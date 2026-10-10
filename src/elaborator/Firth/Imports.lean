import elaborator.Firth.Pipeline

/-!
Programs of several files (`dec.multi-file-imports`).

A file names the files it uses with `import "path";` and offers words to them
with `export name ...;`. This module finds the files of a program, puts them
in their load order, and checks them one at a time with the single-file
pipeline: each against the declared effects of the words its direct imports
export. It never reads the file system; the caller supplies every file.
-/

namespace Firth.Elaborator

/-- One source file of a program: its path, normalised relative to the
source root, and its text. -/
structure Source where
  path : String
  text : String
  deriving Repr, BEq

private def pathChar (c : Char) : Bool :=
  ('a' ≤ c && c ≤ 'z') || ('A' ≤ c && c ≤ 'Z') || ('0' ≤ c && c ≤ '9') ||
    c == '.' || c == '_' || c == '-'

/-- The directories of a normalised path, outermost first. -/
private def directoryOf (path : String) : List String :=
  (path.splitOn "/").dropLast

/-- The path `target` names when written in the file at `importer`, normalised
relative to the source root, or `none` when it is not an import path: empty,
absolute, with an empty segment or another character than ASCII letters,
digits, `.`, `_` and `-`, not ending in a `.firth` file name, or climbing above
the source root. -/
def resolveImportPath (importer target : String) : Option String :=
  let segments := target.splitOn "/"
  let fileName := segments.getLast?.getD ""
  if segments.any (·.isEmpty) || !target.all (fun c => c == '/' || pathChar c) ||
      !fileName.endsWith ".firth" || fileName.length ≤ ".firth".length then none
  else
    let step (directories : Option (List String)) (segment : String) : Option (List String) :=
      directories.bind fun directories =>
        if segment == "." then some directories
        else if segment == ".." then
          if directories.isEmpty then none else some directories.dropLast
        else some (directories ++ [segment])
    (segments.foldl step (some (directoryOf importer))).map ("/".intercalate ·)

/-- Whether `path` is already a normalised path relative to the source root. -/
def normalisedPath (path : String) : Bool :=
  resolveImportPath "" path == some path

/-- A file of the program in its load order. `declarations` is `none` when the
file does not parse; checking it then reports why. `imports` are the files
its valid imports name, each with its declaration, and `errors` the import
errors found in it. -/
structure LoadedFile where
  source : Source
  declarations : Option (List Declaration)
  imports : List (ImportDecl × String) := []
  errors : List ParseError := []

private def importError (code : String) (decl : ImportDecl) (files : List String := []) :
    ParseError :=
  { code, primary := decl.span, actual := some decl.path, cause := .validation, files }

private def importsOf (declarations : List Declaration) : List ImportDecl :=
  declarations.filterMap fun
    | .import decl => some decl
    | _ => none

private structure LoadState where
  /-- Files whose imports are being loaded, outermost first. -/
  active : List String := []
  /-- Loaded files, in load order. -/
  loaded : List LoadedFile := []

/-- Loads `source` and, first, every file it imports that is not loaded yet,
following its imports in the order they are written. -/
private partial def load (files : List Source) (source : Source) (state : LoadState) : LoadState :=
  match parse source.text with
  | .failure _ =>
      { state with loaded := state.loaded ++ [{ source, declarations := none }] }
  | .success file =>
      let state := { state with active := state.active ++ [source.path] }
      -- `named` holds every file an import of this one has named so far,
      -- whether or not it could be loaded, so a repeat is reported as one.
      let (state, imports, errors, _) := (importsOf file.declarations).foldl
        (init := (state, ([] : List (ImportDecl × String)), ([] : List ParseError), ([] : List String)))
        fun (state, imports, errors, named) decl =>
          match resolveImportPath source.path decl.path with
          | none => (state, imports, errors ++ [importError "firth.name.import-path" decl], named)
          | some target =>
              if named.contains target then
                (state, imports, errors ++ [importError "firth.name.duplicate-import" decl [target]], named)
              else
                let named := named ++ [target]
                if state.active.contains target then
                  let cycle := state.active.drop (state.active.idxOf target) ++ [target]
                  (state, imports, errors ++ [importError "firth.name.import-cycle" decl cycle], named)
                else if state.loaded.any (·.source.path == target) then
                  (state, imports ++ [(decl, target)], errors, named)
                else match files.find? (·.path == target) with
                  | none => (state, imports, errors ++ [importError "firth.name.import-not-found" decl [target]],
                      named)
                  | some imported => (load files imported state, imports ++ [(decl, target)], errors, named)
      { active := state.active.dropLast
        loaded := state.loaded ++ [{ source, declarations := some file.declarations, imports, errors }] }

/-- The files of the program whose root is `root`, in load order: each file
after every file it imports, the root last. `files` are the other files
available, by normalised path; the ones the program does not import are left
out. -/
def loadProgram (root : Source) (files : List Source) : List LoadedFile :=
  (load files root {}).loaded

/-- Every canonical key a loaded file brings into a program, with the path of
the file defining it: its own words and, before them, everything its imports
bring in. Two files defining one key are reported as
`firth.name.duplicate-canonical` in the first file whose program holds both:
at the import that brings the second in, or at the word when the file
defines it itself. A file's set keeps the first file for each key, so a
collision is reported once, and a file that imports one where it was
reported gets `firth.name.import-failed` instead. -/
private def collisions (loaded : List LoadedFile) : List (String × List ParseError) :=
  let step (done : List (String × List (String × String)) × List (String × List ParseError))
      (file : LoadedFile) :=
    let (closures, errors) := done
    let own := match file.declarations with
      | some declarations => collectWords declarations
      | none => []
    let (brought, found) := file.imports.foldl (init := (([] : List (String × String)), ([] : List ParseError)))
      fun (brought, found) (decl, path) =>
        let closure := ((closures.find? (·.1 == path)).map (·.2)).getD []
        closure.foldl (init := (brought, found)) fun (brought, found) (key, source) =>
          match brought.find? (·.1 == key) with
          | some (_, other) =>
              if other == source then (brought, found)
              else (brought, found ++ [{ code := "firth.name.duplicate-canonical", primary := decl.span
                                         actual := some key, cause := .validation, files := [other, source] }])
          | none => (brought ++ [(key, source)], found)
    let found := found ++ own.filterMap fun word =>
      (brought.find? (·.1 == word.name)).map fun (_, other) =>
        { code := "firth.name.duplicate-canonical", primary := word.span, actual := some word.name
          cause := .validation, files := [other] }
    let fresh := own.filter fun word => !brought.any (·.1 == word.name)
    (closures ++ [(file.source.path, brought ++ fresh.map (·.name, file.source.path))],
      errors ++ [(file.source.path, found)])
  (loaded.foldl step ([], [])).2

/-- The words of a loaded file as its importers see them. -/
def importedWords (file : LoadedFile) : List ImportedWord :=
  match file.declarations with
  | none => []
  | some declarations =>
      let exported := (exportedNames declarations).map (·.name)
      (collectWords declarations).map fun word =>
        { name := word.name, effect := word.effect, exported := exported.contains word.name
          source := file.source.path }

/-- Checks a program file by file in load order. `check` checks one file
against the words of its direct imports, as `elaborateWith` does, and
`report` renders an import error of that file. A file with import errors is
refused with them; a file that imports a refused file is not checked and is
refused with `firth.name.import-failed` at each such import. Every other file
is checked. The program is accepted with each file's checked words, in load
order, when every file is. -/
def elaborateProgram {α : Type} (check : Source → List ImportedWord → Except (List α) CheckedProgram)
    (report : Source → ParseError → α) (root : Source) (files : List Source) :
    Except (List α) (List (Source × CheckedProgram)) :=
  let loaded := loadProgram root files
  let clashes := collisions loaded
  let outcomes := loaded.foldl (init := ([] : List (Source × Except (List α) CheckedProgram)))
    fun outcomes file =>
      let errors := file.errors ++ (((clashes.find? (·.1 == file.source.path)).map (·.2)).getD [])
      let refused := file.imports.filter fun (_, path) =>
        outcomes.any fun (source, outcome) => source.path == path && outcome matches .error _
      let outcome : Except (List α) CheckedProgram :=
        if !errors.isEmpty then .error (errors.map (report file.source))
        else if !refused.isEmpty then
          .error (refused.map fun (decl, path) => report file.source
            (importError "firth.name.import-failed" decl [path]))
        else
          let imported := file.imports.flatMap fun (_, path) =>
            ((loaded.find? (·.source.path == path)).map importedWords).getD []
          check file.source imported
      outcomes ++ [(file.source, outcome)]
  match outcomes.flatMap (fun (_, outcome) => match outcome with | .error diagnostics => diagnostics | .ok _ => []) with
  | [] => .ok (outcomes.filterMap fun (source, outcome) => match outcome with
      | .ok program => some (source, program)
      | .error _ => none)
  | diagnostics => .error diagnostics

end Firth.Elaborator
