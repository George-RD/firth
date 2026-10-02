import compiler.Firth.TargetSemantics

/-! Examples for `TargetSemantics.lean`, with expected results worked out by
hand from `src/runtime/vm/target-spec.md` §4 and §5, not from the code under
test. Each one fails the build if the semantics disagrees.

Costs are written `total/kernel`: one unit per instruction and per word entry,
kernel cost 0 for `PUSH_CAPTURE` and word entries. -/

namespace Firth.Compiler.TargetSemanticsExamples
open Firth.Compiler.Target Firth.Compiler.TargetSemantics

def render : Value → String
  | .int value => toString value
  | .bool value => toString value
  | .world => "world"
  | .quotation .. => "quotation"
  | .primitiveValue tag bytes => s!"primitive{tag}:{bytes.size}"
  | .bytes bytes => s!"bytes:{bytes.size}"

/-- A run's result: status, stack bottom to top, cost `total/kernel`. -/
def summary : Outcome → String
  | .halted stack machine =>
      s!"halted {stack.reverse.map render} {machine.cost.total}/{machine.cost.kernel}"
  | .trapped trap machine =>
      s!"{trap.code}{if trap.subcode.isEmpty then "" else "/" ++ trap.subcode} " ++
        s!"{machine.stack.reverse.map render} {machine.cost.total}/{machine.cost.kernel}"
  | .outOfBound _ => "out-of-bound"

def word (name : String) (code : List Instruction) : WordEntry :=
  { name, erasedWordType := "", code, kernelEvidenceDigest := .empty,
    refinementEvidenceDigest := .empty, generation := 0 }

/-- Runs `code` as the word `main` beside `words`, on `stack` (bottom to top). -/
def runMain (code : List Instruction) (stack : List Value := []) (fuel : Nat := 100000)
    (words : List WordEntry := []) : String :=
  summary (execute (word "main" code :: words) "main" stack.reverse fuel)

-- `2 3 +`: three instructions.
#guard runMain [.pushLiteral (.int 2), .pushLiteral (.int 3), .prim "addInt"] == "halted [5] 3/3"

-- Out of fuel before the third instruction: it is not charged.
#guard runMain [.pushLiteral (.int 2), .pushLiteral (.int 3), .prim "addInt"] (fuel := 2) ==
  "fuel-exhausted [2, 3] 2/2"

-- A failed validation is not charged.
#guard runMain [.drop] == "stack-fault [] 0/0"
#guard runMain [.pushLiteral (.int 1), .call] == "type-fault [1] 1/1"

-- A primitive fault after validation keeps its charge and leaves the operands.
#guard runMain [.pushLiteral (.int (2 ^ 62)), .dup, .prim "addInt"] ==
  "primitive-fault [4611686018427387904, 4611686018427387904] 3/3"
#guard runMain [.pushLiteral (.int 7), .pushLiteral (.int 0), .prim "divInt"] ==
  "primitive-fault [7, 0] 3/3"

-- An unknown word is charged as an instruction but not as an entry.
#guard runMain [.callWord "absent"] == "unknown-word [] 1/1"

-- `1 2 [10 +] dip`: the quotation runs below the protected 2.
#guard runMain [.pushLiteral (.int 1), .pushLiteral (.int 2),
    .pushQuote [.pushLiteral (.int 10), .prim "addInt"] [] [], .dip] == "halted [11, 2] 6/6"

-- `7 quote call`: the capture is pushed back at kernel cost 0.
#guard runMain [.pushLiteral (.int 7), .quote, .call] == "halted [7] 4/3"

-- `1 quote 2 quote compose call`: the right half's capture index is rebased.
#guard runMain [.pushLiteral (.int 1), .quote, .pushLiteral (.int 2), .quote, .compose, .call] ==
  "halted [1, 2] 8/6"

