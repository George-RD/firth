import Lean
import compiler.Firth.Digest
import exports.All
import Firth.ProgramLogic

/-!
Proof records: Lean theorems about exported kernel programs, admitted as
evidence only after an audit that fails closed.

`src/proofs/contracts.json` lists the contracts a source's authors claim. Each
names a theorem, the proof module that declares it, the exported word it is
about, a `Firth.Logic.WordContract` definition, the registry (`gamma`) and the
cost table. The audit builds the only statement it will accept itself,

    contract.Holds gamma <export>.dictionary costs <export>.«word».body

and refuses the whole run unless, for every contract:

* the proof module's source file still exists, so a stale build of a deleted
  proof cannot be admitted;
* the theorem is a `theorem` declared in the named module;
* every constant it reaches, through its statement and its proof and through
  every definition they use, rests only on `propext`, `Classical.choice` and
  `Quot.sound`. `sorryAx`, `Lean.ofReduceBool` (what compiled-evaluation proofs use),
  `Lean.trustCompiler` and every other constant declared without a proof are
  refused;
* `gamma` is `adapterGamma` or `int64Gamma`, `costs` is a `CostTable`, the
  contract is a `WordContract`, and the export and word exist;
* Lean's definitional equality (`isDefEq`) says the theorem's statement is that
  statement. A statement with an extra hypothesis, a disjunction, another
  registry or another dictionary is a different proposition and is refused.

A `WordContract` carries a `witness` that some arguments meet its
precondition, so a precondition no input satisfies cannot be declared, and a
theorem that assumes one is not of the admitted shape.

A record covers the named word and every exported word it calls, directly or
through quotations, closed under calls. Each covered word is recorded with its
body digest and erased type. The registry and the cost table are recorded with
the digest of their definitions and every definition of this repository
they rest on. The contract's arguments, precondition, stacks and bounds are printed into
the record, so a reader sees every assumption. The record's evidence id is the
SHA-256 of its canonical text.

The kernel check itself is `lake build`, which elaborates every proof module
from source and has the Lean kernel check each declaration. This audit reads
the environment that build produced.

Every exported word is then reported as `contract_verified`, naming the
theorems that cover it, or `type_checked` when none does. `--status` audits
every record of a written report again against the current code and counts a
record only when that audit reproduces it exactly: nothing in a report,
coverage included, is taken on trust.
-/

namespace Firth.Compiler.ProofRecords
open Lean Meta

/-- The constants without a proof that a recorded proof may rest on: the three
that Lean's own standard library and every `simp`, `omega` or `decide` proof
use. -/
def allowedAxioms : List Name := [``propext, ``Classical.choice, ``Quot.sound]

/-- The registries a contract may run under. Any other `Gamma` could give a
primitive another meaning. -/
def allowedGammas : List Name := [``Firth.ReferenceRun.adapterGamma, ``Firth.Logic.int64Gamma]

structure Contract where
  theoremName : Name
  module : Name
  exportModule : String
  word : String
  contract : Name
  gamma : Name
  costs : Name
  claim : String

structure Covered where
  module : String
  source : String
  word : String
  bodyDigest : String
  erasedType : String

/-- A definition a contract names, bound to the digest of its definition and
every definition of this repository it rests on. -/
structure Binding where
  name : Name
  digest : String

/-- The contract as a reader should see it. -/
structure Statement where
  args : String
  pre : String
  input : String
  output : String
  steps : String
  cost : String

structure ProofRecord where
  contract : Contract
  statement : Statement
  statementDigest : String
  axioms : List Name
  gamma : Binding
  costTable : Binding
  covers : List Covered

private def err (message : String) : Except String α := .error message

private def quote (value : String) : String := (Json.str value).compress

/-- A dotted Lean name from its text. French-quoted components are not
needed here: contracts name theorems, modules and definitions, not Firth
words. -/
private def parseName (text : String) : Except String Name := do
  if text.isEmpty then err "empty name"
  let parts := text.splitOn "."
  if parts.any String.isEmpty then err s!"malformed name: {text}"
  pure (parts.foldl Name.str .anonymous)

def contractFields : List String :=
  ["theorem", "module", "export", "word", "contract", "gamma", "costs", "claim"]

