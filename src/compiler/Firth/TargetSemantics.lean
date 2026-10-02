import compiler.Firth.Target

/-!
The execution semantics of the v0.1 target machine, as a Lean function.

`src/runtime/vm/target-spec.md` §4 and §5 define how an admitted image runs:
administrative frames with continuations, tail transfers, the hosted depth
bound, fuel, the cost table and the trap classes. The Rust VM implements that
text and is trusted but not proved. This file states the same machine as a
deterministic small-step function, so that a theorem can be proved about it
(the compiler simulation in `todo.compiler-vm-agreement-proof`) and the VM can
be tested against it (`lake exe firthTargetRun`).

The machine follows the VM's observable behaviour, including the order in
which it charges, validates and traps:

* An instruction first checks fuel (`fuel-exhausted`, nothing charged), then is
  charged one unit (its registry cost for `PRIM`), then validated. A
  validation failure undoes the charge, as §5 says; a failure after
  validation, such as a primitive fault or the depth bound, keeps it.
* `CALL_WORD` charges one more unit for the word entry, with kernel cost 0, and
  so does nothing else. A nested entry past the depth bound is not charged.
  `PUSH_CAPTURE` and word entries have kernel cost 0, every other charge has
  kernel cost equal to its cost.
* A `CALL`, `IF` or `CALL_WORD` that is the last instruction of a frame which
  owns no linear capture replaces that frame instead of nesting one, keeping
  its continuation (§4 "Tail transfers"). A quotation owning a linear capture
  is never a tail target.
* Entering a frame when 256 frames are live is `resource-fault` with subcode
  `call-depth-exceeded`; a tail transfer enters none.
* A frame entered by `CALL` or `DIP` must have consumed its linear captures
  when it ends; `DIP` then restores the value it protected.
* At the end, `World` markers are removed from the stack and any other linear
  value left is a `resource-fault`.

Three things the VM does are outside this file, and an image or run that
reaches them is reported as `unsupported` rather than given a meaning here:

* image admission (decoding, digests, structural bounds). The semantics starts
  from an admitted image, as `execute_report_entry` does after `validate_image`;
* `PUSH_QUOTE` of a quotation owning a linear capture, whose second execution
  the VM refuses by remembering its origin. The compiler never emits one: every
  quotation it lowers has no captures;
* the `World` primitives `makeWorld` and `consumeWorld`, which no source
  program can name (`Interpreter.surfacePrimitives`). They are unknown here.

Allocation failure, traces, residual frame rendering and image replacement are
host concerns of the VM and are not modelled.

Stacks are top-first, as in the reference interpreter.
-/

namespace Firth.Compiler.TargetSemantics

open Firth.Compiler.Target

/-! ## Ownership -/

mutual
/-- Whether a value is linear: `World`, a primitive value the registry does
not declare `many`, or a quotation owning a linear capture (§2). -/
def linearValue : Value → Bool
  | .quotation _ captures _ => linearValues captures
  | .primitiveValue tag _ => !(tag == seqIntTag || tag == seqBoolTag)
  | .world => true
  | .int _ | .bool _ | .bytes _ => false

def linearValues : List Value → Bool
  | [] => false
  | value :: rest => linearValue value || linearValues rest
end

/-- A capture still owed: linear and not yet moved out by `PUSH_CAPTURE`. -/
def owesCapture : List Value → List Bool → Bool
  | value :: values, consumed :: flags => (linearValue value && !consumed) || owesCapture values flags
  | _, _ => false

/-! ## Sequences

A `Seq Int` is eight little-endian two's-complement bytes per element and a
`Seq Bool` one byte, 0 or 1, per element (§3). The primitives below read the
elements, act on the list and write it back with `seqIntBytes` and
`seqBoolBytes`. On canonical bytes, which are the only ones an admitted image
or a primitive produces, that is the VM's in-place byte arithmetic. -/

