import proofs.Inventory.Allocate

/-! Concrete runs against `allocate_batch`. The reference interpreter runs
`allocate-batch`'s body, as the host runs the entry word. On an empty batch the
cost is exactly `batchCost 0`, so the proved constant cannot be lowered. For
larger batches the proved bound is not attained: one partial request costs 322
against `batchCost 1 = 367`, and `examples/inventory/measure_cost.py` measures
at most 341,547 at 64 requests against 341,701. -/

namespace Firth.Proofs.Inventory.CostCheck
open Firth.Interpreter
open Firth.ReferenceRun
open Firth.Exports.Inventory.Allocator
open Firth.Proofs.Inventory.Allocate

/-- Runs `program` from `stack` to the end, with its total cost, or `none`
if it gets stuck or runs out of fuel. -/
def run (program : Program) (stack : Stack) : Option (Stack × Nat) :=
  let rec go : Nat → Config → Nat → Option (Stack × Nat)
    | fuel, config, cost => match step adapterGamma dictionary defaultCosts config with
      | .terminal final => some (final.stack, cost)
      | .stuck _ => none
      | .stepped next charge => match fuel with
        | 0 => none
        | fuel + 1 => go fuel next (cost + charge)
  go 1000000 { stack, program } 0

-- An empty batch: the stock is returned unchanged, at exactly the bound.
#guard run «allocate-batch».body (batchIn 5 false [] [] []) ==
  some (batchOut 0 5 [] [] [], batchCost 0)

-- One request for 2 with 1 in stock under the partial policy: 1 allocated,
-- reason partial (code 1), within the bound.
#guard run «allocate-batch».body (batchIn 1 false [0, 0, 0, 1] [2] []) ==
  some (batchOut 0 0 [1] [1] [], 322)
#guard 322 ≤ batchCost 1

end Firth.Proofs.Inventory.CostCheck
