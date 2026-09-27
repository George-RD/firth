import Lean
import compiler.Firth.Digest
import exports.All

/-!
Proof records: Lean theorems about exported kernel programs, admitted as
evidence only after an audit that fails closed.

`src/proofs/contracts.json` lists the theorems a source's authors claim as its
contracts. For each one this loads the environment the proof modules were
built into and checks, refusing the whole run on any failure:

* the name is a `theorem` in a module under `proofs.`;
* every constant the theorem reaches, through its statement and its proof and
  through every definition they use, rests only on the axioms `propext`,
  `Classical.choice` and `Quot.sound`. A proof that reaches `sorryAx`,
  `Lean.ofReduceBool` (what `native_decide` uses) or any other declared
  axioms is refused;
* the statement runs under `adapterGamma` or `int64Gamma` and covers at least
  one exported word. Each covered word is recorded with its current body
  digest.

Coverage is computed from the statement, never declared, and never from the
proof: it is the words whose bodies the statement names, and the words it
calls by name in a module whose `dictionary` it names, closed under the calls
in their bodies. Naming a dictionary covers nothing by itself, so a theorem
about `has-repeat` covers `has-repeat` and what it calls, not the rest of the
allocator. The record's evidence id is the SHA-256 of its canonical
text, which includes the digest of the theorem's statement.

The kernel check itself is `lake build`, which elaborates every proof module
from source and has the Lean kernel check each declaration. This audit reads
the environment that build produced; it does not re-run the kernel.

Every exported word is then reported as `contract_verified`, naming the
theorems that cover it, or `type_checked` when none does.
-/

namespace Firth.Compiler.ProofRecords
open Lean

/-- The axioms a recorded proof may rest on: the three that Lean's own
standard library and every `simp`, `omega` or `decide` proof use. -/
def allowedAxioms : List Name := [``propext, ``Classical.choice, ``Quot.sound]

structure Contract where
  theoremName : Name
  module : Name
  claim : String

structure Covered where
  module : String
  source : String
  word : String
  bodyDigest : String

structure ProofRecord where
  contract : Contract
  statementDigest : String
  axioms : List Name
  covers : List Covered

private def err (message : String) : Except String α := .error message

private def quote (value : String) : String := (Json.str value).compress

/-- A dotted Lean name from its text. French-quoted components are not
needed here: contracts name theorems and modules, not Firth words. -/
private def parseName (text : String) : Except String Name := do
  if text.isEmpty then err "empty name"
  let parts := text.splitOn "."
  if parts.any String.isEmpty then err s!"malformed name: {text}"
  pure (parts.foldl Name.str .anonymous)

def decodeContracts (root : Name) (json : Json) : Except String (List Contract) := do
  let items ← json.getArr?
  items.toList.mapM fun item => do
    let obj ← item.getObj?
    for (key, _) in obj.toArray do
      if !["theorem", "module", "claim"].contains key then err s!"contract: unknown field {key}"
    let theoremName ← parseName (← item.getObjValAs? String "theorem")
    let module ← parseName (← item.getObjValAs? String "module")
    let claim ← item.getObjValAs? String "claim"
    if module.getRoot != root then err s!"{theoremName}: module {module} is not under {root}."
    if claim.isEmpty then err s!"{theoremName}: empty claim"
    pure { theoremName, module, claim }

/-- Every constant reachable from `root` through types, values and inductive
constructors, and the axioms among them. -/
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

/-- What a theorem's statement names: constants, and the string literals it
passes to `Atom.word`. -/
structure Named where
  constants : NameSet := {}
  wordNames : List String := []

/-- Collects what the statement names, unfolding the definitions it uses that
live under `Firth.Proofs`, the proofs' own helpers such as an abbreviation for
`Runs … dictionary …` or a named program. Nothing outside `Firth.Proofs` is
unfolded, so mentioning an export's `dictionary` names the dictionary, not
every word in it. -/
partial def statementNames (env : Environment) (statement : Expr) : Named :=
  (visit statement).run {} |>.2
where
  visit (e : Expr) : StateM Named Unit := do
    match e with
    | .app function argument =>
        if function.isConstOf ``Firth.Interpreter.Atom.word then
          if let .lit (.strVal name) := argument then
            modify fun named => { named with wordNames := name :: named.wordNames }
        visit function
        visit argument
    | .const name _ =>
        if (← get).constants.contains name then return
        modify fun named => { named with constants := named.constants.insert name }
        if (`Firth.Proofs).isPrefixOf name then
          if let some value := (env.find? name).bind (·.value? (allowOpaque := true)) then
            visit value
    | .lam _ type body _ | .forallE _ type body _ => visit type; visit body
    | .letE _ type value body _ => visit type; visit value; visit body
    | .mdata _ inner | .proj _ _ inner => visit inner
    | _ => pure ()

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

/-- The registries a contract's statement may run under. A statement under any
other `Gamma` could give a primitive another meaning. -/
def allowedGammas : List Name := [``Firth.ReferenceRun.adapterGamma, `Firth.Logic.int64Gamma]