/-- The signed value of eight little-endian bytes. -/
def int64OfBytes (bytes : List UInt8) : Int :=
  let word : Nat := bytes.foldr (fun byte acc => byte.toNat + 256 * acc) 0
  if word < 2 ^ 63 then (word : Int) else (word : Int) - 2 ^ 64

/-- The elements of a `Seq Int`, eight bytes at a time. -/
def seqIntElements : List UInt8 → List Int
  | b0 :: b1 :: b2 :: b3 :: b4 :: b5 :: b6 :: b7 :: rest =>
      int64OfBytes [b0, b1, b2, b3, b4, b5, b6, b7] :: seqIntElements rest
  | _ => []

def decodeSeqInt (bytes : ByteArray) : List Int := seqIntElements bytes.data.toList

def decodeSeqBool (bytes : ByteArray) : List Bool := bytes.data.toList.map (· == 1)

/-- Canonical sequence bytes, as the VM's `canonical_primitive_bytes`. -/
def canonicalSeq (tag : Nat) (bytes : ByteArray) : Bool :=
  if tag == seqIntTag then bytes.size % 8 == 0
  else if tag == seqBoolTag then bytes.data.toList.all (fun byte => byte == 0 || byte == 1)
  else false

/-- A value `PUSH_LITERAL` may carry: a scalar or a canonical sequence. -/
def isLiteral : Value → Bool
  | .int value => isInt64 value
  | .bool _ | .bytes _ => true
  | .primitiveValue tag bytes => canonicalSeq tag bytes
  | _ => false

/-! ## Primitives

The registry the compiler can target: target Gamma version 8 without the
`World` primitives. Each entry lists its operand kinds bottom-first and acts
on the top-first stack. Every primitive costs one unit. -/

inductive Kind where
  | int
  | bool
  | intSeq
  | boolSeq
  deriving BEq, DecidableEq, Repr

def hasKind : Kind → Value → Bool
  | .int, .int _ => true
  | .bool, .bool _ => true
  | .intSeq, .primitiveValue tag _ => tag == seqIntTag
  | .boolSeq, .primitiveValue tag _ => tag == seqBoolTag
  | _, _ => false

/-- An `i64` result, or a primitive fault. -/
def int64Result (value : Int) (rest : List Value) : Option (List Value) :=
  if isInt64 value then some (.int value :: rest) else none

def intSeqValue (values : List Int) : Value := .primitiveValue seqIntTag (seqIntBytes values)
def boolSeqValue (values : List Bool) : Value := .primitiveValue seqBoolTag (seqBoolBytes values)

/-- The element at a signed index, or nothing for a negative index or one at
or past the end. -/
def elementAt {α : Type} (values : List α) (index : Int) : Option α :=
  if index < 0 then none else values[index.toNat]?

/-- The list with the element at a signed index replaced, or nothing where
`elementAt` has nothing. -/
def replaceAt {α : Type} (values : List α) (index : Int) (value : α) : Option (List α) :=
  if index < 0 || values.length ≤ index.toNat then none else some (values.set index.toNat value)

