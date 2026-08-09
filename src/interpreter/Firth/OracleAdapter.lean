import Firth.Interpreter

namespace Firth.Interpreter

/-!
The oracle adapter is the stable boundary for compiler and target conformance
checks. It accepts the kernel environment and execution inputs separately,
then delegates to the reference interpreter without rewriting the resulting
stack, residual program, or observed `World` state.
-/

def runOracleAdapter (gamma : Gamma) (dictionary : Dictionary)
    (program : Program) (initialStack : Stack) (costs : CostTable)
    (fuelBudget : Nat) : OracleResult :=
  runOracle gamma dictionary costs fuelBudget
    { stack := initialStack, program := program }

end Firth.Interpreter