def decodeContract (root : Name) (item : Json) : Except String Contract := do
  let obj ← item.getObj?
  for (key, _) in obj.toArray do
    if !contractFields.contains key then err s!"contract: unknown field {key}"
  let theoremName ← parseName (← item.getObjValAs? String "theorem")
  let module ← parseName (← item.getObjValAs? String "module")
  let claim ← item.getObjValAs? String "claim"
  if module.getRoot != root then err s!"{theoremName}: module {module} is not under {root}."
  if claim.isEmpty then err s!"{theoremName}: empty claim"
  pure { theoremName, module, claim,
         exportModule := ← item.getObjValAs? String "export",
         word := ← item.getObjValAs? String "word",
         contract := ← parseName (← item.getObjValAs? String "contract"),
         gamma := ← parseName (← item.getObjValAs? String "gamma"),
         costs := ← parseName (← item.getObjValAs? String "costs") }

def decodeContracts (root : Name) (json : Json) : Except String (List Contract) := do
  (← json.getArr?).toList.mapM (decodeContract root)

/-- Every constant reachable from `root` through types, values and inductive
constructors, and those among them declared without a proof. -/
partial def reach (env : Environment) (root : Name) : Except String (NameSet × NameSet) :=
  go [root] {} {}
where
  go : List Name → NameSet → NameSet → Except String (NameSet × NameSet)
    | [], seen, axioms => .ok (seen, axioms)
    | name :: rest, seen, axioms =>
        if seen.contains name then go rest seen axioms
        else
          let seen := seen.insert name
          match env.find? name with
          | none => .error s!"unknown constant {name}"
          | some info =>
              let axioms := if info matches .axiomInfo _ then axioms.insert name else axioms
              let used := info.type.getUsedConstants.toList ++
                (match info.value? (allowOpaque := true) with
                 | some value => value.getUsedConstants.toList
                 | none => []) ++
                (match info with
                 | .inductInfo value => value.ctors
                 | _ => [])
              go (used ++ rest) seen axioms

/-- The words a kernel program calls, including inside quotations. -/
partial def callees : Firth.Interpreter.Program → List String
  | .empty => []
  | .cons atom rest => atomCallees atom ++ callees rest
where
  atomCallees : Firth.Interpreter.Atom → List String
    | .word name => [name]
    | .quotation body => callees body
    | .push (.quotation body _) => callees body
    | _ => []