/-- One primitive's transition on an already validated stack, or `none` for a
primitive fault. -/
def primitiveDelta : String → List Value → Option (List Value)
  | "addInt", .int right :: .int left :: rest => int64Result (left + right) rest
  | "subInt", .int right :: .int left :: rest => int64Result (left - right) rest
  | "mulInt", .int right :: .int left :: rest => int64Result (left * right) rest
  | "divInt", .int right :: .int left :: rest =>
      if right = 0 then none else int64Result (left / right) rest
  | "modInt", .int right :: .int left :: rest =>
      if right = 0 then none else int64Result (left % right) rest
  | "ltInt", .int right :: .int left :: rest => some (.bool (decide (left < right)) :: rest)
  | "eqInt", .int right :: .int left :: rest => some (.bool (decide (left = right)) :: rest)
  | "leInt", .int right :: .int left :: rest => some (.bool (decide (left ≤ right)) :: rest)
  | "gtInt", .int right :: .int left :: rest => some (.bool (decide (right < left)) :: rest)
  | "geInt", .int right :: .int left :: rest => some (.bool (decide (right ≤ left)) :: rest)
  | "andBool", .bool right :: .bool left :: rest => some (.bool (left && right) :: rest)
  | "orBool", .bool right :: .bool left :: rest => some (.bool (left || right) :: rest)
  | "notBool", .bool value :: rest => some (.bool (!value) :: rest)
  | "intSeqEmpty", rest => some (intSeqValue [] :: rest)
  | "intSeqLen", .primitiveValue _ bytes :: rest =>
      int64Result (decodeSeqInt bytes).length rest
  | "intSeqAt", .int index :: .primitiveValue _ bytes :: rest =>
      (elementAt (decodeSeqInt bytes) index).map fun value => .int value :: rest
  | "intSeqPush", .int value :: .primitiveValue _ bytes :: rest =>
      some (intSeqValue (decodeSeqInt bytes ++ [value]) :: rest)
  | "intSeqSet", .int value :: .int index :: .primitiveValue _ bytes :: rest =>
      (replaceAt (decodeSeqInt bytes) index value).map fun values => intSeqValue values :: rest
  | "boolSeqEmpty", rest => some (boolSeqValue [] :: rest)
  | "boolSeqLen", .primitiveValue _ bytes :: rest =>
      int64Result (decodeSeqBool bytes).length rest
  | "boolSeqAt", .int index :: .primitiveValue _ bytes :: rest =>
      (elementAt (decodeSeqBool bytes) index).map fun value => .bool value :: rest
  | "boolSeqPush", .bool value :: .primitiveValue _ bytes :: rest =>
      some (boolSeqValue (decodeSeqBool bytes ++ [value]) :: rest)
  | "boolSeqSet", .bool value :: .int index :: .primitiveValue _ bytes :: rest =>
      (replaceAt (decodeSeqBool bytes) index value).map fun values => boolSeqValue values :: rest
  | _, _ => none

/-- The operand kinds of each registry primitive, bottom-first. -/
def primitiveInputs : String → Option (List Kind)
  | "addInt" | "subInt" | "mulInt" | "divInt" | "modInt"
  | "ltInt" | "eqInt" | "leInt" | "gtInt" | "geInt" => some [.int, .int]
  | "andBool" | "orBool" => some [.bool, .bool]
  | "notBool" => some [.bool]
  | "intSeqEmpty" | "boolSeqEmpty" => some []
  | "intSeqLen" => some [.intSeq]
  | "intSeqAt" | "intSeqPush" => some [.intSeq, .int]
  | "intSeqSet" => some [.intSeq, .int, .int]
  | "boolSeqLen" => some [.boolSeq]
  | "boolSeqAt" => some [.boolSeq, .int]
  | "boolSeqPush" => some [.boolSeq, .bool]
  | "boolSeqSet" => some [.boolSeq, .int, .bool]
  | _ => none

/-- The registry cost of a primitive (`kappa_vm`, §5). -/
def primitiveCost (_name : String) : Nat := 1

/-! ## Machine state -/

/-- What happens when a frame's code ends. `halt` ends the run; `plain`
returns; `checked` first requires the frame's linear captures to have been
consumed (a `CALL`); `dip` does the same and then restores the protected
value. A tail transfer keeps the finished frame's exit. -/
inductive Exit where
  | halt
  | plain
  | checked
  | dip (saved : Value)

/-- An administrative frame: the code still to run, the capture slots it owns,
and whether a transfer from its last instruction may replace it. -/
structure Frame where
  word : String
  code : List Instruction
  captures : List Value
  consumed : List Bool
  exit : Exit
  allowTail : Bool

/-- The cost report of §5: the total, the part the kernel accounts for, and
the counts by kind. -/
structure Cost where
  total : Nat := 0
  kernel : Nat := 0
  instructions : Nat := 0
  wordEntries : Nat := 0
  primitives : Nat := 0
  deriving BEq, DecidableEq, Repr

