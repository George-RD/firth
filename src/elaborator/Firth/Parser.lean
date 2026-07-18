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

inductive ParseCause where
  | lexical | grammar | delimiter | validation
  deriving Repr, BEq

structure ParseError where
  code : String
  primary : Span
  expected : Option String := none
  actual : Option String := none
  cause : ParseCause := .grammar
  deriving Repr, BEq

structure Located (α : Type) where
  span : Span
  value : α
  deriving Repr, BEq

inductive Literal where
  | integer (value : Int)
  | boolean (value : Bool)
  | character (value : Char)
  | string (value : String)
  deriving Repr, BEq

inductive Usage where
  | many | linear
  deriving Repr, BEq

structure Refinement where
  span : Span
  tokens : List String
  deriving Repr, BEq

structure TypeExpr where
  name : String
  usage : Usage := .many
  refinements : List Refinement := []
  span : Span
  deriving Repr, BEq

structure LocatedName where
  name : String
  span : Span
  deriving Repr, BEq

inductive StackItem where
  | row (name : String) (span : Span)
  | value (name : String) (type : TypeExpr) (span : Span)
  deriving Repr, BEq

structure StackEffect where
  rowBinders : List LocatedName
  rows : List String
  input : List StackItem
  output : List StackItem
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
  deriving Repr, BEq, Inhabited

structure Token where
  kind : TokenKind
  span : Span
  deriving Repr, BEq

inductive ParseOutput where
  | success (file : SourceFile)
  | failure (errors : List ParseError)
  deriving Repr, BEq

private structure LexState where
  chars : List Char
  position : Position

private structure LexResult where
  tokens : List Token
  endPosition : Position
  deriving Nonempty

private def advance (p : Position) (c : Char) : Position :=
  if c = '\n' then { offset := p.offset + 1, line := p.line + 1, column := 1 }
  else { offset := p.offset + 1, line := p.line, column := p.column + 1 }

private def mkSpan (a b : Position) : Span := { start := a, stop := b }
private def startPos : Position := { offset := 0, line := 1, column := 1 }
private def eofSpan (p : Position) : Span := mkSpan p p
private instance : Inhabited Position := ⟨startPos⟩
private instance : Inhabited Span := ⟨eofSpan startPos⟩
private instance : Inhabited Token := ⟨{ kind := .symbol "", span := eofSpan startPos }⟩

private def err (code : String) (s : Span) (cause := ParseCause.grammar)
    (expected actual : Option String := none) : ParseError :=
  { code, primary := s, expected, actual, cause }

private def charsToString (cs : List Char) : String := String.ofList cs.reverse
private def isLetter (c : Char) : Bool := c.isAlpha || c = 'ρ'
private def isDigit (c : Char) : Bool := c.isDigit
private def isNameChar (c : Char) : Bool := isLetter c || isDigit c || c = '-' || c = '?' || c = '!' || c = '.'
private def isWordName (s : String) : Bool :=
  let cs := s.toList
  match cs with
  | [] => false
  | c :: rest => isLetter c && rest.all (fun x => isLetter x || isDigit x || x = '-' || x = '?' || x = '!')
private def isQualifiedName (s : String) : Bool :=
  s.splitOn "." |>.all isWordName
private def isRowName (s : String) : Bool :=
  match s.toList with
  | 'ρ' :: rest => rest.all (fun c => isLetter c || isDigit c || c = '-')
  | _ => false
private def reserved (s : String) : Bool :=
  ["true", "false", "many", "linear", "forall", "vocab", "use", "export", "locals", "prim",
   "dup", "drop", "swap", "dip", "call", "compose", "quote", "if"].contains s
private def validWordName (s : String) : Bool := isWordName s && !reserved s

private partial def readWhile (pred : Char → Bool) (st : LexState) (acc : List Char) : List Char × LexState :=
  match st.chars with
  | c :: rest => if pred c then readWhile pred { chars := rest, position := advance st.position c } (c :: acc) else (acc, st)
  | [] => (acc, st)

private partial def readString (st : LexState) (acc : List Char) : Except ParseError (String × LexState) :=
  match st.chars with
  | [] => .error (err "firth.syntax.unterminated-string" (eofSpan st.position) .delimiter)
  | '"' :: rest => .ok (charsToString acc, { chars := rest, position := advance st.position '"' })
  | '\\' :: rest =>
      match rest with
      | [] => .error (err "firth.syntax.unterminated-string" (eofSpan st.position) .delimiter)
      | c :: more =>
          if !['\\', '"', 'n', 'r', 't'].contains c then
            .error (err "firth.syntax.invalid-escape" (mkSpan st.position (advance (advance st.position '\\') c)) .validation)
          else
            let value := match c with | '\\' => '\\' | '"' => '"' | 'n' => '\n' | 'r' => '\r' | 't' => '\t' | _ => c
            readString { chars := more, position := advance (advance st.position '\\') c } (value :: acc)
  | c :: rest => readString { chars := rest, position := advance st.position c } (c :: acc)

