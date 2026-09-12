import smt.Firth.SmtSolver

/-!
Real pipe regressions for the production runner. Run on the Linux CI host with
`lake env lean --run src/smt/FirthSmtProcessTest.lean`. Python is only a child
process fixture; no SMT solver or external proof is involved.
-/

open Firth.Smt.Solver

private def ensure (condition : Bool) (message : String) : IO Unit :=
  if condition then pure () else throw (IO.userError message)

private def repeatedChar (count : Nat) (character : Char) : String :=
  String.ofList (List.replicate count character)

def main : IO Unit := do
  let python : System.FilePath := "/usr/bin/python3"
  ensure (← python.pathExists) "real process tests require /usr/bin/python3"
  let run (program script : String) (limit : Nat := 65536) (timeout : Nat := 3000) :=
    (processRunner python limit).run ["-c", program] script timeout

  let eof ← run "import sys; data=sys.stdin.read(); print('unsat' if data == 'query' else 'bad')" "query"
  ensure (!eof.timedOut && eof.exitCode == 0 && eof.stdout == "unsat\n")
    "the child must receive EOF before the parent waits for exit"

  let chunked ← run "import sys,time; sys.stdout.write('s'); sys.stdout.flush(); time.sleep(0.05); sys.stdout.write('at\\n'); sys.stdout.flush()" ""
  ensure (!chunked.timedOut && chunked.stdout == "sat\n")
    "a short read must not discard later output chunks"

  let pressure := "import sys; sys.stdout.write('x'*200000); sys.stdout.flush(); sys.stderr.write('y'*200000); sys.stderr.flush(); sys.stdin.read()"
  let large ← run pressure (repeatedChar 200000 'q') 250000
  ensure (!large.timedOut && !large.outputLimitExceeded && large.exitCode == 0)
    "simultaneous stdin/stdout/stderr pressure must not deadlock"
  ensure (large.stdout == repeatedChar 200000 'x' && large.stderr == repeatedChar 200000 'y')
    "bounded capture must read both streams completely"

  let overflow ← run pressure (repeatedChar 200000 'q') 1024
  ensure (!overflow.timedOut && overflow.outputLimitExceeded)
    "output above the capture bound must be classified as overflow, not timeout"

  let blocked ← run "import time; time.sleep(30)" (repeatedChar 200000 'q') 1024 100
  ensure blocked.timedOut "the timeout must cover a blocked stdin writer"
  IO.println "all real SMT pipe regressions passed"