/-- The machine of §4: the value stack (top first), the live frames
(innermost first), the remaining fuel and the cost so far. -/
structure Machine where
  stack : List Value
  frames : List Frame
  fuel : Nat
  cost : Cost

/-- The trap classes of §4, with `call-depth-exceeded` kept apart from other
resource faults, and `unsupported` for what this file does not model. -/
inductive Trap where
  | malformed
  | unknownWord
  | unknownPrimitive
  | stackFault
  | typeFault
  | resourceFault
  | callDepthExceeded
  | primitiveFault
  | fuelExhausted
  | unsupported
  deriving BEq, DecidableEq, Repr

/-- The stable trap code the VM reports. -/
def Trap.code : Trap → String
  | .malformed => "malformed-instruction"
  | .unknownWord => "unknown-word"
  | .unknownPrimitive => "unknown-primitive"
  | .stackFault => "stack-fault"
  | .typeFault => "type-fault"
  | .resourceFault | .callDepthExceeded => "resource-fault"
  | .primitiveFault => "primitive-fault"
  | .fuelExhausted => "fuel-exhausted"
  | .unsupported => "unsupported"

/-- The VM's stable subcode, empty except for the depth bound. -/
def Trap.subcode : Trap → String
  | .callDepthExceeded => "call-depth-exceeded"
  | _ => ""

/-- The hosted depth bound (`MAX_CALL_DEPTH`). -/
def maxCallDepth : Nat := 256

/-- The result of one step. -/
inductive Step where
  | next (machine : Machine)
  | halted (stack : List Value) (machine : Machine)
  | trapped (trap : Trap) (machine : Machine)

/-! ## One step -/

def isQuotation : Value → Bool
  | .quotation .. => true
  | _ => false

/-- The checks the VM makes before an instruction runs (`validate_before_charge`).
A failure here is not charged. -/
def validate (instruction : Instruction) (stack : List Value) (captures : List Value)
    (consumed : List Bool) : Option Trap :=
  match instruction with
  | .pushLiteral value => if isLiteral value then none else some .malformed
  | .pushQuote _ captured _ => if linearValues captured then some .unsupported else none
  | .pushCapture index =>
      if captures.length ≤ index || consumed.length ≤ index then some .malformed
      else if consumed[index]?.getD false then some .resourceFault else none
  | .dup | .drop =>
      match stack with
      | [] => some .stackFault
      | value :: _ => if linearValue value then some .resourceFault else none
  | .swap => if stack.length < 2 then some .stackFault else none
  | .pick depth =>
      match stack[depth]? with
      | none => some .stackFault
      | some value => if linearValue value then some .resourceFault else none
  | .roll depth => if stack.length ≤ depth then some .stackFault else none
  | .call =>
      match stack with
      | [] => some .stackFault
      | .quotation .. :: _ => none
      | .world :: _ => some .resourceFault
      | _ :: _ => some .typeFault
  | .dip =>
      match stack with
      | top :: _ :: _ =>
          match top with
          | .quotation .. => none
          | .world => some .resourceFault
          | _ => some .typeFault
      | _ => some .stackFault
  | .compose =>
      match stack with
      | right :: left :: _ => if isQuotation right && isQuotation left then none else some .typeFault
      | _ => some .stackFault
  | .quote => if stack.isEmpty then some .stackFault else none
  | .ifThenElse =>
      match stack with
      | falseBranch :: trueBranch :: condition :: _ =>
          match condition with
          | .bool _ =>
              if isQuotation trueBranch && isQuotation falseBranch then none else some .typeFault
          | _ => some .typeFault
      | _ => some .stackFault
  | .callWord _ => none
  | .prim name =>
      match primitiveInputs name with
      | none => some .unknownPrimitive
      | some kinds =>
          if stack.length < kinds.length then some .stackFault
          else if (List.zipWith hasKind kinds (stack.take kinds.length).reverse).all id then none
          else some .typeFault