private def readChar (st : LexState) : Except ParseError (Char × LexState) :=
  match st.chars with
  | '\\' :: c :: '\'' :: rest =>
      if !['\\', 'n', 'r', 't'].contains c then .error (err "firth.syntax.invalid-escape" (eofSpan st.position) .validation)
      else
        let value := match c with | '\\' => '\\' | 'n' => '\n' | 'r' => '\r' | 't' => '\t' | _ => c
        .ok (value, { chars := rest, position := advance (advance (advance st.position '\\') c) '\'' })
  | c :: '\'' :: rest => .ok (c, { chars := rest, position := advance (advance st.position c) '\'' })
  | _ => .error (err "firth.syntax.unterminated-character" (eofSpan st.position) .delimiter)

private partial def lex (st : LexState) (acc : List Token) : Except ParseError LexResult :=
  match st.chars with
  | [] => .ok { tokens := acc.reverse, endPosition := st.position }
  | c :: rest =>
      if " \t\n\r".contains c then lex { chars := rest, position := advance st.position c } acc
      else if c = '\\' then
        let (_, after) := readWhile (· ≠ '\n') { chars := rest, position := advance st.position c } []
        lex after acc
      else if c = '(' && rest.head? = some '*' then
        let rec block (xs : List Char) (p : Position) : Except ParseError LexState :=
          match xs with
          | [] => .error (err "firth.syntax.unterminated-comment" (mkSpan st.position p) .delimiter)
          | '*' :: ')' :: tail => .ok { chars := tail, position := advance (advance p '*') ')' }
          | x :: tail => block tail (advance p x)
        match rest with
        | _ :: tail => match block tail (advance (advance st.position '(') '*') with | .error e => .error e | .ok next => lex next acc
        | [] => .error (err "firth.syntax.unterminated-comment" (eofSpan st.position) .delimiter)
      else if c = '"' then
        match readString { chars := rest, position := advance st.position c } [] with
        | .error e => .error e
        | .ok (v, next) => lex next ({ kind := .string v, span := mkSpan st.position next.position } :: acc)
      else if c = '\'' then
        match readChar { chars := rest, position := advance st.position c } with
        | .error e => .error e
        | .ok (v, next) => lex next ({ kind := .character v, span := mkSpan st.position next.position } :: acc)
      else if isDigit c || (c = '-' && rest.head?.any isDigit) then
        let (cs, next) := readWhile isDigit { chars := if c = '-' then rest else c :: rest, position := if c = '-' then advance st.position c else st.position } []
        let text := (if c = '-' then "-" else "") ++ charsToString cs
        lex next ({ kind := .integer text, span := mkSpan st.position next.position } :: acc)
      else if isLetter c then
        let (cs, next) := readWhile isNameChar st []
        lex next ({ kind := .identifier (charsToString cs), span := mkSpan st.position next.position } :: acc)
      else if c = '-' && rest.head? = some '-' then
        lex { chars := rest.drop 1, position := advance (advance st.position '-') '-' }
          ({ kind := .symbol "--", span := mkSpan st.position (advance (advance st.position '-') '-') } :: acc)
      else if "{}[]();,:^-".contains c then
        let next := { chars := rest, position := advance st.position c }
        lex next ({ kind := .symbol (String.singleton c), span := mkSpan st.position next.position } :: acc)
      else .error (err "firth.syntax.invalid-token" (mkSpan st.position (advance st.position c)) .lexical)

private structure Parser where
  tokens : Array Token
  index : Nat
  deriving Nonempty

private def current (p : Parser) : Option Token := p.tokens[p.index]?
private def remaining (p : Parser) : Nat := p.tokens.size - p.index
private def lastStop (p : Parser) (fallback : Position) : Position :=
  ((p.tokens[p.index - 1]?).map (·.span.stop)).getD fallback
private def bump (p : Parser) : Parser := { p with index := p.index + 1 }
private def kindText : TokenKind → String
  | .identifier s | .integer s | .symbol s => s
  | .character _ => "character"
  | .string _ => "string"
