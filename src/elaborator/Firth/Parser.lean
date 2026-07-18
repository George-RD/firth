namespace Firth.Elaborator

structure Position where
  offset : Nat
  line : Nat
  column : Nat
  deriving Repr, BEq, Nonempty

structure Span where
  start : Position
  stop : Position
  deriving Repr, BEq, Nonempty

inductive Severity where | error | warning | info | hint
  deriving Repr, BEq

structure Diagnostic where
  code : String
  severity : Severity
  messageKey : String
  messageParams : List (String × String)
  location : Span
  deriving Repr, BEq

structure DiagnosticEnvelope where
  schemaVersion : String := "1.0"
  payloadKind : String := "diagnostic"
  payloadId : String
  requestId : String
  body : Diagnostic
  deriving Repr, BEq

inductive Literal where
  | integer (value : Int)
  | boolean (value : Bool)
  | character (value : Char)
  | string (value : String)
  deriving Repr, BEq

structure Located (α : Type) where
  span : Span
  value : α
  deriving Repr, BEq

structure Refinement where
  span : Span
  tokens : List String
  deriving Repr, BEq

structure TypeExpr where
  name : String
  usage : String := "many"
  refinements : List Refinement := []
  span : Span
  deriving Repr, BEq

inductive StackItem where
  | row (name : String) (span : Span)
  | value (name : String) (type : TypeExpr) (span : Span)
  deriving Repr, BEq

structure StackEffect where
  rows : List String
  input : List StackItem
  output : List StackItem
  span : Span
  deriving Repr, BEq

structure LocatedName where
  name : String
  span : Span
  deriving Repr, BEq

inductive Item where
    | literal (literal : Located Literal) (span : Span)
    | word (name : String) (span : Span)
    | atom (name : String) (span : Span)
    | primitive (name : String) (span : Span)
    | quotation (items : List Item) (span : Span)
    | locals (names : List LocatedName) (items : List Item) (span : Span)
  deriving Repr, BEq, Nonempty

structure UseDecl where
  name : String
  alias : Option String
  span : Span
  deriving Repr, BEq

structure WordDefinition where
  name : String
  effect : StackEffect
  body : List Item
  span : Span
  deriving Repr, BEq

inductive Declaration where
  | use (decl : UseDecl)
  | word (decl : WordDefinition)
  | vocabulary (name : String) (declarations : List Declaration) (span : Span)
  deriving Repr, BEq

structure SourceFile where
  declarations : List Declaration
  span : Span
  deriving Repr, BEq

inductive TokenKind where
  | identifier (text : String)
  | integer (text : String)
  | character (value : Char)
  | string (value : String)
  | symbol (text : String)
  deriving Repr, BEq

structure Token where
  kind : TokenKind
  span : Span
  deriving Repr, BEq

inductive ParseOutput where
  | success (file : SourceFile)
  | failure (diagnostics : List DiagnosticEnvelope)
  deriving Repr, BEq

private structure LexState where
  chars : List Char
  position : Position

private def advance (p : Position) (c : Char) : Position :=
  if c = '\n' then { offset := p.offset + 1, line := p.line + 1, column := 1 }
  else { offset := p.offset + 1, line := p.line, column := p.column + 1 }

private def span (a b : Position) : Span := { start := a, stop := b }

private def isLetter (c : Char) : Bool := c.isAlpha || c = 'ρ'
private def isDigit (c : Char) : Bool := c.isDigit
private def isNameChar (c : Char) : Bool := isLetter c || isDigit c || c = '-' || c = '?' || c = '!' || c = '.'

private def diag (code key : String) (s : Span) (params : List (String × String) := []) : Diagnostic :=
  { code := code, severity := .error, messageKey := key, messageParams := params, location := s }

private partial def lexError (code key : String) (s : Span) : ParseOutput :=
  .failure [{ payloadId := "parse-1", requestId := "parse", body := diag code key s }]

private def charsToString (cs : List Char) : String := String.ofList cs.reverse

private partial def readWhile (pred : Char → Bool) (st : LexState) (acc : List Char) : List Char × LexState :=
  match st.chars with
  | c :: rest => if pred c then readWhile pred { chars := rest, position := advance st.position c } (c :: acc) else (acc, st)
  | [] => (acc, st)
termination_by st.chars.length

