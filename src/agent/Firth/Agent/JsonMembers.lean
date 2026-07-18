import Lean.Data.Json

namespace Firth.Agent

open Lean

inductive MemberScanError where
  | malformed
  | duplicate
  deriving Repr, BEq

private def whitespace (character : Char) : Bool :=
  character == ' ' || character == '\n' || character == '\r' || character == '\t'

private def trimLeft : List Char → List Char
  | character :: rest => if whitespace character then trimLeft rest else character :: rest
  | [] => []

private partial def scanStringBody (input reversed : List Char) :
    Except MemberScanError (String × List Char) :=
  match input with
  | [] => .error .malformed
  | '"' :: rest => .ok (String.ofList ('"' :: reversed).reverse, rest)
  | '\\' :: escaped :: rest => scanStringBody rest (escaped :: '\\' :: reversed)
  | character :: rest => scanStringBody rest (character :: reversed)

private def scanString : List Char → Except MemberScanError (String × List Char)
  | '"' :: rest => scanStringBody rest ['"']
  | _ => .error .malformed

private def decodeKey (raw : String) : Except MemberScanError String :=
  match Json.parse raw with
  | .ok (.str key) => .ok key
  | _ => .error .malformed

private def scalarDelimiter (character : Char) : Bool :=
  whitespace character || character == ',' || character == ']' || character == '}'

private def scanScalar (input : List Char) : Except MemberScanError (List Char) :=
  let (token, rest) := input.span fun character => !scalarDelimiter character
  if token.isEmpty then .error .malformed else .ok rest

mutual
  private partial def scanValue (input : List Char) : Except MemberScanError (List Char) :=
    let input := trimLeft input
    match input with
    | [] => .error .malformed
    | '{' :: rest => scanObject rest []
    | '[' :: rest => scanArray rest
    | '"' :: _ => scanString input |>.map (·.2)
    | scalar => scanScalar scalar

  private partial def scanObject (input : List Char) (seen : List String) :
      Except MemberScanError (List Char) := do
    let input := trimLeft input
    match input with
    | '}' :: rest => pure rest
    | '"' :: _ =>
        let (rawKey, afterKey) ← scanString input
        let key ← decodeKey rawKey
        if seen.contains key then throw .duplicate
        let afterColon := trimLeft afterKey
        let valueInput ← match afterColon with
          | ':' :: rest => pure rest
          | _ => throw .malformed
        let afterValue ← scanValue valueInput
        match trimLeft afterValue with
        | ',' :: rest => scanObject rest (key :: seen)
        | '}' :: rest => pure rest
        | _ => throw .malformed
    | _ => throw .malformed

  private partial def scanArray (input : List Char) : Except MemberScanError (List Char) := do
    match trimLeft input with
    | ']' :: rest => pure rest
    | valueInput =>
        let afterValue ← scanValue valueInput
        match trimLeft afterValue with
        | ',' :: rest => scanArray rest
        | ']' :: rest => pure rest
        | _ => throw .malformed
end

def rejectDuplicateMembers (source : String) : Except MemberScanError Unit := do
  let rest ← scanValue source.toList
  if (trimLeft rest).isEmpty then pure () else throw .malformed

end Firth.Agent