private def isSymbol (s : String) (t : Token) : Bool := t.kind == .symbol s
private def expected {α : Type} (p : Parser) (what : String) : Except ParseError α :=
  match current p with
  | some t => .error (err "firth.syntax.unexpected-token" t.span .grammar (some what) (some (kindText t.kind)))
  | none => .error (err "firth.syntax.unexpected-eof" (eofSpan (((p.tokens[p.tokens.size - 1]? ).map (·.span.stop)).getD startPos)) .delimiter (some what) none)
private def takeSymbol (p : Parser) (s : String) : Except ParseError Parser :=
  match current p with | some t => if isSymbol s t then .ok (bump p) else expected p s | none => expected p s
private def takeIdent (p : Parser) : Except ParseError (String × Span × Parser) :=
  match current p with
  | some t => match t.kind with | .identifier s => .ok (s, t.span, bump p) | _ => .error (err "firth.syntax.expected-name" t.span .grammar (some "name") (some (kindText t.kind)))
  | none => expected p "name"
private def literalOf : TokenKind → Option Literal
  | .integer s => s.toInt?.map .integer
  | .string s => some (.string s)
  | .character c => some (.character c)
  | .identifier "true" => some (.boolean true)
  | .identifier "false" => some (.boolean false)
  | _ => none

private def parseName (p : Parser) (qualified : Bool) : Except ParseError (String × Span × Parser) :=
  match takeIdent p with
  | .error e => .error e
  | .ok (n, s, q) =>
      if (if qualified then isQualifiedName n else validWordName n) then .ok (n, s, q)
      else .error (err "firth.syntax.invalid-name" s .validation (some (if qualified then "qualified name" else "word name")) (some n))

private def parseRefinement (p : Parser) (opening : Token) : Except ParseError (Refinement × Parser) :=
  let rec go (fuel : Nat) (q : Parser) (acc : List String) : Except ParseError (List String × Parser × Position) :=
    if fuel = 0 then .error (err "firth.syntax.unterminated-refinement" (eofSpan opening.span.stop) .delimiter (some "}") none) else
    match current q with
    | none => .error (err "firth.syntax.unterminated-refinement" (mkSpan opening.span.start opening.span.stop) .delimiter (some "}") none)
    | some t => if isSymbol "}" t then
        if acc.isEmpty then .error (err "firth.syntax.empty-refinement" t.span .validation)
        else .ok (acc.reverse, bump q, t.span.stop)
      else if isSymbol "{" t then .error (err "firth.syntax.invalid-refinement" t.span .validation)
      else go (fuel - 1) (bump q) (kindText t.kind :: acc)
  match go (remaining p + 1) (bump p) [] with
  | .error e => .error e
  | .ok (tokens, q, stop) =>
      let rec badCommas : List String → Bool
        | [] => true
        | [","] => true
        | "," :: _ => true
        | x :: y :: rest => (x == "," && y == ",") || badCommas (y :: rest)
        | [_] => false
      let badComma := badCommas tokens
      if badComma then .error (err "firth.syntax.invalid-refinement" (eofSpan stop) .validation)
      else .ok ({ span := mkSpan opening.span.start stop, tokens }, q)

private def parseType (p : Parser) (name : String) (nameSpan : Span) : Except ParseError (TypeExpr × Parser) :=
  let parseUsage (q : Parser) : Except ParseError (Usage × Parser × Position) :=
    match current q with
    | some caret => if isSymbol "^" caret then
        match current (bump q) with
        | some t => match t.kind with
          | .identifier "many" => .ok (.many, bump (bump q), t.span.stop)
          | .identifier "linear" => .ok (.linear, bump (bump q), t.span.stop)
          | _ => .error (err "firth.syntax.invalid-usage" t.span .validation (some "many or linear") (some (kindText t.kind)))
        | none => expected (bump q) "many or linear"
      else .ok (.many, q, nameSpan.stop)
    | none => .ok (.many, q, nameSpan.stop)
  match parseUsage p with
  | .error e => .error e
  | .ok (usage, q, usageStop) =>
      let rec refs (fuel : Nat) (r : Parser) (acc : List Refinement) (stop : Position) : Except ParseError (List Refinement × Parser × Position) :=
        if fuel = 0 then .error (err "firth.syntax.invalid-refinement" (eofSpan nameSpan.stop) .validation) else
        match current r with
        | some t => if isSymbol "{" t then match parseRefinement r t with | .error e => .error e | .ok (x, after) => refs (fuel - 1) after (x :: acc) x.span.stop
                    else .ok (acc.reverse, r, stop)
        | none => .ok (acc.reverse, r, stop)
      match refs (remaining q + 1) q [] usageStop with
      | .error e => .error e
      | .ok (rs, after, stop) => .ok ({ name, usage, refinements := rs, span := mkSpan nameSpan.start stop }, after)