private def moduleBase (module : String) : Name :=
  (module.splitOn ".").foldl Name.str `Firth.Exports

/-- The named word of an export and every exported word it calls, closed under
calls, in declaration order. -/
def coveredWords (exportModule word : String) : Except String (List Covered) := do
  let some (_, source, words) := Firth.Exports.all.find? (·.1 == exportModule)
    | err s!"no export module {exportModule}"
  unless words.any (·.1 == word) do err s!"{exportModule} exports no word {word}"
  let mut pending := [word]
  let mut reached : List String := []
  while !pending.isEmpty do
    match pending with
    | [] => pure ()
    | next :: rest =>
        pending := rest
        if !reached.contains next then
          reached := reached ++ [next]
          if let some (_, program, _, _) := words.find? (·.1 == next) then
            pending := pending ++ (callees program).filter fun callee => words.any (·.1 == callee)
  pure <| words.filterMap fun (name, _, bodyDigest, erasedType) =>
    if reached.contains name then
      some { module := exportModule, source, word := name, bodyDigest, erasedType }
    else none

/-- Whether `name` comes from Lean's own toolchain (`Init`, `Std`, `Lean`,
`Lake`), which `lean-toolchain` pins, rather than from this repository. -/
def fromToolchain (env : Environment) (name : Name) : Bool :=
  match env.getModuleIdxFor? name with
  | some index => match env.header.moduleNames[index.toNat]? with
      | some module => [`Init, `Std, `Lean, `Lake].contains module.getRoot
      | none => false
  | none => false

/-- The declarations of `roots` and of every declaration of this repository
they rest on, whatever its namespace, as one line each in name order: its
type, its value when it has one, and an inductive type's constructors. The
walk follows types, values and constructors, as `reach` does, so a changed
inductive such as `Trace` changes the text as a changed definition does.
Declarations from Lean's toolchain (`Nat`, `List`, …) are not followed: they
are pinned by `lean-toolchain` and are not the language's semantics. `none`
when a name is unknown. -/
partial def firthDefinitionsOf (env : Environment) (roots : List Name) : Option String := do
  let lines ← go roots {} [] roots
  pure <| "\n".intercalate ((lines.mergeSort (fun a b => a.1.toString ≤ b.1.toString)).map
      fun (name, text) => s!"{name} {text}")
where
  go : List Name → NameSet → List (Name × String) → List Name →
      Option (List (Name × String))
    | [], _, lines, _ => some lines
    | name :: rest, seen, lines, roots =>
        if seen.contains name || (!roots.contains name && fromToolchain env name) then
          go rest seen lines roots
        else do
          let info ← env.find? name
          let seen := seen.insert name
          let value := info.value? (allowOpaque := true)
          let ctors := match info with
            | .inductInfo induct => induct.ctors
            | _ => []
          let text := s!": {info.type}" ++
            (value.map (s!" := {·}")).getD "" ++
            (if ctors.isEmpty then "" else s!" with {ctors}")
          let used := info.type.getUsedConstants.toList ++
            ((value.map (·.getUsedConstants.toList)).getD []) ++ ctors
          go (used ++ rest) seen (lines ++ [(name, text)]) roots

/-- `firthDefinitionsOf` for one root. -/
def firthDefinitions (env : Environment) (root : Name) : Option String :=
  firthDefinitionsOf env [root]

/-- The digest of a definition and every definition of this repository it
rests on, or `none` when there is no such definition. A change to it, or to
anything of this repository it uses, changes the digest. -/
def definitionDigest (env : Environment) (name : Name) : Option String := do
  let _ ← (← env.find? name).value? (allowOpaque := true)
  (firthDefinitions env name).map Digest.hexOfString

/-- The digest of a statement: its text, and the declarations of every
constant it names with every declaration of this repository they rest on
(`firthDefinitionsOf`). The text alone names `triangle` but not what
`triangle` is, so a changed helper definition or inductive type in a
contract's precondition or output would otherwise leave the digest as it was. -/
def statementDigest (env : Environment) (statement : Expr) : Option String :=
  (firthDefinitionsOf env statement.getUsedConstants.toList).map fun definitions =>
    Digest.hexOfString (toString statement ++ "\n" ++ definitions)

/-- Runs `x` against `env`, under a heartbeat limit. -/
def runMeta (env : Environment) (x : MetaM α) : IO (Except String α) := do
  let options : Options := Options.setBool {} `pp.fieldNotation false
  let context : Core.Context :=
    { fileName := "<proof records>", fileMap := default, maxHeartbeats := 2000000, options }
  try
    pure (Except.ok (← (x.run' {} {}).toIO' context { env }))
  catch error => pure (Except.error (toString error))

private def constOfType (name : Name) (type : Name) (what : String) : MetaM Expr := do
  let some info := (← getEnv).find? name | throwError "{what} {name}: no such definition"
  unless ← isDefEq info.type (mkConst type) do
    throwError "{what} {name}: not a {type}"
  pure (mkConst name)

private def pp (e : Expr) : MetaM String := do
  pure (toString (← ppExpr (← instantiateMVars e)))

/-- The statement the audit admits for `contract`, checked against the
theorem's own type, and the contract's fields as printed. -/
def statementOf (contract : Contract) (theoremType : Expr) : MetaM (Expr × Statement) := do
  unless allowedGammas.contains contract.gamma do
    throwError "{contract.gamma} is not a reference registry (adapterGamma or int64Gamma)"
  let gamma ← constOfType contract.gamma ``Firth.Interpreter.Gamma "registry"
  let costs ← constOfType contract.costs ``Firth.Interpreter.CostTable "cost table"
  let wordContract ← constOfType contract.contract ``Firth.Logic.WordContract "contract"
  let base := moduleBase contract.exportModule
  let dictionary ← constOfType (Name.str base "dictionary") ``Firth.Interpreter.Dictionary
    "dictionary"
  let body ← constOfType (Name.str (Name.str base contract.word) "body")
    ``Firth.Interpreter.Program "body"
  let expected := mkAppN (mkConst ``Firth.Logic.WordContract.Holds)
    #[wordContract, gamma, dictionary, costs, body]
  unless ← withTransparency .default (isDefEq theoremType expected) do
    throwError "its statement is not {← ppExpr expected}"
  -- The fields as written in the contract's definition.
  let some value ← unfoldDefinition? wordContract
    | throwError "contract {contract.contract}: cannot unfold its definition"
  let value ← whnfCore value
  unless value.isAppOfArity ``Firth.Logic.WordContract.mk 7 do
    throwError "contract {contract.contract}: not a structure instance"
  let fields ← value.getAppArgs.toList.take 6 |>.mapM pp
  let [args, pre, input, output, steps, cost] := fields
    | throwError "contract {contract.contract}: unexpected fields"
  let statement : Statement := { args, pre, input, output, steps, cost }
  pure (expected, statement)

/-- The source file of a proof or fixture module, relative to the repository
root. -/
def sourceOf (module : Name) : System.FilePath :=
  ⟨"src/" ++ "/".intercalate (module.components.map toString) ++ ".lean"⟩

def audit (env : Environment) (contract : Contract) : IO (Except String ProofRecord) := do
  let fail (message : String) : IO (Except String ProofRecord) :=
    pure (.error s!"{contract.theoremName}: {message}")
  unless ← (sourceOf contract.module).pathExists do
    return ← fail s!"the source of {contract.module} ({sourceOf contract.module}) is gone, so its build may be stale"
  let some info := env.find? contract.theoremName | fail "no such declaration"
  unless info matches .thmInfo _ do return ← fail "not a theorem"
  match env.getModuleIdxFor? contract.theoremName with
  | some index =>
      if env.header.moduleNames[index.toNat]? != some contract.module then
        return ← fail s!"not declared in {contract.module}"
  | none => return ← fail "not declared in an imported module"
  let axioms ← match reach env contract.theoremName with
    | .ok (_, axioms) => pure (axioms.toList.mergeSort (fun a b => a.toString ≤ b.toString))
    | .error message => return ← fail message
  let refused := axioms.filter (!allowedAxioms.contains ·)
  unless refused.isEmpty do return ← fail s!"rests on refused axioms {refused}"
  let (expected, statement) ← match ← runMeta env (statementOf contract info.type) with
    | .ok result => pure result
    | .error message => return ← fail message
  let covers ← match coveredWords contract.exportModule contract.word with
    | .ok covers => pure covers
    | .error message => return ← fail message
  let bind (name : Name) : Except String Binding := match definitionDigest env name with
    | some digest => .ok { name, digest }
    | none => .error s!"{name} has no definition to bind"
  let some statementDigest := statementDigest env expected
    | fail "its statement names an unknown constant"
  match bind contract.gamma, bind contract.costs with
  | .ok gamma, .ok costTable =>
      pure (.ok { contract, statement, axioms, gamma, costTable, covers, statementDigest })
  | .error message, _ => fail message
  | _, .error message => fail message

private def coveredJson (covered : Covered) : String :=
  s!"\{\"module\": {quote covered.module}, \"source\": {quote covered.source}, \"word\": {quote covered.word}, \"body_digest\": {quote covered.bodyDigest}, \"erased_type\": {quote covered.erasedType}}"

private def bindingJson (binding : Binding) : String :=
  s!"\{\"name\": {quote binding.name.toString}, \"digest\": {quote binding.digest}}"

/-- The canonical text of a record, without its evidence id. -/
private def recordBody (record : ProofRecord) : String :=
  let c := record.contract
  let s := record.statement
  let covers := ",\n      ".intercalate (record.covers.map coveredJson)
  let axioms := ", ".intercalate (record.axioms.map (quote ·.toString))
  s!"\"theorem\": {quote c.theoremName.toString},
    \"module\": {quote c.module.toString},
    \"export\": {quote c.exportModule},
    \"word\": {quote c.word},
    \"contract\": {quote c.contract.toString},
    \"gamma\": {quote c.gamma.toString},
    \"costs\": {quote c.costs.toString},
    \"claim\": {quote c.claim},
    \"statement\": \{
      \"args\": {quote s.args},
      \"pre\": {quote s.pre},
      \"input\": {quote s.input},
      \"output\": {quote s.output},
      \"steps\": {quote s.steps},
      \"cost\": {quote s.cost}},
    \"statement_digest\": {quote record.statementDigest},
    \"axioms\": [{axioms}],
    \"lean\": {quote Lean.versionString},
    \"gamma_binding\": {bindingJson record.gamma},
    \"cost_binding\": {bindingJson record.costTable},
    \"covers\": [
      {covers}]"

