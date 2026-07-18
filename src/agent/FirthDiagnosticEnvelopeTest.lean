import agent.Firth.Agent.DiagnosticEnvelopeTest
import agent.Firth.Agent.ValidationTest
import agent.Firth.Agent.ElaboratorDiagnosticsTest

def main : IO Unit := do
  Firth.Agent.Test.runEnvelopeTests
  Firth.Agent.Test.runValidationTests
  Firth.Agent.Test.runElaboratorDiagnosticTests