private def parseStackItem (p : Parser) (bound : List String) : Except ParseError (StackItem × Parser) :=
  match takeIdent p with
  | .error e => .error e
  | .ok (n, ns, q) =>
      if isRowName n then
        if bound.contains n then .ok ((.row n ns), q)
        else .error (err "firth.syntax.unbound-row" ns .validation (some "bound row") (some n))
      else if !validWordName n then .error (err "firth.syntax.invalid-stack-name" ns .validation (some "stack item") (some n))
      else match takeSymbol q ":" with
        | .error e => .error e
        | .ok afterColon =>
            match parseName afterColon true with
            | .error e => .error e
            | .ok (typeName, typeSpan, afterType) => parseType afterType typeName typeSpan |>.map (fun (ty, r) => (.value n ty (mkSpan ns.start ty.span.stop), r))

private def parseStackEffect (p : Parser) : Except ParseError (StackEffect × Parser) :=
  match current p with
  | none => expected p "("
  | some opening => if !isSymbol "(" opening then expected p "(" else
      let rec collect (fuel : Nat) (q : Parser) (acc : List Token) : Except ParseError (List Token × Parser × Token) :=
        if fuel = 0 then expected q ")" else
        match current q with
        | none => expected q ")"
        | some t => if isSymbol ")" t then .ok (acc.reverse, bump q, t) else collect (fuel - 1) (bump q) (t :: acc)
      match collect (remaining p + 1) (bump p) [] with
      | .error e => .error e
      | .ok (ts, after, closing) =>
          let sub : Parser := { tokens := ts.toArray, index := 0 }
          let rec binder (fuel : Nat) (q : Parser) (acc : List LocatedName) : Except ParseError (List LocatedName × Parser) :=
            if fuel = 0 then .error (err "firth.syntax.invalid-stack-effect" (eofSpan opening.span.stop) .validation) else
            match current q with
            | some t => if t.kind == .identifier "forall" then
                match takeIdent (bump q) with
                | .error e => .error e
                | .ok (n, s, next) => if isRowName n then if acc.any (fun binder => binder.name == n) then .error (err "firth.syntax.duplicate-row" s .validation) else binder (fuel - 1) next ({ name := n, span := s } :: acc) else .error (err "firth.syntax.invalid-row" s .validation)
              else .ok (acc.reverse, q)
            | none => .ok (acc.reverse, q)
          match binder (ts.length + 1) sub [] with
          | .error e => .error e
          | .ok (binders, q0) =>
              let q1 := if (current q0).any (fun t => t.kind == .symbol ";") then bump q0 else q0
              if (current q0).isSome && !(current q0).any (fun t => t.kind == .symbol ";") && binders.length > 0 then
                .error (err "firth.syntax.missing-forall-separator" (current q0 |>.get!).span .delimiter (some ";") none)
              else
                let rec items (fuel : Nat) (q : Parser) (bound : List String) (acc : List StackItem) : Except ParseError (List StackItem × Parser) :=
                  if fuel = 0 then .error (err "firth.syntax.invalid-stack-effect" (eofSpan opening.span.stop) .validation) else
                  match current q with
                  | none => .ok (acc.reverse, q)
                  | some t => if isSymbol "--" t then .ok (acc.reverse, bump q) else parseStackItem q bound >>= fun (item, next) => items (fuel - 1) next bound (item :: acc)
                match items (ts.length + 1) q1 (binders.map (·.name)) [] with
                | .error e => .error e
                | .ok (input, q2) =>
                    let sepCount := ts.countP (fun t => isSymbol "--" t)
                    if sepCount = 0 then .error (err "firth.syntax.missing-separator" opening.span .validation (some "--") none)
                    else if sepCount > 1 then .error (err "firth.syntax.multiple-separators" (ts.find? (isSymbol "--") |>.get!).span .validation)
                    else
                      match items (ts.length + 1) q2 (binders.map (·.name)) [] with
                      | .error e => .error e
                      | .ok (output, q3) => if (current q3).isSome then .error (err "firth.syntax.invalid-stack-effect" (current q3 |>.get!).span .validation)
                        else .ok ({ rowBinders := binders, rows := (input ++ output).filterMap (fun x => match x with | .row n _ => some n | _ => none), input, output, span := mkSpan opening.span.start closing.span.stop }, after)

mutual
private partial def parseItems (p : Parser) (closing : String) : Except ParseError (List Item × Parser × Span) :=
  match current p with
  | none => expected p closing
  | some t => if isSymbol closing t then .ok ([], bump p, t.span) else parseItem p >>= fun (item, next) => parseItems next closing |>.map (fun (items, after, close) => (item :: items, after, close))
