/-!
SHA-256 (FIPS 180-4) over a byte array.

`files/firth-kernel-spec-draft.md` leaves hashing to the target contract, and
`src/runtime/vm/target-spec.md` §7 fixes every digest in the image wire format
as SHA-256 over canonical bytes. The compiler must therefore produce the same
digests the VM recomputes when it decodes an image, so this is a from-scratch
implementation rather than a call into a host tool: a compiler that shelled out
to `sha256sum` would make its output depend on the machine it ran on, and the
gate rebuilds applications in an isolated workspace.

The implementation is pure and total. `Firth.Compiler.Digest.sha256` is the
only entry point the rest of the compiler uses.
-/

namespace Firth.Compiler.Digest

/-- The 64 SHA-256 round constants, the first 32 bits of the fractional parts
of the cube roots of the first 64 primes. -/
private def roundConstants : Array UInt32 := #[
  0x428a2f98, 0x71374491, 0xb5c0fbcf, 0xe9b5dba5, 0x3956c25b, 0x59f111f1, 0x923f82a4, 0xab1c5ed5,
  0xd807aa98, 0x12835b01, 0x243185be, 0x550c7dc3, 0x72be5d74, 0x80deb1fe, 0x9bdc06a7, 0xc19bf174,
  0xe49b69c1, 0xefbe4786, 0x0fc19dc6, 0x240ca1cc, 0x2de92c6f, 0x4a7484aa, 0x5cb0a9dc, 0x76f988da,
  0x983e5152, 0xa831c66d, 0xb00327c8, 0xbf597fc7, 0xc6e00bf3, 0xd5a79147, 0x06ca6351, 0x14292967,
  0x27b70a85, 0x2e1b2138, 0x4d2c6dfc, 0x53380d13, 0x650a7354, 0x766a0abb, 0x81c2c92e, 0x92722c85,
  0xa2bfe8a1, 0xa81a664b, 0xc24b8b70, 0xc76c51a3, 0xd192e819, 0xd6990624, 0xf40e3585, 0x106aa070,
  0x19a4c116, 0x1e376c08, 0x2748774c, 0x34b0bcb5, 0x391c0cb3, 0x4ed8aa4a, 0x5b9cca4f, 0x682e6ff3,
  0x748f82ee, 0x78a5636f, 0x84c87814, 0x8cc70208, 0x90befffa, 0xa4506ceb, 0xbef9a3f7, 0xc67178f2]

/-- The eight initial hash words, the first 32 bits of the fractional parts of
the square roots of the first eight primes. -/
private def initialState : Array UInt32 :=
  #[0x6a09e667, 0xbb67ae85, 0x3c6ef372, 0xa54ff53a,
    0x510e527f, 0x9b05688c, 0x1f83d9ab, 0x5be0cd19]

/-- Rotate right. Every SHA-256 rotation amount is between 1 and 31, so the
complementary shift is always in range. -/
private def rotr (value : UInt32) (amount : UInt32) : UInt32 :=
  (value >>> amount) ||| (value <<< (32 - amount))

/-- Big-endian assembly of one 32-bit message word from four bytes. -/
private def beWord (bytes : ByteArray) (offset : Nat) : UInt32 :=
  ((bytes.get! offset).toUInt32 <<< 24)
    ||| ((bytes.get! (offset + 1)).toUInt32 <<< 16)
    ||| ((bytes.get! (offset + 2)).toUInt32 <<< 8)
    ||| (bytes.get! (offset + 3)).toUInt32

/-- The 64-word message schedule for the block starting at `offset`. -/
private def schedule (bytes : ByteArray) (offset : Nat) : Array UInt32 := Id.run do
  let mut words : Array UInt32 := Array.emptyWithCapacity 64
  for index in [0:16] do
    words := words.push (beWord bytes (offset + 4 * index))
  for index in [16:64] do
    let previous := words[index - 15]!
    let recent := words[index - 2]!
    let sigma0 := (rotr previous 7) ^^^ (rotr previous 18) ^^^ (previous >>> 3)
    let sigma1 := (rotr recent 17) ^^^ (rotr recent 19) ^^^ (recent >>> 10)
    words := words.push (words[index - 16]! + sigma0 + words[index - 7]! + sigma1)
  return words

/-- One compression round set over a single 64-byte block. -/
private def compress (state : Array UInt32) (bytes : ByteArray) (offset : Nat) :
    Array UInt32 := Id.run do
  let words := schedule bytes offset
  let mut a := state[0]!
  let mut b := state[1]!
  let mut c := state[2]!
  let mut d := state[3]!
  let mut e := state[4]!
  let mut f := state[5]!
  let mut g := state[6]!
  let mut h := state[7]!
  for index in [0:64] do
    let sum1 := (rotr e 6) ^^^ (rotr e 11) ^^^ (rotr e 25)
    let choose := (e &&& f) ^^^ ((~~~e) &&& g)
    let temp1 := h + sum1 + choose + roundConstants[index]! + words[index]!
    let sum0 := (rotr a 2) ^^^ (rotr a 13) ^^^ (rotr a 22)
    let majority := (a &&& b) ^^^ (a &&& c) ^^^ (b &&& c)
    let temp2 := sum0 + majority
    h := g
    g := f
    f := e
    e := d + temp1
    d := c
    c := b
    b := a
    a := temp1 + temp2
  return #[state[0]! + a, state[1]! + b, state[2]! + c, state[3]! + d,
           state[4]! + e, state[5]! + f, state[6]! + g, state[7]! + h]

/-- FIPS 180-4 padding: one `0x80` byte, then zeros to 56 mod 64, then the
message length in bits as a big-endian 64-bit integer. -/
private def pad (bytes : ByteArray) : ByteArray := Id.run do
  let length := bytes.size
  let mut padded := bytes.push 0x80
  while padded.size % 64 != 56 do
    padded := padded.push 0
  let bits := length * 8
  for shift in [0:8] do
    padded := padded.push (UInt8.ofNat ((bits >>> (8 * (7 - shift))) % 256))
  return padded

/-- The big-endian byte serialisation of the final state. -/
private def finalise (state : Array UInt32) : ByteArray := Id.run do
  let mut digest := ByteArray.emptyWithCapacity 32
  for word in state do
    for shift in [0:4] do
      digest := digest.push (UInt8.ofNat ((word >>> (UInt32.ofNat (8 * (3 - shift)))).toNat % 256))
  return digest

/-- SHA-256 of `bytes`, as the 32 raw digest bytes. -/
def sha256 (bytes : ByteArray) : ByteArray := Id.run do
  let padded := pad bytes
  let mut state := initialState
  let mut offset := 0
  while offset < padded.size do
    state := compress state padded offset
    offset := offset + 64
  return finalise state

/-- Lowercase hexadecimal rendering, the form every digest takes on the wire. -/
def toHex (bytes : ByteArray) : String := Id.run do
  let digits : Array Char :=
    #['0', '1', '2', '3', '4', '5', '6', '7', '8', '9', 'a', 'b', 'c', 'd', 'e', 'f']
  let mut rendered := ""
  for byte in bytes do
    rendered := rendered.push digits[byte.toNat / 16]!
    rendered := rendered.push digits[byte.toNat % 16]!
  return rendered

/-- SHA-256 of a UTF-8 string, rendered in lowercase hexadecimal. -/
def hexOfString (value : String) : String := toHex (sha256 value.toUTF8)

end Firth.Compiler.Digest