def recordJson (record : ProofRecord) : String :=
  let body := recordBody record
  s!"  \{\n    \"evidence\": {quote (Digest.hexOfString body)},\n    {body}}"

/-- The status of every exported word, in export order, from records already
known to hold of the current code. -/
def statusJson (records : List ProofRecord) : String :=
  let rows := Firth.Exports.all.flatMap fun (module, source, words) =>
    words.map fun (word, _, digest, erasedType) =>
      let theorems := records.filter (·.covers.any fun c => c.module == module && c.word == word)
      let status := if theorems.isEmpty then "type_checked" else "contract_verified"
      let names := ", ".intercalate (theorems.map (quote ·.contract.theoremName.toString))
      s!"  \{\"module\": {quote module}, \"source\": {quote source}, \"word\": {quote word}, \"body_digest\": {quote digest}, \"erased_type\": {quote erasedType}, \"status\": {quote status}, \"theorems\": [{names}]}"
  ",\n".intercalate rows

def reportJson (records : List ProofRecord) : String :=
  s!"\{\"records\": [\n{",\n".intercalate (records.map recordJson)}],\n\"words\": [\n{statusJson records}]}\n"

private def importFor (modules : List Name) : IO Environment := do
  initSearchPath (← findSysroot)
  importModules (modules.eraseDups.map ({ module := · })).toArray {}