private partial def readString (st : LexState) (acc : List Char) : Except Span (String × LexState) :=
  match st.chars with
  | [] => .error (span st.position st.position)
  | '"' :: rest => .ok (charsToString acc, { chars := rest, position := advance st.position '"' })
  | '\\' :: rest =>
      match rest with
      | [] => .error (span st.position st.position)
      | c :: more =>
          let escaped := match c with | '\\' => '\\' | '"' => '"' | 'n' => '\n' | 'r' => '\r' | 't' => '\t' | _ => c
          if c ≠ '\\' && c ≠ '"' && c ≠ 'n' && c ≠ 'r' && c ≠ 't' then .error (span st.position (advance (advance st.position '\\') c))
          else readString { chars := more, position := advance (advance st.position '\\') c } (escaped :: acc)
  | c :: rest => readString { chars := rest, position := advance st.position c } (c :: acc)
termination_by st.chars.length

private def readChar (st : LexState) : Except Span (Char × LexState) :=
  match st.chars with
  | [] => .error (span st.position st.position)
  | '\\' :: c :: rest =>
      let value := match c with | '\\' => '\\' | 'n' => '\n' | 'r' => '\r' | 't' => '\t' | _ => c
      if c ≠ '\\' && c ≠ 'n' && c ≠ 'r' && c ≠ 't' then .error (span st.position (advance (advance st.position '\\') c))
      else match rest with | '\'' :: tail => .ok (value, { chars := tail, position := advance (advance (advance st.position '\\') c) '\'' }) | _ => .error (span st.position st.position)
  | c :: '\'' :: rest => .ok (c, { chars := rest, position := advance (advance st.position c) '\'' })
  | _ => .error (span st.position st.position)

private partial def lex (st : LexState) (acc : List Token) : Except Span (List Token) :=
  match st.chars with
  | [] => .ok acc.reverse
  | c :: rest =>
      if c = ' ' || c = '\t' || c = '\n' || c = '\r' then lex { chars := rest, position := advance st.position c } acc
      else if c = '\\' then
        lex { chars := rest.dropWhile (· ≠ '\n'), position := advance st.position c } acc
      else if c = '(' && rest.head? = some '*' then
        let rec block (xs : List Char) (p : Position) : Except Span LexState :=
          match xs with
          | [] => .error (span st.position p)
          | '*' :: ')' :: tail => .ok { chars := tail, position := advance (advance p '*') ')' }
          | x :: tail => block tail (advance p x)
        match rest with
        | _ :: tail => match block tail (advance (advance st.position '(') '*') with | .error e => .error e | .ok next => lex next acc
        | [] => .error (span st.position st.position)
      else if c = '"' then
        match readString { chars := rest, position := advance st.position c } [] with
        | .error e => .error e
        | .ok (v, next) => lex next ({ kind := .string v, span := span st.position next.position } :: acc)
      else if c = '\'' then
        match readChar { chars := rest, position := advance st.position c } with
        | .error e => .error e
        | .ok (v, next) => lex next ({ kind := .character v, span := span st.position next.position } :: acc)
      else if isDigit c || (c = '-' && rest.head?.any isDigit) then
        let (cs, next) := readWhile isDigit { chars := if c = '-' then rest else c :: rest, position := if c = '-' then advance st.position c else st.position } []
        let text := (if c = '-' then "-" else "") ++ charsToString cs
        lex next ({ kind := .integer text, span := span st.position next.position } :: acc)
      else if isLetter c then
        let (cs, next) := readWhile isNameChar st []
        lex next ({ kind := .identifier (charsToString cs), span := span st.position next.position } :: acc)
      else if c = '-' && rest.head? = some '-' then
        match rest with
        | _ :: tail =>
            let next := { chars := tail, position := advance (advance st.position '-') '-' }
            lex next ({ kind := .symbol "--", span := span st.position next.position } :: acc)
        | [] => .error (span st.position st.position)
      else if "{}[]();,:^-".contains c then
        let next := { chars := rest, position := advance st.position c }
        lex next ({ kind := .symbol (String.singleton c), span := span st.position next.position } :: acc)
      else .error (span st.position (advance st.position c))
termination_by st.chars.length

private structure Parser where
  tokens : Array Token
  index : Nat
  deriving Nonempty

private def current (p : Parser) : Option Token := p.tokens[p.index]?
private def bump (p : Parser) : Parser := { p with index := p.index + 1 }
private def tokenText : TokenKind → Option String
  | .identifier s | .integer s | .symbol s => some s
  | _ => none
