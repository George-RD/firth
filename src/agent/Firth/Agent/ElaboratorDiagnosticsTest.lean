import agent.Firth.Agent.ElaboratorDiagnostics
import agent.Firth.Agent.ElaborateAdapter
import agent.Firth.Agent.Validation
import agent.Firth.Agent.DiagnosticEnvelopeTest
import elaborator.Firth.Refinement
import FirthReferenceRun

namespace Firth.Agent.Test

open Firth.Agent
open Firth.Elaborator

private def point (line column : Nat) : Firth.Elaborator.Position :=
  { offset := column - 1, line, column }

private def span (line start stop : Nat) : Span :=
  { start := point line start, stop := point line stop }

private def location : Location := .path "main.fth" {
  start := { line := 1, column := 1 }
  stop := { line := 1, column := 2 } }

private def fix : ProposedFix := {
  fixId := "fix-1"
  kind := "replace"
  titleKey := "fix.replace"
  applicability := "needs-review"
  edits := [{ location, replacement := "dup" }] }

private def context (payloadId : String) : EmissionContext := {
  payloadId
  requestId := "request-1"
  source := .path "main.fth"
  proposedFixes := [fix]
  related := [{ relation := "origin", location }] }

private def contextWithSource (payloadId path : String) : EmissionContext :=
  { context payloadId with source := .path path }

private def expectSortedFirst (name expected : String) (left right : Envelope) : IO Unit :=
  match sortDiagnosticEnvelopes [left, right] with
  | first :: _ => expectEqual name first.payloadId expected
  | [] => fail s!"{name}: diagnostic sorting dropped both envelopes"

private def expectValidCode (name expectedCode source : String) : IO Unit := do
  match validate source with
  | .error error => fail s!"{name}: invalid emitted envelope {error.code}"
  | .ok _ =>
      match Lean.Json.parse source with
      | .error parseError => fail s!"{name}: emitted invalid JSON {parseError}"
      | .ok json =>
          match json.getObjVal? "body" >>= (·.getObjVal? "code") >>= (·.getStr?) with
          | .ok code => expectEqual name code expectedCode
          | .error jsonError => fail s!"{name}: missing code {jsonError}"

private def expectedStackState (stack : Firth.Elaborator.StackEffect.AStack) : Lean.Json :=
  .mkObj [
    ("encoding", .str "opaque"),
    ("value", .mkObj [
      ("lean_repr", .str s!"{repr stack}"),
      ("firth", .str (Firth.Elaborator.StackEffect.renderStack stack))]),
    ("display_hint", .str "firth")]

private def expectCauseState (name source : String)
    (expected : Firth.Elaborator.StackEffect.AStack) : IO Unit :=
  match Lean.Json.parse source with
  | .error parseError => fail s!"{name}: emitted invalid JSON {parseError}"
  | .ok json =>
      match json.getObjVal? "body" >>= (·.getObjVal? "cause") >>=
          (·.getObjVal? "data") >>= (·.getObjVal? "state") with
      | .ok state =>
          expectEqual name state.compress (expectedStackState expected).compress
      | .error jsonError => fail s!"{name}: missing cause.data.state {jsonError}"

/-- The start of an envelope's structured stack field holding `stack`. -/
private def structuredStack (field stack : String) : String :=
  s!"\"{field}\":\{\"encoding\":\"opaque\",\"value\":\{\"firth\":\"{stack}\""

private def warningByCode (code : String) : List Firth.Elaborator.LintWarning →
    Option Firth.Elaborator.LintWarning
  | [] => none
  | warning :: rest => if warning.code == code then some warning else warningByCode code rest

/-- The reports with this code, of a refused program. -/
private def reportsWithCode (result : StructuredElaborationResult) (code : String) : List Envelope :=
  match result with
  | .failure envelopes => envelopes.filter fun envelope =>
      match Lean.Json.parse (encode envelope) with
      | .ok json => ((json.getObjValD "body").getObjValD "code").getStr?.toOption == some code
      | .error _ => false
  | .success _ => []

/-- The reports in this word, of a refused program. -/
private def reportsIn (result : StructuredElaborationResult) (word : String) : List Envelope :=
  match result with
  | .failure envelopes => envelopes.filter fun envelope =>
      match Lean.Json.parse (encode envelope) with
      | .ok json => (((json.getObjValD "body").getObjValD "message_params").getObjValD "word").getStr?.toOption == some word
      | .error _ => false
  | .success _ => []

/-- Syntax errors say what the text is, not that the input ended (S7 run 8:
answers grouped arguments in parentheses, or closed a branch with `] if;`
inside a `locals` body, and were told "Unexpected the end of the input"). -/
private def runSyntaxMessageTests : IO Unit := do
  let pipelineContext := contextWithSource "pipeline-syntax" "main.fth"
  let agentConfig : Firth.Elaborator.PipelineConfig :=
    { erasureEnv := Elaborate.gammaErasure, typingEnv := Elaborate.gammaTyping }
  let paramsOf (envelope : Envelope) : String × String × String :=
    match Lean.Json.parse (encode envelope) with
    | .ok json =>
        let body := json.getObjValD "body"
        let params := body.getObjValD "message_params"
        ((body.getObjValD "code").getStr?.toOption.getD "",
          (params.getObjValD "message").getStr?.toOption.getD "",
          (params.getObjValD "hint").getStr?.toOption.getD "")
    | .error _ => ("", "", "")
  let cases : List (String × String × String × String) := [
    (": main (forall ρ; ρ n:Int^many -- ρ r:Int^many)\n  locals { n } { (n 1 prim +) };",
      "firth.syntax.parenthesis-in-body",
      "`(` is not allowed in a word's body: parentheses only enclose the stack effect after the word's name.",
      "write `n 1 prim +`, not `(n 1 prim +)`"),
    -- Run 8 sample 2 used parentheses as a comment.
    (": main (forall ρ; ρ n:Int^many -- ρ r:Int^many)\n  n (copy of n) ;",
      "firth.syntax.parenthesis-in-body",
      "`(` is not allowed in a word's body: parentheses only enclose the stack effect after the word's name.",
      "A comment is written `(* ... *)`"),
    (": main (forall ρ; ρ n:Int^many -- ρ r:Int^many)\n  locals { n } { n 0 prim = [ 0 ] [ n ] if;",
      "firth.syntax.definition-ended-early",
      "`;` ends the definition here, but a `locals` body opened with `{` is still open.",
      "Here the next one to close is `}`."),
    (": main (forall ρ; ρ n:Int^many -- ρ r:Int^many)\n  n 0 prim = [ 0 ; ] [ n ] if ;",
      "firth.syntax.definition-ended-early",
      "`;` ends the definition here, but a quotation opened with `[` is still open.",
      "up to the `]` on line 2, so delete this `;`"),
    -- Run 8's shape: `] if;` closing a branch, and `};` on the next line.
    (": main (forall ρ; ρ n:Int^many -- ρ r:Int^many)\n  locals { n } { n 0 prim = [ 0 ] [ n [ 1 ] [ 2 ] if; ] if\n  };",
      "firth.syntax.definition-ended-early",
      "`;` ends the definition here, but a quotation opened with `[` is still open.",
      "up to the `}` on line 3, so delete this `;`"),
    (": main (forall ρ; ρ n:Int^many -- ρ r:Int^many)\n  n 0 prim = [ 0 ;",
      "firth.syntax.definition-ended-early",
      "`;` ends the definition here, but a quotation opened with `[` is still open.",
      "Here the next one to close is `]`."),
    -- The brackets after the `;` close in the wrong order, so it is not the one to delete.
    (": main (forall ρ; ρ n:Int^many -- ρ r:Int^many)\n  locals { n } { n [ 0 ; } } ;",
      "firth.syntax.definition-ended-early",
      "`;` ends the definition here, but a quotation opened with `[` is still open.",
      "Here the next one to close is `]`."),
    -- No `;` follows the bracket, so deleting this one would leave the word open.
    (": main (forall ρ; ρ n:Int^many -- ρ r:Int^many)\n  n [ 0 ; ]",
      "firth.syntax.definition-ended-early",
      "`;` ends the definition here, but a quotation opened with `[` is still open.",
      "no `;` ends the word after it, so move this `;` to just after that `]`"),
    -- The later `;` is inside another quotation, so it does not end the word either,
    -- and the body goes on after the `]`.
    (": main (forall ρ; ρ n:Int^many -- ρ r:Int^many)\n  n [ 1 ; ] [ 2 ; ]",
      "firth.syntax.definition-ended-early",
      "`;` ends the definition here, but a quotation opened with `[` is still open.",
      "delete this `;` and end the word with `;` after its last item"),
    (": f ( n:Int -- r:Int ) locals { n } { n ; } 1 prim +",
      "firth.syntax.definition-ended-early",
      "`;` ends the definition here, but a `locals` body opened with `{` is still open.",
      "up to the `}` on line 1, and the body goes on after it"),
    -- The `}` closes the vocabulary, so the `;` after it does not end the word.
    ("vocab v { : f ( -- r:Int ) [ 1 ; ] };",
      "firth.syntax.definition-ended-early",
      "`;` ends the definition here, but a quotation opened with `[` is still open.",
      "no `;` ends the word after it, so move this `;` to just after that `]`"),
    ("vocab V {\n: f ( n:Int -- r:Int ) locals { n } { n ; }\n}",
      "firth.syntax.definition-ended-early",
      "`;` ends the definition here, but a `locals` body opened with `{` is still open.",
      "up to the `}` on line 2, but no `;` ends the word after it, so move this `;`"),
    -- The next `;` belongs to the next definition.
    (": main (forall ρ; ρ n:Int^many -- ρ r:Int^many)\n  locals { n } { n ;\n  }\n: g ( -- ) ;",
      "firth.syntax.definition-ended-early",
      "`;` ends the definition here, but a `locals` body opened with `{` is still open.",
      "up to the `}` on line 3, but no `;` ends the word after it, so move this `;`"),
    -- Another `;` comes before the brackets close.
    (": main (forall ρ; ρ n:Int^many -- ρ r:Int^many)\n  locals { n } { n [ 0 ; ] ; } ;",
      "firth.syntax.definition-ended-early",
      "`;` ends the definition here, but a quotation opened with `[` is still open.",
      "Here the next one to close is `]`."),
    (": main (forall ρ; ρ n:Int^many -- ρ r:Int^many) n 1 = ;",
      "firth.syntax.invalid-item", "`=` cannot start an item in a word's body.", ""),
    (": divmod (forall ρ; ρ a:Int^many -- ρ q':Int^many) a ;",
      "firth.syntax.quote-in-name",
      "`q'` is not a name: a name cannot contain `'`.",
      "Rename it without the `'`"),
    (": main (forall ρ; ρ -- ρ c:Int^many) 'ab' ;",
      "firth.syntax.overlong-character",
      "A character literal holds exactly one character between its quotes, as in `'a'`.",
      "Write exactly one character between the quotes"),
    (": x (forall ; ρ -- ρ) ;",
      "firth.syntax.missing-row-binder", "This is not valid here (missing row binder).", ""),
    (": main (forall ρ; ρ -- ρ r:Int^many) locals n ;",
      "firth.syntax.unexpected-token", "Unexpected `n`, expected `{`.", ""),
    (": main (forall ρ; ρ n:Int^many -- ρ r:Int^many) n",
      "firth.syntax.unexpected-eof", "The input ends here, expected `;`.", "")]
  for (source, code, message, hint) in cases do
    match elaboratePipeline pipelineContext source agentConfig with
    | .failure (envelope :: _) =>
        let (gotCode, gotMessage, gotHint) := paramsOf envelope
        expectEqual s!"syntax message: code for {source}" gotCode code
        expectEqual s!"syntax message: message for {source}" gotMessage message
        unless hint.isEmpty || (gotHint.splitOn hint).length > 1 do
          fail s!"syntax message: the hint for {source} does not contain {hint}: {gotHint}"
    | _ => fail s!"syntax message: expected a refusal for {source}"

/-- A refused program gets the first error of each word it refuses, in
source order, each naming its word. Other words are checked against a word's
declared effect, whatever its body does, and a word whose declared effect is
no type scheme leaves its callers unchecked, each reported as such. -/
private def runEveryErrorTests : IO Unit := do
  let pipelineContext := contextWithSource "pipeline-every" "main.fth"
  let agentConfig : Firth.Elaborator.PipelineConfig :=
    { erasureEnv := Elaborate.gammaErasure, typingEnv := Elaborate.gammaTyping }
  -- `f` adds a Bool. `sub` binds its inputs out of order and then adds a
  -- Bool too: only the first is its error. `k` calls `f` as declared and
  -- is fine; `k2` hands `f` a Bool. `u` puts its row in the middle, so
  -- `c`, which calls it, cannot be checked, and is reported as unchecked
  -- rather than left silent. So is `c2`, which calls `u` on an empty stack:
  -- erasing it against `u`'s refused effect would report an underflow that
  -- says nothing about `c2`. `g` names a word that does not
  -- exist. The checker that stopped at the first error reported only
  -- `g`'s, the only name error.
  let source := String.intercalate "\n" [
    ": f ( a:Int -- b:Int ) true prim + ;",
    ": sub ( a:Int b:Int -- r:Int ) locals { b a } { a b prim - true prim + } ;",
    ": k ( -- b:Int ) 1 f ;",
    ": k2 ( -- b:Int ) true f ;",
    ": u (forall ρ; x:Int ρ -- ρ) drop ;",
    ": c ( -- ) 1 u ;",
    ": c2 ( -- ) u ;",
    ": g ( -- b:Int ) 1 bar ;"]
  let expected : List (String × String × Nat × Nat) := [
    ("f", "firth.type.primitive-input-mismatch", 1, 29),
    ("sub", "firth.name.locals-order", 2, 41),
    ("k2", "firth.type.word-input-mismatch", 4, 24),
    ("u", "firth.type.invalid-signature", 5, 22),
    ("c", "firth.type.unchecked-word", 6, 14),
    ("c2", "firth.type.unchecked-word", 7, 13),
    ("g", "firth.name.unresolved", 8, 20)]
  let summary (envelope : Envelope) : String × String × Nat × Nat :=
    match Lean.Json.parse (encode envelope) with
    | .ok json =>
        let body := json.getObjValD "body"
        let start := ((body.getObjValD "location").getObjValD "range").getObjValD "start"
        (((body.getObjValD "message_params").getObjValD "word").getStr?.toOption.getD "",
          (body.getObjValD "code").getStr?.toOption.getD "",
          (start.getObjValD "line").getNat?.toOption.getD 0,
          (start.getObjValD "column").getNat?.toOption.getD 0)
    | .error _ => ("", "", 0, 0)
  match elaboratePipeline pipelineContext source agentConfig with
  | .success _ => fail "every error: the program was accepted"
  | .failure envelopes =>
      expectEqual "every error: one report per refused word, in source order"
        (envelopes.map summary) expected
      -- One response, so the protocol needs distinct payload ids.
      match validateBatch (envelopes.map encode) with
      | .ok _ => pure ()
      | .error error => fail s!"every error: the reports are not a valid batch: {error.code}"
  -- Each word's report is the one the program with only that word as
  -- written gets: the others reduced to a call to themselves, which checks
  -- against the declared effect. `u`'s effect is refused whatever its body,
  -- so `u`, `c` and `c2` are left out, except for `u`, `c` and `c2`
  -- themselves, which are kept together.
  let unusable := ["u", "c", "c2"]
  for (word, code, line, column) in expected do
    let alone := String.intercalate "\n" ((source.splitOn "\n").map fun text =>
      match (text.splitOn " ").drop 1 with
      | name :: _ =>
          if name == word || (unusable.contains word && unusable.contains name) then text
          else if unusable.contains name then ""
          else (text.splitOn ")").headD "" ++ ") " ++ name ++ " ;"
      | [] => text)
    let reports := match elaboratePipeline pipelineContext alone agentConfig with
      | .failure envelopes => envelopes.map summary
      | .success _ => []
    let wanted := if unusable.contains word then expected.filter (unusable.contains ·.1)
      else [(word, code, line, column)]
    expectEqual s!"every error: `{word}` alone" reports wanted
  -- A bad `use` ends the words that can be resolved: the ones before it
  -- are reported, then the `use`.
  match elaboratePipeline pipelineContext ": f ( -- b:Int ) foo ;\nuse nope;\n: g ( -- b:Int ) bar ;" agentConfig with
  | .failure envelopes =>
      expectEqual "every error: a bad use ends the file"
        (envelopes.map fun envelope => let (_, code, line, column) := summary envelope; (code, line, column))
        [("firth.name.unresolved", 1, 18), ("firth.name.unresolved", 2, 1)]
  | .success _ => fail "every error: a bad use was accepted"
  -- The words before a bad `use` are checked against every word's declared
  -- effect, those after it included: `a` calls `b`, declared after the
  -- `use`, as `b` declares, and `a2` hands `b` its values in the wrong
  -- order. The report names them by their sources, walking `b` too.
  let beforeUse := String.intercalate "\n" [
    ": a",
    "  (forall ρ; ρ xs:Seq Int^many -- ρ r:Int^many)",
    "  locals { xs } { xs 0 b };",
    ": a2",
    "  (forall ρ; ρ xs:Seq Int^many -- ρ r:Int^many)",
    "  locals { xs } { 0 xs b };",
    "use nope;",
    ": b",
    "  (forall ρ; ρ xs:Seq Int^many i:Int^many -- ρ r:Int^many)",
    "  prim seq-int.at;"]
  match elaboratePipeline pipelineContext beforeUse agentConfig with
  | .failure envelopes =>
      expectEqual "every error: a word before a bad use calls one declared after it"
        (envelopes.map fun envelope => let (word, code, line, column) := summary envelope; (word, code, line, column))
        [("a2", "firth.type.word-input-mismatch", 6, 24), ("", "firth.name.unresolved", 7, 1)]
      let message := match envelopes.head? >>= fun envelope => (Lean.Json.parse (encode envelope)).toOption with
        | some json => ((((json.getObjValD "body").getObjValD "message_params").getObjValD "message").getStr?).toOption.getD ""
        | none => ""
      expectEqual "every error: a call to a word after a bad use names its values"
        message "`b` in `a2` takes xs:Seq Int, i:Int, bottom to top, but here it gets, bottom to top, `0` (Int) and `xs` (Seq Int)."
  | .success _ => fail "every error: a bad use was accepted"
  -- A word whose own effect is refused reports that, even when it also
  -- calls a word whose effect is refused.
  match elaboratePipeline pipelineContext
      ": u (forall ρ; x:Int ρ -- ρ) drop ;\n: w (forall ρ; y:Int ρ -- ρ) u ;" agentConfig with
  | .failure envelopes =>
      expectEqual "every error: a word's own refused effect comes before an unchecked call"
        (envelopes.map fun envelope => let (word, code, _, _) := summary envelope; (word, code))
        [("u", "firth.type.invalid-signature"), ("w", "firth.type.invalid-signature")]
  | .success _ => fail "every error: two refused effects were accepted"