-- `true [1] [2] if` and `false [1] [2] if`.
#guard runMain [.pushLiteral (.bool true), .pushQuote [.pushLiteral (.int 1)] [] [],
    .pushQuote [.pushLiteral (.int 2)] [] [], .ifThenElse] == "halted [1] 5/5"
#guard runMain [.pushLiteral (.bool false), .pushQuote [.pushLiteral (.int 1)] [] [],
    .pushQuote [.pushLiteral (.int 2)] [] [], .ifThenElse] == "halted [2] 5/5"

-- Sequences: `seq-int.empty 5 push 0 at`, and an index past the end.
#guard runMain [.prim "intSeqEmpty", .pushLiteral (.int 5), .prim "intSeqPush",
    .pushLiteral (.int 0), .prim "intSeqAt"] == "halted [5] 5/5"
#guard runMain [.prim "intSeqEmpty", .pushLiteral (.int 0), .prim "intSeqAt"] ==
  "primitive-fault [primitive2:0, 0] 3/3"

-- A `World` threaded through `quote call` is moved, not copied, and is
-- removed from the reported stack.
#guard runMain [.quote, .call] (stack := [.world]) == "halted [] 3/2"
-- Duplicating the quotation that owns it is a resource fault, not charged.
#guard runMain [.quote, .dup] (stack := [.world]) == "resource-fault [quotation] 1/1"
-- A linear value left at the end is a resource fault.
#guard runMain [.quote] (stack := [.world]) == "resource-fault [quotation] 1/1"

/-- `down ( n -- )`: `dup 0 = [drop] [1 - down] if`. Both the `if` and the
recursive call are last in their code, so they are tail transfers. -/
def down : WordEntry :=
  word "down" [.dup, .pushLiteral (.int 0), .prim "eqInt", .pushQuote [.drop] [] [],
    .pushQuote [.pushLiteral (.int 1), .prim "subInt", .callWord "down"] [] [], .ifThenElse]

-- Each of 1000 rounds runs 6 + 3 instructions and one entry (10/9), the last
-- runs 6 + 1 (7/7), and the frame stack never grows, so the depth bound of
-- 256 is never reached.
#guard summary (execute [down] "down" [.int 1000] 100000) == "halted [] 10007/9007"
-- Fuel counts instructions only: 9007 are needed.
#guard summary (execute [down] "down" [.int 1000] 9007) == "halted [] 10007/9007"
#guard (summary (execute [down] "down" [.int 1000] 9006)).startsWith "fuel-exhausted"

/-- `deep ( n -- n )`: `dup 0 = [drop 0] [1 - deep 1 +] if`. The recursive
call is not last, so every level keeps a frame. -/
def deep : WordEntry :=
  word "deep" [.dup, .pushLiteral (.int 0), .prim "eqInt",
    .pushQuote [.drop, .pushLiteral (.int 0)] [] [],
    .pushQuote [.pushLiteral (.int 1), .prim "subInt", .callWord "deep",
      .pushLiteral (.int 1), .prim "addInt"] [] [], .ifThenElse]

-- Level k runs with k + 1 frames live and enters another only while n - k > 0,
-- so the bound of 256 frames admits n = 255 and refuses n = 256. A level that
-- recurses costs 6 + 3 instructions and one entry (10/9) and, on return,
-- `1 +` (2/2); the base level costs 6 + 2 (8/8). For n = 255 that is
-- 255 * 12 + 8 = 3068 in total and 255 * 11 + 8 = 2813 kernel.
#guard summary (execute [deep] "deep" [.int 255] 100000) == "halted [255] 3068/2813"
-- For n = 256, levels 0 to 254 enter (2550/2295) and level 255 is charged its
-- nine instructions but not the entry it is refused, with `0` on the stack.
#guard summary (execute [deep] "deep" [.int 256] 100000) ==
  "resource-fault/call-depth-exceeded [0] 2559/2304"

end Firth.Compiler.TargetSemanticsExamples