/-- The cost of one instruction, charged before it runs. -/
def charge (cost : Cost) (instruction : Instruction) : Cost :=
  match instruction with
  | .prim name =>
      { cost with total := cost.total + primitiveCost name
                  kernel := cost.kernel + primitiveCost name
                  instructions := cost.instructions + 1
                  primitives := cost.primitives + 1 }
  | .pushCapture _ =>
      { cost with total := cost.total + 1, instructions := cost.instructions + 1 }
  | _ =>
      { cost with total := cost.total + 1, kernel := cost.kernel + 1
                  instructions := cost.instructions + 1 }

/-- A word entry: one unit, none of it kernel cost. -/
def chargeEntry (cost : Cost) : Cost :=
  { cost with total := cost.total + 1, wordEntries := cost.wordEntries + 1 }

/-- `PUSH_CAPTURE` rebased by `offset`, for the right half of a composition.
Only the top-level code is rebased: a nested quotation owns its own slots. -/
def rebase (offset : Nat) : List Instruction → List Instruction
  | [] => []
  | .pushCapture index :: rest => .pushCapture (index + offset) :: rebase offset rest
  | instruction :: rest => instruction :: rebase offset rest

/-- The value `depth` places below the top and the stack without it. -/
def rollOut : List Value → Nat → Option (Value × List Value)
  | value :: rest, 0 => some (value, rest)
  | value :: rest, depth + 1 => (rollOut rest depth).map fun (moved, others) => (moved, value :: others)
  | [], _ => none

/-- Ends finished frames, innermost first, until one has code left or none
remain. Fails if a frame entered by `CALL` or `DIP` still owes a capture. -/
def unwind : List Value → List Frame → Except (List Value × List Frame) (List Value × List Frame)
  | stack, [] => .ok (stack, [])
  | stack, frame :: callers =>
      if !frame.code.isEmpty then .ok (stack, frame :: callers)
      else
        match frame.exit with
        | .halt | .plain => unwind stack callers
        | .checked =>
            if owesCapture frame.captures frame.consumed then .error (stack, frame :: callers)
            else unwind stack callers
        | .dip saved =>
            if owesCapture frame.captures frame.consumed then .error (stack, frame :: callers)
            else unwind (saved :: stack) callers

/-- The reported final stack: `World` markers removed, and nothing else
linear left (§4). -/
def terminalStack : List Value → Option (List Value)
  | [] => some []
  | .world :: rest => terminalStack rest
  | value :: rest => if linearValue value then none else (terminalStack rest).map (value :: ·)

/-- A frame running a quotation or a word body. -/
def enter (word : String) (code : List Instruction) (captures : List Value)
    (consumed : List Bool) (exit : Exit) : Frame :=
  { word, code, captures, consumed, exit, allowTail := !linearValues captures }

/-- What an instruction did once charged: the next stack, frames and cost, or
a trap with the state it left. -/
inductive Effect where
  | ok (stack : List Value) (frames : List Frame) (cost : Cost)
  | fault (trap : Trap) (stack : List Value) (frames : List Frame) (cost : Cost)