/-- A report found against the declared effect of a word that has an error
of its own says so, and names that word: fixing its effect instead of its
body can change the report. Only a report found against the effects of
called words (erasure, typing, refinements) says it, and a word's call to
itself does not count. -/
private def runAssumesTests : IO Unit := do
  let pipelineContext := contextWithSource "pipeline-assumes" "main.fth"
  let agentConfig : Firth.Elaborator.PipelineConfig :=
    { erasureEnv := Elaborate.gammaErasure, typingEnv := Elaborate.gammaTyping }
  -- `f` adds a Bool. `g`, `two` and `three` hand `f` a Bool, found against
  -- `f`'s declared effect. `two` calls `g` only after that, so its report
  -- does not depend on `g`; `three` calls `g` first. `short` underflows at
  -- `f`, an erasure error that depends on `f`. `h` binds its inputs out of
  -- order and `opens` underflows at its own `locals`, both found from the
  -- word alone, though they call `f`; `early` underflows before its call.
  -- `r` calls only itself. The branches of `other` leave different numbers
  -- of values, one of them through `f`. `hidden`'s true branch underflows
  -- on its own: `k`'s effect changes nothing the report shows, only what
  -- it does not. `m` hands `p` its values out of order, and the checked
  -- edit in its hint depends on `q` too. `typed` fails after its call to
  -- `same`, at two values it pushed itself: the message names only those,
  -- but the report's stack does change with `same`'s effect. `br` hands
  -- `cb`, in one branch of an `if`, its values out of order; a probe that
  -- changes `cb`'s shape gives a typing error after the report, which
  -- shows the report depends on `cb`. `longest` (from a recorded answer)
  -- does the same with `run`, where only `run`'s own effect with other
  -- types shows it. The checked edits in the
  -- hints of `h` and `m` depend on `f` and `q`, which the reports do not:
  -- the hint says so instead. So does `h2`'s, where the check found that
  -- the edit alone does not fix the word. `quiet` and `late` call `f` in a
  -- quotation they drop: a probe that makes `f` refuse its input stops the
  -- check there, before the report, which says nothing about the report.
  -- `pos` drops what `f` leaves, but its report shows the whole stack, and
  -- an `f` that takes nothing leaves the `5` there. `lu` leaves its linear input unused, found at the end of its
  -- `locals` block though placed where it is bound, so an underflow at `f`
  -- comes before it. `fp` leaves the wrong first type; with only that type fixed,
  -- `gp` gets past its first `prim +` and fails at the second, with
  -- another stack. `rg` (the reviewer's case) has a branch that shows what
  -- `rf` leaves, so a fix to `rf`'s output type alone changes the report.
  -- In `g3`, the branches swap `f3`'s two outputs, so only a fix that
  -- changes both output types and keeps the input gets past the `if`.
  -- In `hs`, the edited word's erasure stops at the second `drop`, after
  -- the call to `q` and before the one to `f`, so its hint names `q` only.
  -- `hl` uses its linear `a` twice. Erasure finds that at the first `a`,
  -- before it reads `q`, though it reports it at the second (Codex on #176),
  -- so its hint names nothing.
  -- `m2` misfeeds `p` too; with the hint's edit it fails at `prim +` in
  -- typing, before it calls `q`, but erasure has read `q`'s effect by then:
  -- with three inputs for `q`, the edited word underflows at `q` instead.
  let source := String.intercalate "\n" [
    ": f ( a:Int -- b:Int ) true prim + ;",
    ": g ( -- b:Int ) true f ;",
    ": h ( a:Int b:Int -- r:Int ) locals { b a } { a f b prim + } ;",
    ": hs ( a:Int b:Int -- r:Int ) locals { b a } { a q b prim + drop drop f } ;",
    ": hl ( a:Int^linear b:Int^linear -- r:Int ) locals { b a } { a q a } ;",
    ": r ( n:Int -- m:Int ) r true prim + ;",
    ": two ( -- b:Int ) true f 1 g prim + ;",
    ": three ( -- b:Int ) g true f prim + ;",
    ": short ( -- b:Int ) f ;",
    ": opens ( -- r:Int ) locals { x } { x f } ;",
    ": early ( a:Int -- b:Int ) swap f ;",
    ": other ( a:Int -- b:Int ) true [ f ] [ drop drop 0 ] if ;",
    ": k (forall ρ; ρ xs:Seq Bool^many i:Int^many b:Bool^many -- ρ r:Bool^many) 1 prim + ;",
    ": hidden (forall ρ; ρ xs:Seq Bool^many -- ρ b:Bool^many) dup prim seq-bool.len 0 prim = [ drop drop true ] [ swap 0 true k ] if ;",
    ": p (forall ρ; ρ a:Int^many b:Bool^many -- ρ r:Int^many) prim + ;",
    ": q (forall ρ; ρ r:Int^many -- ρ s:Int^many) true prim + ;",
    ": m (forall ρ; ρ -- ρ r:Int^many) true 1 p q ;",
    ": same (forall ρ; ρ -- ρ) drop ;",
    ": typed (forall ρ; ρ a:Int^many b:Int^many c:Int^many -- ρ r:Int^many) same true 1 prim + ;",
    ": cb (forall ρ; ρ a:Int^many b:Bool^many -- ρ r:Int^many) prim + ;",
    ": br (forall ρ; ρ x:Int^many -- ρ r:Int^many) dup 0 prim = [ true 1 cb prim + ] [ ] if ;",
    ": hc (forall ρ; ρ acc:Int^many k:Int^many xs:Seq Int^many -- ρ r:Int^many) true prim + ;",
    ": h2 (forall ρ; ρ xs:Seq Int^many k:Int^many -- ρ n:Int^many) locals { k xs } { 0 xs k hc } ;",
    ": run (forall ρ; ρ xs:Seq Int^many prev:Int^many n:Int^many most:Int^many i:Int^many -- ρ r:Int^many) true prim + ;",
    ": longest (forall ρ; ρ xs:Seq Int^many -- ρ r:Int^many) locals { xs } { xs prim seq-int.len 0 prim = [ 0 ] [ xs 0 prim seq-int.at 1 0 1 xs run ] if } ;",
    ": quiet ( -- r:Int ) [ 5 f ] drop true 1 prim + ;",
    ": pos ( -- r:Int ) 5 f drop true 1 prim + ;",
    ": late ( -- r:Bool ) [ 5 f ] drop 7 ;",
    ": lu ( a:Int^linear -- r:Int ) locals { a } { 5 f } ;",
    ": m2 (forall ρ; ρ -- ρ r:Int^many) true 1 p true prim + q ;",
    ": fp ( -- a:Int b:Int ) true 1 ;",
    ": gp ( -- r:Int ) fp 1 prim + true 1 prim + ;",
    ": rf ( forall ρ; ρ s:Seq Int n:Int -- ρ r:Seq Int ) true prim + ;",
    ": rg ( -- r:Int ) true [ [ 0 ] ] [ prim seq-int.empty 5 rf ] if ;",
    ": f3 ( n:Int -- a:Bool b:Bool ) 1 ;",
    ": g3 ( -- r:Int ) 5 f3 true [ ] [ swap ] if true 1 prim + ;"]
  let summary (envelope : Envelope) : String × (List String × List String) × String × String :=
    match Lean.Json.parse (encode envelope) with
    | .ok json =>
        let params := (json.getObjValD "body").getObjValD "message_params"
        let names (key : String) := match params.getObjValD key with
          | .arr callees => callees.toList.filterMap (·.getStr?.toOption)
          | _ => []
        ((params.getObjValD "word").getStr?.toOption.getD "", (names "assumes", names "edit_assumes"),
          (params.getObjValD "message").getStr?.toOption.getD "",
          (params.getObjValD "hint").getStr?.toOption.getD "")
    | .error _ => ("", ([], []), "", "")
  match elaboratePipeline pipelineContext source agentConfig with
  | .success _ => fail "assumes: the program was accepted"
  | .failure envelopes =>
      let reports := envelopes.map summary
      expectEqual "assumes: the words whose reports depend on another reported word"
        (reports.map fun (word, assumes, _) => (word, assumes.1))
        [("f", []), ("g", ["f"]), ("h", []), ("hs", []), ("hl", []), ("r", []), ("two", ["f"]), ("three", ["g", "f"]),
         ("short", ["f"]), ("opens", []), ("early", []), ("other", ["f"]),
         ("k", []), ("hidden", []), ("p", []), ("q", []), ("m", ["p"]),
         ("same", []), ("typed", ["same"]), ("cb", []), ("br", ["cb"]), ("hc", []), ("h2", []), ("run", []), ("longest", ["run"]),
         ("quiet", []), ("pos", ["f"]), ("late", []), ("lu", []),
         ("m2", ["p"]), ("fp", []), ("gp", ["fp"]),
         ("rf", []), ("rg", ["rf"]), ("f3", []), ("g3", ["f3"])]
      expectEqual "assumes: the words whose hint's checked edit depends on another reported word"
        ((reports.filter fun (_, assumes, _) => !assumes.2.isEmpty).map fun (word, assumes, _) => (word, assumes.2))
        [("h", ["f"]), ("hs", ["q"]), ("m", ["q"]), ("h2", ["hc"]), ("m2", ["q"])]
      let endsWith (word clause : String) (hint : Bool := false) : IO Unit :=
        match reports.find? (·.1 == word) with
        | some (_, _, message, hintText) =>
            let text := if hint then hintText else message
            unless text.endsWith clause do
              fail s!"assumes: `{word}`'s {if hint then "hint" else "message"} does not end with the clause: {text}"
        | none => fail s!"assumes: no report for `{word}`"
      endsWith "g" "`g` calls `f`, which has an error of its own; this report assumes `f` keeps its stack effect."
      endsWith "two" "`two` calls `f`, which has an error of its own; this report assumes `f` keeps its stack effect."
      endsWith "three" "`three` calls `g` and `f`, which have errors of their own; this report assumes they keep their stack effects."
      endsWith "m" "That edit was checked assuming `q`, which has an error of its own, keeps its stack effect." (hint := true)
      endsWith "h" "That edit was checked assuming `f`, which has an error of its own, keeps its stack effect." (hint := true)
      for (word, _, message, _) in reports do
        if ["f", "h", "r", "opens", "early", "hidden", "quiet", "late", "lu"].contains word && (message.splitOn "this report assumes").length > 1 then
          fail s!"assumes: `{word}`'s report says it depends on another word: {message}"
      match validateBatch (envelopes.map encode) with
      | .ok _ => pure ()
      | .error error => fail s!"assumes: the reports are not a valid batch: {error.code}"
  -- merge-sorted at cec3707 (haiku-firth-2, answer 1), verbatim. `merge-loop`
  -- calls `merge-loop-y` only in the true branch of its outer `if`, and the
  -- report is about the false branch. A probe that changes
  -- `merge-loop-y`'s shape stops the check at the inner `if` of the true
  -- branch, before the report.
  let mergeSorted := ": main\n  (forall ρ; ρ xs:Seq Int^many ys:Seq Int^many -- ρ merged:Seq Int^many)\n  locals { xs ys } { 0 0 prim seq-int.empty xs ys merge-loop };\n\n: merge-loop\n  (forall ρ; ρ i:Int^many j:Int^many result:Seq Int^many xs:Seq Int^many ys:Seq Int^many -- ρ final:Seq Int^many)\n  locals { i j result xs ys } {\n    i xs prim seq-int.len prim =\n    [\n      j ys prim seq-int.len prim =\n      [ result ]\n      [ ys j prim seq-int.at result prim seq-int.push j 1 prim + ys xs merge-loop-y ]\n      if\n    ]\n    [\n      j ys prim seq-int.len prim =\n      [ xs i prim seq-int.at result prim seq-int.push i 1 prim + xs ys merge-loop ]\n      [\n        xs i prim seq-int.at ys j prim seq-int.at prim <\n        [ xs i prim seq-int.at result prim seq-int.push i 1 prim + xs ys merge-loop ]\n        [ ys j prim seq-int.at result prim seq-int.push j 1 prim + xs ys merge-loop ]\n        if\n      ]\n      if\n    ]\n    if\n  };\n\n: merge-loop-y\n  (forall ρ; ρ j:Int^many result:Seq Int^many ys:Seq Int^many xs:Seq Int^many -- ρ final:Seq Int^many)\n  locals { j result ys xs } {\n    j ys prim seq-int.len prim =\n    [ result ]\n    [ ys j prim seq-int.at result prim seq-int.push j 1 prim + ys xs merge-loop-y ]\n    if\n  };\n"
  match elaboratePipeline pipelineContext mergeSorted agentConfig with
  | .success _ => fail "assumes: merge-sorted was accepted"
  | .failure envelopes =>
      expectEqual "assumes: merge-sorted's reports depend on no other word"
        (envelopes.map fun envelope => let (word, assumes, _) := summary envelope; (word, assumes.1))
        [("merge-loop", []), ("merge-loop-y", [])]
  -- merge-sorted at c6a964a (haiku-firth-2, answer 1), verbatim. The hint
  -- for `merge-loop`'s misordered `locals` checks an edit whose first error is
  -- a typing one before the calls to `append-rest`, but erasure has read
  -- every call's arity by then: give `append-rest` no outputs and the edited
  -- word's first error moves.
  let appendRest := ": main\n  (forall ρ; ρ xs:Seq Int^many ys:Seq Int^many -- ρ merged:Seq Int^many)\n  prim seq-int.empty swap swap 0 0 merge-loop;\n\n: merge-loop\n  (forall ρ; ρ result:Seq Int^many xs:Seq Int^many ys:Seq Int^many i:Int^many j:Int^many -- ρ merged:Seq Int^many)\n  locals { result xs ys i j } {\n    i xs prim seq-int.len prim < [\n      j ys prim seq-int.len prim < [\n        i xs prim seq-int.at j ys prim seq-int.at prim < [\n          i xs prim seq-int.at result prim seq-int.push\n          xs ys i 1 prim + j merge-loop\n        ] [\n          j ys prim seq-int.at result prim seq-int.push\n          xs ys i j 1 prim + merge-loop\n        ] if\n      ] [\n        result xs i append-rest\n      ] if\n    ] [\n      result ys j append-rest\n    ] if\n  };\n\n: append-rest\n  (forall ρ; ρ result:Seq Int^many xs:Seq Int^many idx:Int^many -- ρ merged:Seq Int^many)\n  locals { result xs idx } {\n    idx xs prim seq-int.len prim < [\n      idx xs prim seq-int.at result prim seq-int.push xs idx 1 prim + append-rest\n    ] [ result ] if\n  };\n"
  match elaboratePipeline pipelineContext appendRest agentConfig with
  | .success _ => fail "assumes: merge-sorted (c6a964a) was accepted"
  | .failure envelopes =>
      expectEqual "assumes: merge-sorted (c6a964a)'s checked edits and the words they read"
        (envelopes.map fun envelope => let (word, assumes, _) := summary envelope; (word, assumes))
        [("merge-loop", ([], ["append-rest"])), ("append-rest", ([], []))]

/-- Reports of a word or primitive handed values it does not take. -/
private def runCallAccountTests : IO Unit := do
  let pipelineContext := contextWithSource "pipeline-call" "main.fth"
  let agentConfig : Firth.Elaborator.PipelineConfig :=
    { erasureEnv := Elaborate.gammaErasure, typingEnv := Elaborate.gammaTyping }
  let hintOf (envelope : Envelope) : String :=
    match Lean.Json.parse (encode envelope) with
    | .ok json => (((json.getObjValD "body").getObjValD "message_params").getObjValD "hint").getStr?.toOption.getD ""
    | .error _ => ""
  let upTo (text marker : String) : String := (text.splitOn marker).headD ""
  -- A word or primitive handed values it does not take: the report names
  -- each value by its source (`Account.ofCall`). Where the values were
  -- pushed one after another and their names and types say where each
  -- goes, it gives the edit that pushes them in order, checked by the
  -- pipeline. The test applies the edit as the hint writes it and runs the
  -- result on the reference interpreter, against values worked out by hand.
  let runValues (program : CheckedProgram) (word : String) (inputs : List Firth.Interpreter.Literal) :
      Option (List Firth.Interpreter.Literal) :=
    let toProgram (kernel : KernelProgram) : Firth.Interpreter.Program :=
      kernel.foldr (fun located rest => .cons located.atom rest) .empty
    let dictionary : Firth.Interpreter.Dictionary := fun name =>
      (program.words.find? (·.name == name)).map fun checked =>
        { type := Firth.ReferenceRun.adapterWordType, body := toProgram checked.program }
    let rec steps : Nat → Firth.Interpreter.Config → Option Firth.Interpreter.Stack
      | 0, _ => none
      | fuel + 1, config =>
          match Firth.Interpreter.step Firth.ReferenceRun.adapterGamma dictionary Firth.Interpreter.defaultCosts config with
          | .terminal final => some final.stack
          | .stuck _ => none
          | .stepped next _ => steps fuel next
    let start := (inputs.map Firth.Interpreter.Value.literal).reverse
    (steps 100000 { stack := start, program := .cons (.word word) .empty }).bind fun stack =>
      stack.reverse.mapM fun
        | .literal value => some value
        | _ => none
  -- The edit the hint states, applied where the source has it: just
  -- before the operation reported, which must happen once. The hint writes
  -- the source with its whitespace collapsed, so the source is too.
  let applyCallHint (written hint operation : String) : Option String :=
    let source := " ".intercalate (((written.map fun c => if c.isWhitespace then ' ' else c).splitOn " ").filter (!·.isEmpty))
    match (hint.splitOn "write `")[1]? with
    | none => none
    | some rest =>
        let replacement := upTo rest "`"
        match (rest.splitOn "` in place of `")[1]? with
        | none => none
        | some after =>
            let written := upTo after "`" ++ " " ++ operation
            if (source.splitOn written).length != 2 then none
            else some (source.replace written (replacement ++ " " ++ operation))
  let fieldOf (envelope : Envelope) (field : String) : String :=
    match Lean.Json.parse (encode envelope) with
    | .ok json => (((json.getObjValD "body").getObjValD "message_params").getObjValD field).getStr?.toOption.getD ""
    | .error _ => ""
  let callReport (label code source : String) (needles : List String) (absent : List String := []) :
      IO (String × String) := do
    -- The answers copied here may have errors in other words too; the
    -- report under test is the one with this code.
    match reportsWithCode (elaboratePipeline pipelineContext source agentConfig) code with
    | [envelope] =>
        let emitted := encode envelope
        expectValidCode label code emitted
        for needle in needles do
          unless emitted.contains needle do
            fail s!"{label}: the report does not say {needle}: {emitted}"
        for needle in absent do
          if emitted.contains needle then
            fail s!"{label}: the report says {needle}: {emitted}"
        pure (hintOf envelope, fieldOf envelope "at")
    | envelopes => fail s!"{label}: expected one {code} diagnostic, got {envelopes.length}"
  let expectRuns (label source word : String) (inputs expected : List Firth.Interpreter.Literal) : IO Unit := do
    match elaboratePipeline pipelineContext source agentConfig with
    | .success program =>
        match runValues program word inputs with
        | some result =>
            unless result == expected do
              fail s!"{label}: after the edit `{word}` leaves {repr result}, not {repr expected}"
        | none => fail s!"{label}: after the edit `{word}` does not run"
    | .failure envelopes => fail s!"{label}: after the edit the program is refused: {envelopes.map encode}"
  let callCase (label code source : String) (needles absent : List String) (word : String)
      (inputs expected : List Firth.Interpreter.Literal) : IO Unit := do
    let (hint, operation) ← callReport label code source needles absent
    match applyCallHint source hint operation with
    | some edited => expectRuns label edited word inputs expected
    | none => fail s!"{label}: the hint's edit does not apply: {hint}"
  -- The text replaced is found twice on its line, the first time handed
  -- to `f` in the order `f` takes: the hint names the column of the second.
  -- Planted: without the column the hint would name either. `f` gives `i`,
  -- 1, and the value at 1 is 6.
  callCase "the text replaced found twice on its line" "firth.type.primitive-input-mismatch"
      ": f (forall ρ; ρ i:Int^many xs:Seq Int^many -- ρ r:Int^many) drop ;\n: w (forall ρ; ρ xs:Seq Int^many i:Int^many -- ρ r:Int^many) locals { xs i } { i xs f i xs prim seq-int.at prim + } ;"
      ["write `xs i` in place of `i xs` on line 2, column 87. With that edit `w` checks."] []
      "w" [.intSeq [5, 6, 7], .int 1] [.int 7]
  -- Haiku's seq-sum at 470c6d0 (haiku-firth-1, answer 2), verbatim: `main`
  -- pushes the sequence last. `xs` is named like the input it is for, so
  -- it goes first; the two `0`s are the same. 4 + 5 + 6.
  callCase "sequence pushed last" "firth.type.word-input-mismatch"
      ": sum-loop\n  (forall ρ; ρ xs:Seq Int^many acc:Int^many i:Int^many -- ρ result:Int^many)\n  locals { xs acc i } {\n    i xs prim seq-int.len prim <\n    [\n      xs i prim seq-int.at acc prim +\n      xs swap\n      i 1 prim +\n      sum-loop\n    ]\n    [ acc ]\n    if\n  };\n\n: main\n  (forall ρ; ρ xs:Seq Int^many -- ρ result:Int^many)\n  locals { xs } {\n    0 0 xs sum-loop\n  };"
      ["`sum-loop` in `main` takes xs:Seq Int, acc:Int, i:Int, bottom to top, but here it gets, bottom to top, `0` (Int), `0` (Int) and `xs` (Seq Int).",
       "To push them in its order, write `xs 0 0` in place of `0 0 xs` on line 18. With that edit `main` checks."]
      [] "main" [.intSeq [4, 5, 6]] [.int 15]
  -- keep-positive at 470c6d0 (haiku-firth-1, answer 2), verbatim: `result`
  -- and `xs` are both Seq Int, and the order they were pushed in would put
  -- the empty sequence in `xs`. `xs` is named, so the empty one is
  -- `result`. The loop keeps the values that are not negative.
  callCase "names before types" "firth.type.word-input-mismatch"
      ": filter-loop\n  (forall ρ; ρ xs:Seq Int^many result:Seq Int^many i:Int^many -- ρ result-final:Seq Int^many)\n  locals { xs result i } {\n    i xs prim seq-int.len prim <\n    [\n      xs i prim seq-int.at 0 prim <\n      [\n        result\n      ]\n      [\n        result xs i prim seq-int.at prim seq-int.push\n      ]\n      if\n      xs swap\n      i 1 prim +\n      filter-loop\n    ]\n    [ result ]\n    if\n  };\n\n: main\n  (forall ρ; ρ xs:Seq Int^many -- ρ result:Seq Int^many)\n  locals { xs } {\n    prim seq-int.empty 0 xs filter-loop\n  };"
      ["write `xs prim seq-int.empty 0` in place of `prim seq-int.empty 0 xs`"]
      ["write `prim seq-int.empty xs 0`"] "main" [.intSeq [3, -1, 4]] [.intSeq [3, 4]]
  -- seq-sum at c6a964a (haiku-firth-2, answer 1), verbatim: `idx xs` is
  -- reversed inside a branch. The checker infers the branch's input from
  -- its body and so only fails at the second `prim +`, with inferred
  -- types; the report is at `prim seq-int.at`, where the mistake is.
  callCase "operands reversed in a branch" "firth.type.primitive-input-mismatch"
      ": main\n  (forall ρ; ρ xs:Seq Int^many -- ρ total:Int^many)\n  0 swap 0 sum-loop;\n\n: sum-loop\n  (forall ρ; ρ acc:Int^many xs:Seq Int^many idx:Int^many -- ρ total:Int^many)\n  locals { acc xs idx } {\n    idx xs prim seq-int.len prim < [\n      acc idx xs prim seq-int.at prim + xs idx 1 prim + sum-loop\n    ] [ acc ] if\n  };"
      ["`prim seq-int.at` in `sum-loop` takes the sequence (Seq Int) and the index (Int), bottom to top, but here it gets, bottom to top, `idx` (Int) and `xs` (Seq Int).",
       "write `xs idx` in place of `idx xs` on line 9. With that edit `sum-loop` checks."]
      ["`prim +` in `sum-loop`", "?t"] "main" [.intSeq [4, 5, 6]] [.int 15]
  -- count-distinct at cec3707 (haiku-firth-2, answer 1), the helper
  -- verbatim: the push in a branch was reported as a `compose` the author
  -- never wrote. Adding 3 to [1, 2]; 2 is there already.
  callCase "push reversed in a branch" "firth.type.primitive-input-mismatch"
      ": count-distinct-search\n  (forall ρ; ρ elem:Int^many j:Int^many seen:Seq Int^many -- ρ updated:Seq Int^many)\n  locals { elem j seen } {\n    j seen prim seq-int.len prim =\n    [ elem seen prim seq-int.push ]\n    [\n      seen j prim seq-int.at elem prim =\n      [ seen ]\n      [ elem j 1 prim + seen count-distinct-search ] if\n    ]\n    if\n  };"
      ["`prim seq-int.push` in `count-distinct-search` takes the sequence (Seq Int) and the value pushed (Int), bottom to top, but here it gets, bottom to top, `elem` (Int) and `seen` (Seq Int).",
       "write `seen elem` in place of `elem seen` on line 5. With that edit `count-distinct-search` checks."]
      ["compose"] "count-distinct-search" [.int 3, .int 0, .intSeq [1, 2]] [.intSeq [1, 2, 3]]
  -- A `swap` between the values is part of what the edit replaces.
  callCase "values exchanged by swap" "firth.type.primitive-input-mismatch"
      ": at\n  (forall ρ; ρ xs:Seq Int^many n:Int^many -- ρ r:Int^many)\n  locals { xs n } { xs n swap prim seq-int.at };"
      ["write `xs n` in place of `xs n swap` on line 3. With that edit `at` checks."]
      [] "at" [.intSeq [5, 6, 7], .int 1] [.int 6]
  -- A refused `if` whose branch mends with an edit the pipeline checked
  -- (`staleEdit`, `missingEdit`): the test applies the edit as the hint
  -- writes it, on the source with its whitespace collapsed, where the text
  -- it replaces must occur once, and runs the result on the reference
  -- interpreter against values worked out by hand. Each answer is from run
  -- 10 (eval/s7/runs/2026-09-29-control), verbatim.
  let collapse (text : String) : String :=
    " ".intercalate (((text.map fun c => if c.isWhitespace then ' ' else c).splitOn " ").filter (!·.isEmpty))
  -- The line and column in "on line L, column C", when the hint gives one.
  let placeOf (text : String) : Option (Nat × Nat) := do
    let rest ← (text.splitOn "` on line ")[1]?
    let line ← (upTo rest ",").toNat?
    let column ← (upTo ((rest.splitOn ", column ")[1]?.getD "") ".").toNat?
    pure (line, column)
  let applyBranchHint (source hint : String) : Option String :=
    let original := source
    let source := collapse source
    match (hint.splitOn "write `")[1]? with
    | none => none
    | some rest =>
        let replacement := upTo rest "`"
        match (rest.splitOn "` in place of `")[1]? with
        | none => none
        | some after =>
            let written := upTo after "`"
            -- "on line L, column C" says where, when the text is found
            -- more than once; the edit then goes there and nowhere else.
            match placeOf after with
            | some (line, column) =>
                let lines := original.splitOn "\n"
                let before := "\n".intercalate (lines.take (line - 1))
                let prefix_ := (if line > 1 then before ++ "\n" else "") ++ (((lines[line - 1]?).getD "").take (column - 1)).toString
                let rest := collapse (original.drop prefix_.length).toString
                if rest.startsWith written then some (prefix_ ++ replacement ++ (rest.drop written.length).toString) else none
            | none =>
                if (source.splitOn written).length != 2 then none
                else some (source.replace written replacement)
  let branchCase (label source : String) (needles : List String) (word : String)
      (inputs expected : List Firth.Interpreter.Literal) : IO Unit := do
    let (hint, _) ← callReport label "firth.type.branch-mismatch" source needles
    match applyBranchHint source hint with
    | some edited => expectRuns label edited word inputs expected
    | none => fail s!"{label}: the hint's edit does not apply: {hint}"
  -- prefix-sums (4c379e0, haiku-firth-10, answer 3): the pushed sequence
  -- is left below the call, which gets `result` as it was. [1, 2, 3] has
  -- prefix sums [1, 3, 6].
  branchCase "a local's old value passed on" ": main\n  (forall ρ; ρ xs:Seq Int^many -- ρ sums:Seq Int^many)\n  locals { xs } {\n    0 0 prim seq-int.empty xs prefix-sums-helper\n  };\n\n: prefix-sums-helper\n  (forall ρ; ρ i:Int^many sum:Int^many result:Seq Int^many xs:Seq Int^many -- ρ result:Seq Int^many)\n  locals { i sum result xs } {\n    i xs prim seq-int.len prim = [ result ] [\n      xs i prim seq-int.at sum prim + locals { newsum } {\n        result newsum prim seq-int.push\n        i 1 prim + newsum result xs prefix-sums-helper\n      }\n    ] if\n  };\n"
    ["The result of `prim seq-int.push` is a new value of `result`, but `prefix-sums-helper` is then handed `result` as it was before, so the new value is left below.",
     "write `prim seq-int.push locals { result } { i 1 prim + newsum result xs prefix-sums-helper }` in place of `prim seq-int.push i 1 prim + newsum result xs prefix-sums-helper` on line 12. With that edit `prefix-sums-helper` checks."]
    "main" [.intSeq [1, 2, 3]] [.intSeq [1, 3, 6]]
  -- count-below (locals-guide arm b, haiku-firth-17, answer 3): the
  -- result of the inner `if` is a new `count` on both paths, and the call
  -- is handed the old one. [1, 5, 2, 8] has two values below 4.
  branchCase "an `if` result passed on as its local's old value" ": main\n  (forall ρ; ρ xs:Seq Int^many k:Int^many -- ρ count:Int^many)\n  locals { xs k } { 0 xs 0 k count-below-helper };\n\n: count-below-helper\n  (forall ρ; ρ count:Int^many xs:Seq Int^many i:Int^many k:Int^many -- ρ result:Int^many)\n  locals { count xs i k } {\n    i xs prim seq-int.len prim <\n    [ xs i prim seq-int.at k prim < [ count 1 prim + ] [ count ] if count xs i 1 prim + k count-below-helper ]\n    [ count ]\n    if\n  };\n"
    ["The result of an `if` is a new value of `count`, but `count-below-helper` is then handed `count` as it was before, so the new value is left below.",
     "write `if locals { count } { count xs i 1 prim + k count-below-helper }` in place of `if count xs i 1 prim + k count-below-helper` on line 9. With that edit `count-below-helper` checks."]
    "main" [.intSeq [1, 5, 2, 8], .int 4] [.int 2]
  -- Constructed: two new values left behind, both handed again as they
  -- were. The even numbers below 5 and the odd ones up to 5.
  branchCase "two new values passed on as the old ones" ": fill\n  (forall ρ; ρ evens:Seq Int^many odds:Seq Int^many i:Int^many n:Int^many -- ρ e:Seq Int^many o:Seq Int^many)\n  locals { evens odds i n } {\n    i n prim <\n    [ evens i prim seq-int.push odds i 1 prim + prim seq-int.push evens odds i 2 prim + n fill ]\n    [ evens odds ]\n    if\n  };\n"
    ["The result of `prim seq-int.push` and the result of `prim seq-int.push` are new values of `evens` and `odds`, but `fill` is then handed `evens` and `odds` as they were before, so the new values are left below.",
     "write `prim seq-int.push locals { evens odds } { evens odds i 2 prim + n fill }` in place of `prim seq-int.push evens odds i 2 prim + n fill` on line 5. With that edit `fill` checks."]
    "fill" [.intSeq [], .intSeq [], .int 0, .int 5] [.intSeq [0, 2, 4], .intSeq [1, 3, 5]]
  -- Planted: allocate-batch (locals-guide arm a, haiku-firth-17, answer 1),
  -- verbatim. `stock item-idx prim seq-int.at` is the stock held, an
  -- element, not a new `item-idx`, though it is the one Int local it was
  -- handed. Binding it to `item-idx` for `prim seq-int.set` checks and
  -- would set the wrong entry; #185 offered that edit. No edit now.
  let _ ← callReport "an element read is not a new index" "firth.type.branch-mismatch" ": allocate-item\n  (forall ρ; ρ item-idx:Int^many qty:Int^many whole:Bool^many stock:Seq Int^many -- ρ allocated:Int^many reason:Int^many stock:Seq Int^many)\n  locals { item-idx qty whole stock } {\n    stock item-idx prim seq-int.at\n    qty prim <\n    [ qty prim < ]\n    [ qty prim = ]\n    [ 0 prim < ]\n    if\n    [ qty 0 stock item-idx qty prim - prim seq-int.set ]\n    [\n      stock item-idx prim seq-int.at 0 prim =\n      [ 0 2 stock ]\n      [\n        whole\n        [ 0 3 stock ]\n        [ stock item-idx prim seq-int.at stock item-idx 0 prim seq-int.set 1 stock ]\n        if\n      ]\n      if\n    ]\n    if\n  };\n\n: loop\n  (forall ρ; ρ i:Int^many items:Seq Int^many qtys:Seq Int^many whole:Seq Bool^many stock:Seq Int^many allocated:Seq Int^many reasons:Seq Int^many -- ρ allocated:Seq Int^many reasons:Seq Int^many stock:Seq Int^many)\n  locals { i items qtys whole stock allocated reasons } {\n    i items prim seq-int.len prim <\n    [\n      items i prim seq-int.at\n      qtys i prim seq-int.at\n      whole i prim seq-bool.at\n      stock\n      allocate-item\n      i 1 prim +\n      items\n      qtys\n      whole\n      loop\n    ]\n    [ allocated reasons stock ]\n    if\n  };\n\n: main\n  (forall ρ; ρ stock:Seq Int^many items:Seq Int^many qtys:Seq Int^many whole:Seq Bool^many -- ρ stock-left:Seq Int^many allocated:Seq Int^many reasons:Seq Int^many)\n  locals { stock items qtys whole } {\n    0\n    items\n    qtys\n    whole\n    stock\n    prim seq-int.empty\n    prim seq-int.empty\n    loop\n  };\n"
    ["the result of `prim seq-int.at` is left below the result of `prim seq-int.set`, `1` and `stock`."] ["bind it to the name", "in place of"]
  -- Planted (the reviewer on #189): `n 10 prim mod` is a digit of `n`, not
  -- a new `n`, though `n` is the one Int local it was handed. Bound to `n`
  -- for the call, the word checks and never stops; #185 offered that edit.
  -- Only a sequence changed, a number stepped by `prim +` or `prim -`, or a
  -- truth value accumulated by `prim and` or `prim or` is a new value of
  -- its local. No edit.
  let _ ← callReport "a digit is not a new number" "firth.type.branch-mismatch" ": digits-loop\n  (forall ρ; ρ result:Seq Int^many n:Int^many -- ρ r:Seq Int^many)\n  locals { result n } { n 0 prim = [ result ] [ n 10 prim mod result n digits-loop ] if };\n"
    ["the result of `prim mod` is left below the result of `digits-loop`."] ["bind it to the name", "in place of"]
  -- count-distinct (4c379e0, haiku-firth-4, answer 2), verbatim: the element
  -- read at `i` stood for `i`, so the pushed values seemed meant for other
  -- inputs and no edit was offered. It is `val`, and the search starts at 0.
  let _ ← callReport "an element read placed as the value it is" "firth.type.branch-mismatch" ": is-in-result\n  (forall ρ; ρ result:Seq Int^many val:Int^many i:Int^many -- ρ found:Bool^many)\n  locals { result val i } {\n    [ i result prim seq-int.len prim < ]\n    [\n      i result prim seq-int.at\n      val prim =\n      [ true ]\n      [ result val i 1 prim + is-in-result ]\n      if\n    ]\n    [\n      false\n    ] if\n  };\n\n: count-distinct-helper\n  (forall ρ; ρ xs:Seq Int^many result:Seq Int^many i:Int^many -- ρ result:Seq Int^many)\n  locals { xs result i } {\n    [ i xs prim seq-int.len prim < ]\n    [\n      i xs prim seq-int.at\n      0 is-in-result\n      [ xs result i 1 prim + count-distinct-helper ]\n      [ i xs prim seq-int.at result prim seq-int.push xs swap i 1 prim + count-distinct-helper ]\n      if\n    ]\n    [\n      result\n    ] if\n  };\n\n: main\n  (forall ρ; ρ xs:Seq Int^many -- ρ count:Int^many)\n  prim seq-int.empty 0 count-distinct-helper prim seq-int.len;\n"
    ["write `result i xs prim seq-int.at 0 is-in-result` in place of `i xs prim seq-int.at 0 is-in-result` on line 22."]
  -- Planted: histogram (locals-guide arm b, haiku-firth-17, answer 3),
  -- verbatim. `histogram-count-loop` is handed `i` among its inputs, but
  -- the call after it is handed `i 1 prim +`, not `i`: the count is not a
  -- new `i`, and binding it so would check. No edit.
  let _ ← callReport "a local handed on changed is not handed again" "firth.type.branch-mismatch" ": main\n  (forall ρ; ρ xs:Seq Int^many k:Int^many -- ρ counts:Seq Int^many)\n  locals { xs k } { prim seq-int.empty xs 0 k histogram-loop };\n\n: histogram-loop\n  (forall ρ; ρ result:Seq Int^many xs:Seq Int^many i:Int^many k:Int^many -- ρ counts:Seq Int^many)\n  locals { result xs i k } {\n    i k prim <\n    [ xs 0 i histogram-count-loop result i 1 prim + xs k histogram-loop ]\n    [ result ]\n    if\n  };\n\n: histogram-count-loop\n  (forall ρ; ρ val:Int^many count:Int^many xs:Seq Int^many -- ρ res-count:Int^many)\n  locals { val count xs } {\n    xs prim seq-int.len 0 prim =\n    [ count ]\n    [ xs 0 prim seq-int.at val prim = [ count 1 prim + xs 1 drop val histogram-count-loop ] [ count xs 1 drop val histogram-count-loop ] if ]\n    if\n  };\n"
    ["the result of `histogram-count-loop` is left below the result of `histogram-loop`."] ["bind it to the name", "in place of"]
  -- seq-sum (8ea4a1d, haiku-firth-12, answer 3): the new `acc` and the new
  -- `index` are pushed in the other order, and `xs` not at all. By types
  -- the two Int values could go either way; by the locals they are
  -- computed from, only one. 4 + 5 + 6.
  branchCase "inputs by the locals they stand for" ": seq-sum-loop\n  (forall ρ; ρ xs:Seq Int^many index:Int^many acc:Int^many -- ρ result:Int^many)\n  locals { xs index acc } {\n    index xs prim seq-int.len prim < [\n      xs index prim seq-int.at acc prim +\n      index 1 prim +\n      seq-sum-loop\n    ] [\n      acc\n    ] if\n  };\n\n: main\n  (forall ρ; ρ xs:Seq Int^many -- ρ result:Int^many)\n  locals { xs } {\n    xs 0 0 seq-sum-loop\n  };\n"
    ["the result of `prim +` (from `acc`) and the result of `prim +` (from `index`), which by their names are for inputs in another order.",
     "write `xs index 1 prim + xs index prim seq-int.at acc prim + seq-sum-loop` in place of `xs index prim seq-int.at acc prim + index 1 prim + seq-sum-loop` on line 5. With that edit `seq-sum-loop` checks."]
    "main" [.intSeq [4, 5, 6]] [.int 15]
  -- primes-up-to (4c379e0, haiku-firth-3, answer 3): the text the edit
  -- replaces is in both branches on line 9, and only the second is the
  -- branch refused. Planted: without the column the hint would name either,
  -- and the first leaves the `if` refused. The primes below 4; the answer's
  -- own `check-divisor` tests `d d prim * n prim <`, so it takes 4 and 9
  -- for primes, a mistake of its own the edit leaves alone.
  branchCase "the text replaced found twice on its line" ": main\n  (forall ρ; ρ n:Int^many -- ρ primes:Seq Int^many)\n  locals { n } { prim seq-int.empty 2 n collect-primes };\n\n: collect-primes\n  (forall ρ; ρ result:Seq Int^many candidate:Int^many n:Int^many -- ρ primes:Seq Int^many)\n  locals { result candidate n } {\n    candidate n prim <\n    [ candidate is-prime-simple [ result candidate prim seq-int.push candidate 1 prim + n collect-primes ] [ candidate 1 prim + n collect-primes ] if ]\n    [ result ]\n    if\n  };\n\n: is-prime-simple\n  (forall ρ; ρ n:Int^many -- ρ result:Bool^many)\n  locals { n } {\n    n 2 prim <\n    [ false ]\n    [ n 2 prim = [ true ] [ n 2 check-divisor ] if ]\n    if\n  };\n\n: check-divisor\n  (forall ρ; ρ n:Int^many d:Int^many -- ρ result:Bool^many)\n  locals { n d } {\n    d d prim * n prim <\n    [ n d prim mod 0 prim = [ false ] [ n d 1 prim + check-divisor ] if ]\n    [ true ]\n    if\n  };\n"
    ["write `result candidate 1 prim + n collect-primes` in place of `candidate 1 prim + n collect-primes` on line 9, column 110. With that edit `collect-primes` checks."]
    "main" [.int 4] [.intSeq [2, 3]]
  -- all-true (4c379e0, haiku-firth-1, answer 2): the recursive call inside
  -- an inner `if` is given only the changed index.
  branchCase "an input named like a local" ": all-loop\n  (forall ρ; ρ flags:Seq Bool^many idx:Int^many -- ρ all:Bool^many)\n  locals { flags idx } {\n    idx flags prim seq-bool.len prim <\n    [ \n      flags idx prim seq-bool.at\n      [ idx 1 prim + all-loop ]\n      [ false ]\n      if\n    ]\n    [ true ]\n    if\n  };\n\n: main\n  (forall ρ; ρ flags:Seq Bool^many -- ρ all:Bool^many)\n  0 all-loop;\n"
    ["Push the first one (flags:Seq Bool) before it by writing the local of that name, `flags`: write `flags idx 1 prim + all-loop` in place of `idx 1 prim + all-loop` on line 7. With that edit `all-loop` checks."]
    "main" [.boolSeq [true, false, true]] [.bool false]
  branchCase "an input named like a local, all true" ": all-loop\n  (forall ρ; ρ flags:Seq Bool^many idx:Int^many -- ρ all:Bool^many)\n  locals { flags idx } {\n    idx flags prim seq-bool.len prim <\n    [ \n      flags idx prim seq-bool.at\n      [ idx 1 prim + all-loop ]\n      [ false ]\n      if\n    ]\n    [ true ]\n    if\n  };\n\n: main\n  (forall ρ; ρ flags:Seq Bool^many -- ρ all:Bool^many)\n  0 all-loop;\n" []
    "main" [.boolSeq [true, true]] [.bool true]
  -- Planted: the edit that binds the pushed sequence for the call would
  -- make the branches leave Int and Seq Int, so the refusal stays at the
  -- `if` and no edit is offered.
  let _ ← callReport "an edit that does not get past the `if`" "firth.type.branch-mismatch" ": count\n  (forall ρ; ρ xs:Seq Int^many -- ρ c:Int^many)\n  prim seq-int.len;\n\n: f\n  (forall ρ; ρ xs:Seq Int^many n:Int^many -- ρ r:Seq Int^many)\n  locals { xs n } { n 0 prim < [ xs ] [ xs n prim seq-int.push xs count ] if };"
    ["the result of `prim seq-int.push` is left below the result of `count`"] ["bind it to the name", "in place of"]
  -- Planted: by types alone the sequence computed from `ys` would go to
  -- `xs`, the first Seq Int input, and `k` after the empty one. The empty
  -- sequence stands for no local, so the names cannot say where each goes,
  -- and the one that does stand for a local says the types chose wrong: no
  -- edit.
  let _ ← callReport "types that would misplace a value" "firth.type.branch-mismatch"
    ": w\n  (forall ρ; ρ xs:Seq Int^many ys:Seq Int^many k:Int^many -- ρ r:Seq Int^many)\n  locals { xs ys k } { k 0 prim < [ ys ] [ ys 1 prim seq-int.push prim seq-int.empty w ] if };"
    ["`w` needs 3 values (xs:Seq Int, ys:Seq Int, k:Int)"] ["in place of"]
  -- Planted: by types the new `result` would go to `xs`, and the local
  -- `result` would be written for the input left: no edit.
  let _ ← callReport "a new value for another input" "firth.type.branch-mismatch" ": g\n  (forall ρ; ρ xs:Seq Int^many k:Int^many result:Seq Int^many -- ρ r:Seq Int^many)\n  locals { xs k result } { k 0 prim < [ result ] [ result k prim seq-int.push 5 g ] if };"
    ["`g` needs 3 values (xs:Seq Int, k:Int, result:Seq Int)"] ["in place of"]
  -- Planted: an effect naming two inputs alike. The one pushed value,
  -- from `x`, would fill both by name, and the edit would compute it twice:
  -- no edit.
  let _ ← callReport "two inputs of one name" "firth.type.branch-mismatch"
    ": h (forall ρ; ρ x:Int^many x:Int^many -- ρ r:Int^many) prim + ;\n: g\n  (forall ρ; ρ x:Int^many n:Int^many -- ρ r:Int^many)\n  locals { x n } { n 0 prim < [ x ] [ x 1 prim + h ] if };"
    ["exactly the values it takes, in this order: x:Int, x:Int"] ["in place of"]
  -- Planted: the recheck of a branch edit stops at the first erasure
  -- error, and here one follows the `if` (`locals { a b c }` handed one
  -- value), so typing never runs on the edited word. An edit that writes a
  -- local of the wrong type would pass the recheck: the edit compares the
  -- types itself. `result` is an Int here and `g` takes a Seq Int, so no
  -- edit; with a Seq Int `result` the edit is offered.
  let _ ← callReport "a local of another type, with a later erasure error" "firth.type.branch-mismatch"
    ": f\n  (forall ρ; ρ result:Int^many candidate:Int^many n:Int^many -- ρ r:Seq Int^many)\n  locals { result candidate n } {\n    candidate n prim <\n    [ candidate 1 prim + n g ]\n    [ prim seq-int.empty ]\n    if locals { a b c } { a }\n  };\n\n: g\n  (forall ρ; ρ result:Seq Int^many candidate:Int^many n:Int^many -- ρ r:Seq Int^many)\n  locals { result candidate n } { result };"
    ["`g` needs 3 values (result:Seq Int, candidate:Int, n:Int)"] ["in place of"]
  let _ ← callReport "a local of the input's type, with a later erasure error" "firth.type.branch-mismatch"
    ": f\n  (forall ρ; ρ result:Seq Int^many candidate:Int^many n:Int^many -- ρ r:Seq Int^many)\n  locals { result candidate n } {\n    candidate n prim <\n    [ candidate 1 prim + n g ]\n    [ prim seq-int.empty ]\n    if locals { a b c } { a }\n  };\n\n: g\n  (forall ρ; ρ result:Seq Int^many candidate:Int^many n:Int^many -- ρ r:Seq Int^many)\n  locals { result candidate n } { result };"
    ["write `result candidate 1 prim + n g` in place of `candidate 1 prim + n g` on line 5. With that edit, the next error in `f` is at line 7, column 17."] []
  -- Planted: likewise for a value the branch pushed, placed by the local
  -- it stands for. `result 1 prim +` stands for `result`, so by names it
  -- would go to `g`'s input `result`, but it is an Int where `g` takes a
  -- Seq Int: no edit. (Only an edit that reorders relies on this check: one
  -- that keeps the order is shown only where the types fit, first or last.)
  -- With a Seq Int `result`, `result 5 prim seq-int.push` fills it and the
  -- edit is offered.
  let _ ← callReport "a pushed value of another type, with a later erasure error" "firth.type.branch-mismatch"
    ": f\n  (forall ρ; ρ result:Int^many candidate:Int^many n:Int^many -- ρ r:Seq Int^many)\n  locals { result candidate n } {\n    candidate n prim <\n    [ result 1 prim + n g ]\n    [ prim seq-int.empty ]\n    if locals { a b c } { a }\n  };\n\n: g\n  (forall ρ; ρ n:Int^many result:Seq Int^many candidate:Int^many -- ρ r:Seq Int^many)\n  locals { n result candidate } { result };"
    ["`g` needs 3 values (n:Int, result:Seq Int, candidate:Int)"] ["in place of"]
  let _ ← callReport "a pushed value of the input's type, with a later erasure error" "firth.type.branch-mismatch"
    ": f\n  (forall ρ; ρ result:Seq Int^many candidate:Int^many n:Int^many -- ρ r:Seq Int^many)\n  locals { result candidate n } {\n    candidate n prim <\n    [ result 5 prim seq-int.push n g ]\n    [ prim seq-int.empty ]\n    if locals { a b c } { a }\n  };\n\n: g\n  (forall ρ; ρ n:Int^many result:Seq Int^many candidate:Int^many -- ρ r:Seq Int^many)\n  locals { n result candidate } { result };"
    ["write `n result 5 prim seq-int.push candidate g` in place of `result 5 prim seq-int.push n g` on line 5. With that edit, the next error in `f` is at line 7, column 17."] []
  -- Planted: likewise for a new value left behind. `xs 1 prim +` is handed
  -- no Int local, so its result is a new value of none: no edit binding it
  -- to `xs`. With `n 1 prim +` it is a new `n`, and the edit is offered.
  let _ ← callReport "a result of another type, with a later erasure error" "firth.type.branch-mismatch"
    ": g\n  (forall ρ; ρ xs:Seq Int^many -- ρ r:Seq Int^many)\n  ;\n\n: f\n  (forall ρ; ρ xs:Seq Int^many n:Int^many -- ρ r:Seq Int^many)\n  locals { xs n } { n 0 prim < [ xs ] [ xs 1 prim + xs g ] if locals { a b c } { a } };"
    ["the result of `prim +` is left below the result of `g`"] ["bind it to the name", "in place of"]
  let _ ← callReport "a new value of a local, with a later erasure error" "firth.type.branch-mismatch"
    ": g\n  (forall ρ; ρ n:Int^many -- ρ r:Seq Int^many)\n  drop prim seq-int.empty;\n\n: f\n  (forall ρ; ρ xs:Seq Int^many n:Int^many -- ρ r:Seq Int^many)\n  locals { xs n } { n 0 prim < [ xs ] [ n 1 prim + n g ] if locals { a b c } { a } };"
    ["write `prim + locals { n } { n g }` in place of `prim + n g` on line 7. With that edit, the next error in `f` is at line 7, column 87."] []
  -- Planted: two results of an `if` merged by an outer `if`, one standing
  -- for `a` and one for `b`. The merged value stands for neither, so its
  -- place is told by types alone, not "by their names" as if from `a`.
  let _ ← callReport "an `if` whose paths stand for different locals" "firth.type.branch-mismatch"
    ": h (forall ρ; ρ a:Int^many s:Seq Int^many b:Int^many -- ρ r:Int^many) drop drop ;\n: g\n  (forall ρ; ρ a:Int^many b:Int^many s:Seq Int^many c:Int^many -- ρ r:Int^many)\n  locals { a b s c } {\n    c 0 prim = [ 0 ] [\n      s c 1 prim < [ c 2 prim < [ a 1 prim + ] [ a 1 prim - ] if ] [ c 3 prim < [ b 1 prim + ] [ b 1 prim - ] if ] if h\n    ] if\n  };\n"
    ["in the place of the last 2 (s:Seq Int, b:Int)"] ["(from `a`)", "by their names"]
  -- count-below (8ea4a1d, haiku-firth-11, answer 1), verbatim: the inner
  -- `if`'s condition is written after its two quotations. Moving it first
  -- makes the word check; [1, 5, 2, 8] has two values below 4.
  let (hint, _) ← callReport "a condition after its quotations" "firth.type.expected-bool" ": main\n  (forall ρ; ρ xs:Seq Int^many k:Int^many -- ρ count:Int^many)\n  locals { xs k } {\n    xs k 0 0 count-loop\n  };\n\n: count-loop\n  (forall ρ; ρ xs:Seq Int^many k:Int^many i:Int^many count:Int^many -- ρ result:Int^many)\n  locals { xs k i count } {\n    i xs prim seq-int.len prim <\n    [\n      xs\n      k\n      i 1 prim +\n      [ count 1 prim + ]\n      [ count ]\n      xs i prim seq-int.at k prim <\n      if\n      count-loop\n    ]\n    [ count ]\n    if\n  };\n"
    ["`if` finds the condition on top of its two quotations, not under them.",
     "Write the condition before the first `[`: write `xs i prim seq-int.at k prim < [ count 1 prim + ] [ count ] if` in place of `[ count 1 prim + ] [ count ] xs i prim seq-int.at k prim < if` on line 15. With that edit `count-loop` checks."]
  match applyBranchHint ": main\n  (forall ρ; ρ xs:Seq Int^many k:Int^many -- ρ count:Int^many)\n  locals { xs k } {\n    xs k 0 0 count-loop\n  };\n\n: count-loop\n  (forall ρ; ρ xs:Seq Int^many k:Int^many i:Int^many count:Int^many -- ρ result:Int^many)\n  locals { xs k i count } {\n    i xs prim seq-int.len prim <\n    [\n      xs\n      k\n      i 1 prim +\n      [ count 1 prim + ]\n      [ count ]\n      xs i prim seq-int.at k prim <\n      if\n      count-loop\n    ]\n    [ count ]\n    if\n  };\n" hint with
  | some edited => expectRuns "a condition after its quotations" edited "main" [.intSeq [1, 5, 2, 8], .int 4] [.int 2]
  | none => fail s!"a condition after its quotations: the hint's edit does not apply: {hint}"
  -- Planted: primes-up-to (8ea4a1d, haiku-firth-11, answer 1), verbatim.
  -- Moving `is-prime` before the quotations leaves the `if` refused (its
  -- branches leave different numbers of values): no edit.
  let _ ← callReport "a condition moved that does not get past the `if`" "firth.type.word-input-mismatch" ": main\n  (forall ρ; ρ n:Int^many -- ρ primes:Seq Int^many)\n  locals { n } {\n    prim seq-int.empty 2 primes-loop\n  };\n\n: primes-loop\n  (forall ρ; ρ result:Seq Int^many candidate:Int^many -- ρ out:Seq Int^many)\n  locals { result candidate } {\n    [ candidate 10 prim < ]\n    [ [ result candidate prim seq-int.push candidate 1 prim + ] [ candidate 1 prim + ] is-prime if primes-loop ]\n    [ 0 prim not prim not ]\n    candidate 10 prim <\n    if\n  };\n\n: is-prime\n  (forall ρ; ρ candidate:Int^many -- ρ prime:Bool^many)\n  locals { candidate } {\n    [ prim not prim not ]\n    [ candidate 2 2 is-prime-check ]\n    candidate 2 prim <\n    if\n  };\n\n: is-prime-check\n  (forall ρ; ρ candidate:Int^many divisor:Int^many limit:Int^many -- ρ prime:Bool^many)\n  locals { candidate divisor limit } {\n    [ candidate divisor prim mod 0 prim = prim not ]\n    [ [ prim not prim not ] [ divisor 1 prim + limit is-prime-check ] divisor limit prim < if ]\n    [ 0 prim not prim not ]\n    divisor divisor prim * candidate prim <\n    if\n  };\n"
    ["`is-prime` in `primes-loop`"] ["before the first `[`"]
  -- Planted: a condition that, as written, acts on the quotations under it.
  -- The checker accepts `swap` on top of them and refuses only the `if`;
  -- moved first, `swap` would exchange `a` and `b` and the word would check
  -- with another meaning, so no edit is offered (the reviewer on #187).
  let _ ← callReport "a condition that acts on its quotations" "firth.type.expected-bool"
    ": pick2\n  (forall ρ; ρ a:Int^many b:Int^many c:Int^many -- ρ r:Int^many)\n  locals { a b c } {\n    a b [ prim + ] [ prim - ] swap c 0 prim < if\n  };"
    [] ["before the first `[`"]
  -- Refused inside the condition, the condition was never accepted on the
  -- quotations, so moving it has one reading: `dup` then copies `n`.
  let dupFirst := ": g\n  (forall ρ; ρ n:Int^many -- ρ n2:Int^many r:Int^many)\n  [ 1 ] [ 2 ] dup 0 prim < if\n  ;"
  let (hint, _) ← callReport "a condition refused on its quotations" "firth.type.primitive-input-mismatch" dupFirst
    ["Write the condition before the first `[`: write `dup 0 prim < [ 1 ] [ 2 ] if` in place of `[ 1 ] [ 2 ] dup 0 prim < if` on line 3. With that edit `g` checks."]
  match applyBranchHint dupFirst hint with
  | some edited => expectRuns "a condition refused on its quotations" edited "g" [.int 5] [.int 5, .int 2]
  | none => fail s!"a condition refused on its quotations: the hint's edit does not apply: {hint}"
  -- An edit is said to get past the refused `if` only when its next error
  -- shows the check went beyond it. Planted: an error at the `if`, or one
  -- before it found by erasure, or found by typing when typing refused the
  -- `if`, may have stopped the check short of it.
  let pastCases : List (String × Bool × Bool × Nat × Bool) :=
    [ ("after, by erasure", true, false, 20, true)
    , ("after, by typing", false, true, 20, true)
    , ("a type error before an `if` erasure refused", true, true, 5, true)
    , ("at the `if`", true, true, 10, false)
    , ("before, by erasure", true, false, 5, false)
    , ("before, by typing, when typing refused it", false, true, 5, false) ]
  for (name, byErasure, typing, offset, expected) in pastCases do
    if editGetsPast byErasure typing 10 offset != expected then
      throw <| IO.userError s!"edit gets past its `if`: {name}: expected {expected}"
  -- An edit that gets past this operation but not the next mistake says
  -- where that is: digits at cec3707 (haiku-firth-1, answer 1), the helper
  -- verbatim, where a `swap` also puts the sequence on top for the call.
  -- The second report's edit drops that `swap`; with both, 123 gives its
  -- digits from the last.
  let digits := ": extract-digits\n  (forall ρ; ρ result:Seq Int^many n:Int^many -- ρ final:Seq Int^many)\n  locals { result n } {\n    n 0 prim =\n    [ result ]\n    [\n      n 10 prim mod result prim seq-int.push\n      n 10 prim div swap extract-digits\n    ]\n    if\n  };"
  -- The same with the values on two lines: the edit joins them, so the
  -- next error is on the line after the edit, one earlier than in the
  -- source as written. The edited source is written out here by hand, and
  -- the checker must report its error where the hint says.
  let digitsTwoLines := digits.replace "n 10 prim mod result prim seq-int.push" "n 10 prim mod\n      result prim seq-int.push"
  let digitsJoined := digits.replace "n 10 prim mod result prim seq-int.push" "result n 10 prim mod prim seq-int.push"
  let _ ← callReport "digits, the values on two lines" "firth.type.primitive-input-mismatch" digitsTwoLines
    ["write `result n 10 prim mod` in place of `n 10 prim mod result` on line 7. With that edit, the next error in `extract-digits` is at line 8, column 26."]
  match elaboratePipeline pipelineContext digitsJoined agentConfig with
  | .failure [envelope] =>
      unless (encode envelope).contains "\"start\":{\"line\":8,\"column\":26}" do
        fail s!"digits, the values on two lines: the edited source is refused elsewhere: {encode envelope}"
  | _ => fail "digits, the values on two lines: expected one report for the edited source"
  let (hint, operation) ← callReport "digits" "firth.type.primitive-input-mismatch" digits
    ["write `result n 10 prim mod` in place of `n 10 prim mod result` on line 7. With that edit, the next error in `extract-digits` is at line 8, column 26."]
  match applyCallHint digits hint operation with
  | none => fail s!"digits: the hint's edit does not apply: {hint}"
  | some once =>
      callCase "digits, then the call" "firth.type.word-input-mismatch" once
        ["write `result n 10 prim mod prim seq-int.push n 10 prim div` in place of `result n 10 prim mod prim seq-int.push n 10 prim div swap` on line 1. With that edit `extract-digits` checks."]
        [] "extract-digits" [.intSeq [], .int 123] [.intSeq [3, 2, 1]]
  -- The next error's place is where the author will see it once the edit
  -- is made: the line break before the call stays as written. ledger at
  -- 8ea4a1d (haiku-firth-2, answer 2), verbatim; the checker then reports the
  -- call on line 10, not the start of its values on line 9 (the reviewer on
  -- #187).
  let ledger := ": ledger-loop\n  (forall ρ; ρ txs:Seq Int^many i:Int^many bal:Int^many rej:Int^many -- ρ result1:Int^many result2:Int^many)\n  locals { txs i bal rej } {\n    txs prim seq-int.len i prim < [\n      bal txs i prim seq-int.at prim + dup 0 prim < [\n        drop bal rej 1 prim + txs swap i swap\n        ledger-loop\n      ] [\n        i 1 prim + txs swap rej swap\n        ledger-loop\n      ] if\n    ] [\n      bal rej\n    ] if\n  };\n\n: main\n  (forall ρ; ρ start:Int^many txs:Seq Int^many -- ρ balance:Int^many rejected:Int^many)\n  locals { start txs } {\n    txs 0 start 0 ledger-loop\n  };\n"
  let (hint, _) ← callReport "the next error after an edit before a line break" "firth.type.word-input-mismatch" ledger
    ["write `txs i bal rej 1 prim +` in place of `bal rej 1 prim + txs swap i swap` on line 6. With that edit, the next error in `ledger-loop` is at line 10, column 9."]
  -- Applied on line 6, where the text replaced is found once, with the
  -- source's line breaks kept as the author's would be.
  let written := "bal rej 1 prim + txs swap i swap"
  unless hint.contains s!"in place of `{written}` on line 6." &&
      (ledger.splitOn written).length == 2 && (((ledger.splitOn "\n")[5]?).getD "").contains written do
    fail s!"ledger: the hint's edit is not the one on line 6: {hint}"
  let edited := ledger.replace written "txs i bal rej 1 prim +"
  match reportsWithCode (elaboratePipeline pipelineContext edited agentConfig) "firth.type.word-input-mismatch" with
  | [envelope] =>
      unless (encode envelope).contains "\"start\":{\"line\":10,\"column\":9}" do
        fail s!"ledger: the edited source is not refused at line 10, column 9: {encode envelope}"
  | _ => fail "ledger: expected one report for the edited source"
  -- Where values of one type could go either way, the report says which
  -- values are certain and leaves the rest to the author, with no edit:
  -- seq-sum at 470c6d0 (haiku-firth-1, answer 1), where pushing the Int
  -- values in the order written happens to be right, and longest-run in the
  -- same answer, where it would put the new maximum in `prev`.
  let _ ← callReport "same types either way" "firth.type.word-input-mismatch"
    ": sum-loop\n  (forall ρ; ρ xs:Seq Int^many acc:Int^many i:Int^many -- ρ result:Int^many)\n  locals { xs acc i } {\n    i xs prim seq-int.len prim <\n    [\n      xs i prim seq-int.at acc prim +\n      xs\n      i 1 prim +\n      sum-loop\n    ]\n    [ acc ]\n    if\n  };"
    ["By their names and types, `xs` is for `xs`. Of the values of one type, `xs i prim seq-int.at acc prim +` and `i 1 prim +` are for `acc` and `i`, in the order you mean: only you can tell which is which."]
    ["in place of"]
  -- A sequence primitive's inputs have no names, only types, so the report
  -- tells them by what they are for rather than quoting a type as if it
  -- named one (`counts` is for `Seq Int`, before): increment-count at
  -- 4c379e0 (haiku-firth-3, answer 2), verbatim.
  let _ ← callReport "roles of a sequence primitive" "firth.type.primitive-input-mismatch"
    ": increment-count\n  (forall ρ; ρ counts:Seq Int^many idx:Int^many -- ρ result:Seq Int^many)\n  locals { counts idx }\n  { counts idx prim seq-int.at 1 prim + counts idx swap prim seq-int.set };\n"
    ["`prim seq-int.set` in `increment-count` takes the sequence (Seq Int), the index (Int) and the new value (Int), bottom to top",
     "By their names and types, `counts` is for the sequence. Of the values of one type, `counts idx prim seq-int.at 1 prim +` and `idx` are for the index and the new value, in the order you mean: only you can tell which is which."]
    ["in place of", "`Seq Int`", "`Int`"]
  -- A value the source pushed with `dup` is not a piece of source of its
  -- own, so no edit is stated; the report still names it (prefix-sums at
  -- c6a964a, haiku-firth-2, answer 3, with its first mistake fixed).
  let _ ← callReport "no edit through dup" "firth.type.primitive-input-mismatch"
    ": prefix-loop\n  (forall ρ; ρ result:Seq Int^many sum:Int^many xs:Seq Int^many idx:Int^many -- ρ sums:Seq Int^many)\n  locals { result sum xs idx } {\n    idx xs prim seq-int.len prim < [\n      sum xs idx prim seq-int.at prim + \n      dup result prim seq-int.push\n      xs idx 1 prim + prefix-loop\n    ] [ result ] if\n  };"
    ["`prim seq-int.push` in `prefix-loop` takes the sequence (Seq Int) and the value pushed (Int), bottom to top, but here it gets, bottom to top, the result of `prim +` (Int) and `result` (Seq Int).",
     "The top value, `result` (Seq Int), is not what `prim seq-int.push` takes there (Int)."]
    ["in place of"]
  -- A word the environment defines outside the file (`nth`, Seq Int Int --
  -- Int) has no input names in the account, so the report takes its input
  -- types from the checker's scheme, not only a count (Codex on #171).
  let nthScheme : Firth.Elaborator.StackEffect.Scheme :=
    { rowVariables := ["ρ"]
      input := .snoc (.snoc (.row (.rigid "ρ")) (.base "Seq Int" .many)) (.base "Int" .many)
      output := .snoc (.row (.rigid "ρ")) (.base "Int" .many) }
  let externalConfig : Firth.Elaborator.PipelineConfig :=
    { erasureEnv := { Elaborate.gammaErasure with
        word := fun name => if name == "nth" then some { input := [.many, .many], output := [.many] } else none }
      typingEnv := { Elaborate.gammaTyping with
        word := fun name => if name == "nth" then some nthScheme else none } }
  match elaboratePipeline pipelineContext ": first\n  (forall ρ; ρ xs:Seq Int^many -- ρ r:Int^many)\n  locals { xs } { 0 xs nth };" externalConfig with
  | .failure [envelope] =>
      let emitted := encode envelope
      for needle in ["`nth` in `first` takes Seq Int, Int, bottom to top, but here it gets, bottom to top, `0` (Int) and `xs` (Seq Int).",
                     "write `xs 0` in place of `0 xs` on line 3. With that edit `first` checks."] do
        unless emitted.contains needle do
          fail s!"external word: the report does not say {needle}: {emitted}"
  | _ => fail "external word: expected one diagnostic"
  -- Planted: a local whose type is not known is not passed over. `seven`
  -- is defined outside the file, so the local `m` it is bound to has no
  -- type in the account. By types alone `5` would go to `m` and the local
  -- `n` be written for `n`, but `m` may be the value meant for `g`'s `m`,
  -- so no edit is stated.
  let sevenConfig : Firth.Elaborator.PipelineConfig :=
    { erasureEnv := { Elaborate.gammaErasure with
        word := fun name => if name == "seven" then some { input := [], output := [.many] } else none }
      typingEnv := { Elaborate.gammaTyping with
        word := fun name => if name == "seven" then
          some { rowVariables := ["ρ"], input := .row (.rigid "ρ"), output := .snoc (.row (.rigid "ρ")) (.base "Int" .many) }
          else none } }
  match elaboratePipeline pipelineContext ": g (forall ρ; ρ n:Int^many m:Int^many -- ρ r:Int^many) prim - ;\n: f (forall ρ; ρ n:Int^many -- ρ r:Int^many) locals { n } { seven locals { m } { 5 g } } ;\n" sevenConfig with
  | .failure [envelope] =>
      let emitted := encode envelope
      unless emitted.contains "firth.type.stack-underflow" && emitted.contains "`g` in `f` takes 2 values" do
        fail s!"a local of unknown type: expected the stack-underflow at `g`: {emitted}"
      if emitted.contains "in place of" then
        fail s!"a local of unknown type: the report states an edit: {emitted}"
  | _ => fail "a local of unknown type: expected one diagnostic"
  -- `prim <=`, `prim >` and `prim >=` are primitives. Answers from earlier
  -- runs that wrote them, which were refused when they were not, now check
  -- as written and give the values worked out by hand; each case includes
  -- equal values, where `<` and `<=` part.
  -- keep-positive (4c379e0, haiku-firth-10, answer 2), verbatim. 0 is not
  -- positive, so it is left out.
  expectRuns "`prim >` written for greater than" ": main\n  (forall ρ; ρ xs:Seq Int^many -- ρ positives:Seq Int^many)\n  locals { xs } {\n    0 prim seq-int.empty xs keep-positive-helper\n  };\n\n: keep-positive-helper\n  (forall ρ; ρ i:Int^many result:Seq Int^many xs:Seq Int^many -- ρ result:Seq Int^many)\n  locals { i result xs } {\n    i xs prim seq-int.len prim = [ result ] [\n      xs i prim seq-int.at locals { val } {\n        val 0 prim > [ result val prim seq-int.push ] [ result ] if\n        i 1 prim + swap xs keep-positive-helper\n      }\n    ] if\n  };\n"
    "main" [.intSeq [3, -1, 0, 2]] [.intSeq [3, 2]]
  -- is-sorted (4c379e0, haiku-firth-10, answer 3, a final answer),
  -- verbatim. The answer compares from index 1, a mistake of its own;
  -- 3 then 3 is in order.
  expectRuns "`prim <=` written for at most" ": main\n  (forall ρ; ρ xs:Seq Int^many -- ρ sorted:Bool^many)\n  locals { xs } {\n    xs prim seq-int.len 0 prim = [ true ] [\n      xs prim seq-int.len 1 prim = [ true ] [\n        1 xs is-sorted-helper\n      ] if\n    ] if\n  };\n\n: is-sorted-helper\n  (forall ρ; ρ i:Int^many xs:Seq Int^many -- ρ result:Bool^many)\n  locals { i xs } {\n    i 1 prim + xs prim seq-int.len prim = [ true ] [\n      xs i prim seq-int.at xs i 1 prim + prim seq-int.at prim <= [\n        i 1 prim + xs is-sorted-helper\n      ] [\n        false\n      ] if\n    ] if\n  };\n"
    "main" [.intSeq [1, 3, 3]] [.bool true]
  expectRuns "`prim <=` written for at most, out of order" ": main\n  (forall ρ; ρ xs:Seq Int^many -- ρ sorted:Bool^many)\n  locals { xs } {\n    xs prim seq-int.len 0 prim = [ true ] [\n      xs prim seq-int.len 1 prim = [ true ] [\n        1 xs is-sorted-helper\n      ] if\n    ] if\n  };\n\n: is-sorted-helper\n  (forall ρ; ρ i:Int^many xs:Seq Int^many -- ρ result:Bool^many)\n  locals { i xs } {\n    i 1 prim + xs prim seq-int.len prim = [ true ] [\n      xs i prim seq-int.at xs i 1 prim + prim seq-int.at prim <= [\n        i 1 prim + xs is-sorted-helper\n      ] [\n        false\n      ] if\n    ] if\n  };\n"
    "main" [.intSeq [1, 4, 3]] [.bool false]
  -- Constructed: two comparisons in one word. The
  -- values from 2 to 4 in [1, 2, 3, 4, 5] are 2, 3 and 4.
  expectRuns "`prim >=` and `prim <=` in one word" ": count-in-range\n  (forall ρ; ρ xs:Seq Int^many i:Int^many lo:Int^many hi:Int^many n:Int^many -- ρ r:Int^many)\n  locals { xs i lo hi n } {\n    i xs prim seq-int.len prim = [ n ] [\n      xs i prim seq-int.at locals { x } {\n        x lo prim >=\n        x hi prim <= prim and\n        [ n 1 prim + ] [ n ] if locals { m } { xs i 1 prim + lo hi m count-in-range }\n      }\n    ] if\n  };\n"
    "count-in-range" [.intSeq [1, 2, 3, 4, 5], .int 0, .int 2, .int 4, .int 0] [.int 3]
  -- A word or primitive handed fewer values than it takes, as the body is
  -- written: reported there with the values it gets, not at a `dip` or
  -- `compose` erasure wrote. Where the values written just after it are
  -- for its last inputs by name (a local) or type (a literal), the hint
  -- moves them before it; the test applies that edit and runs the result.
  -- Applies the edit a hint states, `Write `R` in place of `W` on line L`,
  -- and any others it lists after "too: ".
  let replaceOn (source : String) (line : Nat) (written replacement : String) : Option String :=
    let lines := source.splitOn "\n"
    match lines[line - 1]? with
    | none => none
    | some text =>
        let tokens := text.splitOn " "
        let wanted := written.splitOn " "
        let at? := (List.range tokens.length).find? fun k => (tokens.drop k).take wanted.length == wanted
        match at? with
        | none => none
        | some k =>
            let edited := " ".intercalate (tokens.take k ++ [replacement] ++ tokens.drop (k + wanted.length))
            some ("\n".intercalate (lines.set (line - 1) edited))
  let applyEditHint (source hint : String) : Option String := do
    let first ← (hint.splitOn "Write `")[1]?
    let replacement := upTo first "`"
    let after ← (first.splitOn "` in place of `")[1]?
    let written := upTo after "`"
    let line ← (upTo ((after.splitOn "` on line ")[1]?.getD "") "," |>.splitOn "." |>.headD "").toNat?
    let others := ((hint.splitOn "too: ")[1]?.map (upTo · ". With")).getD ""
    let rest := if others.isEmpty then [] else others.splitOn ", "
    let mut edited ← replaceOn source line written replacement
    for other in rest do
      let piece := (other.splitOn "and ").getLast!
      let otherWritten := upTo (piece.drop 1).toString "`"
      let otherLine ← (upTo ((piece.splitOn "` on line ")[1]?.getD "") " ").toNat?
      let otherReplacement := upTo ((piece.splitOn " as `")[1]?.getD "") "`"
      edited ← replaceOn edited otherLine otherWritten otherReplacement
    pure edited
  let shortCase (label source : String) (needles absent : List String) (word : String)
      (inputs expected : List Firth.Interpreter.Literal) : IO Unit := do
    let (hint, _) ← callReport label "firth.type.stack-underflow" source needles absent
    match applyEditHint source hint with
    | some edited => expectRuns label edited word inputs expected
    | none => fail s!"{label}: the hint's edit does not apply: {hint}"
  -- seq-sum (locals-guide arm a, haiku-firth-5, answer 1), verbatim: the
  -- call is written before its values. 4 + 5 + 6.
  shortCase "a call written before its values" ": main\n  (forall ρ; ρ xs:Seq Int^many -- ρ total:Int^many)\n  locals { xs } { sum-loop xs 0 0 };\n\n: sum-loop\n  (forall ρ; ρ xs:Seq Int^many i:Int^many sum:Int^many -- ρ total:Int^many)\n  locals { xs i sum } {\n    i xs prim seq-int.len prim < [\n      xs\n      i 1 prim +\n      xs i prim seq-int.at sum prim +\n      sum-loop\n    ] [\n      sum\n    ] if\n  };\n"
    ["`sum-loop` in `main` takes 3 values (xs:Seq Int, i:Int, sum:Int), bottom to top, but nothing is on the stack before it.",
     "The values `sum-loop` takes are pushed before it, and `xs`, `0` and `0` are written after it. Write `xs 0 0 sum-loop` in place of `sum-loop xs 0 0` on line 3. With that edit `main` checks."] []
    "main" [.intSeq [4, 5, 6]] [.int 15]
  -- Constructed: in a `locals` block the checker refused the `dip`
  -- erasure wrote to reach `xs`, which the author never wrote. 1 + 2 + 5.
  -- Planted: the moved value must fill the input of its name, `g`'s last.
  shortCase "a value written after the call in a `locals` block" ": g (forall ρ; ρ a:Int^many b:Int^many xs:Int^many -- ρ r:Int^many) prim + prim + ;\n: f (forall ρ; ρ xs:Int^many -- ρ r:Int^many) locals { xs } { 1 2 g xs };\n"
    ["`g` in `f` takes 3 values (a:Int, b:Int, xs:Int), bottom to top, but only 2 values are on the stack before it, bottom to top: `1` (Int) and `2` (Int).",
     "Write `xs g` in place of `g xs` on line 2. With that edit `f` checks."] ["dip"]
    "f" [.int 5] [.int 8]
  -- A local not pushed at all: where each input missing is named like a
  -- local of its type and the values present fill the others in one way
  -- alone, the edit writes those locals in their places. The test applies
  -- the edit and runs the result.
  let unpushedCase (label source : String) (needles absent : List String) (word : String)
      (inputs expected : List Firth.Interpreter.Literal) : IO Unit := do
    let (hint, _) ← callReport label "firth.type.stack-underflow" source needles absent
    match applyEditHint source (hint.replace ": write `" ": Write `") with
    | some edited => expectRuns label edited word inputs expected
    | none => fail s!"{label}: the hint's edit does not apply: {hint}"
  -- seq-max (locals-guide arm b, haiku-firth-6, answer 2), verbatim: `xs`,
  -- `loop-max`'s last input, is not pushed. The largest of [3, 9, 2] is 9.
  unpushedCase "a local not pushed" ": main\n  (forall ρ; ρ xs:Seq Int^many -- ρ largest:Int^many)\n  locals { xs } { xs 0 prim seq-int.at locals { first } { first 1 xs prim seq-int.len loop-max } };\n\n: loop-max\n  (forall ρ; ρ max:Int^many i:Int^many len:Int^many xs:Seq Int^many -- ρ result:Int^many)\n  locals { max i len xs } { i len prim < [ xs i prim seq-int.at locals { val } { val max prim < [ max ] [ val ] if locals { new-max } { new-max i 1 prim + len xs loop-max } } ] [ max ] if };\n"
    ["`loop-max` in `main` takes 4 values (max:Int, i:Int, len:Int, xs:Seq Int), bottom to top, but only 3 values are on the stack before it, bottom to top: `first` (Int), `1` (Int) and the result of `prim seq-int.len` (Int).",
     "Push the missing value (xs:Seq Int) by writing the local of that name, `xs`: write `first 1 xs prim seq-int.len xs loop-max` in place of `first 1 xs prim seq-int.len loop-max` on line 3. With that edit `main` checks."]
    ["The local here"]
    "main" [.intSeq [3, 9, 2]] [.int 9]
  -- count-below (locals-guide arm b, haiku-firth-17, answer 2), verbatim:
  -- `k` goes last, after `0 xs 0` fill the first three inputs. The helper
  -- has a mistake of its own, which the next error is.
  let _ ← callReport "a local not pushed, last" "firth.type.stack-underflow" ": main\n  (forall ρ; ρ xs:Seq Int^many k:Int^many -- ρ count:Int^many)\n  locals { xs k } { 0 xs 0 count-below-helper };\n\n: count-below-helper\n  (forall ρ; ρ count:Int^many xs:Seq Int^many i:Int^many k:Int^many -- ρ result:Int^many)\n  locals { count xs i k } {\n    i xs prim seq-int.len prim <\n    [ xs i prim seq-int.at k prim < [ count 1 prim + ] [ count ] if i 1 prim + xs k count-below-helper ]\n    [ count ]\n    if\n  };\n"
    ["`count-below-helper` in `main` takes 4 values (count:Int, xs:Seq Int, i:Int, k:Int), bottom to top, but only 3 values are on the stack before it, bottom to top: `0` (Int), `xs` (Seq Int) and `0` (Int).",
     "Push the missing value (k:Int) by writing the local of that name, `k`: write `0 xs 0 k count-below-helper` in place of `0 xs 0 count-below-helper` on line 3."]
    ["dip"]
  -- Constructed, after dot (locals-guide arm b, haiku-firth-22, answer 1):
  -- the two sequences go first. [1, 2] and [3, 4] give 3 + 8.
  unpushedCase "two locals not pushed, first" ": dot-helper\n  (forall ρ; ρ xs:Seq Int^many ys:Seq Int^many i:Int^many sum:Int^many -- ρ result:Int^many)\n  locals { xs ys i sum } {\n    i xs prim seq-int.len prim <\n    [ xs ys i 1 prim + xs i prim seq-int.at ys i prim seq-int.at prim * sum prim + dot-helper ]\n    [ sum ]\n    if\n  };\n\n: main\n  (forall ρ; ρ xs:Seq Int^many ys:Seq Int^many -- ρ result:Int^many)\n  locals { xs ys } { 0 0 dot-helper };\n"
    ["Push the 2 missing values (xs:Seq Int, ys:Seq Int) by writing the locals of those names, `xs` and `ys`: write `xs ys 0 0 dot-helper` in place of `0 0 dot-helper` on line 12. With that edit `main` checks."] []
    "main" [.intSeq [1, 2], .intSeq [3, 4]] [.int 11]
  -- A value that stands for a local goes to the input of that name, not
  -- to another: `b` fills `b`, and `a` is written before it. 7 - 2.
  unpushedCase "a value present named like an input" ": g (forall ρ; ρ a:Int^many b:Int^many -- ρ r:Int^many) prim - ;\n: f (forall ρ; ρ a:Int^many b:Int^many -- ρ r:Int^many) locals { a b } { b g } ;\n"
    ["write `a b g` in place of `b g` on line 2. With that edit `f` checks."] []
    "f" [.int 7, .int 2] [.int 5]
  -- Planted: one Int present and three Int inputs, each a local: it could
  -- fill any of them, so no edit.
  let _ ← callReport "a place the types leave open" "firth.type.stack-underflow"
    ": g (forall ρ; ρ a:Int^many b:Int^many c:Int^many -- ρ r:Int^many) prim + prim + ;\n: f (forall ρ; ρ a:Int^many b:Int^many c:Int^many -- ρ r:Int^many) locals { a b c } { 1 g } ;\n"
    ["`g` in `f` takes 3 values"] ["in place of"]
  -- Types decide the place too. Both of `g`'s inputs are locals, but `m`
  -- is a Bool, so the Int `5` fills `m` and `n` is written. 7 - 5.
  unpushedCase "a local's type decides" ": g (forall ρ; ρ n:Int^many m:Int^many -- ρ r:Int^many) prim - ;\n: f (forall ρ; ρ n:Int^many m:Bool^many -- ρ r:Int^many) locals { n m } { 5 g } ;\n"
    ["write `n 5 g` in place of `5 g` on line 2. With that edit `f` checks."] []
    "f" [.int 7, .bool true] [.int 2]
  -- Likewise a value's: `true` can only be `flag`, so `n` is written.
  unpushedCase "a value's type decides" ": g (forall ρ; ρ n:Int^many flag:Bool^many -- ρ r:Int^many) drop ;\n: f (forall ρ; ρ n:Int^many flag:Bool^many -- ρ r:Int^many) locals { n flag } { true g } ;\n"
    ["write `n true g` in place of `true g` on line 2. With that edit `f` checks."] []
    "f" [.int 4, .bool false] [.int 4]
  -- Planted: 30 Int inputs, each a local, and 15 Int values present. The
  -- values could fill any 15 of the inputs, C(30, 15) ways; listing each
  -- (as the first version did) does not finish. Counting up to two ways
  -- does, and says the place is open: no edit.
  let many := (List.range 30).map (s!"v{·}")
  let manyEffect := " ".intercalate (many.map (s!"{·}:Int^many"))
  let manyValues := " ".intercalate ((List.range 15).map toString)
  let _ ← callReport "a place open in very many ways" "firth.type.stack-underflow"
    s!": g (forall ρ; ρ {manyEffect} -- ρ r:Int^many) {" ".intercalate (List.replicate 29 "prim +")} ;\n: f (forall ρ; ρ {manyEffect} -- ρ r:Int^many) locals \{ {" ".intercalate many} } \{ {manyValues} g } ;\n"
    ["`g` in `f` takes 30 values"] ["in place of"]
  -- A local written just after the call, named like the input missing,
  -- is moved into place: written again, it would be left over. 4.
  unpushedCase "a local written after the call" ": g (forall ρ; ρ n:Int^many b:Bool^many -- ρ r:Int^many) drop ;\n: f (forall ρ; ρ n:Int^many b:Bool^many -- ρ r:Int^many) locals { n b } { true g n } ;\n"
    ["by moving the local of that name, `n`, written after `g`, into its place before it: write `n true g` in place of `true g n` on line 2. With that edit `f` checks."] []
    "f" [.int 4, .bool false] [.int 4]
  -- Planted: here the `n` after `g` is for `prim +`. Moved, `prim +` would
  -- be short of a value; written again, the word checks: 3 + 3.
  unpushedCase "a local after the call meant for what follows" ": g (forall ρ; ρ n:Int^many b:Bool^many -- ρ r:Int^many) drop ;\n: f (forall ρ; ρ n:Int^many b:Bool^many -- ρ r:Int^many) locals { n b } { true g n prim + } ;\n"
    ["by writing the local of that name, `n`: write `n true g` in place of `true g` on line 2. With that edit `f` checks."] ["by moving"]
    "f" [.int 3, .bool true] [.int 6]
  -- Planted: here the `n` after `g` may be for the last `prim +`, and the
  -- `prim +` of a Bool between is the author's own mistake. Moved or written
  -- again, checking stops at that mistake, so nothing tells the two edits
  -- apart and neither is stated (Codex on #208).
  let _ ← callReport "a local after the call, the two edits stopped alike" "firth.type.stack-underflow"
    ": g (forall ρ; ρ n:Int^many b:Bool^many -- ρ r:Int^many) drop ;\n: f (forall ρ; ρ n:Int^many b:Bool^many -- ρ r:Int^many) locals { n b } { true g n b 1 prim + drop prim + } ;\n"
    ["`g` in `f` takes 2 values"]
    ["by moving", "in place of"]
  -- Moved, checking stops further on than with `n` written again: there
  -- the `n` left over is the condition of the `if`, which takes a Bool.
  let _ ← callReport "a local after the call, moved further" "firth.type.stack-underflow"
    ": g (forall ρ; ρ n:Int^many b:Bool^many -- ρ r:Bool^many) drop drop true ;\n: f (forall ρ; ρ n:Int^many b:Bool^many -- ρ r:Int^many) locals { n b } { true g n [ 1 ] [ 2 ] if true prim + } ;\n"
    ["by moving the local of that name, `n`, written after `g`, into its place before it: write `n true g` in place of `true g n` on line 2. With that edit, the next error in `f` is at line 2"]
    []
  -- Planted: written again, checking stops further on than with `n` moved,
  -- where the first `prim +` is short of a value.
  let _ ← callReport "a local after the call, written again further" "firth.type.stack-underflow"
    ": g (forall ρ; ρ n:Int^many b:Bool^many -- ρ r:Int^many) drop ;\n: f (forall ρ; ρ n:Int^many b:Bool^many -- ρ r:Int^many) locals { n b } { true g n prim + b 1 prim + drop } ;\n"
    ["by writing the local of that name, `n`: write `n true g` in place of `true g` on line 2. With that edit, the next error in `f` is at line 2"]
    ["by moving"]
  -- Planted: a comment between the call and the local is not moved over,
  -- so it is not lost; the local is written again (cubic on #208).
  let _ ← callReport "a local after the call, past a comment" "firth.type.stack-underflow"
    ": g (forall ρ; ρ n:Int^many b:Bool^many -- ρ r:Int^many) drop ;\n: f (forall ρ; ρ n:Int^many b:Bool^many -- ρ r:Int^many) locals { n b } { true g (* kept *) n } ;\n"
    ["`g` in `f` takes 2 values"]
    ["by moving", "in place of `true g (* kept *) n`"]
  -- Planted: only a local of the missing input's name is moved. `k` after
  -- `g` is another local; moving it in place of `n` would get as far, to
  -- the `prim +` of a Bool, but drop `k`.
  let _ ← callReport "another local after the call" "firth.type.stack-underflow"
    ": g (forall ρ; ρ n:Int^many b:Bool^many -- ρ r:Int^many) drop ;\n: f (forall ρ; ρ n:Int^many b:Bool^many k:Int^many -- ρ r:Int^many) locals { n b k } { true g k drop true prim + } ;\n"
    ["by writing the local of that name, `n`: write `n true g` in place of `true g` on line 2."]
    ["by moving", "in place of `true g k`"]
  -- Planted: a local of another type is not written for an input. `xs`
  -- here is an Int and `g` takes a Seq Int: no edit.
  let _ ← callReport "a local of another type" "firth.type.stack-underflow"
    ": g (forall ρ; ρ xs:Seq Int^many n:Int^many -- ρ r:Int^many) drop prim seq-int.len ;\n: f (forall ρ; ρ xs:Int^many n:Int^many -- ρ r:Int^many) locals { xs n } { n g } ;\n"
    ["`g` in `f` takes 2 values"] ["in place of"]
  -- Planted: seq-max (8ea4a1d, haiku-firth-14, answer 2),
  -- verbatim. The `1` after `prim seq-int.at` would check as its index,
  -- but a primitive's inputs have no names to say it is the one missing
  -- (the author's first value is read at 0). No edit.
  let _ ← callReport "a primitive's missing value" "firth.type.stack-underflow" ": main\n  (forall ρ; ρ xs:Seq Int^many -- ρ largest:Int^many)\n  locals { xs } {\n    xs prim seq-int.at 1 0 xs prim seq-int.len max-helper\n  };\n\n: max-helper\n  (forall ρ; ρ xs:Seq Int^many i:Int^many max:Int^many -- ρ result:Int^many)\n  locals { xs i max } {\n    [ i xs prim seq-int.len prim = ] [ max ] [\n      xs i prim seq-int.at max [ prim < ] [ max ] [ xs i prim seq-int.at ] if\n      i 1 prim + xs max-helper\n    ] if\n  };\n"
    ["`prim seq-int.at` in `main` takes 2 values (the sequence (Seq Int) and the index (Int)), bottom to top, but only 1 value is on the stack before it: `xs` (Seq Int)."]
    ["in place of"]
  -- Constructed: the values written after the call include one of another
  -- type than the input it would fill: no edit. Here `true` would be
  -- refused at `g` once moved, but a later `locals` block needs more values
  -- than there are, so erasure stops the recheck before typing; only the
  -- literal's own type check refuses the edit.
  let _ ← callReport "a literal of another type, with a later erasure error" "firth.type.stack-underflow" ": g (forall ρ; ρ a:Int^many b:Int^many n:Int^many -- ρ r:Int^many) prim + prim + ;\n: f (forall ρ; ρ n:Int^many -- ρ r:Int^many) locals { n } { g 1 2 true locals { a b c } { a } } ;\n"
    ["`g` in `f` takes 3 values"]
    ["in place of"]
  -- The same value, moved, is refused at `g` itself.
  let _ ← callReport "a literal of another type" "firth.type.stack-underflow" ": g (forall ρ; ρ a:Int^many b:Int^many n:Int^many -- ρ r:Int^many) prim + prim + ;\n: f (forall ρ; ρ n:Int^many -- ρ r:Int^many) locals { n } { 1 2 g true } ;\n"
    ["`g` in `f` takes 3 values"]
    ["in place of"]
  -- The same with an Int, which the edit moves. 1 + 2 + 3.
  shortCase "a literal of the input's type" ": g (forall ρ; ρ a:Int^many b:Int^many n:Int^many -- ρ r:Int^many) prim + prim + ;\n: f (forall ρ; ρ n:Int^many -- ρ r:Int^many) locals { n } { 1 2 g 3 } ;\n"
    ["Write `3 g` in place of `g 3` on line 2. With that edit `f` checks."] []
    "f" [.int 9] [.int 6]
  -- Planted: sort (8ea4a1d, haiku-firth-14, answer 3), verbatim. `value`,
  -- written after `insert-sorted`, is not its last input, `pos`, so the
  -- values after the call are not moved before it as they stand. `value`
  -- is moved into its own input's place instead, between the new `result`
  -- and the new `pos`. Written there again, the `value` after the call
  -- would be left over, and the `if` refused for it; moved, the `if` is
  -- refused only for its condition, written as a quotation.
  let insertSorted := ": main\n  (forall ρ; ρ xs:Seq Int^many -- ρ sorted:Seq Int^many)\n  locals { xs } { prim seq-int.empty 0 xs sort-insert-all };\n\n: sort-insert-all\n  (forall ρ; ρ result:Seq Int^many i:Int^many xs:Seq Int^many -- ρ result:Seq Int^many)\n  locals { result i xs } {\n    [ i xs prim seq-int.len prim = ] [ result ] [\n      xs i prim seq-int.at result 0 insert-sorted\n      result i 1 prim + xs sort-insert-all\n    ] if\n  };\n\n: insert-sorted\n  (forall ρ; ρ result:Seq Int^many value:Int^many pos:Int^many -- ρ result:Seq Int^many)\n  locals { result value pos } {\n    [ pos result prim seq-int.len prim = ] [ result value prim seq-int.push ] [\n      value result pos prim seq-int.at prim <\n      [ result pos value prim seq-int.set ] [ result ] if\n      pos 1 prim + insert-sorted value\n    ] if\n  };\n"
  let _ ← callReport "a value for another input" "firth.type.stack-underflow" insertSorted
    ["`insert-sorted` in `insert-sorted` takes 3 values (result:Seq Int, value:Int, pos:Int), bottom to top, but only 2 values are on the stack before it",
     "Push the missing value (value:Int) by moving the local of that name, `value`, written after `insert-sorted`, into its place before it: write `value result pos prim seq-int.at prim < [ result pos value prim seq-int.set ] [ result ] if value pos 1 prim + insert-sorted` in place of `value result pos prim seq-int.at prim < [ result pos value prim seq-int.set ] [ result ] if pos 1 prim + insert-sorted value` on line 18. With that edit, the next error in `insert-sorted` is at line 19, column 7."]
    ["`value insert-sorted` in place of", "`value` is written after it"]
  -- With the move made, the word's next error is the condition written as
  -- a quotation, not a value left over.
  let insertMoved := (s!"{insertSorted}").replace "pos 1 prim + insert-sorted value" "value pos 1 prim + insert-sorted"
  let _ ← callReport "insert-sorted with the move made" "firth.type.expected-bool" insertMoved
    ["`if` in `insert-sorted` needs a Bool condition"]

private def stackTypes : Firth.Elaborator.StackEffect.AStack → List Firth.Elaborator.StackEffect.AType
  | .snoc rest type => stackTypes rest ++ [type]
  | _ => []

/-- Every primitive whose inputs repeat a type beside another type, where a
report can only tell the author which value goes where by what each input
is for, has one role per input in `primitiveRoles`; and no listed primitive
has a role count that differs from its inputs. A primitive added to the
language without its roles fails here. -/
private def runPrimitiveRolesTests : IO Unit := do
  for surface in languagePrimitives do
    let some scheme := Elaborate.gammaTyping.primitive surface
      | fail s!"primitive roles: `{surface}` has no scheme"
    let inputs := stackTypes scheme.input
    let repeats := inputs.any fun type => (inputs.filter (· == type)).length > 1
    let mixed := match inputs with
      | first :: rest => rest.any (· != first)
      | [] => false
    match primitiveRoles surface with
    | some roles =>
        unless roles.length == inputs.length do
          fail s!"primitive roles: `{surface}` takes {inputs.length} values but has {roles.length} roles"
    | none =>
        if repeats && mixed then
          fail s!"primitive roles: `{surface}` repeats an input type beside another but has no roles"

/-- `locals` blocks bound out of order: what the report says, and the edits
its hint gives, applied and run. -/
private def runLocalsOrderTests : IO Unit := do
  let pipelineContext := contextWithSource "pipeline-1" "main.fth"
  let agentConfig : Firth.Elaborator.PipelineConfig :=
    { erasureEnv := Elaborate.gammaErasure, typingEnv := Elaborate.gammaTyping }
  -- `locals` blocks that bind the inputs top first, the mode that failed
  -- every task of one authoring-eval sample. Copied verbatim from count-below
  -- in eval/s7/runs/2026-09-28-haiku-c6a964a/haiku-firth-1/answer-2.md. The
  -- report names what every misordered block binds, in every word at once,
  -- and the blocks it says to write make the program check.
  let reversedLocals := ": main\n  (forall ρ; ρ xs:Seq Int^many k:Int^many -- ρ count:Int^many)\n  locals { k xs } {\n    0 0 xs k helper-count\n  };\n\n: helper-count\n  (forall ρ; ρ acc:Int^many idx:Int^many xs:Seq Int^many k:Int^many -- ρ result:Int^many)\n  locals { k xs idx acc } {\n    idx xs prim seq-int.len prim <\n    [\n      xs idx prim seq-int.at locals { v } {\n        v k prim <\n        [ acc 1 prim + idx 1 prim + xs k helper-count ]\n        [ acc idx 1 prim + xs k helper-count ]\n        if\n      }\n    ]\n    [ acc ]\n    if\n  };\n"
  -- Each word's block is its own error, in source order.
  let mainNeedles := [
    "`locals { k xs }` in `main` gives `k` the value the stack effect calls `xs` (Seq Int), `xs` the value the stack effect calls `k` (Int)",
    "Write `locals { xs k }` in `main`, and keep the body as it is",
    "Swapping values with `swap` would not help"]
  let helperNeedles := [
    "`locals { k xs idx acc }` in `helper-count` gives `k` the value the stack effect calls `acc` (Int)",
    "Write `locals { acc idx xs k }` in `helper-count`, and keep the body as it is",
    "Swapping values with `swap` would not help"]
  let localsNeedles := mainNeedles ++ helperNeedles
  match elaboratePipeline pipelineContext reversedLocals agentConfig with
  | .failure [first, second] =>
      for (envelope, needles, word) in [(first, mainNeedles, "main"), (second, helperNeedles, "helper-count")] do
        let emitted := encode envelope
        expectValidCode "reversed locals" "firth.name.locals-order" emitted
        unless emitted.contains s!"\"word\":\"{word}\"" do
          fail s!"reversed locals: the report does not name `{word}`: {emitted}"
        for needle in needles do
          unless emitted.contains needle do
            fail s!"reversed locals: the report does not say {needle}: {emitted}"
  | _ => fail "reversed locals: expected one diagnostic for each word"
  let suggested := (reversedLocals.replace "locals { k xs }" "locals { xs k }").replace
    "locals { k xs idx acc }" "locals { acc idx xs k }"
  match elaboratePipeline pipelineContext suggested agentConfig with
  | .success _ => pure ()
  | .failure _ => fail "reversed locals: the blocks the report suggests do not check"
  -- What the author saw before: a type error at the call, pointing to `swap`.
  let beforeLocals := "code: firth.type.word-input-mismatch\nmessage: `helper-count` in `main` needs Int Int Seq Int Int on top of the stack, but the stack before it is ρ Int Int Int Seq Int.\nhint: The top value is Seq Int but `helper-count` expects Int. Check the argument order (`swap` exchanges the top two values) or the operation."
  if localsNeedles.all (beforeLocals.contains ·) then
    fail "reversed locals: the report from before this change passes the checks"
  -- Same-typed inputs bound in reverse check and compute the wrong value,
  -- so the refusal is the only report such a program gets.
  match elaboratePipeline pipelineContext ": difference\n  (forall ρ; ρ a:Int^many b:Int^many -- ρ r:Int^many)\n  locals { b a } { a b prim - };" agentConfig with
  | .failure [envelope] =>
      unless (encode envelope).contains "Write `locals { a b }` in `difference`" do
        fail s!"reversed same-typed locals: {encode envelope}"
  | _ => fail "reversed same-typed locals were accepted"
  -- The hint is applied as written: the test reads the block, the names to
  -- write for others and the names to start the body with out of the hint
  -- text, edits the source with them, and requires the result to check and
  -- to compute, on sample inputs, the value worked out by hand from what
  -- each declared name means. A plain reordering takes no body edits.
  let hintOf (envelope : Envelope) : String :=
    match Lean.Json.parse (encode envelope) with
    | .ok json => (((json.getObjValD "body").getObjValD "message_params").getObjValD "hint").getStr?.toOption.getD ""
    | .error _ => ""
  let upTo (text marker : String) : String := (text.splitOn marker).headD ""
  let applyLocalsHint (source hint : String) : Option String :=
    match (hint.splitOn "Write `locals { ")[1]? with
    | none => none
    | some afterWrite =>
      let block := upTo afterWrite " }`"
      let renames := ((hint.splitOn "write `").drop 1).filterMap fun piece =>
        match piece.splitOn "` for `" with
        | input :: rest :: _ => some (upTo rest "`", input)
        | _ => none
      let prelude := match (hint.splitOn "start the body with `")[1]? with
        | some rest => (upTo rest "`").splitOn " "
        | none => []
      match source.splitOn "locals { " with
      | [head, tail] =>
          match tail.splitOn " } { " with
          | [_, rest] =>
              match rest.splitOn " }" with
              | body :: after =>
                  let tokens := ((body.splitOn " ").filter (· != "")).map fun token =>
                    (renames.lookup token).getD token
                  some (head ++ "locals { " ++ block ++ " } { " ++ " ".intercalate (prelude ++ tokens) ++ " }" ++
                    " }".intercalate after)
              | [] => none
          | _ => none
      | _ => none
  -- Runs `word` of a checked program on the reference interpreter, with
  -- `inputs` given bottom to top, and returns the Int stack it leaves.
  let runWord (program : CheckedProgram) (word : String) (inputs : List Int) : Option (List Int) :=
    let toProgram (kernel : KernelProgram) : Firth.Interpreter.Program :=
      kernel.foldr (fun located rest => .cons located.atom rest) .empty
    let dictionary : Firth.Interpreter.Dictionary := fun name =>
      (program.words.find? (·.name == name)).map fun checked =>
        { type := Firth.ReferenceRun.adapterWordType, body := toProgram checked.program }
    let rec go : Nat → Firth.Interpreter.Config → Option Firth.Interpreter.Stack
      | 0, _ => none
      | fuel + 1, config =>
          match Firth.Interpreter.step Firth.ReferenceRun.adapterGamma dictionary Firth.Interpreter.defaultCosts config with
          | .terminal final => some final.stack
          | .stuck _ => none
          | .stepped next _ => go fuel next
    let start := (inputs.map fun value => Firth.Interpreter.Value.literal (.int value)).reverse
    (go 10000 { stack := start, program := .cons (.word word) .empty }).bind fun stack =>
      (stack.reverse.mapM fun
        | .literal (.int value) => some value
        | _ => none)
  let localsCases : List (String × String × String × List String × List Int × List Int) := [
    -- `b` then `a`: the reordered block alone, `a - b`.
    ("reordered names", "sub",
      ": sub\n  (forall ρ; ρ a:Int^many b:Int^many -- ρ r:Int^many)\n  locals { b a } { a b prim - };",
      ["Write `locals { a b }` in `sub`, and keep the body as it is"], [10, 3], [7]),
    -- `a` claims the input `a`, so `x` stands for `b`: `b - a`.
    ("fresh name beside a declared one", "sub",
      ": sub\n  (forall ρ; ρ a:Int^many b:Int^many -- ρ r:Int^many)\n  locals { x a } { x a prim - };",
      ["Write `locals { a b }` in `sub`", "In its body, write `b` for `x`"], [10, 3], [-7]),
    -- `a` names the deeper input, and the body drops the value it expects
    -- on the stack, `b`: the result is `a`.
    ("declared name for a deeper input", "sub",
      ": sub\n  (forall ρ; ρ a:Int^many b:Int^many -- ρ r:Int^many)\n  locals { a } { drop a };",
      ["Write `locals { a b }` in `sub`", "Then start the body with `b`"], [10, 3], [10]),
    -- Inputs `n n n2`: `n` claims the first, `n2` the last, and the body
    -- adds the one left on the stack, the second `n`: 10 + (100 - 1).
    ("repeated label", "rep",
      ": rep\n  (forall ρ; ρ n:Int^many n:Int^many n2:Int^many -- ρ r:Int^many)\n  locals { n2 n } { n2 n prim - prim + };",
      ["Write `locals { n n3 n2 }` in `rep`", "Then start the body with `n3`"], [1, 10, 100], [109]),
    -- The body calls a word `b`, so the input `b` is bound as `b2`, and
    -- `x` stands for it: (3 + 10) + 1.
    ("input label that names a word the body calls", "sub",
      ": b\n  (forall ρ; ρ v:Int^many -- ρ r:Int^many)\n  1 prim + ;\n\n: sub\n  (forall ρ; ρ a:Int^many b:Int^many -- ρ r:Int^many)\n  locals { x a } { x a prim + b };",
      ["Write `locals { a b2 }` in `sub`", "In its body, write `b2` for `x`"], [10, 3], [14]),
    -- An input labelled like the word `inc` the body calls, below the one
    -- the block names: the prelude pushes it as `inc2`, and `a` is 5 + 1.
    ("input label that names a word, in the prelude", "sub",
      ": inc\n  (forall ρ; ρ v:Int^many -- ρ r:Int^many)\n  1 prim + ;\n\n: sub\n  (forall ρ; ρ a:Int^many inc:Int^many b:Int^many -- ρ r:Int^many)\n  locals { a } { drop drop a inc };",
      ["Write `locals { a inc2 b }` in `sub`", "Then start the body with `inc2 b`"], [5, 7, 9], [6]),
    -- Another word has a type error of its own; the edit for `sub` is
    -- still checked and stated.
    ("edit beside another word's error", "sub",
      ": bad\n  (forall ρ; ρ v:Int^many -- ρ r:Bool^many)\n  1 prim + ;\n\n: sub\n  (forall ρ; ρ a:Int^many b:Int^many -- ρ r:Int^many)\n  locals { x a } { x a prim - };",
      ["Write `locals { a b }` in `sub`", "In its body, write `b` for `x`"], [10, 3], [-7]),
    -- The same inside a vocabulary: the body calls `b` as written, which
    -- resolves to `v.b`, and the input `b` is still bound as `b2`.
    ("input label that names a word, in a vocabulary", "v.sub",
      "vocab v {\n: b\n  (forall ρ; ρ x:Int^many -- ρ r:Int^many)\n  1 prim + ;\n\n: sub\n  (forall ρ; ρ a:Int^many b:Int^many -- ρ r:Int^many)\n  locals { x a } { x a prim + b };\n}",
      ["Write `locals { a b2 }` in `v.sub`", "In its body, write `b2` for `x`"], [10, 3], [14]),
    -- A repeated input label is numbered, and the number avoids a name the
    -- old block binds to another input (CodeRabbit on #167): `b2` holds
    -- the second input there, so the third is bound as `b3`.
    ("numbered binder beside an old name", "f",
      ": f\n  (forall ρ; ρ a:Int^many b:Int^many b:Int^many -- ρ r:Int^many)\n  locals { b b2 a } { b2 };",
      ["Write `locals { a b b3 }` in `f`", "In its body, write `b3` for `b2`"], [1, 2, 3], [3])]
  let wordOf (envelope : Envelope) : String :=
    match Lean.Json.parse (encode envelope) with
    | .ok json => (((json.getObjValD "body").getObjValD "message_params").getObjValD "word").getStr?.toOption.getD ""
    | .error _ => ""
  for (label, word, source, needles, inputs, expected) in localsCases do
    -- One report for the word, beside any other word's own.
    let reports := match elaboratePipeline pipelineContext source agentConfig with
      | .failure diagnostics => diagnostics.filter (wordOf · == word)
      | .success _ => []
    match reports with
    | [envelope] =>
        let emitted := encode envelope
        expectValidCode label "firth.name.locals-order" emitted
        for needle in needles do
          unless emitted.contains needle do
            fail s!"{label}: the report does not say {needle}: {emitted}"
        match applyLocalsHint source (hintOf envelope) with
        | none => fail s!"{label}: the hint could not be applied: {emitted}"
        | some edited =>
            match elaboratePipeline pipelineContext edited agentConfig with
            | .success program =>
                let result := runWord program word inputs
                unless result == some expected do
                  fail s!"{label}: the edited program computes {result} instead of {expected}: {edited}"
            | .failure diagnostics =>
                -- A refusal charged only to another word leaves this one's
                -- edit standing; its value cannot then be run.
                unless diagnostics.all (fun envelope => let owner := wordOf envelope; owner != "" && owner != word) do
                  fail s!"{label}: the edit the hint gives does not check: {edited}: {diagnostics.map encode}"
    | _ => fail s!"{label}: expected one diagnostic for `{word}`"
  -- Blocks whose edit, applied to the word, is refused: the old body only
  -- fits the values the names hold now. The report states no edit, and no
  -- hint edit can be read out of it.
  let uncheckedCases : List (String × String × String) := [
    -- The name `xs` holds `n`, and the body relies on it.
    ("body fits the old binding (types)", "get",
      ": get\n  (forall ρ; ρ xs:Seq Int^many n:Int^many -- ρ r:Int^many)\n  locals { xs } { xs prim seq-int.at };"),
    -- The prelude would push linear `b` where the body drops a `^many` value.
    ("body fits the old binding (linearity)", "sum",
      ": sum\n  (forall ρ; ρ a:Int^many b:Int^linear c:Int^linear -- ρ r:Int^many)\n  locals { c a } { drop a c prim + };"),
    -- The same as the first, with a later mistake of its own (`true prim +`):
    -- the edit brings the refusal earlier, to `prim seq-int.at`.
    ("body fits the old binding, before a later mistake", "get",
      ": get\n  (forall ρ; ρ xs:Seq Int^many n:Int^many -- ρ r:Int^many)\n  locals { xs } { xs prim seq-int.at true prim + };"),
    -- An inner block binds `x` again, so "write `b` for `x`" would be read
    -- for both.
    ("name to rename bound again inside", "sub",
      ": sub\n  (forall ρ; ρ a:Int^many b:Int^many -- ρ r:Int^many)\n  locals { x a } { x 1 prim + locals { x } { x } a prim - };"),
    -- Planted: `x` holds the Int `a` and would be renamed to `b`, a Bool.
    -- `locals { p q r }` is handed one value, an erasure error, so typing
    -- never runs on the edited word and could not show `b 1 prim +` wrong:
    -- the rename's type is compared instead.
    ("a renamed name of another type, before a later erasure error", "f",
      ": f\n  (forall ρ; ρ a:Int^many b:Bool^many -- ρ r:Int^many)\n  locals { x a } { x 1 prim + locals { p q r } { p } };")]
  -- The same with `b` an Int: renaming `x` to `b` keeps its type, and the
  -- edit is stated although typing does not run.
  match elaboratePipeline pipelineContext ": f\n  (forall ρ; ρ a:Int^many b:Int^many -- ρ r:Int^many)\n  locals { x a } { x 1 prim + locals { p q r } { p } };" agentConfig with
  | .failure [envelope] =>
      let emitted := encode envelope
      for needle in ["Write `locals { a b }` in `f`", "write `b` for `x`"] do
        unless emitted.contains needle do
          fail s!"a renamed name of its own type: the report does not say {needle}: {emitted}"
  | _ => fail "a renamed name of its own type: expected one diagnostic"
  -- A rename that changes the type, where typing does run: `x` is used as
  -- a Bool and the edit gives it `b`, a Bool. The edited word is refused
  -- only later, at `true prim +`, so the edit is stated.
  match elaboratePipeline pipelineContext ": f\n  (forall ρ; ρ a:Int^many b:Bool^many -- ρ r:Int^many)\n  locals { x a } { x prim not drop a true prim + };" agentConfig with
  | .failure [envelope] =>
      let emitted := encode envelope
      for needle in ["Write `locals { a b }` in `f`", "write `b` for `x`"] do
        unless emitted.contains needle do
          fail s!"a renamed name typing checks: the report does not say {needle}: {emitted}"
  | _ => fail "a renamed name typing checks: expected one diagnostic"
  -- A block that repeats a name is refused for that, not for its order.
  match elaboratePipeline pipelineContext ": sum\n  (forall ρ; ρ a:Int^many b:Int^many c:Int^many -- ρ r:Int^many)\n  locals { x a x } { x a x prim + prim + };" agentConfig with
  | .failure (envelope :: _) =>
      expectValidCode "repeated name in a misordered block" "firth.name.duplicate-local" (encode envelope)
  | _ => fail "repeated name in a misordered block: expected a refusal"
  for (label, word, source) in uncheckedCases do
    match elaboratePipeline pipelineContext source agentConfig with
    | .failure [envelope] =>
        let emitted := encode envelope
        expectValidCode label "firth.name.locals-order" emitted
        unless emitted.contains s!"In `{word}` the body was written for the values the names hold now, so changing the block alone does not fix it" do
          fail s!"{label}: the report does not fall back: {emitted}"
        if (applyLocalsHint source (hintOf envelope)).isSome then
          fail s!"{label}: the report still states an edit: {emitted}"
    | _ => fail s!"{label}: expected one diagnostic"
  -- A later word whose declared effect is no type scheme, after a bad `use`
  -- or not, says nothing about whether the edit fits `get` (Codex on #176):
  -- the hint still falls back.
  let get := ": get\n  (forall ρ; ρ xs:Seq Int^many n:Int^many -- ρ r:Int^many)\n  locals { xs } { xs prim seq-int.at };\n"
  let bad := ": bad (forall ρ; a:Int ρ -- ρ r:Int ) 1 ;\n"
  for (label, source) in [("before a word with no scheme", get ++ bad),
      ("before a bad `use` and a word with no scheme", get ++ "use nope;\n" ++ bad)] do
    match elaboratePipeline pipelineContext source agentConfig with
    | .failure (envelope :: _) =>
        let emitted := encode envelope
        expectValidCode label "firth.name.locals-order" emitted
        unless emitted.contains "In `get` the body was written for the values the names hold now, so changing the block alone does not fix it" do
          fail s!"{label}: the report does not fall back: {emitted}"
    | _ => fail s!"{label}: expected a refusal"

def runElaboratorDiagnosticTests : IO Unit := do
  let parseError : ParseError := {
    code := "firth.syntax.unterminated-string"
    primary := span 2 3 7
    expected := some "closing quote"
    actual := some "end of input"
    cause := .delimiter }
  let parserJson := encodeParseError (context "parser-1") parseError
  expectValidCode "parser adapter" "firth.syntax.unterminated-string" parserJson
  if parserJson.contains "\"cause\":{\"kind\":\"delimiter\"" &&
      parserJson.contains "\"proposed_fixes\":[{\"fix_id\":\"fix-1\"" &&
      parserJson.contains "\"related\":[{\"relation\":\"origin\"" then pure ()
  else fail "parser adapter omitted cause, fix, or related information"

  let erasureJson := encodeErasureError (context "erasure-1")
    (.linearUnused "handle" (span 3 1 7))
  expectValidCode "erasure adapter" "firth.linearity.unconsumed-resource" erasureJson
  if erasureJson.contains "\"message_params\":{\"hint\":" && erasureJson.contains "\"name\":\"handle\"" then pure ()
  else fail "erasure adapter omitted the local name"

  let warningJson := encodeErasureWarning (context "warning-1") {
    code := "LOCAL_DEPTH", span := span 3 2 4 }
  expectValidCode "erasure warning adapter" "firth.elaboration.local-depth" warningJson
  if warningJson.contains "\"severity\":\"warning\"" then pure ()
  else fail "erasure warning adapter did not preserve warning severity"

  let intStack : Firth.Elaborator.StackEffect.AStack :=
    .snoc .empty (.base "Int" .many)
  let stackDiagnostic : Firth.Elaborator.StackEffect.Diagnostic := {
    code := "firth.type.stack-mismatch"
    primary := span 4 2 5
    state := intStack
    expected := some (.snoc .empty (.base "Bool" .many))
    actual := some (.snoc .empty (.base "Int" .many)) }
  let stackJson := encodeStackEffectDiagnostic (context "stack-1") stackDiagnostic
  expectValidCode "stack-effect adapter" "firth.type.stack-mismatch" stackJson
  expectCauseState "stack-effect adapter pre-atom state" stackJson intStack
  if stackJson.contains "\"expected_stack\":{\"encoding\":\"opaque\",\"value\":" &&
      stackJson.contains "\"actual_stack\":{\"encoding\":\"opaque\",\"value\":" then pure ()
  else fail "stack-effect adapter omitted expected or actual state"

  let hole : Firth.Elaborator.StackEffect.TypedHole := {
    span := span 5 6 7
    state := .snoc (.row (.rigid "rho")) (.base "Int" .many) }
  let holeJson := encodeTypedHole (context "hole-1") "h-1" hole
  match validate holeJson with
  | .ok envelope => expectEqual "typed-hole adapter kind" envelope.payloadKind "typed_hole"
  | .error error => fail s!"typed-hole adapter invalid: {error.code}"

  let inferredHoleInput : Firth.Elaborator.StackEffect.AStack :=
    .row (.rigid "rho")
  let inferredHoleProgram : Firth.Elaborator.KernelProgram := [{
    span := span 5 1 2
    atom := .lit (.int 7) }]
  match Firth.Elaborator.StackEffect.typedHole
      { literal := Firth.Elaborator.StackEffect.defaultLiteralType }
      inferredHoleInput inferredHoleProgram (span 5 3 3) with
  | .ok inferredHole =>
      let inferredHoleJson := encodeTypedHole (context "inferred-hole-1")
        "h-inferred" inferredHole
      match validate inferredHoleJson with
      | .ok envelope =>
          expectEqual "inferred typed-hole adapter kind" envelope.payloadKind "typed_hole"
      | .error error => fail s!"inferred typed-hole adapter invalid: {error.code}"
  | .error error => fail s!"typed-hole inference failed: {repr error}"

  let refinedStack : Firth.Elaborator.Refinement.RefinedStack := {
    erased := intStack
    refinements := {} }
  let refinementContext : Firth.Elaborator.Refinement.ObligationContext := {
    wordId := "math.increment"
    bodyHash := "sha256:body"
    erasedWordTypeHash := "sha256:word-type"
    specHash := "sha256:spec"
    normaliserVersion := "normaliser-v1"
    vcGeneratorVersion := "vc-v1"
    leanToolchainHash := "lean-toolchain"
    proofModuleHash := "sha256:proof-module"
    toolchainRevision := "firth-a"
    source := { path := "main.fth", span := span 6 2 8 }
    expectedStack := refinedStack
    actualStack := refinedStack }
  let refinementResult := Firth.Elaborator.Refinement.checkBodyRefinements
    "request-refinement" {
      context := refinementContext
      precondition := {}
      bodySemantics := {}
      declaredPostcondition := { conjuncts := [.boolVariable "open"] } }
  match refinementEnvelopes refinementResult with
  | [refinementDiagnostic] =>
      let emitted := encode refinementDiagnostic
      expectValidCode "refinement path emission" "firth.refinement.not-decided" emitted
      if emitted.contains "\"cause\":{\"kind\":\"refinement\"" &&
          emitted.contains "\"obligation_id\":" &&
          emitted.contains "\"kind\":\"body\",\"status\":\"deferred\"" &&
          emitted.contains "\"expected_stack\":{\"encoding\":\"opaque\"" &&
          emitted.contains "\"actual_stack\":{\"encoding\":\"opaque\"" &&
          emitted.contains "\"group_id\":\"refinement(" then pure ()
      else fail "refinement adapter omitted governed diagnostic fields"
  | diagnostics =>
      fail s!"refinement adapter fixture expected one diagnostic, got {diagnostics.length}"

  expectSortedFirst "diagnostic source sorting" "source-a"
    (parserEnvelope (contextWithSource "source-z" "z.fth") parseError)
    (parserEnvelope (contextWithSource "source-a" "a.fth") parseError)
  expectSortedFirst "diagnostic start sorting" "start-a"
    (parserEnvelope (context "start-z") { parseError with primary := span 9 1 2 })
    (parserEnvelope (context "start-a") { parseError with primary := span 1 1 2 })
  expectSortedFirst "diagnostic end sorting" "end-a"
    (parserEnvelope (context "end-z") { parseError with primary := span 1 1 4 })
    (parserEnvelope (context "end-a") { parseError with primary := span 1 1 2 })
  expectSortedFirst "diagnostic code sorting" "code-a"
    (parserEnvelope (context "code-z") { parseError with code := "firth.syntax.z" })
    (parserEnvelope (context "code-a") { parseError with code := "firth.syntax.a" })
  expectSortedFirst "diagnostic payload sorting" "payload-a"
    (parserEnvelope (context "payload-z") parseError)
    (parserEnvelope (context "payload-a") parseError)

  match parse "\"unterminated" with
  | .success _ => fail "parser integration fixture unexpectedly succeeded"
  | .failure (error :: _) =>
      expectValidCode "parser path emission" error.code
        (encodeParseError (context "parser-path") error)
  | .failure [] => fail "parser integration fixture produced no diagnostic"

  match parse ": unbound ( a:Int^many -- ) locals { a } { missing } ;" with
  | .success { declarations := [.word word], .. } =>
      match erase {} word.effect word.body with
      | .ok _ => fail "erasure integration fixture unexpectedly succeeded"
      | .error error =>
          let emitted := encodeErasureError (context "erasure-path") error
          match validate emitted with
          | .ok _ => pure ()
          | .error validation => fail s!"erasure path emitted invalid JSON: {validation.code}"
  | .success _ => fail "erasure integration fixture parsed the wrong declaration shape"
  | .failure errors => fail s!"erasure integration fixture did not parse: {repr errors}"

  match parse ": deep ( a:Int^many b:Int^many c:Int^many d:Int^many e:Int^many -- ) locals { a b c d e } { } ;" with
  | .success { declarations := [.word word], .. } =>
      match erase {} word.effect word.body with
      | .error error => fail s!"erasure warning fixture failed: {repr error}"
      | .ok result =>
          match warningByCode "LOCAL_DEPTH" result.warnings with
          | none => fail "erasure warning path produced no LOCAL_DEPTH warning"
          | some warning =>
              expectValidCode "erasure warning path emission" "firth.elaboration.local-depth"
                (encodeErasureWarning (context "erasure-warning-path") warning)
  | .success _ => fail "erasure warning fixture parsed the wrong declaration shape"
  | .failure errors => fail s!"erasure warning fixture did not parse: {repr errors}"

  let seed : Firth.Elaborator.LocatedKernel := {
    span := span 6 1 5
    atom := .prim "seed" }
  let missing : Firth.Elaborator.LocatedKernel := {
    span := span 6 6 13
    atom := .word "missing" }
  let seedScheme : Firth.Elaborator.StackEffect.Scheme := {
    rowVariables := []
    input := .empty
    output := intStack }
  let stackEnv : Firth.Elaborator.StackEffect.Env := {
    primitive := fun name => if name == "seed" then some seedScheme else none }
  match Firth.Elaborator.StackEffect.infer stackEnv [seed, missing] with
  | .ok _ => fail "stack-effect integration fixture unexpectedly succeeded"
  | .error diagnostic =>
      let emitted := encodeStackEffectDiagnostic (context "stack-path") diagnostic
      expectValidCode "stack-effect path emission" diagnostic.code emitted
      expectCauseState "stack-effect path pre-atom state" emitted intStack

  let pipelineContext := contextWithSource "pipeline-1" "main.fth"
  match elaboratePipeline pipelineContext ": id ( -- ) ;" with
  | .success program =>
      match program.words with
      | [word] => expectEqual "pipeline success word" word.name "id"
      | _ => fail "pipeline success returned the wrong word count"
  | .failure _ => fail "pipeline success returned diagnostics"

  match elaboratePipeline pipelineContext ":" with
  | .failure [envelope] =>
      expectValidCode "pipeline parser path" "firth.syntax.unexpected-eof" (encode envelope)
      match envelope.body with
      | .diagnostic diagnostic =>
          expectEqual "pipeline parser source" diagnostic.location.source (.path "main.fth")
          expectEqual "pipeline parser line" diagnostic.location.range.start.line 1
      | _ => fail "pipeline parser result was not a diagnostic payload"
  | _ => fail "pipeline parser result was not singular"

  -- An unknown word reference carries the normative resolver code; only a
  -- primitive the environment does not declare is an unresolved effect.
  match elaboratePipeline pipelineContext ": bad ( -- ) missing ;" with
  | .failure [envelope] =>
      expectValidCode "pipeline name-resolution path" "firth.name.unresolved" (encode envelope)
  | _ => fail "pipeline name-resolution result was not singular"

  match elaboratePipeline pipelineContext ": bad ( -- ) prim nope ;" with
  | .failure [envelope] =>
      expectValidCode "pipeline erasure path" "firth.name.unresolved-effect" (encode envelope)
  | _ => fail "pipeline erasure result was not singular"

  match elaboratePipeline pipelineContext ": bad ( -- ) 1 ;" with
  | .failure [envelope] =>
      expectValidCode "pipeline stack-effect path"
        "firth.type.declared-effect-mismatch" (encode envelope)
      -- The message names the word and both whole stacks, and the hint says
      -- how many values are left over, so an author can repair it unaided.
      let emitted := encode envelope
      if emitted.contains "declares that it leaves (empty) but its body leaves Int" &&
          emitted.contains "1 extra value on top (Int)" &&
          emitted.contains "\"word\":\"bad\"" then pure ()
      else fail s!"pipeline stack-effect message was not explanatory: {emitted}"
  | _ => fail "pipeline stack-effect result was not singular"

  match elaboratePipeline pipelineContext ": bad ( -- ) missing ;" with
  | .failure [envelope] =>
      if (encode envelope).contains "`missing` is not a defined word" then pure ()
      else fail "pipeline name-resolution message did not name the word"
  | _ => fail "pipeline name-resolution result was not singular"

  -- A stack-effect name used as a variable, the mistake that stopped every
  -- attempt of a weaker model in the authoring eval: the hint says effect
  -- names are not variables and shows the `locals` block that binds the
  -- inputs, in declared order.
  let effectSource := ": second (forall ρ; ρ xs:Seq Int^many n:Int^many -- ρ r:Int^many)\n  xs 1 prim seq-int.at n prim + ;"
  match elaboratePipeline pipelineContext effectSource with
  | .failure [envelope] =>
      let emitted := encode envelope
      expectValidCode "effect-name path" "firth.name.unresolved" emitted
      if emitted.contains "`xs` is a name in the word's stack effect" &&
          emitted.contains "they are not variables" &&
          emitted.contains "`locals { xs n } { ... }`" &&
          emitted.contains "the last name from the top" then pure ()
      else fail s!"an effect input used as a variable did not point to locals: {emitted}"
  | _ => fail "effect-name result was not singular"

  match elaboratePipeline pipelineContext ": double (forall ρ; ρ n:Int^many -- ρ r:Int^many) 2 prim * r ;" with
  | .failure [envelope] =>
      let emitted := encode envelope
      if emitted.contains "`r` names an output in the word's stack effect" &&
          emitted.contains "leave the result on the stack" &&
          emitted.contains "`locals { n } { ... }`" then pure ()
      else fail s!"an effect output used as a variable was not explained: {emitted}"
  | _ => fail "effect-output result was not singular"

  -- A stack effect may repeat a label, but `locals` refuses a repeated name,
  -- so the hint numbers the repeats. The suggested block is checked by the
  -- real checker, which refused the unnumbered `locals { n n }` it used to
  -- suggest with `firth.name.duplicate-local`.
  let agentConfig : Firth.Elaborator.PipelineConfig :=
    { erasureEnv := Elaborate.gammaErasure, typingEnv := Elaborate.gammaTyping }
  let repeated := "(forall ρ; ρ n:Int^many n:Int^many -- ρ r:Int^many)"
  match elaboratePipeline pipelineContext s!": pair {repeated} n n prim + ;" agentConfig with
  | .failure [envelope] =>
      let emitted := encode envelope
      if emitted.contains "`locals { n n2 } { ... }`" &&
          emitted.contains "the repeats are numbered" then pure ()
      else fail s!"a repeated effect name got a duplicate-binder hint: {emitted}"
  | _ => fail "repeated-effect-name result was not singular"

  runLocalsOrderTests
  match elaboratePipeline pipelineContext
      s!": pair {repeated} locals \{ n n2 } \{ n n2 prim + } ;" agentConfig with
  | .success _ => pure ()
  | .failure diagnostics =>
      fail s!"the suggested locals block does not check: {diagnostics.map encode}"
  match elaboratePipeline pipelineContext
      s!": pair {repeated} locals \{ n n } \{ n n prim + } ;" agentConfig with
  | .failure [envelope] => expectValidCode "duplicate local" "firth.name.duplicate-local" (encode envelope)
  | _ => fail "a repeated local name was accepted"
  expectEqual "binders keep distinct names" (Firth.Elaborator.localBinders ["xs", "n"]) ["xs", "n"]
  expectEqual "binders skip a name an input uses" (Firth.Elaborator.localBinders ["n", "n", "n2"]) ["n", "n3", "n2"]
  expectEqual "binders number every repeat" (Firth.Elaborator.localBinders ["a", "a", "a"]) ["a", "a2", "a3"]

  -- An `if` inside `locals` whose branches change the stack depth by
  -- different amounts, with a local used after it. Erasure loses track of
  -- the stack at the `if` and used to report the later use of `x` as an
  -- untracked local, with a hint saying such quotations are fine. The real
  -- error is the branch mismatch, reported at the `if` with both branches.
  let branchSource := ": keep-positive (forall ρ; ρ x:Int^many -- ρ r:Int^many)\n  locals { x } { 0 x prim < [ x ] [ ] if x prim + } ;"
  match elaboratePipeline pipelineContext branchSource agentConfig with
  | .failure [envelope] =>
      let emitted := encode envelope
      expectValidCode "branch shape" "firth.type.branch-mismatch" emitted
      if emitted.contains "The two branches of the `if` in `keep-positive` whose true branch is `[ x ]` leave different numbers of values. The true branch leaves `x`; the false branch leaves nothing." &&
          emitted.contains "`x` is left by the true branch alone. If nothing is meant to use it, the mistake is where it is pushed" &&
          emitted.contains "\"start\":{\"line\":2,\"column\":39}" &&
          !emitted.contains "untracked" && !emitted.contains "are fine" then pure ()
      else fail s!"an if with branches of different depths was not reported at the if: {emitted}"
  | _ => fail "branch-shape result was not singular"
  -- The same mistake inside a quotation that is then called: the quotation's
  -- effect is unknown because of the inner `if`, and the report still points
  -- at that `if`, not at the `call` that runs it.
  let nestedSource := ": keep-positive (forall ρ; ρ x:Int^many -- ρ r:Int^many)\n  locals { x } { [ true [ 1 ] [ ] if ] call x prim + } ;"
  match elaboratePipeline pipelineContext nestedSource agentConfig with
  | .failure [envelope] =>
      let emitted := encode envelope
      expectValidCode "nested branch shape" "firth.type.branch-mismatch" emitted
      if emitted.contains "\"start\":{\"line\":2,\"column\":35}" && !emitted.contains "untracked" then pure ()
      else fail s!"an if with branches of different depths inside a called quotation was not reported at the if: {emitted}"
  | _ => fail "nested branch-shape result was not singular"
  -- The mismatched `if` two and three levels down, inside a branch of an
  -- outer `if` whose own branches have unknown effects because of it. The
  -- report is at the innermost mismatched `if`, whatever the nesting.
  let expectInnerIf (label source : String) (line column : Nat) : IO Unit := do
    match elaboratePipeline pipelineContext source agentConfig with
    | .failure [envelope] =>
        let emitted := encode envelope
        expectValidCode label "firth.type.branch-mismatch" emitted
        unless emitted.contains s!"\"start\":\{\"line\":{line},\"column\":{column}}" &&
            !emitted.contains "untracked" do
          fail s!"{label}: not reported at the innermost if: {emitted}"
    | _ => fail s!"{label}: result was not singular"
  expectInnerIf "two levels"
    ": g (forall ρ; ρ x:Int^many -- ρ r:Int^many)\n  locals { x } {\n    0 x prim <\n    [ 1 x prim < [ x ] [ ] if ]\n    [ 0 ]\n    if\n    x prim + } ;"
    4 28
  -- Bound to a local first, then called: the mismatch is still found at the
  -- inner `if`, since erasure refuses the `if` itself, wherever it sits.
  expectInnerIf "bound to a local"
    ": g (forall ρ; ρ x:Int^many -- ρ r:Int^many)\n  locals { x } {\n    [ true [ 1 ] [ ] if ] locals { q } { q call } x } ;"
    3 22
  -- Outside `locals` too, with the same message. The type checker reported
  -- this one too, but inside a quotation its report was an occurs check.
  expectInnerIf "outside locals"
    ": g (forall ρ; ρ -- ρ r:Int^many)\n  0 1 prim < [ 1 ] [ ] if ;"
    2 24
  expectInnerIf "outside locals, in a quotation"
    ": g (forall ρ; ρ -- ρ r:Int^many)\n  [ 0 1 prim < [ 1 ] [ ] if ] call ;"
    2 26
  -- Branches bound to locals keep their exact effects, so the `if` is
  -- refused before the later use of `x` could report an untracked local.
  expectInnerIf "branches from locals"
    ": g (forall ρ; ρ -- ρ r:Int^many)\n  [ 1 ] [ ] 5 locals { t f x } { true t f if x prim + } ;"
    2 43
  expectInnerIf "three levels"
    ": g (forall ρ; ρ x:Int^many -- ρ r:Int^many)\n  locals { x } {\n    0 x prim <\n    [ 1 x prim < [ 2 x prim < [ x ] [ ] if ] [ 0 ] if ]\n    [ 0 ]\n    if\n    x prim + } ;"
    4 41

  -- Branch mismatches as the authoring eval met them. Each report must name
  -- the operation or the values responsible, from the source as written,
  -- and say which `if` it means. `branchReport` holds those checks, and the
  -- reports the eval recorded before this change must fail them.
  let branchReport (label source : String) (needles : List String) : IO Unit := do
    -- The answers copied here may have errors in other words too; the
    -- first in the source is the one under test.
    match reportsWithCode (elaboratePipeline pipelineContext source agentConfig) "firth.type.branch-mismatch" with
    | envelope :: _ =>
        let emitted := encode envelope
        expectValidCode label "firth.type.branch-mismatch" emitted
        for needle in needles do
          unless emitted.contains needle do
            fail s!"{label}: the report does not say {needle}: {emitted}"
    | [] => fail s!"{label}: expected a branch-mismatch diagnostic"
  let needlesMissing (report : String) (needles : List String) : Bool :=
    needles.any (!report.contains ·)
  -- longest-run (eval/s7/runs/2026-09-28-haiku-cec3707/haiku-firth-2,
  -- answer 1): the loop is called with one argument too few, so the false
  -- branch takes a value from below the `if`. The report names the call and
  -- the inputs it takes, and what the branch pushed for it.
  let longestRun := [
    "In the false branch of the `if` in `main` whose true branch is `[ 0 ]`, `longest-run-loop` needs 5 values (prev:Int, curr-run:Int, max-run:Int, idx:Int, xs:Seq Int), but the branch has pushed only 4 values before it (the result of `prim seq-int.at`, `1`, `1` and `xs`)",
    "where there is none: everything the word was given is bound to locals or already used",
    "Make the branch push, just before `longest-run-loop`, exactly the values it takes, in this order: prev:Int, curr-run:Int, max-run:Int, idx:Int, xs:Seq Int. The branch already pushes the result of `prim seq-int.at`, `1`, `1` and `xs`: keep each in its place where it is one of these and replace it where it is not, and push the other one in its place"]
  branchReport "longest-run" ": main\n  (forall ρ; ρ xs:Seq Int^many -- ρ length:Int^many)\n  locals { xs } {\n    xs prim seq-int.len 0 prim =\n    [ 0 ]\n    [ xs 0 prim seq-int.at 1 1 xs longest-run-loop ] if\n  };\n\n: longest-run-loop\n  (forall ρ; ρ prev:Int^many curr-run:Int^many max-run:Int^many idx:Int^many xs:Seq Int^many -- ρ result:Int^many)\n  locals { prev curr-run max-run idx xs } {\n    idx xs prim seq-int.len prim =\n    [ max-run curr-run prim < [ curr-run ] [ max-run ] if ]\n    [\n      xs idx prim seq-int.at dup prev prim =\n      [ curr-run 1 prim + ] [ 1 swap ] if\n      idx 1 prim +\n      xs\n      longest-run-loop\n    ]\n    if\n  };" longestRun
  -- keep-positive (the same run, answer 1): the false branch pushes the
  -- sequence on top of the element it means to append, so it takes a Seq Int
  -- where there is an Int. Both answers are copied verbatim. The report says
  -- what `prim seq-int.push` takes and what it gets, in order.
  let keepPositive := [
    "In the false branch of the `if` in `keep-positive-loop` whose true branch is `[ drop result ]`, `prim seq-int.push` takes 2 values (Seq Int, Int, bottom to top). It gets, bottom to top, the result of `prim seq-int.at` from below the `if` and `result`.",
    "Check that it gets the values it should, in its order"]
  branchReport "keep-positive" ": main\n  (forall ρ; ρ xs:Seq Int^many -- ρ positives:Seq Int^many)\n  locals { xs } { prim seq-int.empty 0 xs keep-positive-loop };\n\n: keep-positive-loop\n  (forall ρ; ρ result:Seq Int^many idx:Int^many xs:Seq Int^many -- ρ final:Seq Int^many)\n  locals { result idx xs } {\n    idx xs prim seq-int.len prim =\n    [ result ]\n    [\n      xs idx prim seq-int.at dup 0 prim <\n      [ drop result ]\n      [ result prim seq-int.push ] if\n      idx 1 prim +\n      xs\n      keep-positive-loop\n    ]\n    if\n  };" keepPositive
  -- The same depth, different types.
  let differentTypes := [
    "the true branch leaves ρ Int and the false branch leaves ρ Bool",
    "the top value is Int after the true branch and Bool after the false branch"]
  branchReport "different types" ": g (forall ρ; ρ -- ρ r:Int^many)\n  0 1 prim < [ 1 ] [ true ] if ;" differentTypes
  -- Two values too many: the report names both, and where they are left.
  let twoExtra := ["The true branch leaves 3 values, bottom to top: `1`, `2` and `3`; the false branch leaves `4`.",
    "The true branch leaves 2 values more than the false branch: `1` and `2` are left below `3`."]
  branchReport "two extra" ": g (forall ρ; ρ -- ρ r:Int^many)\n  0 1 prim < [ 1 2 3 ] [ 4 ] if ;" twoExtra
  -- A branch, or the `if` itself, reaching for a local as if it were on the
  -- stack, or below everything the word was given: the commonest mistake in
  -- the authoring eval. Evening out the branches with a `drop` or a push only
  -- moves it, so the report must not suggest either, and the edit it does
  -- suggest must make the program check. Each case also carries the edit the
  -- earlier report suggested, which must still be refused: that is the
  -- planted wrong suggestion. The answers are copied verbatim from
  -- eval/s7/runs (and `p q` from 2026-09-27-plus-only/haiku-firth,
  -- solutions-1.json, task `and`).
  let noEvening (label : String) (source : String) : IO Unit := do
    -- No report, in any word, suggests it.
    match elaboratePipeline pipelineContext source agentConfig with
    | .failure envelopes =>
        for envelope in envelopes do
          let emitted := encode envelope
          if emitted.contains "either add `drop" || emitted.contains "push 1 value more" then
            fail s!"{label}: the report still suggests evening out the branches: {emitted}"
    | .success _ => fail s!"{label}: the program was accepted"
  let checks (label source : String) (expected : Bool) : IO Unit :=
    match elaboratePipeline pipelineContext source agentConfig with
    | .success _ => unless expected do fail s!"{label}: the program was accepted"
    | .failure _ => if expected then fail s!"{label}: the program was refused" else pure ()
  let fixtures : List (String × String × List String × String × String) := [
    ("p q", ": main\n  (forall ρ; ρ p:Bool^many q:Bool^many -- ρ r:Bool^many)\n  locals { p q } { [ q ] [ drop false ] if };",
      ["looked for where the local `p` would be, but a local is not a value on the stack",
        "Write the condition just before the two quotations"],
      -- The suggested edit: the condition written before the quotations, and
      -- the local used by name instead of taken with `drop`.
      ": main\n  (forall ρ; ρ p:Bool^many q:Bool^many -- ρ r:Bool^many)\n  locals { p q } { p [ q ] [ false ] if };",
      -- The earlier suggestion: a `drop` to even out the branches.
      ": main\n  (forall ρ; ρ p:Bool^many q:Bool^many -- ρ r:Bool^many)\n  locals { p q } { [ q drop ] [ drop false ] if };"),
    ("lcm (2026-09-27-hard/haiku-firth-2, answer 1)", ": lcm\n  (forall ρ; ρ a:Int^many b:Int^many -- ρ r:Int^many)\n  locals { a b } {\n    a b gcd\n    a b prim *\n    swap\n    prim -\n    0 prim =\n    [\n      a b prim *\n    ]\n    [\n      a b prim * swap prim -\n    ]\n    if\n  };\n\n: gcd\n  (forall ρ; ρ a:Int^many b:Int^many -- ρ r:Int^many)\n  locals { a b } {\n    b 0 prim =\n    [ a ]\n    [\n      a b prim =\n      [ b ]\n      [\n        b a b prim - gcd\n      ]\n      if\n    ]\n    if\n  };",
      ["In the false branch of the `if` in `lcm` whose true branch is `[ a b prim * ]`, `swap` needs 2 values, but the branch has pushed only 1 value before it (the result of `prim *`).",
        "Remove it, or push the values it should work on first."],
      -- The value the false branch reaches for, computed inside it.
      ": lcm\n  (forall ρ; ρ a:Int^many b:Int^many -- ρ r:Int^many)\n  locals { a b } {\n    a b gcd\n    a b prim *\n    swap\n    prim -\n    0 prim =\n    [\n      a b prim *\n    ]\n    [\n      a b prim * a b gcd prim -\n    ]\n    if\n  };\n\n: gcd\n  (forall ρ; ρ a:Int^many b:Int^many -- ρ r:Int^many)\n  locals { a b } {\n    b 0 prim =\n    [ a ]\n    [\n      a b prim =\n      [ b ]\n      [\n        b a b prim - gcd\n      ]\n      if\n    ]\n    if\n  };",
      ": lcm\n  (forall ρ; ρ a:Int^many b:Int^many -- ρ r:Int^many)\n  locals { a b } {\n    a b gcd\n    a b prim *\n    swap\n    prim -\n    0 prim =\n    [\n      a b prim * drop\n    ]\n    [\n      a b prim * swap prim -\n    ]\n    if\n  };\n\n: gcd\n  (forall ρ; ρ a:Int^many b:Int^many -- ρ r:Int^many)\n  locals { a b } {\n    b 0 prim =\n    [ a ]\n    [\n      a b prim =\n      [ b ]\n      [\n        b a b prim - gcd\n      ]\n      if\n    ]\n    if\n  };"),
    ("digit-sum (2026-09-27-hard/haiku-firth-2, answer 2)", ": digit-sum-loop\n  (forall ρ; ρ s:Int^many n:Int^many -- ρ r:Int^many)\n  locals { s n } {\n    n 0 prim =\n    [\n      s\n    ]\n    [\n      n 10 prim -\n      0 prim =\n      [\n        s n prim +\n      ]\n      [\n        s n prim - prim +\n        n 10 prim -\n        digit-sum-loop\n      ]\n      if\n    ]\n    if\n  };\n\n: main\n  (forall ρ; ρ n:Int^many -- ρ r:Int^many)\n  locals { n } {\n    0 n digit-sum-loop\n  };",
      ["In the false branch of the `if` in `digit-sum-loop` whose true branch is `[ s n prim + ]`, `prim +` needs 2 values (Int, Int), but the branch has pushed only 1 value before it (the result of `prim -`).",
        "If `prim +` should not be in this branch, remove it."],
      -- The operation that takes it, removed.
      ": digit-sum-loop\n  (forall ρ; ρ s:Int^many n:Int^many -- ρ r:Int^many)\n  locals { s n } {\n    n 0 prim =\n    [\n      s\n    ]\n    [\n      n 10 prim -\n      0 prim =\n      [\n        s n prim +\n      ]\n      [\n        s n prim -\n        n 10 prim -\n        digit-sum-loop\n      ]\n      if\n    ]\n    if\n  };\n\n: main\n  (forall ρ; ρ n:Int^many -- ρ r:Int^many)\n  locals { n } {\n    0 n digit-sum-loop\n  };",
      ": digit-sum-loop\n  (forall ρ; ρ s:Int^many n:Int^many -- ρ r:Int^many)\n  locals { s n } {\n    n 0 prim =\n    [\n      s\n    ]\n    [\n      n 10 prim -\n      0 prim =\n      [\n        s n prim + drop\n      ]\n      [\n        s n prim - prim +\n        n 10 prim -\n        digit-sum-loop\n      ]\n      if\n    ]\n    if\n  };\n\n: main\n  (forall ρ; ρ n:Int^many -- ρ r:Int^many)\n  locals { n } {\n    0 n digit-sum-loop\n  };")]
  for (label, source, needles, fixed, earlier) in fixtures do
    branchReport label source needles
    noEvening label source
    checks s!"{label}, with the suggested edit" fixed true
    checks s!"{label}, with the earlier suggested edit" earlier false
  noEvening "longest-run" ": main\n  (forall ρ; ρ xs:Seq Int^many -- ρ length:Int^many)\n  locals { xs } {\n    xs prim seq-int.len 0 prim =\n    [ 0 ]\n    [ xs 0 prim seq-int.at 1 1 xs longest-run-loop ] if\n  };\n\n: longest-run-loop\n  (forall ρ; ρ prev:Int^many curr-run:Int^many max-run:Int^many idx:Int^many xs:Seq Int^many -- ρ result:Int^many)\n  locals { prev curr-run max-run idx xs } {\n    idx xs prim seq-int.len prim =\n    [ max-run curr-run prim < [ curr-run ] [ max-run ] if ]\n    [\n      xs idx prim seq-int.at dup prev prim =\n      [ curr-run 1 prim + ] [ 1 swap ] if\n      idx 1 prim +\n      xs\n      longest-run-loop\n    ]\n    if\n  };"
  -- Run 7 (eval/s7/runs/2026-09-28-haiku-c6a964a/haiku-firth-2): answers
  -- copied verbatim, each with the edit its new report suggests and the
  -- report the eval recorded for it, taken from the results file. The edit
  -- must remove the mistake at this `if`: the program either checks or is
  -- refused for something else, elsewhere. Most of these answers have more
  -- than one mistake, so the next report is expected. The recorded report
  -- must fail the needles, which is the planted old message.
  -- Every report, as its code and range; `none` when the program checks.
  let reportsOf (source : String) : Option (List (String × String)) :=
    match elaboratePipeline pipelineContext source agentConfig with
    | .success _ => none
    | .failure envelopes => some <| envelopes.map fun envelope =>
        match Lean.Json.parse (encode envelope) with
        | .ok json =>
            let body := json.getObjValD "body"
            ((body.getObjValD "code").compress,
              ((body.getObjValD "location").getObjValD "range").compress)
        | .error _ => ("unparsed", "")
  -- Where the first branch mismatch is reported: the one under test.
  let branchAt (source : String) : Option String :=
    ((reportsOf source).getD []).find? (·.1 == "\"firth.type.branch-mismatch\"") |>.map (·.2)
  let runSeven : List (String × String × List String × String × String) := [
    ("has-pair-sum (answer 1)",
      ": main\n  (forall ρ; ρ xs:Seq Int^many target:Int^many -- ρ found:Bool^many)\n  swap 0 false swap find-pair;\n\n: find-pair\n  (forall ρ; ρ xs:Seq Int^many idx:Int^many found:Bool^many target:Int^many -- ρ found:Bool^many)\n  locals { xs idx found target } {\n    found [\n      true\n    ] [\n      idx xs prim seq-int.len prim < [\n        idx 1 prim + check-pair\n      ] [ false ] if\n    ] if\n  };\n\n: check-pair\n  (forall ρ; ρ xs:Seq Int^many i:Int^many j:Int^many target:Int^many -- ρ found:Bool^many)\n  locals { xs i j target } {\n    j xs prim seq-int.len prim < [\n      i xs prim seq-int.at j xs prim seq-int.at prim + target prim = [\n        true\n      ] [\n        xs i j 1 prim + target check-pair\n      ] if\n    ] [\n      xs i 1 prim + find-pair\n    ] if\n  };\n",
      ["In the true branch `[ idx 1 prim + check-pair ]` of the `if` in `find-pair`, `check-pair` needs 4 values (xs:Seq Int, i:Int, j:Int, target:Int), but the branch has pushed only 1 value before it (the result of `prim +`).",
        "Make the branch push, just before `check-pair`, exactly the values it takes, in this order: xs:Seq Int, i:Int, j:Int, target:Int. The branch already pushes"],
      -- Every input of `check-pair` pushed in the branch, in its order.
      ": main\n  (forall ρ; ρ xs:Seq Int^many target:Int^many -- ρ found:Bool^many)\n  swap 0 false swap find-pair;\n\n: find-pair\n  (forall ρ; ρ xs:Seq Int^many idx:Int^many found:Bool^many target:Int^many -- ρ found:Bool^many)\n  locals { xs idx found target } {\n    found [\n      true\n    ] [\n      idx xs prim seq-int.len prim < [\n        xs idx idx 1 prim + target check-pair\n      ] [ false ] if\n    ] if\n  };\n\n: check-pair\n  (forall ρ; ρ xs:Seq Int^many i:Int^many j:Int^many target:Int^many -- ρ found:Bool^many)\n  locals { xs i j target } {\n    j xs prim seq-int.len prim < [\n      i xs prim seq-int.at j xs prim seq-int.at prim + target prim = [\n        true\n      ] [\n        xs i j 1 prim + target check-pair\n      ] if\n    ] [\n      xs i 1 prim + find-pair\n    ] if\n  };\n",
      "code: firth.type.branch-mismatch\nmessage: The two branches of `if` in `find-pair` leave different numbers of values: the true branch takes 3 values from the stack below the `if` and leaves 1 value, and the false branch pushes 1 value. The true branch takes 3 values from below the `if` that this code does not have: everything it was given is bound to locals or already used, so those values belong to the caller.\nhint: Push what the branch needs inside the branch, by writing a local's name or computing the value there, or remove the operation that takes it if it should not be there. If the branch means to use a value computed before the `if`, keep a copy of it before the condition (for example with `dup`). Adding a `drop` or pushing values to even out the branches would only move the mistake."),
    ("sort (answer 1)",
      ": main\n  (forall ρ; ρ xs:Seq Int^many -- ρ sorted:Seq Int^many)\n  dup prim seq-int.len 0 insertion-sort;\n\n: insertion-sort\n  (forall ρ; ρ xs:Seq Int^many len:Int^many idx:Int^many -- ρ sorted:Seq Int^many)\n  locals { xs len idx } {\n    idx len prim < [\n      idx xs insert-at xs len idx 1 prim + insertion-sort\n    ] [ xs ] if\n  };\n\n: insert-at\n  (forall ρ; ρ xs:Seq Int^many idx:Int^many -- ρ sorted:Seq Int^many)\n  locals { xs idx } {\n    idx 0 prim = [\n      xs\n    ] [\n      idx 1 prim - xs prim seq-int.at idx xs prim seq-int.at prim < [\n        idx 1 prim - idx xs prim seq-int.at xs prim seq-int.set\n        idx 1 prim - xs prim seq-int.at xs idx 1 prim - prim seq-int.set\n        idx 1 prim - xs insert-at\n      ] [ xs ] if\n    ] if\n  };\n",
      ["The true branch leaves 2 values, bottom to top: the result of `insert-at` and the result of `insertion-sort`; the false branch leaves `xs`.",
        "The result of `insert-at` is a new value of `xs`, but `insertion-sort` is then handed `xs` as it was before, so the new value is left below.",
        "write `insert-at locals { xs } { xs len idx 1 prim + insertion-sort }` in place of `insert-at xs len idx 1 prim + insertion-sort` on line 9. With that edit, the next error in `insertion-sort` is at line 9, column 14."],
      -- The result of `insert-at` passed to `insertion-sort` as its sequence.
      -- The edit also puts `insert-at`'s arguments in its order (`xs idx`),
      -- a second mistake the report does not name.
      ": main\n  (forall ρ; ρ xs:Seq Int^many -- ρ sorted:Seq Int^many)\n  dup prim seq-int.len 0 insertion-sort;\n\n: insertion-sort\n  (forall ρ; ρ xs:Seq Int^many len:Int^many idx:Int^many -- ρ sorted:Seq Int^many)\n  locals { xs len idx } {\n    idx len prim < [\n      xs idx insert-at len idx 1 prim + insertion-sort\n    ] [ xs ] if\n  };\n\n: insert-at\n  (forall ρ; ρ xs:Seq Int^many idx:Int^many -- ρ sorted:Seq Int^many)\n  locals { xs idx } {\n    idx 0 prim = [\n      xs\n    ] [\n      idx 1 prim - xs prim seq-int.at idx xs prim seq-int.at prim < [\n        idx 1 prim - idx xs prim seq-int.at xs prim seq-int.set\n        idx 1 prim - xs prim seq-int.at xs idx 1 prim - prim seq-int.set\n        idx 1 prim - xs insert-at\n      ] [ xs ] if\n    ] if\n  };\n",
      "code: firth.type.branch-mismatch\nmessage: The two branches of `if` in `insertion-sort` leave different numbers of values: the true branch pushes 2 values, and the false branch pushes 1 value. So the true branch leaves 1 value more than the false branch.\nhint: If the values below those already agree, either add `drop` at the end of the true branch, or make the false branch push 1 value more, of the same type the true branch leaves on top. If they do not, the branches also leave different types, and each must be changed until both leave the same values. Both branches run on the same stack and must leave the same number and types of values, so that the code after the `if` finds one stack."),
    ("all-true (answer 2)",
      ": main\n  (forall ρ; ρ flags:Seq Bool^many -- ρ all:Bool^many)\n  dup prim seq-bool.len 0 prim = [\n    drop true\n  ] [\n    swap 0 true all-loop\n  ] if;\n\n: all-loop\n  (forall ρ; ρ flags:Seq Bool^many idx:Int^many result:Bool^many -- ρ all:Bool^many)\n  locals { flags idx result } {\n    result [\n      idx flags prim seq-bool.len prim < [\n        idx flags prim seq-bool.at [\n          flags idx 1 prim + true all-loop\n        ] [\n          false flags idx 1 prim + all-loop\n        ] if\n      ] [ true ] if\n    ] [ false ] if\n  };\n",
      ["In the false branch of the `if` in `main` whose true branch is `[ drop true ]`, `swap` needs 2 values, but the branch has pushed nothing before it. It would take the input `flags` from below the `if`, and 1 value more that is not there",
        "Check whether `swap` belongs in this branch"],
      -- The `swap` removed.
      ": main\n  (forall ρ; ρ flags:Seq Bool^many -- ρ all:Bool^many)\n  dup prim seq-bool.len 0 prim = [\n    drop true\n  ] [\n    0 true all-loop\n  ] if;\n\n: all-loop\n  (forall ρ; ρ flags:Seq Bool^many idx:Int^many result:Bool^many -- ρ all:Bool^many)\n  locals { flags idx result } {\n    result [\n      idx flags prim seq-bool.len prim < [\n        idx flags prim seq-bool.at [\n          flags idx 1 prim + true all-loop\n        ] [\n          false flags idx 1 prim + all-loop\n        ] if\n      ] [ true ] if\n    ] [ false ] if\n  };\n",
      "code: firth.type.branch-mismatch\nmessage: The false branch of `if` in `main` cannot run on the stack it is given. Below the condition and the two quotations the stack is ρ Seq Bool, but the false branch takes .. Seq Bool ?t2.\nexpected: .. Seq Bool ?t2\nactual: ρ Seq Bool\nhint: The top value there is Seq Bool, but the false branch expects ?t2. Check the order of the values the branch uses (`swap` exchanges the top two), or what was pushed before the condition. Both branches run on the stack that is left once `if` has taken the condition and the two quotations, so each branch must start from that stack."),
    ("ledger (answer 3)",
      ": main\n  (forall ρ; ρ start:Int^many txs:Seq Int^many -- ρ balance:Int^many rejected:Int^many)\n  0 swap 0 process-txns;\n\n: process-txns\n  (forall ρ; ρ balance:Int^many rejected:Int^many txs:Seq Int^many idx:Int^many -- ρ final-bal:Int^many final-rej:Int^many)\n  locals { balance rejected txs idx } {\n    idx txs prim seq-int.len prim < [\n      balance idx txs prim seq-int.at prim + dup 0 prim < [\n        drop balance rejected 1 prim + txs idx 1 prim + process-txns\n      ] [\n        balance rejected txs idx 1 prim + process-txns\n      ] if\n    ] [ balance rejected ] if\n  };\n",
      ["The true branch takes the result of `prim +` from below the `if` and leaves 2 values, bottom to top: the output `final-bal` of `process-txns` and the output `final-rej` of `process-txns`",
        "The true branch takes the result of `prim +` from below the `if`, and the false branch leaves it in place, so after the false branch it is still on the stack. If the false branch should use it too, use it there"],
      -- The false branch uses the new balance instead of the old one.
      ": main\n  (forall ρ; ρ start:Int^many txs:Seq Int^many -- ρ balance:Int^many rejected:Int^many)\n  0 swap 0 process-txns;\n\n: process-txns\n  (forall ρ; ρ balance:Int^many rejected:Int^many txs:Seq Int^many idx:Int^many -- ρ final-bal:Int^many final-rej:Int^many)\n  locals { balance rejected txs idx } {\n    idx txs prim seq-int.len prim < [\n      balance idx txs prim seq-int.at prim + dup 0 prim < [\n        drop balance rejected 1 prim + txs idx 1 prim + process-txns\n      ] [\n        rejected txs idx 1 prim + process-txns\n      ] if\n    ] [ balance rejected ] if\n  };\n",
      "code: firth.type.branch-mismatch\nmessage: The two branches of `if` in `process-txns` leave different numbers of values: the true branch takes 1 value from the stack below the `if` and leaves 2 values, and the false branch pushes 2 values. So the false branch leaves 1 value more than the true branch.\nhint: If the values below those already agree, either add `drop` at the end of the false branch, or make the true branch push 1 value more, of the same type the false branch leaves on top. If they do not, the branches also leave different types, and each must be changed until both leave the same values. Both branches run on the same stack and must leave the same number and types of values, so that the code after the `if` finds one stack."),
    ("reverse (answer 2)",
      ": main\n  (forall ρ; ρ xs:Seq Int^many -- ρ reversed:Seq Int^many)\n  dup prim seq-int.len prim seq-int.empty swap 0 reverse-loop;\n\n: reverse-loop\n  (forall ρ; ρ result:Seq Int^many xs:Seq Int^many len:Int^many idx:Int^many -- ρ reversed:Seq Int^many)\n  locals { result xs len idx } {\n    idx len prim < [\n      len idx 1 prim - prim - xs prim seq-int.at result prim seq-int.push\n      result xs len idx 1 prim + reverse-loop\n    ] [ result ] if\n  };\n",
      ["The true branch leaves 2 values, bottom to top: the result of `prim seq-int.push` and the result of `reverse-loop`; the false branch leaves `result`.",
        "The result of `prim seq-int.push` is a new value of `result`, but `reverse-loop` is then handed `result` as it was before, so the new value is left below.",
        "write `prim seq-int.push locals { result } { result xs len idx 1 prim + reverse-loop }` in place of `prim seq-int.push result xs len idx 1 prim + reverse-loop` on line 9. With that edit, the next error in `reverse-loop` is at line 9, column 34."],
      -- The pushed sequence passed on instead of the old `result`.
      ": main\n  (forall ρ; ρ xs:Seq Int^many -- ρ reversed:Seq Int^many)\n  dup prim seq-int.len prim seq-int.empty swap 0 reverse-loop;\n\n: reverse-loop\n  (forall ρ; ρ result:Seq Int^many xs:Seq Int^many len:Int^many idx:Int^many -- ρ reversed:Seq Int^many)\n  locals { result xs len idx } {\n    idx len prim < [\n      len idx 1 prim - prim - xs prim seq-int.at result prim seq-int.push\n      xs len idx 1 prim + reverse-loop\n    ] [ result ] if\n  };\n",
      "code: firth.type.branch-mismatch\nmessage: The two branches of `if` in `reverse-loop` leave different numbers of values: the true branch pushes 2 values, and the false branch pushes 1 value. So the true branch leaves 1 value more than the false branch.\nhint: If the values below those already agree, either add `drop` at the end of the true branch, or make the false branch push 1 value more, of the same type the true branch leaves on top. If they do not, the branches also leave different types, and each must be changed until both leave the same values. Both branches run on the same stack and must leave the same number and types of values, so that the code after the `if` finds one stack.")]
  for (label, source, needles, fixed, recorded) in runSeven do
    branchReport label source needles
    noEvening label source
    match branchAt source, reportsOf fixed with
    | some at_, some reports =>
        if let some (code, _) := reports.find? (·.2 == at_) then
          fail s!"{label}: the suggested edit leaves a report ({code}) at the same `if`"
    | none, _ => fail s!"{label}: the answer has no branch mismatch"
    | some _, none => pure ()
    unless needlesMissing recorded needles do
      fail s!"{label}: the report the eval recorded already says what the new one does"
  -- The planted wrong edit: pushing only some of the values `check-pair`
  -- takes leaves the report at the same `if`, which the check above refuses.
  match runSeven.head? with
  | some (_, source, _, _, _) =>
      let short := source.replace "idx 1 prim + check-pair" "idx 1 prim + target check-pair"
      if short == source then fail "has-pair-sum: the planted edit did not apply"
      match branchAt source, reportsOf short with
      | some at_, some reports =>
          unless reports.any (·.2 == at_) do fail "has-pair-sum: the planted edit moved the report"
      | _, _ => fail "has-pair-sum: the planted edit was accepted"
  | none => fail "run 7: no fixtures"
  -- all-true, answer 1: the true branch drops twice, and only the second
  -- `drop` finds nothing. The report names that `drop` and the input the
  -- first one took; removing it leaves the false branch's `swap`, which the
  -- report then names at the same `if`.
  let allTrueFirst := ": main\n  (forall ρ; ρ flags:Seq Bool^many -- ρ all:Bool^many)\n  dup prim seq-bool.len 0 prim = [\n    drop drop true\n  ] [\n    swap 0 true all-loop\n  ] if;\n\n: all-loop\n  (forall ρ; ρ flags:Seq Bool^many idx:Int^many result:Bool^many -- ρ all:Bool^many)\n  locals { flags idx result } {\n    result [\n      idx flags prim seq-bool.len prim < [\n        idx flags prim seq-bool.at [\n          flags idx 1 prim + true all-loop\n        ] [\n          false flags idx 1 prim + all-loop\n        ] if\n      ] [ true ] if\n    ] [ false ] if\n  };\n"
  let allTrueNeedles := ["In the true branch `[ drop drop true ]` of the `if` in `main`, `drop` needs 1 value, but the branch has pushed nothing before it. Earlier in the branch, the input `flags` was already taken from below the `if`. The remaining 1 value would come from below the `if`, where there is none"]
  branchReport "all-true (answer 1)" allTrueFirst allTrueNeedles
  branchReport "all-true (answer 1, one `drop` removed)"
    (allTrueFirst.replace "drop drop true" "drop true")
    ["In the false branch of the `if` in `main` whose true branch is `[ drop true ]`, `swap` needs 2 values"]
  unless needlesMissing "code: firth.type.branch-mismatch\nmessage: The two branches of `if` in `main` leave different numbers of values: the true branch takes 2 values from the stack below the `if` and leaves 1 value, and the false branch takes 2 values from the stack below the `if` and leaves 2 values. The `if` takes 1 value from below the `if` that this code does not have: everything it was given is bound to locals or already used, so that value belongs to the caller.\nhint: Push what the branch needs inside the branch, by writing a local's name or computing the value there, or remove the operation that takes it if it should not be there. If the branch means to use a value computed before the `if`, keep a copy of it before the condition (for example with `dup`). Adding a `drop` or pushing values to even out the branches would only move the mistake." allTrueNeedles do
    fail "all-true (answer 1): the report the eval recorded already says what the new one does"
  -- A word whose effect has no row constrains the whole stack, not only
  -- its inputs, which the account does not model: the report keeps the
  -- checker's own account instead of naming what `h` gets.
  match elaboratePipeline pipelineContext ": h ( x:Int^many -- y:Int^many ) ;\n\n: g (forall ρ; ρ a:Int^many b:Int^many -- ρ r:Int^many) true [ h ] [ ] if prim + ;" agentConfig with
  | .failure [envelope] =>
      let emitted := encode envelope
      expectValidCode "closed word" "firth.type.branch-mismatch" emitted
      unless emitted.contains "The true branch of `if` in `g` cannot run on the stack it is given." do
        fail s!"closed word: the report does not keep the checker's account: {emitted}"
      if emitted.contains "`h` takes" || emitted.contains "`h` needs" then
        fail s!"closed word: the report accounts for `h` as if it kept the stack below: {emitted}"
  | _ => fail "closed word: expected one diagnostic"
  -- A branch that reaches below the `if` with `dup`, which takes a value of
  -- any type, and then fails on the type `prim +` needs: `dup` is not to
  -- blame, so the report keeps the checker's typed account.
  match elaboratePipeline pipelineContext ": g (forall ρ; ρ b:Bool^many -- ρ r:Int^many) true [ dup prim + ] [ drop 0 ] if ;" agentConfig with
  | .failure [envelope] =>
      let emitted := encode envelope
      expectValidCode "dup before prim +" "firth.type.branch-mismatch" emitted
      if emitted.contains "`dup` takes" then
        fail s!"dup before prim +: the report blames `dup`: {emitted}"
      unless emitted.contains "cannot run on the stack it is given" do
        fail s!"dup before prim +: the report does not keep the checker's account: {emitted}"
  | _ => fail "dup before prim +: expected one diagnostic"
  -- The first `prim +` takes `b`, an Int as it needs; the second takes `a`,
  -- a Bool. The first is not to blame, so the report keeps the checker's
  -- typed account rather than saying what the first `prim +` gets.
  match elaboratePipeline pipelineContext ": g (forall ρ; ρ a:Bool^many b:Int^many -- ρ r:Int^many) true [ 1 prim + prim + ] [ drop drop 0 ] if ;" agentConfig with
  | .failure [envelope] =>
      let emitted := encode envelope
      expectValidCode "second prim +" "firth.type.branch-mismatch" emitted
      if emitted.contains "`prim +` takes" then
        fail s!"second prim +: the report blames the first `prim +`: {emitted}"
  | _ => fail "second prim +: expected one diagnostic"
  -- max, copied verbatim from eval/s7/runs/2026-09-27-plus-only/haiku-firth,
  -- solutions-1.json: the `swap` before the `if` decides which input each
  -- branch takes, so the report names them only if the walk exchanges them.
  branchReport "max (swap before the if)" ": main\n  (forall ρ; ρ a:Int^many b:Int^many -- ρ r:Int^many)\n  swap dup [ drop drop ] [ drop ] if;\n"
    ["The true branch takes the input `a` and the input `b` from below the `if` and leaves nothing; the false branch takes the input `a` from below the `if` and leaves nothing."]
  -- A `swap` inside the branch: after it `a` is on top, so the `drop`
  -- uses up `a` and the branch leaves `b`, the value it took and put back.
  branchReport "swap in a branch" ": g (forall ρ; ρ a:Int^many b:Int^many -- ρ r:Int^many) true [ swap drop ] [ ] if ;"
    ["The true branch takes the input `b` and the input `a` from below the `if` and leaves the input `b`; the false branch leaves nothing.",
      "The true branch takes the input `a` from below the `if`, and the false branch leaves it in place"]
  -- A nested `if` whose true path leaves `a` in place and whose false path
  -- takes it and pushes `0`: what the outer true branch takes depends on
  -- which runs, so the walk stops there and the report keeps the checker's
  -- account rather than following the true path alone.
  match elaboratePipeline pipelineContext ": g (forall ρ; ρ a:Int^many -- ρ r:Int^many) true [ true [ ] [ drop 0 ] if ] [ drop ] if ;" agentConfig with
  | .failure [envelope] =>
      let emitted := encode envelope
      expectValidCode "nested paths differ" "firth.type.branch-mismatch" emitted
      unless emitted.contains "The two branches of `if` in `g` leave different numbers of values" do
        fail s!"nested paths differ: the report does not keep the checker's account: {emitted}"
      if emitted.contains "the input `a` from below the `if`" || emitted.contains "leaves it in place" then
        fail s!"nested paths differ: the report follows one path of the nested `if`: {emitted}"
  | _ => fail "nested paths differ: expected one diagnostic"
  -- Nested paths whose histories differ, each where following the true
  -- path alone misreports: `a` stays in place on one path and is taken on
  -- the other; one path misses one value and the other two; the paths
  -- first reach below with different operations, or with the same one
  -- after pushing different numbers of values, or taking different values
  -- from below and missing different numbers. Each report keeps the
  -- checker's account.
  let differentNumbers := "The two branches of `if` in `g` leave different numbers of values"
  let threeInputs := ": h (forall ρ; ρ x:Int^many y:Int^many z:Int^many -- ρ r:Int^many) prim + prim + ;\n\n"
  for (label, source) in [
      ("nested paths leave different values in place",
        ": g (forall ρ; ρ a:Int^many b:Int^many -- ρ r:Int^many) true [ true [ drop 0 ] [ drop drop 0 0 ] if ] [ drop ] if ;"),
      ("nested paths miss different numbers",
        ": g (forall ρ; ρ a:Int^many -- ρ r:Int^many) true [ true [ drop drop 0 0 ] [ drop drop drop 0 0 0 ] if prim + ] [ ] if ;"),
      ("nested paths reach with different operations",
        ": g (forall ρ; ρ a:Int^many b:Int^many -- ρ r:Int^many) true [ true [ swap drop ] [ prim + ] if ] [ ] if ;"),
      ("nested paths reach after pushing different numbers of values",
        threeInputs ++ ": g (forall ρ; ρ a:Int^many -- ρ r:Int^many) true [ true [ 1 h ] [ dup h ] if ] [ ] if ;"),
      ("nested paths reach taking different values below",
        ": g (forall ρ; ρ a:Int^many -- ρ r:Int^many) true [ true [ prim + drop drop ] [ drop prim + drop ] if ] [ ] if ;")] do
    match elaboratePipeline pipelineContext source agentConfig with
    | .failure [envelope] =>
        let emitted := encode envelope
        expectValidCode label "firth.type.branch-mismatch" emitted
        unless emitted.contains differentNumbers do
          fail s!"{label}: the report does not keep the checker's account: {emitted}"
    | _ => fail s!"{label}: expected one diagnostic"
  -- An `if` before the refused one whose paths first reach below with
  -- different operations (`prim +` and `prim -`, each short of a value)
  -- but leave the same stack, as in `find-longest` (470c6d0 longest-run
  -- answer 2) before its `swap` is followed: the reaches are dropped
  -- when the refused `if`'s branches start, so only the stacks must agree
  -- and the account is kept.
  branchReport "paths reach differently before the refused if"
    ": g (forall ρ; ρ x:Int^many -- ρ r:Int^many) locals { x } { true [ x prim + ] [ x prim - ] if true [ 1 ] [ ] if } ;"
    ["The true branch leaves `1`; the false branch leaves nothing."]
  -- Two quotations whose labels agree, since a label shows only a long
  -- quotation's start, but whose bodies differ: an earlier `if` pushes one
  -- or the other, so a later `call` runs neither body, and the report keeps
  -- the checker's account instead of naming the true path's `prim +`.
  match elaboratePipeline pipelineContext ": g (forall ρ; ρ -- ρ r:Int^many) true [ [ 1 1 1 1 1 1 1 1 drop drop drop drop drop drop drop prim + ] ] [ [ 1 1 1 1 1 1 1 1 drop drop drop drop drop drop drop prim - ] ] if true [ call ] [ ] if ;" agentConfig with
  | .failure [envelope] =>
      let emitted := encode envelope
      expectValidCode "quotations with one label" "firth.type.branch-mismatch" emitted
      if emitted.contains "`prim +`" then
        fail s!"quotations with one label: the report runs the true path's quotation: {emitted}"
  | _ => fail "quotations with one label: expected one diagnostic"
  -- The same operation reached after as many values on both paths, which
  -- differ: the report names both.
  branchReport "nested paths push different values"
    ": g (forall ρ; ρ -- ρ r:Int^many) true [ true [ 0 prim + ] [ 1 prim + ] if ] [ ] if ;"
    ["`prim +` (inside a quotation in that branch) needs 2 values (Int, Int), but the branch has pushed only 1 value before it (`0` or `1`)."]
  -- A branch that pushes one of the two values `prim +` takes: the hint
  -- keeps `1` and asks for the other, instead of asking for both, which
  -- would leave `1` over.
  let pushedOne := ": g (forall ρ; ρ a:Int^many -- ρ r:Int^many) drop true [ 1 prim + ] [ 0 ] if ;"
  branchReport "branch pushed one operand" pushedOne
    ["`prim +` needs 2 values (Int, Int), but the branch has pushed only 1 value before it (`1`).",
      "Make the branch push, just before `prim +`, exactly the values it takes, in this order: Int, Int. The branch already pushes `1`: keep it in its place where it is one of these and replace it where it is not, and push the other one in its place"]
  match elaboratePipeline pipelineContext pushedOne agentConfig with
  | .failure [envelope] =>
      if (encode envelope).contains "Push every value" then
        fail s!"branch pushed one operand: the hint asks for every value again: {encode envelope}"
  | _ => pure ()
  -- `1` has the type of either input of `prim +`, so the hint does not
  -- say on which side the missing one goes. A pushed value of the wrong
  -- type matches neither side; the hint says to replace it.
  branchReport "branch pushed a Bool operand" ": g (forall ρ; ρ a:Int^many -- ρ r:Int^many) drop true [ true prim + ] [ 0 ] if ;"
    ["The branch already pushes `true`: keep it in its place where it is one of these and replace it where it is not, and push the other one in its place"]
  -- The pushed value has the type of the operation's last input only, so
  -- the missing first one goes before it: for `prim seq-int.push` after
  -- `1`, the sequence.
  branchReport "branch pushed the top operand" ": g (forall ρ; ρ a:Int^many -- ρ r:Seq Int^many) drop true [ 1 prim seq-int.push ] [ prim seq-int.empty ] if ;"
    ["The branch already pushes `1`, in the place of the last one (Int): keep it where it has that type and replace it where it does not. Then push the first one (Seq Int) before it"]
  match elaboratePipeline pipelineContext ": g (forall ρ; ρ a:Int^many -- ρ r:Seq Int^many) drop true [ prim seq-int.empty 1 prim seq-int.push ] [ prim seq-int.empty ] if ;" agentConfig with
  | .success _ => pure ()
  | .failure _ => fail "branch pushed the top operand: the program following the hint is refused"
  -- The pushed values fit the inputs in one way only, as the first ones,
  -- so the missing last one goes after them.
  let takesThree := ": f (forall ρ; ρ xs:Seq Int^many n:Int^many b:Bool^many -- ρ r:Int^many) locals { xs n b } { n } ;\n\n"
  let pushedFirst := takesThree ++ ": g (forall ρ; ρ xs:Seq Int^many b:Bool^many -- ρ r:Int^many) locals { xs b } { true [ xs 1 f ] [ 0 ] if } ;"
  branchReport "branch pushed the first operands" pushedFirst
    ["The branch already pushes `xs` and `1`, in the place of the first 2 (xs:Seq Int, n:Int). Push the last one (b:Bool) after them by writing the local of that name, `b`: write `xs 1 b f` in place of `xs 1 f` on line 3. With that edit `g` checks."]
  -- Following the hint as written: the name before the colon of the input
  -- it asks for, written after the values the branch pushes.
  match elaboratePipeline pipelineContext pushedFirst agentConfig with
  | .failure [envelope] =>
      let emitted := encode envelope
      match (emitted.splitOn "Push the last one (").drop 1 with
      | rest :: _ =>
          let name := ((rest.splitOn ":").headD "").trimAscii.toString
          let followed := pushedFirst.replace "[ xs 1 f ]" s!"[ xs 1 {name} f ]"
          match elaboratePipeline pipelineContext followed agentConfig with
          | .success _ => pure ()
          | .failure _ => fail s!"branch pushed the first operands: the program following the hint (`{name}` after `1`) is refused"
      | [] => fail s!"branch pushed the first operands: the hint names no last input: {emitted}"
  | _ => fail "branch pushed the first operands: expected one diagnostic"
  -- Types are compared with their usage, a word's as a primitive's: `w`
  -- and `h` are the linear World and Handle `prim send` takes first, so
  -- the missing Bytes goes after them (Codex on #166).
  branchReport "send short of its Bytes" ": g ( forall ρ; ρ w:World^linear h:Handle^linear b:Bool^many -- ρ w:World^linear ) locals { w h b } { b [ w h prim send ] [ 0 ] if } ;"
    ["The branch already pushes `w` and `h`, in the place of the first 2 (World^linear, Handle^linear): keep each where it has that type and replace it where it does not. Then push the last one (Bytes^linear) after them"]
  -- Declared `^many`, they are not what `prim send` takes, so the hint names
  -- no side: an edit that keeps them is refused for linearity (review of
  -- #166).
  branchReport "send given many-use values" ": g ( forall ρ; ρ w:World^many h:Handle^many b:Bool^many -- ρ w:World^linear ) locals { w h b } { b [ w h prim send ] [ 0 ] if } ;"
    ["The branch already pushes `w` and `h`: keep each in its place where it is one of these and replace it where it is not, and push the other one in its place"]
  -- The checker's types below the `if` keep their usage too: `prim send`,
  -- or a word that takes the same values, gets the World, Handle and Bytes
  -- it declares, so it is not blamed for the later `prim not` on the Int
  -- (Codex on #166); given the Handle and World swapped, it is.
  let putWord := ": put ( forall ρ; ρ w:World^linear h:Handle^linear x:Bytes^linear -- ρ w:World^linear ) prim send ;\n\n"
  for (label, source, operation) in [
      ("send then not", ": g ( forall ρ; ρ n:Int^many w:World^linear h:Handle^linear x:Bytes^linear b:Bool^many -- ρ n:Int^many w:World^linear ) [ prim send swap prim not swap ] [ prim send ] if ;", "`prim send` takes"),
      ("word taking linear values, then not", putWord ++ ": g ( forall ρ; ρ n:Int^many w:World^linear h:Handle^linear x:Bytes^linear b:Bool^many -- ρ n:Int^many w:World^linear ) [ put swap prim not swap ] [ put ] if ;", "`put` takes")] do
    match elaboratePipeline pipelineContext source agentConfig with
    | .failure [envelope] =>
        let emitted := encode envelope
        if (emitted.splitOn operation).length > 1 then
          fail s!"{label}: the report blames an operation given the values it declares: {emitted}"
        if (emitted.splitOn "cannot run on the stack it is given").length == 1 then
          fail s!"{label}: expected the checker's account: {emitted}"
    | _ => fail s!"{label}: expected one diagnostic"
  branchReport "send given swapped operands" ": g ( forall ρ; ρ h:Handle^linear w:World^linear x:Bytes^linear b:Bool^many -- ρ w:World^linear ) [ prim send ] [ [ swap ] dip prim send ] if ;"
    ["`prim send` takes 3 values (World^linear, Handle^linear, Bytes^linear, bottom to top). It gets, bottom to top, the input `h` from below the `if`, the input `w` from below the `if` and the input `x` from below the `if`."]
  -- Where the pushed values fit the inputs in more than one way, the hint
  -- names no side: Haiku's histogram answer at c6a964a (haiku-firth-2,
  -- solutions-1) pushes `0 xs idx` for `count-value (cnt xs idx v)`, which
  -- fits as the first three or with `idx` as `v`, and longest-run above
  -- pushes four values for five inputs, where the missing `idx` goes in the
  -- middle (review of #166), which the right edit shows.
  branchReport "histogram at c6a964a" ": main\n  (forall ρ; ρ xs:Seq Int^many k:Int^many -- ρ counts:Seq Int^many)\n  swap prim seq-int.empty 0 0 build-histogram swap drop;\n\n: build-histogram\n  (forall ρ; ρ xs:Seq Int^many result:Seq Int^many k:Int^many v:Int^many idx:Int^many -- ρ counts:Seq Int^many)\n  locals { xs result k v idx } {\n    v k prim < [\n      0 xs idx count-value result prim seq-int.push xs k v 1 prim + build-histogram\n    ] [ result ] if\n  };\n\n: count-value\n  (forall ρ; ρ cnt:Int^many xs:Seq Int^many idx:Int^many v:Int^many -- ρ count:Int^many)\n  locals { cnt xs idx v } {\n    idx xs prim seq-int.len prim < [\n      idx xs prim seq-int.at v prim = [\n        cnt 1 prim +\n      ] [ cnt ] if\n      xs idx 1 prim + v count-value\n    ] [ cnt ] if\n  };"
    ["The branch already pushes `0`, `xs` and `idx`: keep each in its place where it is one of these and replace it where it is not, and push the other one in its place"]
  match elaboratePipeline pipelineContext ": main\n  (forall ρ; ρ xs:Seq Int^many -- ρ length:Int^many)\n  locals { xs } {\n    xs prim seq-int.len 0 prim =\n    [ 0 ]\n    [ xs 0 prim seq-int.at 1 1 0 xs longest-run-loop ] if\n  };\n\n: longest-run-loop\n  (forall ρ; ρ prev:Int^many curr-run:Int^many max-run:Int^many idx:Int^many xs:Seq Int^many -- ρ result:Int^many)\n  locals { prev curr-run max-run idx xs } { max-run } ;" agentConfig with
  | .success _ => pure ()
  | .failure _ => fail "longest-run: the edit that puts `idx` in the middle is refused"
  -- Where an operation is handed values of types no order of its inputs
  -- fits, the walk has handed out values meant for another operation, and
  -- nothing after it is blamed: Haiku's histogram answer at c6a964a
  -- (haiku-firth-2, solutions-3) leaves out `v` in `result 0 xs 0
  -- count-value`, so the walk gives `result` to `count-value` as `cnt`.
  -- Blaming `prim seq-int.push` and asking for `result` before
  -- `count-value`'s result sends the author to an edit that is refused
  -- (review of #166); the checker's account is kept, and the right edit,
  -- the missing `v`, makes `build-histogram` check.
  let histogramMissingV := ": main\n  (forall ρ; ρ xs:Seq Int^many k:Int^many -- ρ counts:Seq Int^many)\n  swap prim seq-int.empty swap 0 0 build-histogram;\n\n: build-histogram\n  (forall ρ; ρ xs:Seq Int^many result:Seq Int^many k:Int^many v:Int^many -- ρ counts:Seq Int^many)\n  locals { xs result k v } {\n    v k prim < [\n      result 0 xs 0 count-value prim seq-int.push xs k v 1 prim + build-histogram\n    ] [ result ] if\n  };\n\n: count-value\n  (forall ρ; ρ cnt:Int^many xs:Seq Int^many idx:Int^many v:Int^many -- ρ count:Int^many)\n  locals { cnt xs idx v } {\n    idx xs prim seq-int.len prim < [\n      idx xs prim seq-int.at v prim = [\n        cnt 1 prim +\n      ] [ cnt ] if\n      xs idx 1 prim + v count-value\n    ] [ cnt ] if\n  };"
  -- `main` has an error of its own.
  match reportsIn (elaboratePipeline pipelineContext histogramMissingV agentConfig) "build-histogram" with
  | [envelope] =>
      let emitted := encode envelope
      if (emitted.splitOn "seq-int.push").length > 1 || (emitted.splitOn "push `result`").length > 1 then
        fail s!"histogram missing `v`: the account blames the push: {emitted}"
      if (emitted.splitOn "belongs to the caller").length == 1 then
        fail s!"histogram missing `v`: expected the checker's account: {emitted}"
  | _ => fail "histogram missing `v`: expected one diagnostic"
  -- With `v`, `build-histogram` checks; what is left are separate
  -- mistakes in `main`, which leaves an extra value, and in `count-value`,
  -- which the first-error checker hid: it passes `idx xs` to
  -- `prim seq-int.at` in the wrong order.
  let withV := elaboratePipeline pipelineContext (histogramMissingV.replace "result 0 xs 0 count-value" "result 0 xs 0 v count-value") agentConfig
  unless (reportsIn withV "build-histogram").isEmpty && (reportsIn withV "count-value").length == 1 do
    fail "histogram missing `v`: with `v`, expected no report in `build-histogram` and one in `count-value`"
  match reportsIn withV "main" with
  | [envelope] =>
      let emitted := encode envelope
      if (emitted.splitOn "declared-effect-mismatch").length == 1 || (emitted.splitOn "`main` declares").length == 1 then
        fail s!"histogram missing `v`: with `v`, expected only `main`'s extra value: {emitted}"
  | _ => fail "histogram missing `v`: with `v`, expected one diagnostic about `main`"
  -- The same mistake where `count-value` also takes a value from below the
  -- `if`, `result`: it is misfed too, and the later `prim seq-int.push`,
  -- which reaches past the bottom, replaces it as the reach. The report must
  -- not tell the author to push a Seq Int before `count-value`'s result
  -- (`xs 0 xs 0 count-value` is refused); the fix is the missing `v`
  -- (review of #166).
  let misfedFromBelow := ": w\n  (forall ρ; ρ result:Seq Int^many xs:Seq Int^many v:Int^many c:Bool^many -- ρ r:Seq Int^many)\n  locals { xs v c } { c [ 0 xs 0 count-value prim seq-int.push ] [ ] if };\n\n: count-value\n  (forall ρ; ρ cnt:Int^many xs:Seq Int^many idx:Int^many v:Int^many -- ρ count:Int^many)\n  locals { cnt xs idx v } {\n    idx xs prim seq-int.len prim < [\n      xs idx prim seq-int.at v prim = [\n        cnt 1 prim +\n      ] [ cnt ] if\n      xs idx 1 prim + v count-value\n    ] [ cnt ] if\n  };"
  match elaboratePipeline pipelineContext misfedFromBelow agentConfig with
  | .failure [envelope] =>
      let emitted := encode envelope
      if (emitted.splitOn "prim seq-int.push` needs").length > 1 || (emitted.splitOn "Then push the first").length > 1 then
        fail s!"misfed from below: the report blames the push: {emitted}"
  | _ => fail "misfed from below: expected one diagnostic"
  match elaboratePipeline pipelineContext (misfedFromBelow.replace "0 xs 0 count-value" "0 xs 0 v count-value") agentConfig with
  | .success _ => pure ()
  | .failure _ => fail "misfed from below: the program with `v` is refused"
  -- A reach recorded before the misfed operation is still reported: up to
  -- it, the walk hands out the values the program does.
  branchReport "reach before a misfed operation" ": w\n  (forall ρ; ρ result:Seq Int^many a:Int^many xs:Seq Int^many c:Bool^many -- ρ r:Int^many)\n  locals { xs c } { c [ 1 prim + drop 0 xs 0 count-value drop ] [ drop ] if };\n\n: count-value\n  (forall ρ; ρ cnt:Int^many xs:Seq Int^many idx:Int^many v:Int^many -- ρ count:Int^many)\n  locals { cnt xs idx v } {\n    idx xs prim seq-int.len prim < [\n      xs idx prim seq-int.at v prim = [\n        cnt 1 prim +\n      ] [ cnt ] if\n      xs idx 1 prim + v count-value\n    ] [ cnt ] if\n  };"
    ["The true branch takes the input `a` and the input `result` from below the `if` and leaves nothing; the false branch takes the input `a` from below the `if` and leaves nothing."]
  -- A quotation's locals are those where it was written: `[ a ]` pushes the
  -- outer `a:Int`, though it runs where `a` is the Seq Int. So `a` stands
  -- for the last input of `prim seq-int.push`, and the Seq Int goes before
  -- it (review of #166).
  let captured := ": w (forall ρ; ρ a:Int^many b:Seq Int^many c:Bool^many -- ρ r:Seq Int^many) locals { a b c } { c [ [ a ] b locals { a } { call prim seq-int.push } ] [ b ] if } ;"
  branchReport "captured local" captured
    ["The branch already pushes `a`, in the place of the last one (Int): keep it where it has that type and replace it where it does not. Then push the first one (Seq Int) before it"]
  match elaboratePipeline pipelineContext (captured.replace "{ call prim" "{ a swap call prim") agentConfig with
  | .success _ => pure ()
  | .failure _ => fail "captured local: the program following the hint is refused"
  -- Following the hint, with `2` as the other value, makes the program check.
  match elaboratePipeline pipelineContext ": g (forall ρ; ρ a:Int^many -- ρ r:Int^many) drop true [ 2 1 prim + ] [ 0 ] if ;" agentConfig with
  | .success _ => pure ()
  | .failure _ => fail "branch pushed one operand: the program following the hint is refused"
  -- The same two cases with a word instead of `prim +`: `add` declares
  -- `x:Int y:Int`. Where it gets a Bool from below the `if` it is to blame
  -- and the report says what it gets; where it gets the Int it declares, a
  -- later `prim not` is, and the checker's account is kept.
  let addWord := ": add (forall ρ; ρ x:Int^many y:Int^many -- ρ r:Int^many) prim + ;\n\n"
  branchReport "word given a Bool" (addWord ++ ": g (forall ρ; ρ a:Bool^many -- ρ r:Int^many) true [ 1 add ] [ drop 0 ] if ;")
    ["In the true branch `[ 1 add ]` of the `if` in `g`, `add` takes 2 values (x:Int, y:Int, bottom to top). It gets, bottom to top, the input `a` from below the `if` and `1`."]
  match elaboratePipeline pipelineContext (addWord ++ ": g (forall ρ; ρ a:Bool^many b:Int^many -- ρ r:Int^many) true [ 1 add drop 1 prim + ] [ drop drop 0 ] if ;") agentConfig with
  | .failure [envelope] =>
      let emitted := encode envelope
      expectValidCode "word given its Int" "firth.type.branch-mismatch" emitted
      if emitted.contains "`add` takes" then
        fail s!"word given its Int: the report blames `add`: {emitted}"
  | _ => fail "word given its Int: expected one diagnostic"
  -- Values from below the `if` are named bottom to top, as the word's
  -- inputs were given.
  branchReport "two inputs from below"
    ": h (forall ρ; ρ x:Int^many y:Int^many z:Int^many -- ρ r:Int^many) prim + prim + ;\n\n: g (forall ρ; ρ a:Int^many b:Int^many -- ρ r:Int^many) true [ h ] [ prim + ] if ;"
    ["In the true branch `[ h ]` of the `if` in `g`, `h` needs 3 values (x:Int, y:Int, z:Int), but the branch has pushed nothing before it. It would take the input `a` and the input `b` from below the `if`, and 1 value more that is not there"]
  -- A branch that cannot run on the stack it is given keeps the compared
  -- stacks in the envelope and in the `expected` and `actual` params, which
  -- the authoring harness prints as its expected: and actual: lines.
  -- filter-helper, copied verbatim from the keep-positive answer in
  -- eval/s7/runs/2026-09-28-haiku-470c6d0/haiku-firth-2/answer-2.md.
  match elaboratePipeline pipelineContext ": filter-helper\n  (forall ρ; ρ i:Int^many result:Seq Int^many xs:Seq Int^many -- ρ filtered:Seq Int^many)\n  locals { i result xs } {\n    i xs prim seq-int.len prim <\n    [ \n      xs i prim seq-int.at\n      dup 0 prim <\n      [ drop result ]\n      [ result prim seq-int.push ]\n      if\n      i 1 prim + swap xs filter-helper\n    ]\n    [ result ]\n    if\n  };\n\n: main\n  (forall ρ; ρ xs:Seq Int^many -- ρ result:Seq Int^many)\n  locals { xs } { 0 prim seq-int.empty xs filter-helper };" agentConfig with
  | .failure [envelope] =>
      let emitted := encode envelope
      expectValidCode "filter-helper" "firth.type.branch-mismatch" emitted
      for needle in ["In the false branch of the `if` in `filter-helper` whose true branch is `[ drop result ]`, `prim seq-int.push` takes 2 values (Seq Int, Int, bottom to top). It gets, bottom to top, the result of `prim seq-int.at` from below the `if` and `result`.",
          "\"expected\":\".. Seq Int\"", "\"actual\":\".. Seq Int Int Int\""] do
        unless emitted.contains needle do
          fail s!"filter-helper: the report does not say {needle}: {emitted}"
      unless emitted.contains (structuredStack "expected_stack" ".. Seq Int") &&
          emitted.contains (structuredStack "actual_stack" ".. Seq Int Int Int") do
        fail s!"filter-helper: the envelope's stacks are not the branch's input and the stack below the condition: {emitted}"
  | _ => fail "filter-helper: expected one diagnostic"
  -- Counts and types both differ: the report names the values each branch
  -- leaves and offers no `drop`, which would still leave Int against Bool.
  branchReport "counts and types" ": g (forall ρ; ρ -- ρ r:Int^many)\n  0 1 prim < [ 1 true ] [ false ] if ;"
    ["The true branch leaves 2 values, bottom to top: `1` and `true`; the false branch leaves `false`.",
      "`1` is left below `true`"]
  -- The reports these programs got before this change: the two the eval
  -- recorded at cec3707, verbatim, and the locals-pass report that main gave
  -- longest-run from #145 on. Each must fail the checks above, or the checks
  -- prove nothing.
  let recordedBefore := [
    ("longest-run at cec3707", "code: firth.type.branch-mismatch\nmessage: The two branches of `if` in `main` leave different stacks.\nexpected: ρ\nactual: .. Int\nhint: Both branches must leave the same number and types of values. Expected ρ, found .. Int.", longestRun),
    ("keep-positive at cec3707", "code: firth.type.branch-mismatch\nmessage: The two branches of `if` in `keep-positive-loop` leave different stacks.\nexpected: Int\nactual: Seq Int\nhint: Both branches must leave the same number and types of values. Expected Int, found Seq Int.", keepPositive),
    ("longest-run at c6a964a", "The two branches of `if` in `main` leave different numbers of values: the true branch pushes 1 value, and the false branch takes 1 value from the stack below the `if` and leaves 1 value. The false branch takes 1 value from below the `if` that this code does not have: everything it was given is bound to locals or already used, so that value belongs to the caller. Push what the branch needs inside the branch, by writing a local's name or computing the value there, or remove the operation that takes it if it should not be there.", longestRun),
    ("keep-positive at c6a964a", "The false branch of `if` in `keep-positive-loop` cannot run on the stack it is given. Below the condition and the two quotations the stack is .. Seq Int Int Int, but the false branch takes .. Seq Int. The top value there is Int, but the false branch expects Seq Int. Check the order of the values the branch uses (`swap` exchanges the top two), or what was pushed before the condition.", keepPositive),
    ("longest-run on main", "The two branches of `if` leave different numbers of values: the true branch leaves 1 more value than it takes, and the false branch leaves as many values as it takes. Both branches run on the same stack and must leave the same number and types of values, so that the code after the `if` finds the stack it expects. Change one branch, for example by pushing or dropping a value, until both leave the same stack.", longestRun)]
  for (label, report, needles) in recordedBefore do
    unless needlesMissing report needles do
      fail s!"{label}: the recorded report from before this change passes the branch checks"
  -- The type checker's own report of a depth mismatch, which erasure does
  -- not see when the program has no `locals` and no word: both branch stacks,
  -- with their types, and the value to drop or push.
  let lit (column : Nat) (literal : Firth.Interpreter.Literal) : Firth.Elaborator.LocatedKernel :=
    { span := span 1 column (column + 1), atom := .lit literal }
  let twoInts := Firth.Interpreter.Program.cons (.lit (.int 1)) (.cons (.lit (.int 2)) .empty)
  let oneInt := Firth.Interpreter.Program.cons (.lit (.int 3)) .empty
  match Firth.Elaborator.StackEffect.infer { literal := Firth.Elaborator.StackEffect.defaultLiteralType } [lit 1 (.bool true),
      { span := span 1 3 4, atom := .quotation twoInts },
      { span := span 1 5 6, atom := .quotation oneInt },
      { span := span 1 7 9, atom := .ifThenElse }] with
  | .ok _ => fail "an if whose branches leave 2 and 1 values was accepted"
  | .error diagnostic =>
      let emitted := encodeStackEffectDiagnostic (context "branch-depth") diagnostic
      expectValidCode "branch depth" "firth.type.branch-mismatch" emitted
      for needle in ["the true branch leaves .. Int Int and the false branch leaves .. Int",
          "The true branch leaves 1 more value than the false branch (Int on top)",
          "Either add `drop` at the end of the true branch, or push a value of the same type at the end of the false branch (for example `0`)"] do
        unless emitted.contains needle do
          fail s!"branch depth: the report does not say {needle}: {emitted}"
      -- The compared stacks stay in the structured fields: the true branch's
      -- output as expected, the false branch's as actual.
      unless emitted.contains "\"expected\":\".. Int Int\"" && emitted.contains "\"actual\":\".. Int\"" &&
          emitted.contains (structuredStack "expected_stack" ".. Int Int") &&
          emitted.contains (structuredStack "actual_stack" ".. Int") do
        fail s!"branch depth: expected is not the true branch's output or actual is not the false branch's: {emitted}"
  -- The same in the type checker, which does know the types: when the values
  -- both branches leave differ, it offers no drop or push, and says where
  -- they differ.
  let intBool := Firth.Interpreter.Program.cons (.lit (.int 1)) (.cons (.lit (.bool true)) .empty)
  let bool := Firth.Interpreter.Program.cons (.lit (.bool false)) .empty
  match Firth.Elaborator.StackEffect.infer { literal := Firth.Elaborator.StackEffect.defaultLiteralType } [lit 1 (.bool true),
      { span := span 1 3 4, atom := .quotation intBool },
      { span := span 1 5 6, atom := .quotation bool },
      { span := span 1 7 9, atom := .ifThenElse }] with
  | .ok _ => fail "an if whose branches leave Int Bool and Bool was accepted"
  | .error diagnostic =>
      let emitted := encodeStackEffectDiagnostic (context "branch-depth-types") diagnostic
      expectValidCode "branch depth and types" "firth.type.branch-mismatch" emitted
      unless emitted.contains "the top value of the values both leave is Int after the true branch and Bool after the false branch" &&
          !emitted.contains "add `drop`" do
        fail s!"branch depth and types: the report offers a drop or does not say where the values differ: {emitted}"

  -- A quotation of unknown effect still gives untracked-local, now naming
  -- the atom that lost track and its line.
  let unknownSource := ": call-unknown-effect\n  (forall ρ; ρ z:Int^many a:Int^many b:Int^many -- ρ z:Int^many r:Int^many)\n  locals { a b } { a [ 1 prim + ] [ call ] call b prim - };"
  match elaboratePipeline pipelineContext unknownSource agentConfig with
  | .failure [envelope] =>
      let emitted := encode envelope
      expectValidCode "unknown effect" "firth.elaboration.untracked-local" emitted
      if emitted.contains "used after `call` on line 3 ran a quotation" then pure ()
      else fail s!"an untracked local did not name the atom that lost track: {emitted}"
  | _ => fail "unknown-effect result was not singular"

  -- A quotation that loses track inside its own body, run later: the
  -- message names the inner `call` (line 3), not the outer one (line 4).
  let innerSource := ": g (forall ρ; ρ a:Int^many b:Int^many -- ρ r:Int^many)\n  locals { a b } {\n    a [ [ 1 prim + ] [ call ] call ]\n    call b prim - } ;"
  match elaboratePipeline pipelineContext innerSource agentConfig with
  | .failure [envelope] =>
      let emitted := encode envelope
      expectValidCode "inner unknown effect" "firth.elaboration.untracked-local" emitted
      unless emitted.contains "used after `call` on line 3 ran a quotation" do
        fail s!"an untracked local did not name the inner call: {emitted}"
  | _ => fail "inner-unknown-effect result was not singular"

  -- The same quotation bound to a local and run from it, once and through a
  -- copy made for a second use: the local keeps where its body lost track,
  -- so the message still names the inner `call` on line 3, not the `call`
  -- that runs the local on line 5.
  for (label, use) in [("bound", "q call"), ("copied", "q q drop call")] do
    let source := s!": g (forall ρ; ρ a:Int^many b:Int^many -- ρ r:Int^many)\n  locals \{ a b } \{\n    a [ [ 1 prim + ] [ call ] call ]\n    locals \{ q } \{\n      {use} b prim - } } ;"
    match elaboratePipeline pipelineContext source agentConfig with
    | .failure [envelope] =>
        let emitted := encode envelope
        expectValidCode s!"{label} unknown effect" "firth.elaboration.untracked-local" emitted
        unless emitted.contains "used after `call` on line 3 ran a quotation" do
          fail s!"{label}: an untracked local did not name the inner call: {emitted}"
    | _ => fail s!"{label}: unknown-effect result was not singular"

  -- A word typed `ρ -- ρ2` may leave a stack of any depth, so a branch
  -- running it has no exact effect and erasure does not refuse the `if`;
  -- the type checker accepts this program, as it did before the refusal.
  let rowSource := ": w (forall ρ ρ2; ρ -- ρ2) w ;\n: main (forall ρ; ρ -- ρ r:Int^many) true [ w ] [ 1 ] if ;"
  match elaboratePipeline pipelineContext rowSource agentConfig with
  | .success _ => pure ()
  | .failure envelopes =>
      fail s!"a branch running a row-changing word was refused: {envelopes.map encode}"
  -- The same through a quotation that calls one, and through `compose`:
  -- both are accepted outright, as on main.
  for (label, body) in [("nested", "true [ [ w ] call ] [ 1 ] if"),
      ("composed", "true [ w ] [ ] compose [ 1 ] if")] do
    let source := s!": w (forall ρ ρ2; ρ -- ρ2) w ;\n: main (forall ρ; ρ -- ρ r:Int^many) {body} ;"
    match elaboratePipeline pipelineContext source agentConfig with
    | .success _ => pure ()
    | .failure envelopes =>
        fail s!"{label}: a branch running a row-changing word was refused: {envelopes.map encode}"

  -- A name that is not in the stack effect keeps the general hint, which
  -- now also mentions `locals`.
  match elaboratePipeline pipelineContext ": double (forall ρ; ρ n:Int^many -- ρ r:Int^many) 2 prim * dobule ;" with
  | .failure [envelope] =>
      let emitted := encode envelope
      if !emitted.contains "stack effect" && emitted.contains "bind it as a local with `locals" then pure ()
      else fail s!"a misspelt word got the stack-effect hint: {emitted}"
  | _ => fail "misspelt-word result was not singular"

  -- Every hint that lists primitives lists all of them. The expected names
  -- are written out here, not read from `languagePrimitives`, so a hint
  -- that falls behind the language fails.
  let everyPrimitive := ["+", "-", "*", "<", "=", "<=", ">", ">=", "div", "mod", "and", "or", "not",
    "seq-int.empty", "seq-int.len", "seq-int.at", "seq-int.push", "seq-int.set",
    "seq-bool.empty", "seq-bool.len", "seq-bool.at", "seq-bool.push", "seq-bool.set", "send"]
  -- The list is the checker's: each name has a signature in the agent Gamma,
  -- which refuses a name that is not a primitive.
  for name in everyPrimitive do
    if (Elaborate.gammaTyping.primitive name).isNone || (Elaborate.gammaErasure.primitive name).isNone then
      fail s!"`prim {name}` is listed but the agent Gamma has no signature for it"
  if (Elaborate.gammaTyping.primitive "nope").isSome then
    fail "the agent Gamma gave `prim nope` a signature"
  if (Elaborate.gammaErasure.primitive "nope").isSome then
    fail "the agent erasure Gamma gave `prim nope` a signature"
  -- The World primitives come from `worldPrimitiveSchemes` alone. Their
  -- signatures are written out here, not read from that table, so a scheme
  -- that drifts, or an erasure signature that disagrees with its typing,
  -- fails.
  expectEqual "world primitives" worldPrimitives ["send"]
  let row : Firth.Elaborator.StackEffect.AStack := .row (.rigid "ρ")
  expectEqual "send typing" (Elaborate.gammaTyping.primitive "send")
    (some { rowVariables := ["ρ"]
            input := .snoc (.snoc (.snoc row (.base "World" .linear))
              (.base "Handle" .linear)) (.base "Bytes" .linear)
            output := .snoc row (.base "World" .linear) })
  expectEqual "send erasure" (Elaborate.gammaErasure.primitive "send")
    (some { input := [.linear, .linear, .linear], output := [.linear] })
  let listsEvery (label emitted : String) : IO Unit := do
    for name in everyPrimitive do
      unless emitted.contains s!"`prim {name}`" do
        fail s!"the {label} hint leaves out `prim {name}`: {emitted}"
  match elaboratePipeline pipelineContext ": bad ( -- ) prim nope ;" with
  | .failure [envelope] => listsEvery "unresolved-effect" (encode envelope)
  | _ => fail "unresolved-effect result was not singular"
  match elaboratePipeline pipelineContext ": bad ( -- ) missing ;" with
  | .failure [envelope] => listsEvery "unresolved-name" (encode envelope)
  | _ => fail "unresolved-name result was not singular"
  -- The checker's own unknown-word and unknown-primitive hints, for a
  -- diagnostic the type checker reports itself rather than the resolver.
  let unknownWord : Firth.Elaborator.StackEffect.Diagnostic := {
    code := "firth.name.unknown-word", primary := span 1 14 21, state := .empty
    subject := some "missing", word := some "bad" }
  listsEvery "unknown-word" (encodeStackEffectDiagnostic (context "unknown-word") unknownWord)
  let unknownPrimitive : Firth.Elaborator.StackEffect.Diagnostic := {
    code := "firth.name.unknown-primitive", primary := span 1 14 23, state := .empty
    subject := some "prim nope", word := some "bad" }
  listsEvery "unknown-primitive"
    (encodeStackEffectDiagnostic (context "unknown-primitive") unknownPrimitive)
  if languagePrimitives.length != everyPrimitive.length then
    fail s!"the language has {languagePrimitives.length} primitives but this test lists {everyPrimitive.length}; add the new ones above"
  runCallAccountTests
  runPrimitiveRolesTests
  runEveryErrorTests
  runSyntaxMessageTests
  runAssumesTests

end Firth.Agent.Test