private def isSymbol (s : String) : Token → Bool := fun t => t.kind == .symbol s
private def expected {α : Type} (p : Parser) (what : String) : Except Diagnostic α :=
  match current p with | some t => .error (diag "firth.syntax.unexpected-token" "diagnostic.unexpected_token" t.span [("expected", what)]) | none => .error (diag "firth.syntax.unexpected-eof" "diagnostic.unexpected_eof" (match p.tokens[p.tokens.size - 1]? with | some t => t.span | none => { start := { offset := 0, line := 1, column := 1 }, stop := { offset := 0, line := 1, column := 1 } }))

private def takeSymbol (p : Parser) (s : String) : Except Diagnostic Parser :=
  match current p with | some t => if isSymbol s t then .ok (bump p) else expected p s | none => expected p s

private def takeIdent (p : Parser) : Except Diagnostic (String × Span × Parser) :=
  match current p with
  | some t =>
      match t.kind with
      | .identifier s => .ok (s, t.span, bump p)
      | _ => .error (diag "firth.syntax.expected-name" "diagnostic.expected_name" t.span)
  | none => .error (diag "firth.syntax.unexpected-eof" "diagnostic.unexpected_eof" (match p.tokens[p.tokens.size - 1]? with | some t => t.span | none => { start := { offset := 0, line := 1, column := 1 }, stop := { offset := 0, line := 1, column := 1 } }))

private def literalOf : TokenKind → Option Literal
  | .integer s => s.toInt?.map Literal.integer
  | .string s => some (.string s)
  | .character c => some (.character c)
  | .identifier "true" => some (.boolean true)
  | .identifier "false" => some (.boolean false)
  | _ => none

mutual
private partial def parseItems (p : Parser) (closing : String) : Except Diagnostic (List Item × Parser) :=
  match current p with
  | none => .error (diag "firth.syntax.unexpected-eof" "diagnostic.unexpected_eof" (match p.tokens[p.tokens.size - 1]? with | some t => t.span | none => { start := { offset := 0, line := 1, column := 1 }, stop := { offset := 0, line := 1, column := 1 } }))
  | some t => if isSymbol closing t then .ok ([], bump p) else
      match parseItem p with | .error e => .error e | .ok (item, next) => match parseItems next closing with | .error e => .error e | .ok (items, finished) => .ok (item :: items, finished)

private partial def parseItem (p : Parser) : Except Diagnostic (Item × Parser) :=
  match current p with
  | some t =>
      match literalOf t.kind with
      | some lit => .ok ((.literal { span := t.span, value := lit } t.span), bump p)
      | none => match t.kind with
        | .symbol "[" => match parseItems (bump p) "]" with | .error e => .error e | .ok (xs, next) => let stop := match current next with | some x => x.span.stop | none => t.span.stop; .ok ((.quotation xs { start := t.span.start, stop }), next)
        | .identifier "prim" => match takeIdent (bump p) with | .error e => .error e | .ok (name, ns, next) => .ok ((.primitive name { start := t.span.start, stop := ns.stop }), next)
        | .identifier "locals" => parseLocals p t
        | .identifier name => if ["dup","drop","swap","dip","call","compose","quote","if"].contains name then .ok ((.atom name t.span), bump p) else .ok ((.word name t.span), bump p)
        | _ => .error (diag "firth.syntax.invalid-item" "diagnostic.invalid_item" t.span)
  | none => .error (diag "firth.syntax.unexpected-eof" "diagnostic.unexpected_eof" { start := { offset := 0, line := 1, column := 1 }, stop := { offset := 0, line := 1, column := 1 } })

private partial def parseLocals (p : Parser) (start : Token) : Except Diagnostic (Item × Parser) :=
  match takeSymbol (bump p) "{" with
  | .error e => .error e
  | .ok p1 =>
      let rec names (q : Parser) (acc : List LocatedName) : Except Diagnostic (List LocatedName × Parser) :=
        match current q with
        | some t =>
            if isSymbol "}" t then .ok (acc.reverse, bump q)
            else match takeIdent q with
              | .error e => .error e
              | .ok (n, s, r) => names r ({ name := n, span := s } :: acc)
        | none => expected q "}"
      match names p1 [] with
      | .error e => .error e
      | .ok (ns, p2) =>
          match takeSymbol p2 "{" with
          | .error e => .error e
          | .ok p3 =>
              match parseItems p3 "}" with
              | .error e => .error e
              | .ok (xs, p4) =>
                  let stop := match current p4 with | some x => x.span.stop | none => start.span.stop
                  .ok ((.locals ns xs { start := start.span.start, stop }), p4)
