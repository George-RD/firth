private def runSuite (name : String) : IO Unit := do
  let result ← IO.Process.output { cmd := "lake", args := #["exe", name] }
  if result.exitCode != 0 then
    throw <| IO.userError s!"{name} failed:\n{result.stdout}{result.stderr}"

def main : IO Unit := do
  runSuite "firthTest"
  runSuite "firthParserTest"
  runSuite "firthErasureTest"
  runSuite "firthStackEffectTest"
  runSuite "firthRefinementTest"
  runSuite "firthAgentDiagnosticTest"