/-- The words a statement covers: every export word whose body it names, and
every word it calls by name in a module whose `dictionary` it names, closed
under the calls in their bodies. A named body whose module's dictionary the
statement does not name is refused, because its calls would not run the
exported words. -/
def coveredWords (named : Named) : Except String (List Covered) := do
  if !allowedGammas.any named.constants.contains then
    err "statement runs under no reference registry (adapterGamma or int64Gamma)"
  let mut covered : List Covered := []
  for (module, source, words) in Firth.Exports.all do
    let base := moduleBase module
    let hasDictionary := named.constants.contains (Name.str base "dictionary")
    let bodyRoots := words.filter fun (word, _, _) =>
      named.constants.contains (Name.str (Name.str base word) "body")
    if !bodyRoots.isEmpty && !hasDictionary then
      err s!"statement names {module} bodies but not {module}.dictionary, so their calls do not run the exported words"
    let callRoots := if hasDictionary then
      words.filter fun (word, _, _) => named.wordNames.contains word else []
    let mut pending := (bodyRoots ++ callRoots).map (·.1)
    let mut reached : List String := []
    while !pending.isEmpty do
      match pending with
      | [] => pure ()
      | word :: rest =>
          pending := rest
          if !reached.contains word then
            reached := reached ++ [word]
            if let some (_, program, _) := words.find? (·.1 == word) then
              pending := pending ++ (callees program).filter fun callee =>
                words.any (·.1 == callee)
    for (word, _, digest) in words do
      if reached.contains word then
        covered := covered ++ [{ module, source, word, bodyDigest := digest }]
  pure covered

def audit (env : Environment) (contract : Contract) : Except String ProofRecord := do
  let some info := env.find? contract.theoremName
    | err s!"{contract.theoremName}: no such declaration"
  unless info matches .thmInfo _ do err s!"{contract.theoremName}: not a theorem"
  match env.getModuleIdxFor? contract.theoremName with
  | some index =>
      if env.header.moduleNames[index.toNat]? != some contract.module then
        err s!"{contract.theoremName}: not declared in {contract.module}"
  | none => err s!"{contract.theoremName}: not declared in an imported module"
  let (_, axioms) ← reach env contract.theoremName
  let axioms := axioms.toList.mergeSort (fun a b => a.toString ≤ b.toString)
  let refused := axioms.filter (!allowedAxioms.contains ·)
  unless refused.isEmpty do
    err s!"{contract.theoremName}: rests on refused axioms {refused}"
  let covers ← match coveredWords (statementNames env info.type) with
    | .ok covers => pure covers
    | .error message => err s!"{contract.theoremName}: {message}"
  if covers.isEmpty then err s!"{contract.theoremName}: covers no exported word"
  pure { contract, axioms, covers,
         statementDigest := Digest.hexOfString (toString info.type) }

private def coveredJson (covered : Covered) : String :=
  s!"\{\"module\": {quote covered.module}, \"source\": {quote covered.source}, \"word\": {quote covered.word}, \"body_digest\": {quote covered.bodyDigest}}"

/-- The canonical text of a record, without its evidence id. -/
private def recordBody (record : ProofRecord) : String :=
  let covers := ",\n      ".intercalate (record.covers.map coveredJson)
  let axioms := ", ".intercalate (record.axioms.map (quote ·.toString))
  s!"\"theorem\": {quote record.contract.theoremName.toString},
    \"module\": {quote record.contract.module.toString},
    \"claim\": {quote record.contract.claim},
    \"statement_digest\": {quote record.statementDigest},
    \"axioms\": [{axioms}],
    \"covers\": [
      {covers}]"

def recordJson (record : ProofRecord) : String :=
  let body := recordBody record
  s!"  \{\n    \"evidence\": {quote (Digest.hexOfString body)},\n    {body}}"

/-- The status of every exported word, in export order. -/
def statusJson (records : List ProofRecord) : String :=
  let rows := Firth.Exports.all.flatMap fun (module, source, words) =>
    words.map fun (word, _, digest) =>
      let theorems := records.filter (·.covers.any fun c => c.module == module && c.word == word)
      let status := if theorems.isEmpty then "type_checked" else "contract_verified"
      let names := ", ".intercalate (theorems.map (quote ·.contract.theoremName.toString))
      s!"  \{\"module\": {quote module}, \"source\": {quote source}, \"word\": {quote word}, \"body_digest\": {quote digest}, \"status\": {quote status}, \"theorems\": [{names}]}"
  ",\n".intercalate rows

def reportJson (records : List ProofRecord) : String :=
  s!"\{\"records\": [\n{",\n".intercalate (records.map recordJson)}],\n\"words\": [\n{statusJson records}]}\n"

/-- `firthProofRecords CONTRACTS`: audits every contract and prints the
report, or prints every refusal and exits 1. Run under `lake env` so the
built proof modules are on the search path. `--fixtures` audits the refusal
fixtures under `prooftests.` instead of the proofs under `proofs.`; it changes
which modules may be named, not what the audit accepts. -/
def main (args : List String) : IO UInt32 := do
  let (root, path) ← match args with
    | [path] => pure (`proofs, path)
    | ["--fixtures", path] => pure (`prooftests, path)
    | _ => IO.eprintln "usage: firthProofRecords [--fixtures] CONTRACTS"; return 2
  let contracts ← match Json.parse (← IO.FS.readFile path) >>= decodeContracts root with
    | .ok contracts => pure contracts
    | .error message => IO.eprintln s!"{path}: {message}"; return 1
  initSearchPath (← findSysroot)
  let modules := contracts.map (·.module) |>.eraseDups
  let env ← importModules (modules.map ({ module := · })).toArray {}
  let mut records : List ProofRecord := []
  let mut failures : List String := []
  for contract in contracts do
    match audit env contract with
    | .ok record => records := records ++ [record]
    | .error message => failures := failures ++ [message]
  unless failures.isEmpty do
    for failure in failures do IO.eprintln s!"refused: {failure}"
    return 1
  IO.print (reportJson records)
  pure 0

end Firth.Compiler.ProofRecords
