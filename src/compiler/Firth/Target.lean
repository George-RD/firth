import compiler.Firth.Digest

/-!
The v0.1 target algebra and its canonical wire encoding.

Both are frozen by `src/runtime/vm/target-spec.md`: §2 fixes the value and
instruction sets, §7 fixes the byte encoding (unsigned LEB128, zig-zag signed
`i64`, length-prefixed strings and vectors, opcodes and tags numbered in
declaration order from zero) and defines `body_digest` as SHA-256 over a word
body's canonical encoding.

This file is the compiler's half of a two-implementation agreement: the Rust
VM recomputes every `body_digest` when it decodes an image, so a divergence
between this encoder and `src/runtime/vm/src/encoding.rs` is refused at load
time rather than executed.
-/

namespace Firth.Compiler.Target

/-!
The target value and instruction algebras of §2. They are mutually recursive
because a quotation is a value carrying code, and `PUSH_QUOTE` carries a
quotation. `World` is administrative and never appears in a compiled program;
it is present so the encoding is total over the frozen algebra.
-/
mutual
  inductive Value where
    /-- A signed 64-bit integer. The constructor is total over `Int` because
    the algebra is frozen, but the wire domain is `i64`: callers must respect
    `isInt64`, since the encoder below is also total and the VM refuses the
    ten-byte LEB128 form of anything outside that range. -/
    | int (value : Int)
    | bool (value : Bool)
    | bytes (value : ByteArray)
    /-- `consumed` carries one flag per capture slot. The two lists must have
    equal length; `wellFormedQuotation` checks that, matching the VM's
    `InvalidCaptureBitmap` refusal. -/
    | quotation (code : List Instruction) (captures : List Value) (consumed : List Bool)
    | primitiveValue (tag : Nat) (value : ByteArray)
    | world

  inductive Instruction where
    | pushLiteral (value : Value)
    | pushQuote (code : List Instruction) (captures : List Value) (consumed : List Bool)
    | pushCapture (index : Nat)
    | dup
    | drop
    | swap
    | call
    | dip
    | compose
    | quote
    | ifThenElse
    | callWord (name : String)
    | prim (name : String)
end

instance : Inhabited Value := ⟨.world⟩
instance : Inhabited Instruction := ⟨.dup⟩

/-- The signed 64-bit range of a target integer (§2). -/
def isInt64 (value : Int) : Bool :=
  -(2 ^ 63 : Int) ≤ value && value < (2 ^ 63 : Int)

/-!
Admission bounds the VM enforces on every image, from
`src/runtime/vm/src/lib.rs` (`MAX_INSTRUCTIONS`, `MAX_NESTING`) and
`target-spec.md` ("Direct runtime ingress bounds"). A code or capture vector
holds at most 4096 elements at every level, and quotation nesting is counted
from zero at a word body: depth 32 is admitted and depth 33 refused.
-/

/-- The largest code or capture vector the VM decodes. -/
def maxInstructions : Nat := 4096

/-- The deepest quotation nesting the VM decodes. -/
def maxNesting : Nat := 32

mutual

/-- Every quotation at every depth pairs each capture with exactly one
consumed flag, which is what the VM's structural validation requires. -/
partial def wellFormedCode : List Instruction → Bool
  | [] => true
  | .pushLiteral value :: rest => wellFormedValue value && wellFormedCode rest
  | .pushQuote code captures consumed :: rest =>
      wellFormedQuotation code captures consumed && wellFormedCode rest
  | _ :: rest => wellFormedCode rest

partial def wellFormedValue : Value → Bool
  | .quotation code captures consumed => wellFormedQuotation code captures consumed
  | _ => true

partial def wellFormedQuotation (code : List Instruction) (captures : List Value)
    (consumed : List Bool) : Bool :=
  captures.length == consumed.length && wellFormedCode code && wellFormedValues captures

partial def wellFormedValues : List Value → Bool
  | [] => true
  | value :: rest => wellFormedValue value && wellFormedValues rest

end

mutual

/-- The first admission bound a code vector breaks, or `none`. The walk mirrors
`resource_bounds.rs`: `depth` is the nesting level of `code` itself, every
`PUSH_QUOTE` body and captured quotation is one level deeper, and both code and
capture vectors are bounded at every level. -/
partial def boundViolation (code : List Instruction) (depth : Nat := 0) : Option String :=
  if depth > maxNesting then
    some s!"quotation nesting depth {depth} exceeds the target bound of {maxNesting}"
  else if code.length > maxInstructions then
    some s!"instruction count {code.length} exceeds the target bound of {maxInstructions}"
  else instructionViolation code depth

partial def instructionViolation (code : List Instruction) (depth : Nat) : Option String :=
  match code with
  | [] => none
  | .pushLiteral value :: rest =>
      match valueViolation value depth with
      | some detail => some detail
      | none => instructionViolation rest depth
  | .pushQuote body captures _ :: rest =>
      match quotationViolation body captures (depth + 1) with
      | some detail => some detail
      | none => instructionViolation rest depth
  | _ :: rest => instructionViolation rest depth

partial def valueViolation (value : Value) (depth : Nat) : Option String :=
  match value with
  | .quotation body captures _ => quotationViolation body captures (depth + 1)
  | _ => none

partial def quotationViolation (body : List Instruction) (captures : List Value) (depth : Nat) :
    Option String :=
  if captures.length > maxInstructions then
    some s!"capture count {captures.length} exceeds the target bound of {maxInstructions}"
  else
    match boundViolation body depth with
    | some detail => some detail
    | none => capturesViolation captures depth