private partial def parseItem (p : Parser) : Except ParseError (Item × Parser) :=
  match current p with
  | none => expected p "item"
  | some t => match literalOf t.kind with
    | some lit => .ok ((.literal { span := t.span, value := lit } t.span), bump p)
    | none => match t.kind with
      | .symbol "[" => parseItems (bump p) "]" |>.map (fun (xs, after, close) => (.quotation xs (mkSpan t.span.start close.stop), after))
      | .identifier "prim" => parseName (bump p) true |>.map (fun (n, s, after) => (.primitive n (mkSpan t.span.start s.stop), after))
      | .identifier "locals" => parseLocals p t
      | .identifier name => if name ∈ ["dup", "drop", "swap", "dip", "call", "compose", "quote", "if"] then .ok ((.atom name t.span), bump p) else if reserved name then .error (err "firth.syntax.invalid-item" t.span .validation) else .ok ((.word name t.span), bump p)
      | _ => .error (err "firth.syntax.invalid-item" t.span .grammar)
private partial def parseLocals (p : Parser) (start : Token) : Except ParseError (Item × Parser) :=
  takeSymbol (bump p) "{" >>= fun q =>
    let rec names (fuel : Nat) (r : Parser) (acc : List LocatedName) : Except ParseError (List LocatedName × Parser × Span) :=
      if fuel = 0 then expected r "}" else
      match current r with
      | none => expected r "}"
      | some t => if isSymbol "}" t then if acc.isEmpty then .error (err "firth.syntax.empty-locals" t.span .validation) else .ok (acc.reverse, bump r, t.span)
        else parseName r false >>= fun (n, s, after) => names (fuel - 1) after ({ name := n, span := s } :: acc)
    names (remaining q + 1) q [] >>= fun (ns, afterNames, _) =>
      takeSymbol afterNames "{" >>= fun bodyOpen =>
        parseItems bodyOpen "}" |>.map (fun (xs, after, close) => (.locals ns xs (mkSpan start.span.start close.stop), after))
end

private partial def parseDeclarations (p : Parser) (closing : Option String) : Except ParseError (List Declaration × Parser × Option Span) :=
  match current p with
  | none => match closing with | some c => expected p c | none => .ok ([], p, none)
  | some t => if closing.any (fun c => isSymbol c t) then .ok ([], bump p, some t.span) else
    match t.kind with
    | .identifier "use" => parseName (bump p) true >>= fun (n, ns, p1) =>
        (match current p1 with | some a => if a.kind == .identifier "as" then parseName (bump p1) false |>.map (fun (x, _, r) => (some x, r)) else .ok (none, p1) | none => .ok (none, p1)) >>= fun (alias, p2) =>
          takeSymbol p2 ";" >>= fun p3 => parseDeclarations p3 closing |>.map (fun (ds, r, close) => (.use { name := n, alias, span := mkSpan t.span.start (lastStop p3 ns.stop) } :: ds, r, close))
    | .identifier "vocab" => if closing.isSome then .error (err "firth.syntax.nested-vocabulary" t.span .validation)
        else parseName (bump p) false >>= fun (n, ns, p1) => takeSymbol p1 "{" >>= fun p2 => parseDeclarations p2 (some "}") >>= fun (ds, p3, close) => parseDeclarations p3 closing |>.map (fun (outer, r, outerClose) => (.vocabulary n ds (mkSpan t.span.start (close.map (·.stop) |>.getD ns.stop)) :: outer, r, outerClose))
    | .symbol ":" => parseName (bump p) false >>= fun (n, _, p1) => parseStackEffect p1 >>= fun (effect, p2) => parseItems p2 ";" >>= fun (body, p3, close) => parseDeclarations p3 closing |>.map (fun (ds, r, outerClose) => (.word { name := n, effect, body, span := mkSpan t.span.start close.stop } :: ds, r, outerClose))
    | _ => .error (err "firth.syntax.invalid-declaration" t.span .grammar)

def parse (source : String) : ParseOutput :=
  let initial := startPos
  match lex { chars := source.toList, position := initial } [] with
  | .error e => .failure [e]
  | .ok result =>
      let p : Parser := { tokens := result.tokens.toArray, index := 0 }
      match parseDeclarations p none with
      | .error e => .failure [e]
      | .ok (declarations, rest, _) => if current rest |>.isSome then .failure [err "firth.syntax.trailing-input" (current rest |>.get!).span .grammar]
        else .success { declarations, span := mkSpan initial result.endPosition }

end Firth.Elaborator