/-- One validated, charged instruction of `frame`, whose remaining code after
it is `rest`. `image` is the admitted dictionary. -/
def exec (image : List WordEntry) (frame : Frame) (callers : List Frame)
    (instruction : Instruction) (rest : List Instruction) (stack : List Value)
    (cost : Cost) : Effect :=
  let here := { frame with code := rest }
  let tail := frame.allowTail && rest.isEmpty
  -- A nested frame, refused past the depth bound.
  let nest (stack : List Value) (callee : Frame) (cost : Cost) : Effect :=
    if maxCallDepth ≤ (here :: callers).length then
      .fault .callDepthExceeded stack (here :: callers) cost
    else .ok stack (callee :: here :: callers) cost
  -- A tail transfer: the callee takes the finished frame's place and exit.
  let replace (stack : List Value) (callee : Frame) (cost : Cost) : Effect :=
    .ok stack ({ callee with exit := frame.exit, allowTail := true } :: callers) cost
  match instruction with
  | .pushLiteral value => .ok (value :: stack) (here :: callers) cost
  | .pushQuote code captured flags =>
      .ok (.quotation code captured flags :: stack) (here :: callers) cost
  | .pushCapture index =>
      let value := frame.captures[index]?.getD (.bytes ByteArray.empty)
      if linearValue value then
        let moved := { here with captures := frame.captures.set index (.bytes ByteArray.empty)
                                 consumed := frame.consumed.set index true }
        .ok (value :: stack) (moved :: callers) cost
      else .ok (value :: stack) (here :: callers) cost
  | .dup =>
      match stack with
      | value :: _ => .ok (value :: stack) (here :: callers) cost
      | [] => .fault .stackFault stack (here :: callers) cost
  | .drop => .ok stack.tail (here :: callers) cost
  | .swap =>
      match stack with
      | top :: second :: others => .ok (second :: top :: others) (here :: callers) cost
      | _ => .fault .stackFault stack (here :: callers) cost
  | .pick depth =>
      match stack[depth]? with
      | some value => .ok (value :: stack) (here :: callers) cost
      | none => .fault .stackFault stack (here :: callers) cost
  | .roll depth =>
      match rollOut stack depth with
      | some (value, others) => .ok (value :: others) (here :: callers) cost
      | none => .fault .stackFault stack (here :: callers) cost
  | .call =>
      match stack with
      | .quotation code captured flags :: others =>
          if tail && !linearValues captured then
            replace others (enter frame.word code captured flags .plain) cost
          else nest others (enter frame.word code captured flags .checked) cost
      | _ => .fault .typeFault stack (here :: callers) cost
  | .dip =>
      match stack with
      | .quotation code captured flags :: saved :: others =>
          nest others (enter frame.word code captured flags (.dip saved)) cost
      | _ => .fault .typeFault stack (here :: callers) cost
  | .compose =>
      match stack with
      | .quotation rightCode rightCaptures rightFlags
          :: .quotation leftCode leftCaptures leftFlags :: others =>
          let composed := Value.quotation
            (leftCode ++ rebase leftCaptures.length rightCode)
            (leftCaptures ++ rightCaptures) (leftFlags ++ rightFlags)
          .ok (composed :: others) (here :: callers) cost
      | _ => .fault .typeFault stack (here :: callers) cost
  | .quote =>
      match stack with
      | value :: others =>
          .ok (.quotation [.pushCapture 0] [value] [false] :: others) (here :: callers) cost
      | [] => .fault .stackFault stack (here :: callers) cost
  | .ifThenElse =>
      match stack with
      | .quotation falseCode falseCaptures falseFlags
          :: .quotation trueCode trueCaptures trueFlags :: .bool condition :: others =>
          if linearValues trueCaptures || linearValues falseCaptures then
            .fault .resourceFault others (here :: callers) cost
          else
            let callee := if condition
              then enter frame.word trueCode trueCaptures trueFlags .plain
              else enter frame.word falseCode falseCaptures falseFlags .plain
            if tail then replace others callee cost else nest others callee cost
      | _ => .fault .typeFault stack (here :: callers) cost
  | .callWord name =>
      match image.find? (·.name == name) with
      | none => .fault .unknownWord stack (here :: callers) cost
      | some entry =>
          let callee := enter entry.name entry.code [] [] .plain
          if tail then replace stack callee (chargeEntry cost)
          else if maxCallDepth ≤ (here :: callers).length then
            .fault .callDepthExceeded stack (here :: callers) cost
          else .ok stack (callee :: here :: callers) (chargeEntry cost)
  | .prim name =>
      match primitiveDelta name stack with
      | some result => .ok result (here :: callers) cost
      | none => .fault .primitiveFault stack (here :: callers) cost

