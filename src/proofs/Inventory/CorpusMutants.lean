import proofs.Inventory.Allocate

/-! Known-bad expectations for the `batchSpec` guards in `SpecCorpus.lean`.
Each is a corpus case with one planted error in its expected result, and
`#guard_msgs` fails the build unless Lean's `#guard` rejects it, so a guard
that stopped comparing results would be caught here. -/

namespace Firth.Proofs.Inventory.CorpusMutants
open Firth.Proofs.Inventory.Allocate

-- range-before-duplicate with the duplicate code where the contract says range.
/--
error: Expression
  batchSpec (-1) false [4902227890625, 0, 0, 0, 4902227890625, 0, 0, 0] [1, 1] == (2, 0, [], [])
did not evaluate to `true`
-/
#guard_msgs in
#guard batchSpec (-1) false [4902227890625, 0, 0, 0, 4902227890625, 0, 0, 0] [1, 1] ==
  (2, 0, [], [])

-- partial-final with the second request's reason fulfilled instead of partial.
/--
error: Expression
  batchSpec 5 false [4902227890625, 0, 0, 0, 9804455781250, 0, 0, 0] [3, 4] == (0, 0, [3, 2], [0, 0])
did not evaluate to `true`
-/
#guard_msgs in
#guard batchSpec 5 false [4902227890625, 0, 0, 0, 9804455781250, 0, 0, 0] [3, 4] ==
  (0, 0, [3, 2], [0, 0])

-- duplicate-id accepted as a successful allocation.
/--
error: Expression
  batchSpec 2 false [4902227890625, 0, 0, 0, 4902227890625, 0, 0, 0] [1, 1] == (0, 0, [1, 1], [0, 0])
did not evaluate to `true`
-/
#guard_msgs in
#guard batchSpec 2 false [4902227890625, 0, 0, 0, 4902227890625, 0, 0, 0] [1, 1] ==
  (0, 0, [1, 1], [0, 0])

end Firth.Proofs.Inventory.CorpusMutants
