import compiler.Firth.LoweringFacts

/-! Planted faults for `compileWords_ok` in `LoweringFacts.lean`.

`agrees` evaluates the theorem's conclusion on a concrete dictionary: each
entry, in order, carries its word's mapped target name and the lowering of
its body. The real `compileWords` passes it. Each `#guard_msgs` block plants a
wrong image (entries out of order, a word published under its unmangled source
name, a body lowered under a different name map) and fails the build unless
`#guard` rejects it, so the property the theorem states holds of the real
image and fails for each wrong one. -/

namespace Firth.Compiler.LoweringMutants
open Firth.Compiler Firth.Compiler.Lowering

def intScheme : WordType.Scheme :=
  { rowVariables := [], input := .mk none [], output := .mk none [.base "Int" .many] }

def oneWord : CheckedWord :=
  { name := "one-word", scheme := intScheme, program := .cons (.lit (.int 1)) .empty }

def twoWord : CheckedWord :=
  { name := "two", scheme := intScheme, program := .cons (.word "one-word") .empty }

def dictionary : List CheckedWord := [oneWord, twoWord]

def sameCode (left right : List Target.Instruction) : Bool :=
  (Target.canonicalCode left).data == (Target.canonicalCode right).data

/-- `compileWords_ok`'s conclusion, evaluated. -/
def agrees (words : List CheckedWord) (entries : List Target.WordEntry) : Bool :=
  match nameMap words with
  | .error _ => false
  | .ok mapping =>
      words.length == entries.length && (words.zip entries).all fun (word, entry) =>
        mapping.find? (fun e => e.1 == word.name) == some (word.name, entry.name) &&
        match lowerProgram { word := word.name, words := mapping } word.program with
        | .ok code => sameCode code entry.code
        | .error _ => false

def compiled : List Target.WordEntry :=
  match compileWords dictionary with
  | .ok entries => entries
  | .error e => panic! s!"compileWords dictionary failed: {e.code} in {e.word}: {e.message}"

-- The real compiler: two entries, the second calling the first by its mangled name.
#guard compiled.length == 2
#guard compiled.map (·.name) == ["one_hword", "two"]
#guard agrees dictionary compiled

-- Entries out of order.
/--
error: Expression
  agrees dictionary compiled.reverse
did not evaluate to `true`
-/
#guard_msgs in
#guard agrees dictionary compiled.reverse

-- A word published under its source name rather than its mangled one.
def unmangled : List Target.WordEntry :=
  compiled.map fun entry =>
    { entry with name := if entry.name == "one_hword" then "one-word" else entry.name }

/--
error: Expression
  agrees dictionary unmangled
did not evaluate to `true`
-/
#guard_msgs in
#guard agrees dictionary unmangled

-- The caller lowered against an unmangled name map, so its `CALL_WORD` names a
-- word the image does not publish.
def wrongCall : List Target.WordEntry :=
  compiled.map fun entry =>
    if entry.name == "two" then { entry with code := [.callWord "one-word"] } else entry

/--
error: Expression
  agrees dictionary wrongCall
did not evaluate to `true`
-/
#guard_msgs in
#guard agrees dictionary wrongCall

end Firth.Compiler.LoweringMutants