/-- One step: end finished frames, then halt, or fetch, check fuel, validate,
charge and run the innermost frame's next instruction. -/
def step (image : List WordEntry) (machine : Machine) : Step :=
  match unwind machine.stack machine.frames with
  | .error (stack, frames) => .trapped .resourceFault { machine with stack, frames }
  | .ok (stack, []) =>
      match terminalStack stack with
      | some final => .halted final { machine with stack, frames := [] }
      | none => .trapped .resourceFault { machine with stack, frames := [] }
  | .ok (stack, frame :: callers) =>
      let state : Machine := { machine with stack, frames := frame :: callers }
      match frame.code with
      | [] => .trapped .unsupported state
      | instruction :: rest =>
          if machine.fuel = 0 then .trapped .fuelExhausted state
          else
            match validate instruction stack frame.captures frame.consumed with
            | some trap => .trapped trap state
            | none =>
                match exec image frame callers instruction rest stack
                    (charge machine.cost instruction) with
                | .ok stack frames cost => .next { stack, frames, fuel := machine.fuel - 1, cost }
                | .fault trap stack frames cost =>
                    .trapped trap { stack, frames, fuel := machine.fuel - 1, cost }

/-! ## Runs -/

/-- How a run ended. `outOfBound` is unreachable from `execute` (see
`execute_within_bound`); it exists only because `run` recurses on a bound. -/
inductive Outcome where
  | halted (stack : List Value) (machine : Machine)
  | trapped (trap : Trap) (machine : Machine)
  | outOfBound (machine : Machine)

/-- At most `bound` steps. -/
def run (image : List WordEntry) : Nat → Machine → Outcome
  | bound, machine =>
      match step image machine with
      | .halted stack final => .halted stack final
      | .trapped trap final => .trapped trap final
      | .next following =>
          match bound with
          | 0 => .outOfBound following
          | bound + 1 => run image bound following

/-- The machine that runs `entry` on `stack` (top first): one root frame with
the `halt` continuation and no entry charge, as `execute_report_entry`. -/
def start (entry : WordEntry) (stack : List Value) (fuel : Nat) : Machine :=
  { stack, frames := [enter entry.name entry.code [] [] .halt], fuel, cost := {} }

/-- Runs the word named `entry` of an admitted image with `fuel` units of
instruction budget. -/
def execute (image : List WordEntry) (entry : String) (stack : List Value) (fuel : Nat) : Outcome :=
  match image.find? (·.name == entry) with
  | none => .trapped .unknownWord { stack, frames := [], fuel, cost := {} }
  | some word => run image fuel (start word stack fuel)

/-! ## Fuel bounds every run -/

theorem step_next_fuel {image : List WordEntry} {machine following : Machine}
    (h : step image machine = .next following) : following.fuel + 1 = machine.fuel := by
  unfold step at h
  split at h
  · cases h
  · split at h <;> cases h
  · split at h
    · cases h
    · split at h
      · cases h
      · rename_i hfuel
        split at h
        · cases h
        · split at h
          · cases h
            simp only
            omega
          · cases h

/-- A run given as many steps as it has fuel never stops on the bound: each
step that continues spends one unit of fuel, and a step with no fuel left
halts or traps. -/
theorem run_within_bound {image : List WordEntry} :
    ∀ (bound : Nat) (machine : Machine), machine.fuel ≤ bound →
      ∀ last, run image bound machine ≠ .outOfBound last
  | bound, machine, hfuel, last => by
      unfold run
      split
      · simp
      · simp
      · rename_i following hstep
        have := step_next_fuel hstep
        cases bound with
        | zero => omega
        | succ bound => exact run_within_bound bound following (by omega) last

theorem execute_within_bound {image : List WordEntry} {entry : String} {stack : List Value}
    {fuel : Nat} (last : Machine) : execute image entry stack fuel ≠ .outOfBound last := by
  unfold execute
  split
  · simp
  · exact run_within_bound fuel _ (by simp [start]) last

end Firth.Compiler.TargetSemantics