end
private def parseStackEffect (p : Parser) : Except Diagnostic (StackEffect × Parser) :=
  match current p with
  | some opening => if isSymbol "(" opening then
      let rec collect (fuel : Nat) (q : Parser) (acc : List Token) : Except Diagnostic (List Token × Parser) :=
        match fuel with
        | 0 => expected q ")"
        | fuel + 1 =>
            match current q with
            | some t => if isSymbol ")" t then .ok (acc.reverse, bump q) else collect fuel (bump q) (t :: acc)
            | none => expected q ")"
      match collect (p.tokens.size + 1) (bump p) [] with
      | .error e => .error e
      | .ok (ts, next) =>
          let words := (ts.map (fun t => tokenText t.kind)).filterMap id
          let cut := words.findIdx? (· = "--")
          match cut with
          | none => .error (diag "firth.syntax.missing-separator" "diagnostic.missing_stack_separator" opening.span)
          | some i =>
              let left := words.take i
              let right := words.drop (i+1)
              let rows := (left.filter (fun s => s ≠ "forall" && s ≠ ";")).filter (·.startsWith "ρ")
              let parseOne (s : String) : StackItem := .row s opening.span
              let stop := match current next with | some x => x.span.stop | none => opening.span.stop
              .ok ({ rows := rows, input := left.filterMap (fun s => if s.startsWith "ρ" then some (parseOne s) else none), output := right.filterMap (fun s => if s.startsWith "ρ" then some (parseOne s) else none), span := { start := opening.span.start, stop } }, next)
    else expected p "("
  | none => expected p "("

private partial def parseDeclarations (p : Parser) (closing : Option String) : Except Diagnostic (List Declaration × Parser) :=
  match current p with
  | none => match closing with | some c => expected p c | none => .ok ([],p)
  | some t => if closing.any (fun c => isSymbol c t) then .ok ([], bump p) else
    match t.kind with
    | .identifier "use" => match takeIdent (bump p) with
      | .error e => .error e
      | .ok (n, ns, p1) =>
          let aliasResult : Except Diagnostic (Option String × Parser) := match current p1 with
            | some a => match a.kind with
              | .identifier "as" => match takeIdent (bump p1) with | .error e => .error e | .ok (alias, _, after) => .ok (some alias, after)
              | _ => .ok (none, p1)
            | none => .ok (none, p1)
          match aliasResult with
          | .error e => .error e
          | .ok (alias, p2) => match takeSymbol p2 ";" with
            | .error e => .error e
            | .ok p3 => parseDeclarations p3 closing |>.map (fun (ds,r) => (.use { name := n, alias, span := { start := t.span.start, stop := ns.stop } } :: ds, r))
    | .identifier "vocab" => match takeIdent (bump p) with | .error e => .error e | .ok (n,ns,p1) => match takeSymbol p1 "{" with | .error e => .error e | .ok p2 => match parseDeclarations p2 (some "}") with | .error e => .error e | .ok (ds,p3) => parseDeclarations p3 closing |>.map (fun (outer,r) => (.vocabulary n ds { start := t.span.start, stop := ns.stop } :: outer, r))
    | .symbol ":" => match takeIdent (bump p) with | .error e => .error e | .ok (n,ns,p1) => match parseStackEffect p1 with | .error e => .error e | .ok (effect,p2) => match parseItems p2 ";" with | .error e => .error e | .ok (body,p3) => parseDeclarations p3 closing |>.map (fun (ds,r) => (.word { name := n, effect, body, span := { start := t.span.start, stop := ns.stop } } :: ds, r))
    | _ => .error (diag "firth.syntax.invalid-declaration" "diagnostic.invalid_declaration" t.span)

def parse (source : String) (requestId : String := "parse") : ParseOutput :=
  let initial : Position := { offset := 0, line := 1, column := 1 }
  match lex { chars := source.toList, position := initial } [] with
  | .error s => .failure [{ payloadId := "parse-1", requestId, body := diag "firth.syntax.invalid-token" "diagnostic.invalid_token" s }]
  | .ok tokens =>
      let p : Parser := { tokens := tokens.toArray, index := 0 }
      match parseDeclarations p none with
      | .error d => .failure [{ payloadId := "parse-1", requestId, body := d }]
      | .ok (declarations, rest) => if current rest |>.isSome then .failure [{ payloadId := "parse-1", requestId, body := diag "firth.syntax.trailing-input" "diagnostic.trailing_input" (match current rest with | some t => t.span | none => { start := initial, stop := initial }) }] else
          let finalStop := (tokens.getLast?.map (·.span.stop)).getD initial
          .success { declarations, span := { start := initial, stop := finalStop } }

end Firth.Elaborator