/-- `firthProofRecords --status REPORT`: the status of every exported word
from a report written earlier. Each record's contract is audited again against
the current code, and the record counts only when that audit reproduces it
exactly, evidence id included. Coverage, digests and statement are never read
from the report. Prints `{"words": [...]}` in the form of the report's own
`words`. -/
def status (root : Name) (path : String) : IO UInt32 := do
  let parsed := Json.parse (← IO.FS.readFile path) >>= fun json => do
    let records ← json.getObjValAs? (Array Json) "records"
    records.toList.mapM fun record => do
      let fields := contractFields.filterMap fun key =>
        (record.getObjVal? key).toOption.map (key, ·)
      pure (← decodeContract root (Json.mkObj fields), record.compress)
  let recorded ← match parsed with
    | .ok recorded => pure recorded
    | .error message => IO.eprintln s!"{path}: {message}"; return 1
  let present ← recorded.filterM fun (contract, _) => (sourceOf contract.module).pathExists
  let env ← importFor (present.map (·.1.module))
  let mut current : List ProofRecord := []
  for (contract, text) in recorded do
    if let .ok record ← audit env contract then
      if (Json.parse (recordJson record)).toOption.map (·.compress) == some text then
        current := current ++ [record]
  IO.print s!"\{\"words\": [\n{statusJson current}]}\n"
  pure 0

/-- `firthProofRecords CONTRACTS`: audits every contract and prints the
report, or prints every refusal and exits 1. Run under `lake env` from the
repository root so the built proof modules are on the search path. `--fixtures`
audits the fixtures under `prooftests.` instead of the proofs under `proofs.`;
it changes which modules may be named, not what the audit accepts. -/
def main (args : List String) : IO UInt32 := do
  match args with
  | ["--status", path] => return ← status `proofs path
  | ["--fixtures", "--status", path] => return ← status `prooftests path
  | _ => pure ()
  let (root, path) ← match args with
    | [path] => pure (`proofs, path)
    | ["--fixtures", path] => pure (`prooftests, path)
    | _ => IO.eprintln "usage: firthProofRecords [--fixtures] [--status] FILE"; return 2
  let contracts ← match Json.parse (← IO.FS.readFile path) >>= decodeContracts root with
    | .ok contracts => pure contracts
    | .error message => IO.eprintln s!"{path}: {message}"; return 1
  let present ← contracts.filterM fun contract => (sourceOf contract.module).pathExists
  let env ← importFor (present.map (·.module))
  let mut records : List ProofRecord := []
  let mut failures : List String := []
  for contract in contracts do
    match ← audit env contract with
    | .ok record => records := records ++ [record]
    | .error message => failures := failures ++ [message]
  unless failures.isEmpty do
    for failure in failures do IO.eprintln s!"refused: {failure}"
    return 1
  IO.print (reportJson records)
  pure 0

end Firth.Compiler.ProofRecords