partial def capturesViolation (captures : List Value) (depth : Nat) : Option String :=
  match captures with
  | [] => none
  | value :: rest =>
      match valueViolation value depth with
      | some detail => some detail
      | none => capturesViolation rest depth

end

/-- One published word, in the shape §6 gives a `WordEntry`. -/
structure WordEntry where
  name : String
  erasedWordType : String
  code : List Instruction
  kernelEvidenceDigest : ByteArray
  refinementEvidenceDigest : ByteArray
  generation : Nat

/-- Unsigned LEB128, the canonical form: the shortest encoding of `value`. -/
partial def putUnsigned (value : Nat) : ByteArray :=
  let rec go (remaining : Nat) (out : ByteArray) : ByteArray :=
    let byte := remaining % 128
    let rest := remaining / 128
    if rest == 0 then out.push (UInt8.ofNat byte)
    else go rest (out.push (UInt8.ofNat (byte + 128)))
  go value ByteArray.empty

/-- Zig-zag mapping of a signed `i64` onto the unsigned LEB128 domain. -/
def zigzag (value : Int) : Nat :=
  if value ≥ 0 then 2 * value.toNat else 2 * (-value).toNat - 1

/-- A length-prefixed byte string. -/
def putBytes (value : ByteArray) : ByteArray :=
  putUnsigned value.size ++ value

/-- A length-prefixed UTF-8 string. The prefix counts bytes, not characters. -/
def putString (value : String) : ByteArray :=
  putBytes value.toUTF8

/-- The consumed-capture bitmap: one bit per slot, least significant bit
first, padded to whole bytes. -/
def captureBitmap (consumed : List Bool) (count : Nat) : ByteArray := Id.run do
  let width := (count + 7) / 8
  let mut bitmap : Array UInt8 := Array.replicate width 0
  let mut index := 0
  for flag in consumed do
    if flag && index < count then
      let slot := index / 8
      bitmap := bitmap.set! slot (bitmap[slot]! ||| (1 <<< UInt8.ofNat (index % 8)))
    index := index + 1
  return bitmap.foldl (fun out byte => out.push byte) ByteArray.empty

mutual

/-- The canonical encoding of an instruction vector: a length prefix followed
by each instruction's opcode and operands. -/
partial def canonicalCode (code : List Instruction) : ByteArray :=
  canonicalInstructions code (putUnsigned code.length)

private partial def canonicalInstructions (code : List Instruction) (out : ByteArray) :
    ByteArray :=
  match code with
  | [] => out
  | instruction :: rest => canonicalInstructions rest (out ++ canonicalInstruction instruction)

/-- Opcodes are numbered in the declaration order of §2, starting at zero. -/
private partial def canonicalInstruction : Instruction → ByteArray
  | .pushLiteral value => (ByteArray.empty.push 0) ++ canonicalValue value
  | .pushQuote code captures consumed =>
      (ByteArray.empty.push 1) ++ canonicalQuotation code captures consumed
  | .pushCapture index => (ByteArray.empty.push 2) ++ putUnsigned index
  | .dup => ByteArray.empty.push 3
  | .drop => ByteArray.empty.push 4
  | .swap => ByteArray.empty.push 5
  | .call => ByteArray.empty.push 6
  | .dip => ByteArray.empty.push 7
  | .compose => ByteArray.empty.push 8
  | .quote => ByteArray.empty.push 9
  | .ifThenElse => ByteArray.empty.push 10
  | .callWord name => (ByteArray.empty.push 11) ++ putString name
  | .prim name => (ByteArray.empty.push 12) ++ putString name

/-- Quotation code, then the capture count, then the consumed bitmap, then
each capture value. -/
private partial def canonicalQuotation (code : List Instruction) (captures : List Value)
    (consumed : List Bool) : ByteArray :=
  canonicalCaptures captures
    (canonicalCode code ++ putUnsigned captures.length
      ++ captureBitmap consumed captures.length)

private partial def canonicalCaptures (captures : List Value) (out : ByteArray) : ByteArray :=
  match captures with
  | [] => out
  | value :: rest => canonicalCaptures rest (out ++ canonicalValue value)

/-- Value tags follow the declaration order of §2, starting at zero. -/
partial def canonicalValue : Value → ByteArray
  | .int value => (ByteArray.empty.push 0) ++ putUnsigned (zigzag value)
  | .bool value => (ByteArray.empty.push 1).push (if value then 1 else 0)
  | .bytes value => (ByteArray.empty.push 2) ++ putBytes value
  | .quotation code captures consumed =>
      (ByteArray.empty.push 3) ++ canonicalQuotation code captures consumed
  | .primitiveValue tag value =>
      ((ByteArray.empty.push 4) ++ putUnsigned tag) ++ putBytes value
  | .world => ByteArray.empty.push 5

end

/-- SHA-256 over a word body's canonical encoding, which is exactly how §7
defines `body_digest`. -/
def bodyDigest (code : List Instruction) : ByteArray :=
  Digest.sha256 (canonicalCode code)

/-- The canonical encoding of a sorted word vector, as §7 defines the input to
`dictionary_digest`. -/
def canonicalDictionary (words : List WordEntry) : ByteArray := Id.run do
  let mut out := putUnsigned words.length
  for word in words do
    out := out ++ putString word.name
    out := out ++ putString word.erasedWordType
    out := out ++ canonicalCode word.code
    out := out ++ bodyDigest word.code
    out := out ++ word.kernelEvidenceDigest
    out := out ++ word.refinementEvidenceDigest
    out := out ++ putUnsigned word.generation
  return out

end Firth.Compiler.Target
