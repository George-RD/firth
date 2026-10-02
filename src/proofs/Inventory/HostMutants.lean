import proofs.Inventory.Host

/-! Known values and known-bad inputs for the host encoding in `Host.lean`.

The expected parts are written out by hand, not computed by `encodeId`: a
character's digit is its position in `A..Z a..z 0..9 _ -` plus one, so "A" is
`1 · 65^7` and "-" is `64 · 65^7`. Each `#guard_msgs` block fails the build
unless Lean's `#guard` rejects the planted expectation, so a guard that stopped
comparing would be caught here. -/

namespace Firth.Proofs.Inventory.HostMutants
open Firth.Proofs.Inventory.Host

-- 65^7 = 4902227890625.
#guard encodeId "A" == [4902227890625, 0, 0, 0]
#guard encodeId "-" == [64 * 4902227890625, 0, 0, 0]
#guard encodeId "AB" == [4902227890625 + 2 * 75418890625, 0, 0, 0]
-- The ninth character starts the second part.
#guard encodeId "AAAAAAAAB" == [318644812890624 / 64, 2 * 4902227890625, 0, 0]
#guard encodeIds ["A", "B"] == [4902227890625, 0, 0, 0, 2 * 4902227890625, 0, 0, 0]

-- The ID syntax: empty, too long, and a character outside the alphabet.
#guard validId "" == false
#guard validId (String.ofList (List.replicate 33 'a')) == false
#guard validId (String.ofList (List.replicate 32 'a')) == true
#guard validId "a b" == false
#guard validId "a.b" == false

-- Padding with 0 is why a digit is a position plus one: with the position
-- alone, "A" and "AA" would collide.
def badDigits (s : String) : List Nat :=
  s.toList.map (alphabet.idxOf ·) ++ List.replicate (32 - s.length) 0
#guard part (chunk (badDigits "A") 0) == part (chunk (badDigits "AA") 0)
#guard encodeId "A" != encodeId "AA"

-- The answer: IDs attached by position, reasons by name.
#guard hostEncode ["x", "y"] 0 5 [3, 0] [0, 2] ==
  some (.ok 5 [⟨"x", 3, "fulfilled"⟩, ⟨"y", 0, "out-of-stock"⟩])
#guard hostEncode ["x"] 2 0 [] [] == some (.error "duplicate-id")
-- Refused: an unknown reason, an unknown error code, and lengths that differ.
#guard hostEncode ["x"] 0 0 [1] [4] == none
#guard hostEncode ["x"] 3 0 [] [] == none
#guard hostEncode ["x", "y"] 0 0 [1] [0] == none

-- The IDs swapped in the answer.
/--
error: Expression
  hostEncode ["x", "y"] 0 5 [3, 0] [0, 2] ==
    some
      (Answer.ok 5
        [{ id := "y", quantity := 3, reason := "fulfilled" }, { id := "x", quantity := 0, reason := "out-of-stock" }])
did not evaluate to `true`
-/
#guard_msgs in
#guard hostEncode ["x", "y"] 0 5 [3, 0] [0, 2] ==
  some (.ok 5 [⟨"y", 3, "fulfilled"⟩, ⟨"x", 0, "out-of-stock"⟩])

-- duplicate-id accepted as a successful allocation, on the ID strings.
/--
error: Expression
  hostSpec 2 false ["A", "A"] [1, 1] == (0, 0, [1, 1], [0, 0])
did not evaluate to `true`
-/
#guard_msgs in
#guard hostSpec 2 false ["A", "A"] [1, 1] == (0, 0, [1, 1], [0, 0])

-- Two different IDs that share their first eight characters reported as a duplicate.
/--
error: Expression
  hostSpec 2 false ["AAAAAAAAB", "AAAAAAAAC"] [1, 1] == (2, 0, [], [])
did not evaluate to `true`
-/
#guard_msgs in
#guard hostSpec 2 false ["AAAAAAAAB", "AAAAAAAAC"] [1, 1] == (2, 0, [], [])

end Firth.Proofs.Inventory.HostMutants
